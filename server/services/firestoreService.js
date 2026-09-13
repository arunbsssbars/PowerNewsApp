const fs = require('fs');
const path = require('path');

let db = null;
let isInitialized = false;

// In-memory cache & throttle state to eliminate redundant Cloud Firestore reads
let cachedSummaryMap = {};
let cachedArticles = [];
let lastFullSyncTime = 0;
let lastSyncTimestamp = null;
const SYNC_COOLDOWN_MS = 30 * 60 * 1000; // 30-minute minimum throttle between full scans

function initFirestore() {
  if (isInitialized) return db;

  // 0. Support explicit offline mode for local Flutter development (0 cloud reads)
  if (process.env.USE_CLOUD_FIRESTORE === 'false' || process.argv.includes('--offline')) {
    console.log('[Firestore] Offline mode active (--offline / USE_CLOUD_FIRESTORE=false). Running in zero-cloud local mode.');
    return null;
  }

  try {
    const { initializeApp, cert, getApps } = require('firebase-admin/app');
    const { getFirestore } = require('firebase-admin/firestore');

    let serviceAccount = null;

    // 1. Try environment variable containing JSON string
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch (_) {
        // May be base64 encoded
        try {
          const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8');
          serviceAccount = JSON.parse(decoded);
        } catch (_) {}
      }
    }

    // 2. Try local serviceAccountKey.json if present
    if (!serviceAccount) {
      const localKeyPath = path.join(__dirname, '..', 'config', 'serviceAccountKey.json');
      if (fs.existsSync(localKeyPath)) {
        serviceAccount = JSON.parse(fs.readFileSync(localKeyPath, 'utf8'));
      }
    }

    if (!serviceAccount) {
      console.log('[Firestore] No service account configured. Operating in local cache fallback mode.');
      return null;
    }

    let app;
    if (getApps().length === 0) {
      app = initializeApp({
        credential: cert(serviceAccount),
      });
    } else {
      app = getApps()[0];
    }

    db = getFirestore(app);
    isInitialized = true;
    console.log('[Firestore] Connected successfully to Cloud Firestore database.');
    return db;
  } catch (err) {
    console.warn('[Firestore] Initialization warning (falling back to local cache):', err.message);
    return null;
  }
}

/**
 * Loads AI summaries and full article documents from Cloud Firestore.
 * Employs in-memory caching, a 30-minute cooldown, and timestamped delta sync
 * to guarantee that development restarts and polling cycles do not exhaust quotas.
 */
async function loadAllSummariesFromFirestore(forceRefresh = false) {
  const database = initFirestore();
  if (!database) {
    const res = { ...cachedSummaryMap, summaryMap: cachedSummaryMap, articles: cachedArticles };
    return res;
  }

  const now = Date.now();

  // Guard: If we synced recently, serve RAM cache (0 reads)
  if (!forceRefresh && lastFullSyncTime > 0 && (now - lastFullSyncTime < SYNC_COOLDOWN_MS) && !lastSyncTimestamp) {
    console.log(`[Firestore Cache] Serving ${cachedArticles.length} articles from RAM (cooldown active: ${Math.round((SYNC_COOLDOWN_MS - (now - lastFullSyncTime)) / 60000)}m remaining, saved 100% reads).`);
    return { ...cachedSummaryMap, summaryMap: cachedSummaryMap, articles: cachedArticles };
  }

  try {
    let snapshot;
    const isDelta = !!lastSyncTimestamp && !forceRefresh;

    if (isDelta) {
      // Incremental Delta Sync: only fetch documents updated since last successful sync
      snapshot = await database.collection('ai_summaries')
        .where('updatedAt', '>', lastSyncTimestamp)
        .limit(50)
        .get();
      console.log(`[Firestore Delta] Checked for updates since ${lastSyncTimestamp} -> ${snapshot.size} new/modified documents.`);
    } else {
      // Initial Boot: Cap fetch to most recent 100 articles to eliminate runaway read costs
      snapshot = await database.collection('ai_summaries')
        .orderBy('updatedAt', 'desc')
        .limit(100)
        .get();
      console.log(`[Firestore Initial] Loaded ${snapshot.size} latest documents from cloud.`);
    }

    if (snapshot.empty && cachedArticles.length > 0) {
      lastFullSyncTime = now;
      lastSyncTimestamp = new Date().toISOString();
      return { ...cachedSummaryMap, summaryMap: cachedSummaryMap, articles: cachedArticles };
    }

    const freshArticles = [];
    const freshMap = {};

    snapshot.forEach(doc => {
      const data = doc.data();
      if (
        data &&
        data.summary &&
        typeof data.summary === 'string' &&
        data.summary.length >= 50 &&
        !data.summary.startsWith('• ')
      ) {
        const id = doc.id;
        freshMap[id] = data.summary;

        // Reconstruct full article record with all fields
        const categories = Array.isArray(data.categories) && data.categories.length > 0
          ? data.categories
          : [data.category || 'generation'];

        const primarySource = data.source || 'PowerNews';
        const sources = Array.isArray(data.sources) && data.sources.length > 0
          ? data.sources
          : [primarySource];

        const sourceLinks = Array.isArray(data.sourceLinks) ? data.sourceLinks : [];
        if (sourceLinks.length === 0 && data.url) {
          sourceLinks.push({ source: primarySource, url: data.url });
        }

        freshArticles.push({
          id,
          title: data.title || '',
          summary: data.summary,
          url: data.url || '',
          source: primarySource,
          publishedAt: data.publishedAt || data.updatedAt || new Date().toISOString(),
          categories,
          player: data.player || null,
          city: data.city || null,
          state: data.state || 'National / Pan-India',
          discom: data.discom || null,
          fullText: data.fullText || null,
          sources,
          sourceLinks,
          coverageCount: typeof data.coverageCount === 'number' ? data.coverageCount : (sources.length > 1 ? sources.length : 1),
          imageUrl: data.imageUrl || null,
          isAiSummary: true,
          isAiGenerated: true,
        });
      }
    });

    // Merge fresh delta into in-memory cache
    if (isDelta) {
      const articleMap = new Map(cachedArticles.map(a => [a.id, a]));
      freshArticles.forEach(a => articleMap.set(a.id, a));
      cachedArticles = Array.from(articleMap.values());
      Object.assign(cachedSummaryMap, freshMap);
    } else {
      cachedArticles = freshArticles;
      cachedSummaryMap = freshMap;
    }

    lastFullSyncTime = now;
    lastSyncTimestamp = new Date().toISOString();

    const result = { ...cachedSummaryMap };
    result.summaryMap = cachedSummaryMap;
    result.articles = cachedArticles;
    return result;
  } catch (err) {
    lastFullSyncTime = now;
    if (err.code === 8 || (err.message && err.message.includes('RESOURCE_EXHAUSTED'))) {
      console.warn('[Firestore Notice] Daily free-tier quota (50k reads) exhausted for today. Automatically resets at midnight Pacific Time (approx 12:30 PM IST). Serving in-memory articles safely.');
    } else {
      console.warn('[Firestore] Sync warning (falling back to memory):', err.message);
    }
    const fallback = { ...cachedSummaryMap };
    fallback.summaryMap = cachedSummaryMap;
    fallback.articles = cachedArticles;
    return fallback;
  }
}

/**
 * Persists a complete AI-summarized article document with all 14 fields to Cloud Firestore.
 * Strictly enforces that only genuine AI-generated summaries are stored.
 */
async function saveSummaryToFirestore(id, summary, metadata = {}) {
  const database = initFirestore();
  if (!database || !id || !summary) return;

  const trimmed = summary.trim();
  // Reject any heuristic bullets, non-AI content, or stubs
  if (!metadata.isAiGenerated || trimmed.startsWith('• ') || trimmed.length < 50) {
    return;
  }

  const primarySource = metadata.source || 'PowerNews';
  const categories = Array.isArray(metadata.categories) && metadata.categories.length > 0
    ? metadata.categories
    : [metadata.category || 'generation'];

  const sources = Array.isArray(metadata.sources) && metadata.sources.length > 0
    ? metadata.sources
    : [primarySource];

  const sourceLinks = Array.isArray(metadata.sourceLinks) && metadata.sourceLinks.length > 0
    ? metadata.sourceLinks
    : (metadata.url ? [{ source: primarySource, url: metadata.url }] : []);

  const coverageCount = typeof metadata.coverageCount === 'number'
    ? metadata.coverageCount
    : (sources.length > 1 ? sources.length : 1);

  const docData = {
    id,
    title: metadata.title || '',
    summary: trimmed,
    url: metadata.url || '',
    source: primarySource,
    publishedAt: metadata.publishedAt || new Date().toISOString(),
    categories,
    player: metadata.player || null,
    city: metadata.city || null,
    state: metadata.state || 'National / Pan-India',
    discom: metadata.discom || null,
    fullText: metadata.fullText || null,
    sources,
    sourceLinks,
    coverageCount,
    imageUrl: metadata.imageUrl || null,
    isAiGenerated: true,
    updatedAt: new Date().toISOString(),
  };

  try {
    await database.collection('ai_summaries').doc(id).set(docData, { merge: true });
    console.log(`[Firestore] Saved complete AI article for "${(metadata.title || id).slice(0, 40)}" to Cloud Firestore.`);
  } catch (err) {
    console.warn(`[Firestore] Failed saving article ${id}:`, err.message);
  }
}

/**
 * Monitors Firestore storage and evicts the oldest summaries if size approaches the 1,000 MB free tier limit.
 * @param {number} thresholdMb - Size in MB at which purging begins (default: 850 MB)
 * @param {number} targetMb - Safe target size in MB to reduce down to (default: 750 MB)
 */
async function purgeOldestIfNearLimit(thresholdMb = 850, targetMb = 750) {
  const database = initFirestore();
  if (!database) return 0;

  try {
    const countSnapshot = await database.collection('ai_summaries').count().get();
    const totalDocs = countSnapshot.data().count;

    // Approximate size: ~1.2 KB per summary document (text + metadata + index overhead)
    const estimatedMb = (totalDocs * 1.2) / 1024;

    if (estimatedMb < thresholdMb) {
      // Safe: database is well below the 1,000 MB threshold
      return 0;
    }

    console.log(`[Firestore Storage] Storage near limit (${estimatedMb.toFixed(1)} MB / 1000 MB, ${totalDocs} articles). Starting FIFO eviction...`);

    const docsToPurge = Math.ceil(((estimatedMb - targetMb) * 1024) / 1.2);
    let purged = 0;

    while (purged < docsToPurge) {
      const batchSize = Math.min(docsToPurge - purged, 450);
      const oldestDocs = await database.collection('ai_summaries')
        .orderBy('updatedAt', 'asc')
        .limit(batchSize)
        .get();

      if (oldestDocs.empty) break;

      const batch = database.batch();
      oldestDocs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();

      purged += oldestDocs.size;
      console.log(`[Firestore Storage] Evicted ${purged}/${docsToPurge} oldest summaries.`);
    }

    console.log(`[Firestore Storage] Cleanup complete. Purged ${purged} old summaries.`);
    return purged;
  } catch (err) {
    console.warn('[Firestore Storage] Auto-purge warning:', err.message);
    return 0;
  }
}

module.exports = {
  initFirestore,
  loadAllSummariesFromFirestore,
  saveSummaryToFirestore,
  purgeOldestIfNearLimit,
};


