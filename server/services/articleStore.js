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
};
