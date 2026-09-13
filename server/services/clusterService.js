function tokenizeForClustering(str) {
  const stopWords = new Set([
    'the', 'and', 'for', 'with', 'from', 'under', 'this', 'that', 'india', 'power',
    'across', 'could', 'about', 'after', 'before', 'says', 'will', 'are', 'has', 'have',
    'all', 'more', 'into', 'over', 'per', 'new', 'set', 'get', 'see', 'due'
  ]);
  return (str || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .map(w => w.replace(/(ing|tion|ment|ed|ly|s)$/, ''))
    .filter(w => w.length > 2 && !stopWords.has(w));
}

function calculateSimilarity(titleA, titleB) {
  const tokensA = new Set(tokenizeForClustering(titleA));
  const tokensB = new Set(tokenizeForClustering(titleB));
  if (tokensA.size === 0 || tokensB.size === 0) return 0;

  let intersection = 0;
  for (const token of tokensA) {
    if (tokensB.has(token)) intersection++;
  }
  const union = new Set([...tokensA, ...tokensB]).size;
  return intersection / union;
}

function clusterArticles(articles, aiSummaryCache = {}) {
  const clusters = [];

  for (const article of articles) {
    let matchedCluster = null;

    for (const cluster of clusters) {
      const primary = cluster.primary;
      const sim = calculateSimilarity(primary.title, article.title);

      const sameEntity = (primary.player && primary.player !== 'Power Sector Stakeholder' && primary.player === article.player) ||
        (primary.state && primary.state !== 'National / Pan-India' && primary.state === article.state);

      if (sim >= 0.42 || (sameEntity && sim >= 0.25)) {
        matchedCluster = cluster;
        break;
      }
    }

    if (matchedCluster) {
      matchedCluster.articles.push(article);
      if (article.source && !matchedCluster.sources.includes(article.source)) {
        matchedCluster.sources.push(article.source);
      }
      if (article.url) {
        matchedCluster.sourceLinks.push({ source: article.source || 'PowerNews', url: article.url });
      }
    } else {
      clusters.push({
        primary: article,
        articles: [article],
        sources: [article.source || 'PowerNews'],
        sourceLinks: [{ source: article.source || 'PowerNews', url: article.url || '' }],
      });
    }
  }

  return clusters.map(c => {
    // Utmost priority: if cluster contains an article from Power Line or PIB, elevate it to master
    const authoritative = c.articles.find(a =>
      (a.source && /power line|pib ministry/i.test(a.source)) ||
      (a.url && a.url.includes('powerline.net.in'))
    );
    const primaryArticle = authoritative || c.primary;
    const master = { ...primaryArticle };
    master.sources = c.sources;
    master.sourceLinks = c.sourceLinks;
    master.coverageCount = c.articles.length;

    if (!master.imageUrl) {
      const mateWithImage = c.articles.find(a => a.imageUrl);
      if (mateWithImage) {
        master.imageUrl = mateWithImage.imageUrl;
      }
    }

    // Zero-Waste Gemini Optimization: If any source in this cluster already has a verified AI summary, share it across the whole cluster
    const mateWithSummary = c.articles.find(a => a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].length >= 80);
    if (mateWithSummary) {
      const sharedSummary = aiSummaryCache[mateWithSummary.id];
      for (const a of c.articles) {
        if (a.id && !aiSummaryCache[a.id]) {
          aiSummaryCache[a.id] = sharedSummary;
        }
      }
      master.summary = sharedSummary;
    }

    return master;
  });
}

module.exports = {
  tokenizeForClustering,
  calculateSimilarity,
  clusterArticles,
};
