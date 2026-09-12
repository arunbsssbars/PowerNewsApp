const express = require('express');
const path = require('path');
const fs = require('fs');
const articleStore = require('../services/articleStore');
const {
  UTILITY_PLAYER_RULES,
  STATE_DISCOM_DIRECTORY,
} = require('../config/rules');
const {
  cleanHeadline,
  cleanText,
  filterArticlesRetention7Days,
} = require('../services/classifierService');
const {
  ai,
  aiSummaryCache,
  saveAiSummaryCache,
  geminiCoolingDownUntil,
  generateGeminiPowerSummary,
  runGeminiBatchSummarization,
  generateDailyDigest,
  askGeminiQnA,
} = require('../services/geminiService');
const {
  searchLiveTopicRSS,
  syncFeeds,
} = require('../services/rssService');
const {
  scrapeFullArticle,
} = require('../services/scraperService');
const { DEFAULT_PAGE_SIZE } = require('../config/constants');

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
function requireApiKey(req, res, next) {
  if (req.path === '/health' || req.path === '/apk' || req.path === '/memory') {
    return next();
  }
  
  const expectedSecret = process.env.APP_CLIENT_SECRET;
  const apiKey = req.headers['x-api-key'];
  if (!apiKey || apiKey !== expectedSecret) {
    return res.status(401).json({ error: 'Unauthorized access' });
  }
  next();
}

router.use(globalLimiter);
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
// Core Health & Ingestion
// ----------------------------------------------------------------------------
router.get('/health', (req, res) => {
  const articles = articleStore.getArticles();
  const rawDate = articleStore.getLastRefreshedAt();
  res.json({
    app: 'PowerNews',
    status: 'healthy',
    uptimeSeconds: Math.floor(process.uptime()),
    totalArticles: articles.length,
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
// Primary News Feed Endpoint
// ----------------------------------------------------------------------------
router.get('/news', async (req, res) => {
  const { category, state, city, discom, player, search, source, page = 1, limit = DEFAULT_PAGE_SIZE } = req.query;
  const cachedArticles = articleStore.getArticles();

  let filtered = filterArticlesRetention7Days([...cachedArticles]);

  if (category && category !== 'All') {
    const catLower = category.toLowerCase();
    let catMatches = filtered.filter(
      (a) =>
        a.categories.some((c) => c.toLowerCase() === catLower) ||
        (catLower === 'scada' &&
          (a.title.toLowerCase().includes('scada') ||
            a.summary.toLowerCase().includes('scada') ||
            a.title.toLowerCase().includes('automation') ||
            a.summary.toLowerCase().includes('automation') ||
            a.title.toLowerCase().includes('substation') ||
            a.title.toLowerCase().includes('it-ot')))
    );

    if (catMatches.length < 5) {
      try {
        const queryTopic = catLower === 'scada' ? 'SCADA power grid' : category;
        const liveCatResults = await searchLiveTopicRSS(queryTopic);
        for (const item of liveCatResults) {
          if (!item.categories.includes(catLower)) {
            item.categories.unshift(catLower);
          }
        }
        const combined = [...catMatches, ...liveCatResults];
        const seen = new Set();
        catMatches = combined.filter((item) => {
          const key = item.title.toLowerCase().replace(/[^a-z0-9]/g, '');
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
        const allCached = articleStore.getArticles();
        for (const item of liveCatResults) {
          if (!allCached.some(a => a.id === item.id)) {
            allCached.push(item);
          }
        }
      } catch (_) { }
    }

    catMatches = filterArticlesRetention7Days(catMatches);
    catMatches.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    filtered = catMatches;
  }

  if (player && player !== 'All Players' && player !== 'All') {
    const pLower = player.toLowerCase();
    const rule = UTILITY_PLAYER_RULES.find(r => r.player.toLowerCase() === pLower || r.player.toLowerCase().includes(pLower));
    const keywords = rule ? rule.keywords.map(k => k.toLowerCase()) : [pLower];

    let playerMatches = filtered.filter((a) => {
      if (a.player === player || (a.player && a.player.toLowerCase().includes(pLower))) return true;
      const titleLower = (a.title || '').toLowerCase();
      const summaryLower = (a.summary || '').toLowerCase();
      return keywords.some((k) => titleLower.includes(k) || summaryLower.includes(k));
    });

    if (playerMatches.length < 3) {
      try {
        const liveQuery = rule ? `${rule.player} power India` : `${player} power India`;
        const liveResults = await searchLiveTopicRSS(liveQuery);
        for (const item of liveResults) {
          if (!item.player) item.player = rule ? rule.player : player;
        }
        const combined = [...playerMatches, ...liveResults];
        const seen = new Set();
        playerMatches = combined.filter((item) => {
          const key = item.title.toLowerCase().replace(/[^a-z0-9]/g, '');
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
        // Merge into cachedArticles so future requests hit cache
        const allCached = articleStore.getArticles();
        for (const item of liveResults) {
          if (!allCached.some(a => a.id === item.id)) {
            allCached.push(item);
          }
        }
      } catch (_) { }
    }

    playerMatches = filterArticlesRetention7Days(playerMatches);
    playerMatches.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    filtered = playerMatches;
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
    let localMatches = filtered.filter(
      (a) => a.title.toLowerCase().includes(q) || a.summary.toLowerCase().includes(q)
    );

    if (localMatches.length < 5) {
      try {
        const liveResults = await searchLiveTopicRSS(search);
        const combined = [...localMatches, ...liveResults];
        const seen = new Set();
        localMatches = combined.filter((item) => {
          const key = item.title.toLowerCase().replace(/[^a-z0-9]/g, '');
          if (seen.has(key)) return false;
          seen.add(key);
          return true;
        });
        // Merge live search results into articleStore cache
        const allCached = articleStore.getArticles();
        for (const item of liveResults) {
          if (!allCached.some(a => a.id === item.id)) {
            allCached.push(item);
          }
        }
      } catch (_) { }
    }

    localMatches = filterArticlesRetention7Days(localMatches);
    localMatches.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    filtered = localMatches;
  }

  filtered.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

  const p = parseInt(page, 10) || 1;
  const l = parseInt(limit, 10) || DEFAULT_PAGE_SIZE;
  const startIndex = (p - 1) * l;
  const paginated = filtered.slice(startIndex, startIndex + l).map(a => ({
    ...a,
    title: cleanHeadline(a.title),
    summary: (a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].includes('•'))
      ? aiSummaryCache[a.id]
      : cleanText(a.summary)
  }));

  // Background pre-summarization for top 10 unsummarized articles in page 1
  if (p === 1 && ai && Date.now() > geminiCoolingDownUntil) {
    setImmediate(async () => {
      const candidates = paginated.filter(a => a.id && !aiSummaryCache[a.id]).slice(0, 10);
      for (const item of candidates) {
        try {
          await generateGeminiPowerSummary(
            item.id, item.title, item.summary, item.categories?.[0], item.player, item.state, item.discom, item.url, cachedArticles
          );
        } catch (_) { }
      }
    });
  }

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
  const { url } = req.query;
  if (!url || !url.startsWith('http')) {
    return res.status(400).json({ success: false, message: 'Valid url query parameter required' });
  }

  const scraped = await scrapeFullArticle(url);
  if (scraped && scraped.fullText) {
    return res.json({
      success: true,
      url,
      summary: scraped.summary,
      fullText: scraped.fullText
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
    const wasCached = !!(id && aiSummaryCache[id] && aiSummaryCache[id].includes('•'));

    const summary = await generateGeminiPowerSummary(
      id, title, snippet || '', category || 'Power Sector', player, state, discom, url, articleStore.getArticles()
    );

    if (id && summary) {
      aiSummaryCache[id] = summary;
      saveAiSummaryCache();
      const article = articleStore.getArticles().find(a => a.id === id);
      if (article) article.summary = summary;
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
  const cachedArticles = articleStore.getArticles();
  for (const rule of UTILITY_PLAYER_RULES) {
    const pName = rule.player;
    const keywords = rule.keywords.map(k => k.toLowerCase());
    const count = cachedArticles.filter(a => {
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
  for (const article of articleStore.getArticles()) {
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
  for (const article of articleStore.getArticles()) {
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
  for (const article of articleStore.getArticles()) {
    counts[article.state] = (counts[article.state] || 0) + 1;
  }
  res.json(counts);
});

router.get('/discoms', (req, res) => {
  const counts = {};
  for (const article of articleStore.getArticles()) {
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
// Intelligence Features: Digest, Status, Ask Gemini
// ----------------------------------------------------------------------------
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
