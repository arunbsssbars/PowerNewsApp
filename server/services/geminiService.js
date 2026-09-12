const fs = require('fs');
const { GoogleGenAI } = require('@google/genai');
const {
  CACHE_FILE,
  GEMINI_BATCH_SIZE,
  GEMINI_WAVE_DELAY_MS,
  GEMINI_SAVE_EVERY,
  MAX_CACHED_SUMMARIES,
} = require('../config/constants');
const {
  cleanHeadline,
  cleanSummaryOutput,
} = require('./classifierService');
const { calculateSimilarity } = require('./clusterService');
const { scrapeFullArticle } = require('./scraperService');

const apiKey = process.env.GEMINI_API_KEY;
let ai = null;
if (apiKey) {
  try {
    ai = new GoogleGenAI({ apiKey });
    console.log('[Gemini AI] Initialized successfully with API Key.');
  } catch (err) {
    console.warn('[Gemini AI] Initialization error:', err.message);
  }
} else {
  console.warn('[Gemini AI] No GEMINI_API_KEY found in .env. AI summarization will fall back to smart heuristic extractor.');
}

let aiSummaryCache = {};
try {
  if (fs.existsSync(CACHE_FILE)) {
    aiSummaryCache = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
    console.log(`[Gemini Cache] Loaded ${Object.keys(aiSummaryCache).length} cached summaries.`);
  }
} catch (e) {
  console.warn('[Gemini Cache] Load error:', e.message);
}

function saveAiSummaryCache() {
  try {
    fs.writeFileSync(CACHE_FILE, JSON.stringify(aiSummaryCache, null, 2), 'utf8');
  } catch (e) {
    console.warn('[Gemini Cache] Save error:', e.message);
  }
}

function pruneAiSummaryCache(activeArticles = []) {
  const cacheKeys = Object.keys(aiSummaryCache);
  if (cacheKeys.length > MAX_CACHED_SUMMARIES) {
    const validIds = new Set(activeArticles.map(a => a.id).filter(Boolean));
    for (const id of cacheKeys) {
      if (!validIds.has(id)) {
        delete aiSummaryCache[id];
        if (Object.keys(aiSummaryCache).length <= MAX_CACHED_SUMMARIES) break;
      }
    }
    saveAiSummaryCache();
  }
}

function getLatestSummary(a) {
  if (!a) return '';
  const fromCache = a.id && aiSummaryCache[a.id];
  return fromCache || a.summary || '';
}

let geminiCoolingDownUntil = 0;

function findSimilarCachedSummary(targetTitle, targetPlayer, targetState, cachedArticles = []) {
  if (!targetTitle || !cachedArticles || cachedArticles.length === 0) return null;
  const cleanT = cleanHeadline(targetTitle);
  for (const article of cachedArticles) {
    if (!article.id || !aiSummaryCache[article.id] || !aiSummaryCache[article.id].includes('•')) continue;
    const sim = calculateSimilarity(article.title, cleanT);
    const sameEntity = (targetPlayer && targetPlayer !== 'Power Sector Stakeholder' && targetPlayer === article.player) ||
      (targetState && targetState !== 'National / Pan-India' && targetState === article.state);
    if (sim >= 0.45 || (sameEntity && sim >= 0.28)) {
      return aiSummaryCache[article.id];
    }
  }
  return null;
}

/**
 * Generates an executive summary grounded in actual scraped publisher article content.
 */
async function generateGeminiPowerSummary(articleId, title, snippet, category, player, state, discom, url, cachedArticles = []) {
  if (articleId && aiSummaryCache[articleId] && aiSummaryCache[articleId].includes('•')) {
    return aiSummaryCache[articleId];
  }
  const cleanTitle = cleanHeadline(title);

  // Zero-Waste Gemini Optimization: check if a similar story already has a verified AI summary
  const similarSummary = findSimilarCachedSummary(cleanTitle, player, state, cachedArticles);
  if (similarSummary) {
    console.log(`[Gemini AI] Reusing existing summary for similar story: "${cleanTitle.slice(0, 40)}" (0 API calls spent)`);
    if (articleId) {
      aiSummaryCache[articleId] = similarSummary;
      saveAiSummaryCache();
    }
    return similarSummary;
  }

  let articleContent = '';

  // Step 1: Scrape real publisher article body via Cheerio selectors
  if (url && url.startsWith('http')) {
    try {
      const scraped = await scrapeFullArticle(url);
      if (scraped && scraped.fullText && scraped.fullText.length > 80) {
        articleContent = scraped.fullText;
        console.log(`[Scraper] Successfully extracted ${articleContent.length} chars from actual article: ${url.slice(0, 60)}...`);
      }
    } catch (err) {
      console.warn(`[Scraper] Could not scrape ${url.slice(0, 50)}: ${err.message}`);
    }
  }

  // Fall back to clean snippet if scraping didn't yield body
  const contentToAnalyze = (articleContent.length > 80 ? articleContent.slice(0, 4000) : (snippet || cleanTitle)).trim();

  // Step 2: Process with Gemini AI models
  if (ai && Date.now() > geminiCoolingDownUntil) {
    const prompt = `You are an elite Senior Indian Power Sector Analyst & Editorial Expert providing intelligence briefings for key stakeholders (CEA, CERC, State DISCOMs like UPPCL/BESCOM/MSEDCL/TANGEDCO, Power PSUs like NTPC/PGCIL/NHPC/SJVN/SECI, Private Giants like Tata Power/Adani Power/JSW, and Power OEMs like BHEL/Siemens/ABB/Schneider/L&T).

Read the COMPLETE ARTICLE CONTENT below and craft a short story that covers the full article in 3 to 5 crisp, sequentially flowing bullet points — like a concise news brief that tells the whole story from start to finish:

Headline: ${cleanTitle}
Key Entity: ${player || 'Power Sector Stakeholder'}
Geography: ${state || 'Pan-India'} ${discom ? `(${discom})` : ''}

ACTUAL ARTICLE CONTENT:
"""
${contentToAnalyze}
"""

Strict Output Rules:
- Cover the COMPLETE article — from the core development to key details to impact/outlook — in 3 to 5 bullets.
- Each bullet should flow naturally as part of a short story: What happened → supporting facts → impact or next steps.
- Ground every bullet strictly in the provided article content. Do NOT hallucinate or invent facts.
- Keep bullets SHORT and punchy: maximum 15 to 20 words per bullet.
- Output 3 to 5 bullet points, each on a new line starting with "• ".
- • Bullet 1 (REQUIRED): The core event, decision, or development (the 'what happened').
- • Bullet 2 (if article contains numbers/data): Key figures, metrics, or specifics (MW/GW, ₹ Crore, kV, ₹/kWh, dates, entities). Skip if no such data exists.
- • Bullet 3 (if applicable): Operational, regulatory, or grid-level context or implication. Skip if not mentioned.
- • Bullet 4 (if applicable): A secondary detail or stakeholder angle from the article. Skip if not present.
- • Bullet 5 (if applicable): Forward outlook, next steps, or broader significance mentioned in the article. Skip if not present.
- IMPORTANT: Only include a bullet if its content genuinely exists in the article. Never pad with generic or invented points.
- Do NOT include markdown bold labels, preambles, section headers, or emojis. Output only the bullet lines starting with "• ".`;

    const modelsToTry = ['gemini-2.0-flash-lite', 'gemini-2.0-flash'];

    for (const model of modelsToTry) {
      try {
        const response = await ai.models.generateContent({
          model,
          contents: prompt,
        });

        let aiText = (response.text || '').trim();
        aiText = cleanSummaryOutput(aiText);
        if (aiText && aiText.includes('•') && aiText.length > 25) {
          if (articleId) {
            aiSummaryCache[articleId] = aiText;
            saveAiSummaryCache();
          }
          console.log(`[Gemini AI] Synthesized ${aiText.split('\n').length} bullets for "${cleanTitle.slice(0, 40)}" via ${model}`);
          return aiText;
        }
      } catch (err) {
        if (err.message && err.message.includes('429')) {
          geminiCoolingDownUntil = Date.now() + 30000; // 30s pause
          console.warn(`[Gemini AI] Quota cooling down (429). Pausing for 30s.`);
        } else {
          console.warn(`[Gemini AI] Error with model ${model} for "${cleanTitle.slice(0, 40)}":`, err.message);
        }
      }
    }
  }

  // Step 3: Pure Content-Grounded Heuristic Fallback
  const fallbackBullets = [];
  if (articleContent && articleContent.length > 80) {
    const paras = articleContent
      .split('\n\n')
      .map(p => p.trim())
      .filter(p => p.length > 35 && !p.toLowerCase().startsWith(cleanTitle.toLowerCase().slice(0, 25)));

    for (const p of paras) {
      if (fallbackBullets.length >= 3) break;
      const firstSentence = p.split(/[.!?]\s+/)[0].trim();
      if (firstSentence.length > 25) {
        const words = firstSentence.split(/\s+/);
        const shortSentence = words.length > 20 ? words.slice(0, 18).join(' ') + '...' : firstSentence;
        fallbackBullets.push(`• ${shortSentence.endsWith('.') ? shortSentence : shortSentence + '.'}`);
      }
    }
  }

  if (fallbackBullets.length < 3 && snippet) {
    const clauses = snippet
      .split(/[.;]\s+/)
      .map(c => c.trim())
      .filter(c => c.length > 20 && !cleanTitle.toLowerCase().includes(c.toLowerCase().slice(0, 20)));

    for (const c of clauses) {
      if (fallbackBullets.length >= 3) break;
      const words = c.split(/\s+/);
      const shortClause = words.length > 20 ? words.slice(0, 18).join(' ') + '...' : c;
      fallbackBullets.push(`• ${shortClause.endsWith('.') ? shortClause : shortClause + '.'}`);
    }
  }

  if (fallbackBullets.length === 0) {
    fallbackBullets.push(`• ${cleanTitle}.`);
  }

  const result = cleanSummaryOutput(fallbackBullets.join('\n'));
  if (articleId && result.length > 20) {
    aiSummaryCache[articleId] = result;
    saveAiSummaryCache();
  }
  return result;
}

/**
 * Batched background summarization queue
 */
async function runGeminiBatchSummarization(articles = []) {
  if (!ai || !articles || articles.length === 0) return;

  const unsummarized = articles.filter(a => !aiSummaryCache[a.id]);
  if (unsummarized.length === 0) {
    console.log('[Gemini AI] All articles already summarized — nothing to do.');
    return;
  }

  console.log(`[Gemini AI] Starting full batch summarization: ${unsummarized.length} articles across all outlets, OEMs, utilities, DISCOMs & states...`);
  let processed = 0;
  let savedCount = 0;

  for (let i = 0; i < unsummarized.length; i += GEMINI_BATCH_SIZE) {
    if (Date.now() < geminiCoolingDownUntil) {
      console.log('[Gemini AI] Quota cooling down. Pausing batch to prioritize on-demand user requests.');
      break;
    }

    const wave = unsummarized.slice(i, i + GEMINI_BATCH_SIZE);

    await Promise.allSettled(
      wave.map(async (a) => {
        try {
          const aiSum = await generateGeminiPowerSummary(
            a.id, a.title, a.summary,
            a.categories[0], a.player, a.state, a.discom, a.url, articles
          );
          if (aiSum && aiSum.length > 30) {
            a.summary = aiSum;
            processed++;
            savedCount++;
            if (savedCount % GEMINI_SAVE_EVERY === 0) {
              saveAiSummaryCache();
            }
          }
        } catch (_) { /* non-fatal */ }
      })
    );

    if (i + GEMINI_BATCH_SIZE < unsummarized.length) {
      await new Promise(r => setTimeout(r, GEMINI_WAVE_DELAY_MS));
    }
  }

  saveAiSummaryCache();
  console.log(`[Gemini AI] Batch complete: ${processed}/${unsummarized.length} articles summarized. Total cache: ${Object.keys(aiSummaryCache).length}`);
}

// Daily Digest Cache
let dailyDigestCache = {};

function generateDailyDigest(cachedArticles = []) {
  const todayKey = new Date().toISOString().slice(0, 10);
  if (dailyDigestCache[todayKey] && dailyDigestCache[todayKey].items.length >= 3) {
    return dailyDigestCache[todayKey];
  }

  const selected = [];
  const usedIds = new Set();

  function pickOne(predicate, pillarLabel) {
    const candidate = cachedArticles.find(a => !usedIds.has(a.id) && predicate(a));
    if (candidate) {
      usedIds.add(candidate.id);
      const latestSummary = getLatestSummary(candidate);
      const cleanBullet = latestSummary
        .split('\n')
        .map(s => s.replace(/^[^a-zA-Z0-9]+/, '').trim())
        .filter(s => s.length > 20)[0] || candidate.title;

      selected.push({
        pillar: pillarLabel,
        articleId: candidate.id,
        headline: candidate.title,
        bullet: cleanBullet,
        fullSummary: latestSummary,
        source: candidate.source,
        sources: candidate.sources || [candidate.source],
        coverageCount: candidate.coverageCount || 1,
        state: candidate.state,
        player: candidate.player,
        url: candidate.url,
      });
    }
  }

  pickOne(a => (a.categories || []).some(c => ['transmission', 'scada', 'substation'].includes(c.toLowerCase())) || /transmission|substation|hvdc|grid|scada/i.test(a.title), 'Transmission & Grid');
  pickOne(a => (a.categories || []).some(c => ['renewables', 'generation'].includes(c.toLowerCase())) || /solar|wind|tender|auction|bess|green energy/i.test(a.title), 'Renewables & Generation');
  pickOne(a => (a.categories || []).some(c => ['distribution', 'smart meters', 'tariffs'].includes(c.toLowerCase())) || /discom|meter|tariff|rdss|consumer|bill/i.test(a.title), 'DISCOMs & Smart Metering');
  pickOne(a => a.player && a.player !== 'Power Sector Stakeholder' && /bhel|hitachi|siemens|abb|schneider|apar|genus|premier|waaree|inox|suzlon|larsen/i.test(a.player), 'OEMs & Equipment');
  pickOne(a => /cerc|serc|cea|ministry|ntpc|powergrid|nhpc|sjvn|seci/i.test(a.title + (a.player || '')), 'Policy & Regulators');

  for (const a of cachedArticles) {
    if (selected.length >= 5) break;
    if (!usedIds.has(a.id)) {
      usedIds.add(a.id);
      const latestSummary = getLatestSummary(a);
      const cleanBullet = latestSummary
        .split('\n')
        .map(s => s.replace(/^[^a-zA-Z0-9]+/, '').trim())
        .filter(s => s.length > 20)[0] || a.title;

      selected.push({
        pillar: a.categories && a.categories[0] ? a.categories[0].toUpperCase() : 'Sector News',
        articleId: a.id,
        headline: a.title,
        bullet: cleanBullet,
        fullSummary: latestSummary,
        source: a.source,
        sources: a.sources || [a.source],
        coverageCount: a.coverageCount || 1,
        state: a.state,
        player: a.player,
        url: a.url,
      });
    }
  }

  const expandForTTS = (text) => {
    if (!text) return '';
    return text
      .replace(/₹/g, 'Rupees ')
      .replace(/\bRs\.?\b/g, 'Rupees ')
      .replace(/\bcr\b/gi, 'crore')
      .replace(/\bMW\b/g, 'Megawatts')
      .replace(/\bGW\b/g, 'Gigawatts')
      .replace(/\bkV\b/g, 'kilovolts')
      .replace(/\bPGCIL\b/g, 'Power Grid Corporation')
      .replace(/\bNTPC\b/g, 'N.T.P.C.')
      .replace(/\bSECI\b/g, 'S.E.C.I.')
      .replace(/\bMoP\b/g, 'Ministry of Power')
      .replace(/\bCERC\b/g, 'C.E.R.C.')
      .replace(/\bDISCOMs\b/gi, 'distribution companies')
      .replace(/\bDISCOM\b/gi, 'distribution company')
      .replace(/\bBESS\b/g, 'Battery Energy Storage Systems')
      .replace(/\bHVDC\b/g, 'High Voltage D.C.')
      .replace(/\bEPC\b/g, 'E.P.C.')
      .replace(/\bTBCB\b/g, 'T.B.C.B.')
      .replace(/&/g, 'and');
  };

  const broadcastTransitions = [
    "Leading our headlines,",
    "Turning to",
    "In other developments,",
    "Moving on to",
    "And finally, wrapping up our digest,"
  ];

  let audioScript = `Good morning. You're tuned into the Daily Power Executive Briefing. Here are the top stories shaping the Indian grid today. `;

  selected.forEach((item, idx) => {
    const transition = idx === 0
      ? broadcastTransitions[0]
      : (idx === selected.length - 1 ? broadcastTransitions[4] : broadcastTransitions[(idx % 3) + 1]);

    const pillarTTS = expandForTTS(item.pillar);
    const headlineTTS = expandForTTS(item.headline);
    const bulletTTS = expandForTTS(item.bullet);

    audioScript += `${transition} the ${pillarTTS} sector: ${headlineTTS}. ${bulletTTS}. `;
  });

  audioScript += `That concludes your executive power digest for today. Thank you for listening, and have a highly productive day ahead!`;

  const digest = {
    date: todayKey,
    title: 'Daily Power Executive Briefing',
    subtitle: `${selected.length} Top Grid, DISCOM & OEM Developments`,
    generatedAt: new Date().toISOString(),
    audioScript,
    items: selected
  };

  if (selected.length >= 3) {
    dailyDigestCache = { [todayKey]: digest };
  }
  return digest;
}

/**
 * Interactive Q&A with Gemini using cached articles as grounded context
 */
async function askGeminiQnA(question, persona, cachedArticles = []) {
  const qTrim = (question || '').trim();
  const qLower = qTrim.toLowerCase();

  const queryTokens = qLower.replace(/[^a-z0-9\s]/g, ' ').split(/\s+/).filter(t => t.length > 2);
  const scored = cachedArticles.map(a => {
    let score = 0;
    const latestSum = getLatestSummary(a);
    const text = `${a.title} ${latestSum} ${a.player || ''} ${a.state || ''} ${a.discom || ''} ${(a.categories || []).join(' ')}`.toLowerCase();
    for (const t of queryTokens) {
      if (text.includes(t)) score += 10;
      if ((a.title || '').toLowerCase().includes(t)) score += 15;
    }
    return { article: a, score };
  });

  scored.sort((a, b) => b.score - a.score);
  const topMatches = scored.filter(s => s.score > 0).slice(0, 8).map(s => s.article);
  const contextArticles = topMatches.length >= 2 ? topMatches : cachedArticles.slice(0, 5);

  const contextText = contextArticles.map((a, i) =>
    `[${i + 1}] "${a.title}" (${a.publishedAt ? a.publishedAt.slice(0, 10) : ''} | ${a.source || 'PowerNews'} | Category: ${a.categories ? a.categories.join(', ') : 'General'} | Player: ${a.player || 'Sector'} | State: ${a.state || 'National'})\nSummary: ${getLatestSummary(a)}`
  ).join('\n\n');

  const personaContext = persona && persona !== 'all'
    ? `The user's sector role is: ${persona.toUpperCase()}. Prioritize operational, financial, and regulatory aspects most relevant to this role.`
    : `The user is an Indian Power Sector executive or engineer.`;

  const prompt = `You are "PowerNews Grid AI" — an elite Senior Analyst specializing in the Indian Power & Energy Grid (Generation, Transmission, Distribution, Renewables, Utilities, DISCOMs, OEMs, and Regulations).

${personaContext}

USER QUESTION: "${qTrim}"

CURRENT SECTOR INTELLIGENCE & NEWS CONTEXT:
${contextText}

INSTRUCTIONS:
1. Provide a direct, authoritative, and fact-grounded answer based on the sector news and domain knowledge.
2. Structure your response as a short story covering the complete answer in 3 to 5 sequential bullet points:
   - • **What's happening** (REQUIRED) — The core development, decision, or status
   - • **Key figures & facts** (only if data exists) — Specific metrics, capacities, costs, dates, or entities; omit if unavailable
   - • **Grid / regulatory impact** (only if applicable) — Operational, policy, or sector-level implication; omit if not relevant
   - • **Stakeholder angle** (only if applicable) — Who is affected and how (DISCOM, OEM, PSU, etc.)
   - • **Outlook / next steps** (only if applicable) — What comes next or the broader significance
   - Only include bullets where the information genuinely exists. Do not pad with generic content.
3. If specific citations apply from the context, mention the publisher or entity (e.g. "According to POWERGRID...", "As per CERC norms...").
4. Keep the response crisp, professional, and directly actionable for grid, DISCOM, OEM and other power sector professionals.`;

  if (ai && Date.now() > geminiCoolingDownUntil) {
    const modelsToTry = ['gemini-2.0-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash'];
    for (const model of modelsToTry) {
      try {
        const response = await ai.models.generateContent({
          model,
          contents: prompt,
        });

        const answer = (response.text || '').trim();
        if (answer.length > 40) {
          return {
            success: true,
            question: qTrim,
            answer,
            groundingArticles: contextArticles.slice(0, 4).map(a => ({
              id: a.id,
              title: a.title,
              source: a.source,
              publishedAt: a.publishedAt,
              url: a.url,
            })),
          };
        }
      } catch (err) {
        if (err.message && err.message.includes('429')) {
          geminiCoolingDownUntil = Date.now() + 30000;
        }
        console.warn(`[Gemini AI Q&A] Error with model ${model}:`, err.message);
      }
    }
  }

  // Fallback
  const fallbackBulletPoints = contextArticles.slice(0, 3).map(a => `• **${a.title}**: ${a.summary.slice(0, 150)}...`).join('\n\n');
  const heuristicAnswer = `**Executive Takeaway**:\nBased on current sector intelligence on "${qTrim}", state utilities, grid operators, and OEMs are actively executing related milestones.\n\n**Key Grid Developments & Data**:\n${fallbackBulletPoints}\n\n**Strategic Outlook**:\nStakeholders are tracking regulatory notifications and tender timelines to optimize project commissioning.`;

  return {
    success: true,
    question: qTrim,
    answer: heuristicAnswer,
    groundingArticles: contextArticles.slice(0, 3).map(a => ({
      id: a.id,
      title: a.title,
      source: a.source,
      publishedAt: a.publishedAt,
      url: a.url,
    })),
  };
}

module.exports = {
  ai,
  aiSummaryCache,
  geminiCoolingDownUntil,
  saveAiSummaryCache,
  pruneAiSummaryCache,
  getLatestSummary,
  findSimilarCachedSummary,
  generateGeminiPowerSummary,
  runGeminiBatchSummarization,
  generateDailyDigest,
  askGeminiQnA,
};
