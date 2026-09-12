const { GoogleGenAI } = require('@google/genai');
const {
  GEMINI_BATCH_SIZE,
  GEMINI_WAVE_DELAY_MS,
  MAX_CACHED_SUMMARIES,
} = require('../config/constants');
const {
  cleanHeadline,
  cleanSummaryOutput,
} = require('./classifierService');
const { calculateSimilarity } = require('./clusterService');
const { scrapeFullArticle } = require('./scraperService');
const {
  loadAllSummariesFromFirestore,
  saveSummaryToFirestore,
} = require('./firestoreService');

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

// In-memory RAM cache for 0ms API response times
let aiSummaryCache = {};

// Asynchronously synchronize with Cloud Firestore on startup
setImmediate(async () => {
  try {
    const cloudSummaries = await loadAllSummariesFromFirestore();
    const cloudCount = Object.keys(cloudSummaries).length;
    if (cloudCount > 0) {
      let merged = 0;
      for (const [id, summary] of Object.entries(cloudSummaries)) {
        if (!aiSummaryCache[id]) {
          aiSummaryCache[id] = summary;
          merged++;
        }
      }
      if (merged > 0) {
        console.log(`[Firestore Sync] Loaded and merged ${merged} active summaries from Cloud Firestore into RAM.`);
      }
    }
  } catch (err) {
    console.warn('[Firestore Sync] Async sync warning:', err.message);
  }
});

function saveAiSummaryCache() {
  // Pure in-memory cache; persistence is handled asynchronously via Cloud Firestore.
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
    if (!article.id || !aiSummaryCache[article.id] || aiSummaryCache[article.id].length < 100) continue;
    const sim = calculateSimilarity(article.title, cleanT);
    // Strict match only: identical or syndicated stories across publishers (sim >= 0.88)
    if (sim >= 0.88) {
      return aiSummaryCache[article.id];
    }
  }
  return null;
}

/**
 * Generates an executive summary grounded in actual scraped publisher article content.
 */
async function generateGeminiPowerSummary(articleId, title, snippet, category, player, state, discom, url, cachedArticles = []) {
  // Reject short or low-quality cached stubs (< 90 characters)
  if (articleId && aiSummaryCache[articleId] && aiSummaryCache[articleId].length >= 90) {
    return aiSummaryCache[articleId];
  }
  const cleanTitle = cleanHeadline(title);

  // Strict check: only reuse if the exact same story exists (syndicated wire copy)
  const similarSummary = findSimilarCachedSummary(cleanTitle, player, state, cachedArticles);
  if (similarSummary) {
    console.log(`[Gemini AI] Reusing identical syndicated story summary for: "${cleanTitle.slice(0, 40)}"`);
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
    const prompt = `You are the Chief Editor and Senior Power Sector Intelligence Analyst for PowerNews India. Your audience includes leadership at CEA, CERC, State DISCOMs, Power PSUs (NTPC, PGCIL, SECI), Private Utilities (Tata Power, Adani, JSW), and Grid OEMs (Siemens, Hitachi Energy, BHEL, GE Vernova).

Read the ACTUAL ARTICLE CONTENT below and synthesize an ultra-crisp executive narrative story of strictly 50 to 100 words. Deliver the briefing as a single, fluid journalistic paragraph that reads like an opening dispatch from Bloomberg Energy or Reuters.

ARTICLE METADATA:
Headline: ${cleanTitle}
Key Entity: ${player || 'Power Sector Stakeholder'}
Geography: ${state || 'National / Pan-India'} ${discom ? `(${discom})` : ''}

ACTUAL ARTICLE CONTENT:
"""
${contentToAnalyze}
"""

STRICT EDITORIAL GUIDELINES:
- Output ONLY a single, continuous paragraph of narrative prose.
- DO NOT use bullet points ("•", "-", "*"), numbers ("1.", "2."), bold section titles, preambles, or conversational filler.
- Total word count MUST strictly be between 50 and 100 words.
- Weave the complete story into 3 to 4 tightly linked sentences:
    1. The Catalyst: The core event, contract award, regulatory order, or capacity commissioning.
    2. Data & Metrics: Key figures, capacity (MW/GW), capex (₹ Crore), voltage (kV), tariff (₹/kWh), or partners.
    3. Operational & Strategic Impact: Technical scope and its broader significance for grid reliability or power supply.
- Tone: Executive business-intelligence tone (active voice, dense with facts, authoritative).
- Grounding: 100% strictly grounded in the provided article content. Never hallucinate, extrapolate, or invent numbers.`;

    const envModel = process.env.GEMINI_MODEL ? process.env.GEMINI_MODEL.trim() : null;
    const modelsToTry = envModel
      ? [envModel, 'gemini-3.1-flash-lite', 'gemini-flash-lite-latest', 'gemini-3.5-flash-lite', 'gemini-3.6-flash'].filter((v, i, a) => a.indexOf(v) === i)
      : ['gemini-3.1-flash-lite', 'gemini-flash-lite-latest', 'gemini-3.5-flash-lite', 'gemini-3.6-flash', 'gemini-3.7-flash'];

    for (const model of modelsToTry) {
      try {
        const response = await ai.models.generateContent({
          model,
          contents: prompt,
        });

        let aiText = (response.text || '').trim();
        aiText = cleanSummaryOutput(aiText);
        if (aiText && aiText.length > 40) {
          if (articleId) {
            aiSummaryCache[articleId] = aiText;
            saveSummaryToFirestore(articleId, aiText, {
              title: cleanTitle,
              category,
              player,
              state,
              discom,
              isAiGenerated: true,
            });
          }
          const wordCount = aiText.split(/\s+/).filter(Boolean).length;
          console.log(`[Gemini AI] Synthesized narrative story (${wordCount} words) for "${cleanTitle.slice(0, 40)}" via ${model}`);
          return aiText;
        }
      } catch (err) {
        if (err.message && err.message.includes('429')) {
          console.warn(`[Gemini AI] Quota limit on model ${model}. Trying fallback model...`);
          continue;
        } else {
          console.warn(`[Gemini AI] Error with model ${model} for "${cleanTitle.slice(0, 40)}":`, err.message);
        }
      }
    }
    // If all models hit quota or failed, brief cooldown before next attempt
    geminiCoolingDownUntil = Date.now() + 20000;
  }

  // Step 3: Pure Content-Grounded Heuristic Fallback (Ephemeral only — NEVER saved to DB or AI Cache)
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
  // Note: Fallbacks are NOT saved to Firestore or aiSummaryCache.
  // The curated feed and database only take genuine Gemini AI summaries.
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

  // Utmost Priority: Power Line is the power sector core entity.
  // Sort queue: Power Line first, followed by PIB/core power authorities, then general feeds.
  unsummarized.sort((a, b) => {
    const isPowerLineA = (a.source && /power line/i.test(a.source)) || (a.url && a.url.includes('powerline.net.in')) ? 1 : 0;
    const isPowerLineB = (b.source && /power line/i.test(b.source)) || (b.url && b.url.includes('powerline.net.in')) ? 1 : 0;
    if (isPowerLineA !== isPowerLineB) return isPowerLineB - isPowerLineA;

    const isCoreA = (a.source && /pib|mercom|economic times power|cea|cerc|ntpc|powergrid/i.test(a.source)) ? 1 : 0;
    const isCoreB = (b.source && /pib|mercom|economic times power|cea|cerc|ntpc|powergrid/i.test(b.source)) ? 1 : 0;
    if (isCoreA !== isCoreB) return isCoreB - isCoreA;

    return new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0);
  });

  console.log(`[Gemini AI] Starting prioritized batch summarization: ${unsummarized.length} articles (PowerLine & core power sector entities prioritized first)...`);
  let processed = 0;

  for (let i = 0; i < unsummarized.length; i += GEMINI_BATCH_SIZE) {
    if (Date.now() < geminiCoolingDownUntil) {
      const waitMs = geminiCoolingDownUntil - Date.now() + 1500;
      console.log(`[Gemini AI] Quota cooling down. Waiting ${Math.ceil(waitMs / 1000)}s before resuming batch (${processed}/${unsummarized.length} done so far)...`);
      await new Promise(r => setTimeout(r, waitMs));
    }

    const wave = unsummarized.slice(i, i + GEMINI_BATCH_SIZE);

    await Promise.allSettled(
      wave.map(async (a) => {
        try {
          const aiSum = await generateGeminiPowerSummary(
            a.id, a.title, a.summary,
            a.categories[0], a.player, a.state, a.discom, a.url, articles
          );
          if (aiSum && aiSum.length > 30 && !aiSum.startsWith('• ')) {
            a.summary = aiSum;
            processed++;
          }
        } catch (_) { /* non-fatal */ }
      })
    );

    if (i + GEMINI_BATCH_SIZE < unsummarized.length) {
      await new Promise(r => setTimeout(r, GEMINI_WAVE_DELAY_MS));
    }
  }

  console.log(`[Gemini AI] Batch complete: ${processed}/${unsummarized.length} articles summarized. Total RAM cache: ${Object.keys(aiSummaryCache).length}`);
}

// Daily Digest Cache
let dailyDigestCache = {};

function generateDailyDigest(cachedArticles = []) {
  const todayKey = new Date().toISOString().slice(0, 10);
  const cachedDigest = dailyDigestCache[todayKey];

  // If cached digest exists, check if all items have genuine AI summaries.
  // If any item was cached before its AI summary was ready, but an AI summary is now available, refresh the digest!
  if (cachedDigest && cachedDigest.items.length >= 3) {
    const hasUnsummarizedItems = cachedDigest.items.some(it => !it.isAiSummary);
    const anyNewlySummarized = hasUnsummarizedItems && cachedDigest.items.some(it =>
      it.articleId && aiSummaryCache[it.articleId] && aiSummaryCache[it.articleId].length >= 75 && !aiSummaryCache[it.articleId].startsWith('• ')
    );
    if (!anyNewlySummarized && !hasUnsummarizedItems) {
      return cachedDigest;
    }
  }

  const selected = [];
  const usedIds = new Set();

  function pickOne(predicate, pillarLabel) {
    // Utmost Priority 1: Pick an article matching predicate that already has a genuine Gemini AI summary
    let candidate = cachedArticles.find(a =>
      !usedIds.has(a.id) &&
      predicate(a) &&
      a.id &&
      aiSummaryCache[a.id] &&
      aiSummaryCache[a.id].length >= 75 &&
      !aiSummaryCache[a.id].startsWith('• ')
    );

    // Priority 2: If none in this pillar has an AI summary yet, pick matching candidate
    if (!candidate) {
      candidate = cachedArticles.find(a => !usedIds.has(a.id) && predicate(a));
    }

    if (candidate) {
      usedIds.add(candidate.id);
      const isAi = Boolean(
        candidate.id &&
        aiSummaryCache[candidate.id] &&
        aiSummaryCache[candidate.id].length >= 75 &&
        !aiSummaryCache[candidate.id].startsWith('• ')
      );
      const fullSummary = isAi ? aiSummaryCache[candidate.id] : getLatestSummary(candidate);

      let cleanBullet;
      if (isAi) {
        // Extract punchy first catalyst sentence from the narrative AI briefing
        const firstSentence = fullSummary.split(/[.!?]\s+/)[0].trim();
        cleanBullet = firstSentence.endsWith('.') ? firstSentence : `${firstSentence}.`;
      } else {
        cleanBullet = fullSummary
          .split('\n')
          .map(s => s.replace(/^[^a-zA-Z0-9]+/, '').trim())
          .filter(s => s.length > 20)[0] || candidate.title;
      }

      selected.push({
        pillar: pillarLabel,
        articleId: candidate.id,
        headline: cleanHeadline(candidate.title),
        bullet: cleanBullet,
        fullSummary: fullSummary,
        source: candidate.source,
        sources: candidate.sources || [candidate.source],
        coverageCount: candidate.coverageCount || 1,
        state: candidate.state,
        player: candidate.player,
        url: candidate.url,
        isAiSummary: isAi,
      });
    }
  }

  pickOne(a => (a.categories || []).some(c => ['transmission', 'scada', 'substation'].includes(c.toLowerCase())) || /transmission|substation|hvdc|grid|scada/i.test(a.title), 'Transmission & Grid');
  pickOne(a => (a.categories || []).some(c => ['renewables', 'generation'].includes(c.toLowerCase())) || /solar|wind|tender|auction|bess|green energy/i.test(a.title), 'Renewables & Generation');
  pickOne(a => (a.categories || []).some(c => ['distribution', 'smart meters', 'tariffs'].includes(c.toLowerCase())) || /discom|meter|tariff|rdss|consumer|bill/i.test(a.title), 'DISCOMs & Smart Metering');
  pickOne(a => a.player && a.player !== 'Power Sector Stakeholder' && /bhel|hitachi|siemens|abb|schneider|apar|genus|premier|waaree|inox|suzlon|larsen/i.test(a.player), 'OEMs & Equipment');
  pickOne(a => /cerc|serc|cea|ministry|ntpc|powergrid|nhpc|sjvn|seci/i.test(a.title + (a.player || '')), 'Policy & Regulators');

  // Fill up to 5 items if any pillar was missing, preferring AI-summarized articles
  const remainingCandidates = cachedArticles
    .filter(a => !usedIds.has(a.id))
    .sort((a, b) => {
      const aHasAi = (a.id && aiSummaryCache[a.id] && !aiSummaryCache[a.id].startsWith('• ')) ? 1 : 0;
      const bHasAi = (b.id && aiSummaryCache[b.id] && !aiSummaryCache[b.id].startsWith('• ')) ? 1 : 0;
      if (aHasAi !== bHasAi) return bHasAi - aHasAi;
      return new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0);
    });

  for (const a of remainingCandidates) {
    if (selected.length >= 5) break;
    usedIds.add(a.id);
    const isAi = Boolean(
      a.id &&
      aiSummaryCache[a.id] &&
      aiSummaryCache[a.id].length >= 75 &&
      !aiSummaryCache[a.id].startsWith('• ')
    );
    const fullSummary = isAi ? aiSummaryCache[a.id] : getLatestSummary(a);

    let cleanBullet;
    if (isAi) {
      const firstSentence = fullSummary.split(/[.!?]\s+/)[0].trim();
      cleanBullet = firstSentence.endsWith('.') ? firstSentence : `${firstSentence}.`;
    } else {
      cleanBullet = fullSummary
        .split('\n')
        .map(s => s.replace(/^[^a-zA-Z0-9]+/, '').trim())
        .filter(s => s.length > 20)[0] || a.title;
    }

    selected.push({
      pillar: a.categories && a.categories[0] ? a.categories[0].toUpperCase() : 'Sector News',
      articleId: a.id,
      headline: cleanHeadline(a.title),
      bullet: cleanBullet,
      fullSummary: fullSummary,
      source: a.source,
      sources: a.sources || [a.source],
      coverageCount: a.coverageCount || 1,
      state: a.state,
      player: a.player,
      url: a.url,
      isAiSummary: isAi,
    });
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
    const envModel = process.env.GEMINI_MODEL ? process.env.GEMINI_MODEL.trim() : null;
    const modelsToTry = envModel ? [envModel] : ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash'];

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
          console.warn(`[Gemini AI Q&A] Quota cooling down (429). Pausing for 30s.`);
          break; // Stop trying other models on quota error
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
