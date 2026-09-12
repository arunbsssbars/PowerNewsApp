/**
 * In-memory article store and state management
 */
let cachedArticles = [];
let lastRefreshedAt = null;

module.exports = {
  getArticles: () => cachedArticles,
  setArticles: (articles) => {
    cachedArticles = articles;
    lastRefreshedAt = new Date().toISOString();
  },
  getLastRefreshedAt: () => lastRefreshedAt,
  mergeArticles: (articles = []) => {
    if (!articles || articles.length === 0) return;
    const existingMap = new Map(cachedArticles.map(a => [a.id, a]));
    for (const a of articles) {
      if (!a || !a.id) continue;
      if (!existingMap.has(a.id)) {
        existingMap.set(a.id, a);
      } else {
        const current = existingMap.get(a.id);
        existingMap.set(a.id, {
          ...a,
          ...current,
          summary: (current.summary && current.summary.length >= 75 && !current.summary.startsWith('• '))
            ? current.summary
            : (a.summary || current.summary),
          sources: (current.sources && current.sources.length > 0) ? current.sources : a.sources,
          sourceLinks: (current.sourceLinks && current.sourceLinks.length > 0) ? current.sourceLinks : a.sourceLinks,
        });
      }
    }
    cachedArticles = Array.from(existingMap.values());
    cachedArticles.sort((a, b) => new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0));
    if (!lastRefreshedAt) {
      lastRefreshedAt = new Date().toISOString();
    }
  },
};
