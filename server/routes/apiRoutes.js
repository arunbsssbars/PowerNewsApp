const express = require('express');
const path = require('path');
const fs = require('fs');
const articleStore = require('../services/articleStore');
const { getArticleContentById } = require('../services/firestoreService');
const {
  UTILITY_PLAYER_RULES,
  STATE_DISCOM_DIRECTORY,
  HIGH_VALUE_KEYWORDS,
} = require('../config/rules');
const {
  cleanHeadline,
  cleanText,
  filterArticlesRetention7Days,
} = require('../services/classifierService');
const {
  ai,
  aiSummaryCache,
  geminiCoolingDownUntil,
  generateGeminiPowerSummary,
  runGeminiBatchSummarization,
  generateDailyDigest,
  askGeminiQnA,
  discoverNewKeywordsFromNews,
} = require('../services/geminiService');
const {
  searchLiveTopicRSS,
  syncFeeds,
} = require('../services/rssService');
const {
  scrapeFullArticle,
} = require('../services/scraperService');
const { DEFAULT_PAGE_SIZE } = require('../config/constants');
const { getSystemLifecycle } = require('../services/systemStateService');

const router = express.Router();
const rateLimit = require('express-rate-limit');

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 150,
  message: { error: 'Too many requests from this IP, please try again after 15 minutes' }
});

const qnaLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many Q&A requests, please try again later' }
});

// Auth Middleware
async function requireApiKey(req, res, next) {
  if (req.path === '/health' || req.path === '/apk' || req.path === '/memory') {
    return next();
  }
  
  const providedKey = req.headers['x-api-key'] || req.query.key || req.headers['authorization'];
  if (!providedKey) {
    return res.status(401).json({ error: 'Unauthorized access' });
  }

  // 1. Check legacy API Secret (used by the mobile app for now, if necessary)
  const expectedSecret = process.env.APP_CLIENT_SECRET;
  if (providedKey === expectedSecret || providedKey === `Bearer ${expectedSecret}`) {
    return next();
  }

  // 2. Otherwise, treat it as a Firebase ID Token (for web dashboard)
  const token = providedKey.replace(/^Bearer\s+/, '');
  try {
    require('../services/firestoreService').initFirestore(); // Ensure Firebase App is initialized
    const admin = require('firebase-admin');
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // STRICT ADMIN CHECK
    if (decodedToken.email !== 'arunbsssbars@gmail.com') {
      return res.status(403).json({ error: 'Forbidden: Admin access only' });
    }
    
    req.user = decodedToken;
    return next();
  } catch (error) {
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
}

// Apply Rate Limiter conditionally (allow health checks to pass infinitely for Render/UptimeRobot)
router.use((req, res, next) => {
  if (req.path === '/health' || req.path === '/apk' || req.path === '/memory') {
    return next();
  }
  return globalLimiter(req, res, next);
});
router.use(requireApiKey);

function getReadableRefreshTime(isoDateString) {
  if (!isoDateString) return 'Not refreshed yet';
  const d = new Date(isoDateString);
  const formatted = d.toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    dateStyle: 'medium',
    timeStyle: 'medium',
    hour12: true,
  }) + ' IST';

  const diffSec = Math.max(0, Math.floor((Date.now() - d.getTime()) / 1000));
  let relative = `${diffSec}s ago`;
  if (diffSec >= 60) {
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin >= 60) {
      const diffHours = Math.floor(diffMin / 60);
      relative = `${diffHours}h ago`;
    } else {
      relative = `${diffMin}m ago`;
    }
  }

  return `${formatted} (${relative})`;
}

// ----------------------------------------------------------------------------
// Strictly Verified AI Summaries Gatekeeper
// Only articles with genuine Gemini narrative summaries (saved in DB) are served
// ----------------------------------------------------------------------------
function getActiveArticles() {
  const cachedArticles = articleStore.getArticles();
  const retained = filterArticlesRetention7Days(cachedArticles);
  return retained
    .filter(a => {
      const s = a.id && aiSummaryCache[a.id];
      return Boolean(
        s &&
        s.length >= 75 &&
        !s.startsWith('• ') &&
        !s.startsWith('- ') &&
        !s.startsWith('* ') &&
        s.toLowerCase() !== a.title.trim().toLowerCase()
      );
    })
    .map(a => ({
      ...a,
      title: cleanHeadline(a.title),
      summary: aiSummaryCache[a.id],
      isAiSummary: true,
      isAiGenerated: true,
    }));
}

// ----------------------------------------------------------------------------
// Core Health & Ingestion
// ----------------------------------------------------------------------------
router.get('/health', (req, res) => {
  const rawArticles = articleStore.getArticles();
  const activeSummaries = getActiveArticles();
  const rawDate = articleStore.getLastRefreshedAt();
  const lifecycle = getSystemLifecycle();

  res.json({
    app: 'PowerNews',
    status: 'healthy',
    uptimeSeconds: lifecycle.uptimeSeconds,
    uptimeFormatted: lifecycle.uptimeFormatted,
    serverStartedAt: lifecycle.serverStartedAt,
    serverStartedAtIso: lifecycle.serverStartedAtIso,
    lastRestartReason: lifecycle.lastRestartReason,
    restartCount: lifecycle.restartCount,
    previousExitTime: lifecycle.previousExitTime,
    databaseMode: lifecycle.databaseMode,
    totalArticles: activeSummaries.length,
    rawScrapedArticles: rawArticles.length,
    totalAiSummaries: Object.keys(aiSummaryCache).length,
    lastRefreshedAt: getReadableRefreshTime(rawDate),
    lastRefreshedAtIso: rawDate || null,
  });
});

router.get('/memory', (req, res) => {
  const mem = process.memoryUsage();
  res.json({
    rssMb: `${(mem.rss / (1024 * 1024)).toFixed(1)} MB`,
    heapUsedMb: `${(mem.heapUsed / (1024 * 1024)).toFixed(1)} MB`,
    heapTotalMb: `${(mem.heapTotal / (1024 * 1024)).toFixed(1)} MB`,
    externalMb: `${(mem.external / (1024 * 1024)).toFixed(1)} MB`,
    totalCachedArticles: articleStore.getArticles().length,
    totalAiSummaries: Object.keys(aiSummaryCache).length,
  });
});

router.get('/refresh', async (req, res) => {
  const freshArticles = await syncFeeds(articleStore.getArticles());
  articleStore.setArticles(freshArticles);
  res.json({ success: true, count: freshArticles.length });
});

// ----------------------------------------------------------------------------
// Primary News Feed Endpoint (Strictly AI-Summarized Curated Feed)
// ----------------------------------------------------------------------------
router.get('/news', async (req, res) => {
  const { category, state, city, discom, player, search, source, page = 1, limit = DEFAULT_PAGE_SIZE } = req.query;
  const activePool = getActiveArticles();

  let filtered = [...activePool];

  if (category && category !== 'All') {
    const catLower = category.toLowerCase();
    filtered = filtered.filter(
      (a) =>
        (a.categories || []).some((c) => c.toLowerCase() === catLower) ||
        (catLower === 'scada' &&
          ((a.title && a.title.toLowerCase().includes('scada')) ||
            (a.summary && a.summary.toLowerCase().includes('scada')) ||
            (a.title && a.title.toLowerCase().includes('automation')) ||
            (a.summary && a.summary.toLowerCase().includes('automation')) ||
            (a.title && a.title.toLowerCase().includes('substation')) ||
            (a.title && a.title.toLowerCase().includes('it-ot'))))
    );
  }

  if (player && player !== 'All Players' && player !== 'All') {
    const pLower = player.toLowerCase();
    const rule = UTILITY_PLAYER_RULES.find(r => r.player.toLowerCase() === pLower || r.player.toLowerCase().includes(pLower));
    const keywords = rule ? rule.keywords.map(k => k.toLowerCase()) : [pLower];

    filtered = filtered.filter((a) => {
      if (a.player === player || (a.player && a.player.toLowerCase().includes(pLower))) return true;
      const titleLower = (a.title || '').toLowerCase();
      const summaryLower = (a.summary || '').toLowerCase();
      return keywords.some((k) => titleLower.includes(k) || summaryLower.includes(k));
    });
  }

  if (state && state !== 'All States') {
    filtered = filtered.filter((a) => a.state === state);
  }

  if (city && city !== 'All Cities') {
    filtered = filtered.filter((a) => a.city === city);
  }

  if (discom && discom !== 'All DISCOMs') {
    filtered = filtered.filter((a) => a.discom === discom);
  }

  if (source && source !== 'All Sources') {
    filtered = filtered.filter((a) => a.source === source);
  }

  if (search && search.trim()) {
    const q = search.toLowerCase().trim();
    filtered = filtered.filter(
      (a) => (a.title && a.title.toLowerCase().includes(q)) || (a.summary && a.summary.toLowerCase().includes(q))
    );
  }

  // --- Phase 1: Balanced Power Sector Scoring Algorithm ---
  const isDefaultFeed = !category || category === 'All';

  filtered.forEach((a) => {
    let baseScore = 100; // Base points

    const titleLower = (a.title || '').toLowerCase();
    const summaryLower = (a.summary || '').toLowerCase();
    const sourceLower = (a.source || '').toLowerCase();
    const categories = (a.categories || []).map((c) => c.toLowerCase());

    // 2. Keyword Boosting (Targeting underserved verticals)
    let keywordMatches = 0;
    for (const kw of HIGH_VALUE_KEYWORDS) {
      if (titleLower.includes(kw) || summaryLower.includes(kw)) {
        keywordMatches++;
      }
    }
    baseScore += (keywordMatches * 50);

    // 3. Source Weighting
    if (sourceLower.includes('powerline') || sourceLower.includes('press release')) {
      baseScore += 80;
    }
    if (sourceLower.includes('mercom')) {
      // Normalize Mercom's high volume
      baseScore -= 20;
    }

    // Penalize generic solar if it's the main feed to allow tech/OEMs to surface
    if (isDefaultFeed && (categories.includes('solar') || categories.includes('renewables'))) {
      baseScore -= 30;
    }

    // 4. Time Decay (Gravity Algorithm: Score = P / (T + 2)^G)
    const ageInHours = (Date.now() - new Date(a.publishedAt).getTime()) / (1000 * 60 * 60);
    const safeAge = Math.max(0, ageInHours);
    a._calculatedScore = baseScore / Math.pow(safeAge + 2, 1.5);
  });

  // Sort by calculated score descending
  filtered.sort((a, b) => b._calculatedScore - a._calculatedScore);

  // 1. Anti-Clumping (Category Quotas for Solar)
  if (isDefaultFeed) {
    let recentSolarCount = 0;
    for (let i = 0; i < filtered.length; i++) {
      const cats = (filtered[i].categories || []).map((c) => c.toLowerCase());
      const isSolar = cats.includes('solar') || cats.includes('renewables');

      if (isSolar) {
        recentSolarCount++;
        if (recentSolarCount > 2) {
          // Find next non-solar article and swap to break the clump
          let swapIdx = -1;
          for (let j = i + 1; j < filtered.length; j++) {
            const jCats = (filtered[j].categories || []).map((c) => c.toLowerCase());
            if (!jCats.includes('solar') && !jCats.includes('renewables')) {
              swapIdx = j;
              break;
            }
          }
          if (swapIdx !== -1) {
            const temp = filtered[i];
            filtered[i] = filtered[swapIdx];
            filtered[swapIdx] = temp;
            recentSolarCount = 0; // Reset after breaking clump
          }
        }
      } else {
        recentSolarCount = 0;
      }
    }
  }

  const p = parseInt(page, 10) || 1;
  const l = parseInt(limit, 10) || DEFAULT_PAGE_SIZE;
  const startIndex = (p - 1) * l;
  const paginated = filtered.slice(startIndex, startIndex + l);

  res.json({
    total: filtered.length,
    page: p,
    limit: l,
    articles: paginated
  });
});

// ----------------------------------------------------------------------------
// Scraped Full Article Content (Reader Mode)
// ----------------------------------------------------------------------------
router.get('/article-content', async (req, res) => {
  const { url, id } = req.query;
  if (!url || !url.startsWith('http')) {
    return res.status(400).json({ success: false, message: 'Valid url query parameter required' });
  }

  // 1. Try fetching from Firestore first (Zero-scrape instant load)
  if (id) {
    const cachedContent = await getArticleContentById(id);
    if (cachedContent && cachedContent.length > 200) {
      return res.json({
        success: true,
        url,
        summary: null,
        fullText: cachedContent,
        cached: true,
      });
    }
  }

  // 2. Fallback to live scraping
  const scraped = await scrapeFullArticle(url);
  if (scraped && scraped.fullText) {
    return res.json({
      success: true,
      url,
      summary: scraped.summary,
      fullText: scraped.fullText,
      cached: false,
    });
  }

  return res.json({
    success: false,
    message: 'Could not extract article body from publisher'
  });
});

// ----------------------------------------------------------------------------
// On-Demand AI Summary
// ----------------------------------------------------------------------------
router.get('/article-summary', async (req, res) => {
  const { id, title, snippet, category, player, state, discom, url } = req.query;
  if (!title) {
    return res.status(400).json({ success: false, message: 'Title is required' });
  }

  try {
    const wasCached = !!(id && aiSummaryCache[id] && aiSummaryCache[id].length > 40);

    const existingArticle = articleStore.getArticles().find(a => a.id === id);
    const summary = await generateGeminiPowerSummary(
      id, title, snippet || '', category || 'Power Sector', player, state, discom, url, articleStore.getArticles(), existingArticle
    );

    if (id && summary && !summary.startsWith('• ') && summary.length >= 75 && summary.toLowerCase() !== title.trim().toLowerCase()) {
      aiSummaryCache[id] = summary;
      if (existingArticle) existingArticle.summary = summary;
    }

    return res.json({
      success: true,
      id,
      summary,
      cached: wasCached
    });
  } catch (err) {
    console.warn('[Gemini API] Failed to generate on-demand summary:', err.message);
    return res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

router.get('/search-topic', async (req, res) => {
  const { q } = req.query;
  if (!q || !q.trim()) {
    return res.json({ total: 0, articles: [] });
  }
  const results = await searchLiveTopicRSS(q, { applyGemini: true });
  res.json({
    total: results.length,
    query: q,
    articles: results
  });
});

// ----------------------------------------------------------------------------
// Metadata & Category Counters
// ----------------------------------------------------------------------------
router.get('/players', (req, res) => {
  const counts = {};
  const activeArticles = getActiveArticles();
  for (const rule of UTILITY_PLAYER_RULES) {
    const pName = rule.player;
    const keywords = rule.keywords.map(k => k.toLowerCase());
    const count = activeArticles.filter(a => {
      if (a.player === pName) return true;
      const titleLower = (a.title || '').toLowerCase();
      const summaryLower = (a.summary || '').toLowerCase();
      return keywords.some(k => titleLower.includes(k) || summaryLower.includes(k));
    }).length;
    counts[pName] = count;
  }
  res.json(counts);
});

router.get('/cities', (req, res) => {
  const counts = {};
  for (const article of getActiveArticles()) {
    if (article.city) {
      counts[article.city] = (counts[article.city] || 0) + 1;
    }
  }
  res.json(counts);
});

router.get('/categories', (req, res) => {
  const counts = {
    generation: 0,
    transmission: 0,
    distribution: 0,
    renewables: 0,
    policy: 0,
    tenders: 0,
    scada: 0
  };
  for (const article of getActiveArticles()) {
    for (const cat of article.categories || []) {
      if (counts[cat] !== undefined) {
        counts[cat]++;
      }
    }
  }
  res.json(counts);
});

router.get('/states', (req, res) => {
  const counts = {};
  for (const article of getActiveArticles()) {
    if (article.state) {
      counts[article.state] = (counts[article.state] || 0) + 1;
    }
  }
  res.json(counts);
});

router.get('/discoms', (req, res) => {
  const counts = {};
  for (const article of getActiveArticles()) {
    if (article.discom) {
      counts[article.discom] = (counts[article.discom] || 0) + 1;
    }
  }
  res.json(counts);
});

router.get('/state-discoms', (req, res) => {
  res.json(STATE_DISCOM_DIRECTORY);
});

router.get('/sources', (req, res) => {
  const counts = {};
  for (const article of articleStore.getArticles()) {
    counts[article.source] = (counts[article.source] || 0) + 1;
  }
  res.json(counts);
});

// ----------------------------------------------------------------------------
// Intelligence Features: Digest, Status, Ask Gemini, Keyword Discovery, ML Data
// ----------------------------------------------------------------------------
router.get('/admin/discover-keywords', async (req, res) => {
  const articles = articleStore.getArticles();
  const result = await discoverNewKeywordsFromNews(articles, HIGH_VALUE_KEYWORDS);
  res.json(result);
});

router.get('/admin/training-data', async (req, res) => {
  const limit = parseInt(req.query.limit) || 50;
  const data = await require('../services/firestoreService').getTrainingData(limit);
  res.json({ success: true, data });
});

router.post('/admin/training-data/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status) return res.status(400).json({ error: 'Status is required' });
  const success = await require('../services/firestoreService').updateTrainingDataStatus(id, status);
  res.json({ success });
});

router.get('/admin/export-dataset', async (req, res) => {
  try {
    const rawData = await require('../services/firestoreService').getApprovedTrainingData();
    
    // Format perfectly for Gemini Fine-Tuning (.jsonl)
    let jsonlString = '';
    for (const doc of rawData) {
      if (!doc.originalText || !doc.geminiSummary) continue;
      
      const payload = {
        messages: [
          { role: 'user', content: doc.originalText },
          { role: 'model', content: doc.geminiSummary }
        ]
      };
      jsonlString += JSON.stringify(payload) + '\n';
    }

    res.setHeader('Content-Type', 'application/jsonl');
    res.setHeader('Content-Disposition', 'attachment; filename="power60_dataset.jsonl"');
    res.send(jsonlString);
  } catch (error) {
    res.status(500).json({ error: 'Failed to export dataset' });
  }
});

router.get('/gemini-status', (req, res) => {
  const cachedArticles = articleStore.getArticles();
  const total = cachedArticles.length;
  const summarized = cachedArticles.filter(a => !!aiSummaryCache[a.id]).length;
  const unsummarized = total - summarized;
  const coverage = total > 0 ? ((summarized / total) * 100).toFixed(1) : '0.0';

  const byPlayer = {};
  const byState = {};
  const byDiscom = {};

  for (const article of cachedArticles) {
    const hasSummary = !!aiSummaryCache[article.id];
    if (article.player) {
      if (!byPlayer[article.player]) byPlayer[article.player] = { total: 0, summarized: 0 };
      byPlayer[article.player].total++;
      if (hasSummary) byPlayer[article.player].summarized++;
    }
    if (article.state && article.state !== 'National / Pan-India') {
      if (!byState[article.state]) byState[article.state] = { total: 0, summarized: 0 };
      byState[article.state].total++;
      if (hasSummary) byState[article.state].summarized++;
    }
    if (article.discom) {
      if (!byDiscom[article.discom]) byDiscom[article.discom] = { total: 0, summarized: 0 };
      byDiscom[article.discom].total++;
      if (hasSummary) byDiscom[article.discom].summarized++;
    }
  }

  res.json({
    aiEnabled: !!ai,
    totalArticles: total,
    geminiSummarized: summarized,
    unsummarized,
    coveragePercent: `${coverage}%`,
    totalCachedSummaries: Object.keys(aiSummaryCache).length,
    byPlayer,
    byState,
    byDiscom
  });
});

router.get('/morning-digest', (req, res) => {
  const digest = generateDailyDigest(articleStore.getArticles());
  res.json(digest);
});

router.post('/ask-gemini', qnaLimiter, async (req, res) => {
  const { question, persona } = req.body || {};
  if (!question || typeof question !== 'string' || question.trim().length < 3) {
    return res.status(400).json({ success: false, message: 'A valid question is required.' });
  }
  const result = await askGeminiQnA(question, persona, articleStore.getArticles());
  return res.json(result);
});

router.get('/summarize-all', async (req, res) => {
  if (!ai) {
    return res.status(503).json({ success: false, message: 'Gemini AI not initialized. Check GEMINI_API_KEY in .env' });
  }
  const cachedArticles = articleStore.getArticles();
  const unsummarized = cachedArticles.filter(a => !aiSummaryCache[a.id]).length;
  setImmediate(() => runGeminiBatchSummarization(cachedArticles));
  res.json({
    success: true,
    message: `Gemini batch summarization started for ${unsummarized} unsummarized articles.`,
    totalArticles: cachedArticles.length,
    unsummarized
  });
});

module.exports = router;
