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
  timeout: 10000,
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
 * Executes a full feed sync cycle. Returns the new list of cached articles.
 */
async function syncFeeds(currentCachedArticles = []) {
  console.log(`[${new Date().toISOString()}] Refreshing PowerNews feeds...`);
  try {
    const rawArticles = await fetchRSSArticles();

    console.log(`[PowerNews] Pre-warming ${ALL_PREWARM_QUERIES.length} OEM/Utility/DISCOM/State topic feeds...`);
    const prewarmStart = Date.now();
    for (let i = 0; i < ALL_PREWARM_QUERIES.length; i++) {
      const query = ALL_PREWARM_QUERIES[i];
      try {
        const articles = await searchLiveTopicRSS(query);
        rawArticles.push(...articles);
      } catch (_) { }
      if ((i + 1) % 10 === 0 || i === ALL_PREWARM_QUERIES.length - 1) {
        console.log(`[PowerNews] Pre-warm progress: ${i + 1}/${ALL_PREWARM_QUERIES.length} feeds fetched (${Math.round((Date.now() - prewarmStart) / 1000)}s elapsed)`);
      }
      await new Promise(r => setTimeout(r, 150));
    }

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

      return clusteredArticles;
    } else {
      console.warn(`[PowerNews] Feed sync returned 0 articles (network/DNS glitch). Preserving existing ${currentCachedArticles.length} cached articles.`);
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
