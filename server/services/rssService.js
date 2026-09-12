const Parser = require('rss-parser');
const { RSS_FEEDS, ALL_PREWARM_QUERIES } = require('../config/feeds');
const {
  cleanHeadline,
  cleanText,
  parsePublisherDate,
  extractCleanSnippet,
  isPowerSectorNews,
  extractCategories,
  extractPlayer,
  extractCityStateAndDiscom,
  generateArticleId,
  filterArticlesRetention7Days,
} = require('./classifierService');
const { clusterArticles } = require('./clusterService');
const {
  ai,
  aiSummaryCache,
  generateGeminiPowerSummary,
  runGeminiBatchSummarization,
  pruneAiSummaryCache,
} = require('./geminiService');

const parser = new Parser({
  timeout: 20000,
  headers: {
    'User-Agent': 'PowerNewsEngine/3.0 (India Power Sector Intelligence)'
  }
});

async function fetchRSSArticles() {
  const results = [];
  for (const feed of RSS_FEEDS) {
    try {
      const parsed = await parser.parseURL(feed.url);
      for (const item of parsed.items || []) {
        const rawTitle = cleanText(item.title);
        const rawSummary = cleanText(item.contentSnippet || item.content || item.summary || '');
        if (!rawTitle) continue;

        if (!isPowerSectorNews(rawTitle, rawSummary, feed.isStrictPowerFeed)) {
          continue;
        }

        let categories = extractCategories(`${rawTitle} ${rawSummary}`);
        if (categories.length === 0) {
          categories = ['generation'];
        }

        const player = extractPlayer(`${rawTitle} ${rawSummary}`);
        const { city, state, discom } = extractCityStateAndDiscom(`${rawTitle} ${rawSummary}`);
        const title = cleanHeadline(rawTitle);
        const articleId = generateArticleId(item, rawTitle);
        const summary = aiSummaryCache[articleId] || extractCleanSnippet(rawTitle, rawSummary);

        const rawPubDate = item.pubDate || item.isoDate || item.date || item.published || item['dc:date'];
        results.push({
          id: articleId,
          title,
          summary,
          url: item.link || '',
          source: feed.source,
          publishedAt: parsePublisherDate(rawPubDate),
          categories,
          player,
          city,
          state,
          discom
        });
      }
    } catch (e) {
      console.warn(`[Aggregator] Feed fetch error (${feed.source}): ${e.message}`);
    }
  }
  return results;
}

async function searchLiveTopicRSS(queryText, { applyGemini = false } = {}) {
  if (!queryText || !queryText.trim()) return [];
  const cleanQ = queryText.trim().replace(/[()]/g, '');
  const encoded = encodeURIComponent(cleanQ);
  const searchUrl = `https://news.google.com/rss/search?q=${encoded}&hl=en-IN&gl=IN&ceid=IN:en`;

  try {
    const parsed = await parser.parseURL(searchUrl);
    const results = [];
    for (const item of parsed.items || []) {
      const rawTitle = cleanText(item.title);
      const rawSummary = cleanText(item.contentSnippet || item.content || item.summary || '');
      if (!rawTitle) continue;

      if (!isPowerSectorNews(rawTitle, rawSummary, false)) {
        continue;
      }

      let categories = extractCategories(`${rawTitle} ${rawSummary}`);
      if (queryText.toLowerCase().includes('scada') && !categories.includes('scada')) {
        categories.unshift('scada');
      }
      if (categories.length === 0) categories = ['scada'];

      const player = extractPlayer(`${rawTitle} ${rawSummary}`);
      const { city, state, discom } = extractCityStateAndDiscom(`${rawTitle} ${rawSummary}`);
      const title = cleanHeadline(rawTitle);
      const articleId = generateArticleId(item, rawTitle);
      const summary = aiSummaryCache[articleId] || extractCleanSnippet(rawTitle, rawSummary);

      const rawPubDate = item.pubDate || item.isoDate || item.date || item.published || item['dc:date'];
      results.push({
        id: articleId,
        title,
        summary,
        url: item.link || '',
        source: 'Google News Archive',
        publishedAt: parsePublisherDate(rawPubDate),
        categories,
        player,
        city,
        state,
        discom
      });
    }

    // Sort search results strictly newest first
    results.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

    // Apply Gemini summaries to live search results when requested
    if (applyGemini && ai) {
      const toSummarize = results.filter(a => !aiSummaryCache[a.id]).slice(0, 10);
      for (const a of toSummarize) {
        try {
          const aiSum = await generateGeminiPowerSummary(
            a.id, a.title, a.summary, a.categories[0], a.player, a.state, a.discom, a.url, results
          );
          if (aiSum && aiSum.length > 30) a.summary = aiSum;
        } catch (_) { }
        await new Promise(r => setTimeout(r, 300));
      }
    }

    return results;
  } catch (err) {
    console.warn(`[LiveSearch] Error querying topic "${queryText}":`, err.message);
    return [];
  }
}

/**
 * Runs prewarm topic searches in the background (non-blocking).
 * Results are merged into the article store after syncFeeds has already returned.
 */
async function prewarmTopicFeeds(articleStore) {
  console.log(`[PowerNews] Background pre-warming ${ALL_PREWARM_QUERIES.length} OEM/Utility/DISCOM/State topic feeds...`);
  const prewarmStart = Date.now();
  const prewarmArticles = [];

  for (let i = 0; i < ALL_PREWARM_QUERIES.length; i++) {
    const query = ALL_PREWARM_QUERIES[i];
    try {
      // Per-query timeout guard: skip any query that takes longer than 15s
      const articles = await Promise.race([
        searchLiveTopicRSS(query),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 15000)),
      ]);
      prewarmArticles.push(...articles);
    } catch (_) { }
    if ((i + 1) % 10 === 0 || i === ALL_PREWARM_QUERIES.length - 1) {
      console.log(`[PowerNews] Pre-warm progress: ${i + 1}/${ALL_PREWARM_QUERIES.length} feeds fetched (${Math.round((Date.now() - prewarmStart) / 1000)}s elapsed)`);
    }
    await new Promise(r => setTimeout(r, 150));
  }

  if (prewarmArticles.length === 0) return;

  // Merge prewarm results into the live article store
  const current = articleStore.getArticles();
  const seenKeys = new Set(current.map(a => (a.title || '').toLowerCase().replace(/[^a-z0-9]/g, '')));
  const newArticles = prewarmArticles.filter(a => {
    const key = (a.title || '').toLowerCase().replace(/[^a-z0-9]/g, '');
    if (seenKeys.has(key)) return false;
    seenKeys.add(key);
    return true;
  });

  if (newArticles.length > 0) {
    const merged = [...current, ...newArticles];
    merged.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    articleStore.setArticles(merged);
    console.log(`[PowerNews] Pre-warm complete: merged ${newArticles.length} additional articles. Total: ${merged.length}`);

    // Kick off AI summarization for any new unsummarized articles
    if (ai) {
      const unsumCount = merged.filter(a => a.id && !aiSummaryCache[a.id]).length;
      if (unsumCount > 0) {
        console.log(`[Gemini AI] Queuing summarization for ${unsumCount} pre-warmed articles...`);
        setImmediate(() => runGeminiBatchSummarization(merged));
      }
    }
  }
}

/**
 * Executes a full feed sync cycle. Returns the new list of cached articles.
 * Pre-warming of topic feeds is kicked off in the background after articles are returned.
 */
async function syncFeeds(currentCachedArticles = [], articleStore = null) {
  console.log(`[${new Date().toISOString()}] Refreshing PowerNews feeds...`);
  try {
    const rawArticles = await fetchRSSArticles();

    // Deduplicate identical raw titles and preserve original publisher dates
    const previousDateMap = new Map();
    for (const ca of currentCachedArticles) {
      if (ca.id && ca.publishedAt) {
        previousDateMap.set(ca.id, ca.publishedAt);
        const titleKey = (ca.title || '').toLowerCase().replace(/[^a-z0-9]/g, '');
        if (titleKey) previousDateMap.set(titleKey, ca.publishedAt);
      }
    }

    const seenMap = new Map();
    for (const article of rawArticles) {
      const key = article.title.toLowerCase().replace(/[^a-z0-9]/g, '');
      const existingDate = previousDateMap.get(article.id) || previousDateMap.get(key);
      if (existingDate) {
        article.publishedAt = existingDate;
      }
      if (!seenMap.has(key)) {
        seenMap.set(key, article);
      }
    }

    const uniqueRawArticles = Array.from(seenMap.values());
    const sevenDayArticles = filterArticlesRetention7Days(uniqueRawArticles);

    console.log(`[PowerNews Phase 1] Clustering ${sevenDayArticles.length} active 7-day articles across multiple publishers...`);
    const clusteredArticles = clusterArticles(sevenDayArticles, aiSummaryCache);

    if (clusteredArticles.length > 0) {
      clusteredArticles.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));

      pruneAiSummaryCache(clusteredArticles);

      console.log(`[PowerNews] Indexed ${clusteredArticles.length} clean power sector articles (strictly within 7-day retention, newest first). AI Cache: ${Object.keys(aiSummaryCache).length} active summaries.`);

      if (ai) {
        const unsumCount = clusteredArticles.filter(a => a.id && !aiSummaryCache[a.id]).length;
        if (unsumCount > 0) {
          console.log(`[Gemini AI] Auto-queuing background summarization for ${unsumCount} new/unsummarized articles...`);
          setImmediate(() => runGeminiBatchSummarization(clusteredArticles));
        } else {
          console.log('[Gemini AI] All articles already summarized — skipping background batch.');
        }
      }

      // Kick off topic prewarm in the background — does NOT block return
      if (articleStore) {
        setImmediate(() => prewarmTopicFeeds(articleStore));
      }

      return clusteredArticles;
    } else {
      console.warn(`[PowerNews] Feed sync returned 0 articles (network/DNS glitch). Preserving existing ${currentCachedArticles.length} cached articles.`);
      // Still attempt prewarm even if base RSS was empty
      if (articleStore) {
        setImmediate(() => prewarmTopicFeeds(articleStore));
      }
      return currentCachedArticles;
    }
  } catch (err) {
    console.error('[PowerNews] Feed sync error:', err);
    return currentCachedArticles;
  }
}

module.exports = {
  fetchRSSArticles,
  searchLiveTopicRSS,
  syncFeeds,
};
