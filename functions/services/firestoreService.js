const fs = require('fs');
const path = require('path');
const { HIGH_VALUE_KEYWORDS } = require('../config/rules');

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
    const { initializeApp, getApps } = require('firebase-admin/app');
    const { getFirestore } = require('firebase-admin/firestore');

    if (getApps().length === 0) {
      initializeApp(); // In Cloud Functions, this auto-discovers credentials
    }

    db = getFirestore();
    db.settings({ ignoreUndefinedProperties: true });
    isInitialized = true;
    console.log('[Firestore] Connected successfully to Cloud Firestore database via Cloud Functions default credentials.');
    return db;
  } catch (err) {
    console.error('[Firestore] Initialization failed:', err.message);
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
        data.summary.length >= 75 &&
        !data.summary.startsWith('• ') &&
        !data.summary.startsWith('- ') &&
        !data.summary.startsWith('* ') &&
        data.summary.trim().toLowerCase() !== (data.title || '').trim().toLowerCase()
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
          // fullText: data.fullText || null, // Omitted from RAM caching to prevent OOM
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
  // Reject any heuristic bullets, non-AI content, stubs, or title duplicates
  if (
    !metadata.isAiGenerated ||
    trimmed.startsWith('• ') ||
    trimmed.startsWith('- ') ||
    trimmed.startsWith('* ') ||
    trimmed.length < 75 ||
    trimmed.toLowerCase() === (metadata.title || '').trim().toLowerCase()
  ) {
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

/**
 * Silently saves the (original text, native summary, gemini summary) to the training dataset.
 */
async function saveTrainingDataToFirestore(metadata) {
  const database = initFirestore();
  if (!database || !metadata.articleId || !metadata.originalText) return;

  const titleLower = (metadata.title || '').toLowerCase();
  const summaryLower = (metadata.geminiSummary || metadata.nativeSummary || '').toLowerCase();
  const sourceLower = (metadata.publisher || '').toLowerCase();
  
  let keywordMatches = 0;
  const matchedEntities = [];
  for (const kw of HIGH_VALUE_KEYWORDS) {
    if (titleLower.includes(kw) || summaryLower.includes(kw)) {
      keywordMatches++;
      matchedEntities.push(kw);
    }
  }

  let calculatedScore = 100 + (keywordMatches * 50);
  if (sourceLower.includes('powerline') || sourceLower.includes('press release')) {
    calculatedScore += 80;
  }
  if (sourceLower.includes('mercom')) {
    calculatedScore -= 20;
  }

  const docData = {
    articleId: metadata.articleId,
    title: metadata.title || '',
    publisher: metadata.publisher || 'PowerNews',
    originalText: metadata.originalText,
    nativeSummary: metadata.nativeSummary || null,
    geminiSummary: metadata.geminiSummary || null,
    categories: metadata.categories || [],
    isStrictB2B: metadata.isStrictB2B || false,
    createdAt: new Date().toISOString(),
    // --- NEW ML TRAINING FIELDS ---
    calculatedScore: calculatedScore,
    matchedEntities: matchedEntities,
    mlStatus: 'auto_approved'
  };

  try {
    await database.collection('power60_training_data').doc(metadata.articleId).set(docData, { merge: true });
  } catch (err) {
    console.warn(`[Firestore] Failed to save training data for ${metadata.articleId}:`, err.message);
  }
}

/**
 * Fetches the heavy fullText of an article directly from Firestore.
 * This ensures the Node process RAM footprint remains tiny while still allowing users to read the full article on-demand.
 */
async function getArticleContentById(id) {
  const database = initFirestore();
  if (!database || !id) return null;

  try {
    const docRef = database.collection('ai_summaries').doc(id);
    const docSnap = await docRef.get();
    
    if (docSnap.exists) {
      const data = docSnap.data();
      return data.fullText || null;
    }
  } catch (err) {
    console.warn(`[Firestore] Failed to fetch fullText for ${id}:`, err.message);
  }
  return null;
}

/**
 * Retrieves training data records from Firestore.
 * @param {number} limit - Maximum number of records to fetch
 */
async function getTrainingData(limit = 50) {
  const database = initFirestore();
  if (!database) return [];

  try {
    const snapshot = await database.collection('power60_training_data')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const data = [];
    snapshot.forEach(doc => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (err) {
    console.warn('[Firestore] Failed to fetch training data:', err.message);
    return [];
  }
}

/**
 * Updates the approval or processing status of a training data record in Firestore.
 * @param {string} articleId - The ID of the training article
 * @param {string} status - New status (e.g., 'approved', 'rejected', 'auto_approved')
 */
async function updateTrainingDataStatus(articleId, status) {
  const database = initFirestore();
  if (!database || !articleId) return false;

  try {
    await database.collection('power60_training_data').doc(articleId).set({
      mlStatus: status,
      updatedAt: new Date().toISOString()
    }, { merge: true });
    console.log(`[Firestore] Updated training data status for ${articleId} to "${status}".`);
    return true;
  } catch (err) {
    console.warn(`[Firestore] Failed to update training data status for ${articleId}:`, err.message);
    return false;
  }
}

/**
 * Retrieves all approved training data records for ML fine-tuning.
 */
async function getApprovedTrainingData() {
  const database = initFirestore();
  if (!database) return [];

  try {
    const snapshot = await database.collection('power60_training_data')
      .where('mlStatus', '==', 'approved')
      .get();

    const data = [];
    snapshot.forEach(doc => {
      data.push({ id: doc.id, ...doc.data() });
    });
    return data;
  } catch (err) {
    console.warn('[Firestore] Failed to fetch approved training data:', err.message);
    return [];
  }
}

/**
 * Retrieves comprehensive Firestore database storage and Firebase Cloud Storage telemetry.
 */
async function getStorageStatus() {
  const database = initFirestore();
  const result = {
    success: true,
    timestamp: new Date().toISOString(),
    firestore: {
      connected: !!database,
      status: database ? 'online' : 'offline',
      databaseId: '(default)',
      totalDocuments: 0,
      estimatedSizeKb: 0,
      estimatedSizeMb: 0,
      freeTierQuotaMb: 1024,
      quotaUsedPercent: 0,
      purgeThresholdMb: 850,
      isNearLimit: false,
      collections: {
        ai_summaries: { count: 0, estimatedKb: 0, estimatedMb: 0 },
        power60_training_data: { count: 0, estimatedKb: 0, estimatedMb: 0 },
        system_state: { count: 0, estimatedKb: 0, estimatedMb: 0 },
        users: { count: 0, estimatedKb: 0, estimatedMb: 0 }
      }
    },
    cloudStorage: {
      configured: false,
      bucketName: null,
      status: 'zero_storage_policy',
      message: 'Zero-Storage Policy: Article images reference publisher CDNs directly with zero binary cloud storage costs.'
    },
    cache: {
      inMemorySummaries: Object.keys(cachedSummaryMap).length,
      lastFullSyncTime: lastFullSyncTime ? new Date(lastFullSyncTime).toISOString() : null,
      syncCooldownActive: (Date.now() - lastFullSyncTime) < SYNC_COOLDOWN_MS
    }
  };

  if (!database) {
    return result;
  }

  try {
    const collectionsToInspect = ['ai_summaries', 'power60_training_data', 'system_state', 'users'];
    let totalDocs = 0;
    let totalEstimatedKb = 0;

    for (const collName of collectionsToInspect) {
      try {
        const countSnap = await database.collection(collName).count().get();
        const count = countSnap.data().count || 0;
        const avgDocKb = collName === 'power60_training_data' ? 3.5 : (collName === 'ai_summaries' ? 1.5 : 1.0);
        const estimatedKb = Math.round(count * avgDocKb * 10) / 10;
        const estimatedMb = Math.round((estimatedKb / 1024) * 100) / 100;

        result.firestore.collections[collName] = {
          count,
          estimatedKb,
          estimatedMb
        };
        totalDocs += count;
        totalEstimatedKb += estimatedKb;
      } catch (collErr) {
        result.firestore.collections[collName] = { count: 0, error: collErr.message };
      }
    }

    const estimatedMb = Math.round((totalEstimatedKb / 1024) * 100) / 100;
    result.firestore.totalDocuments = totalDocs;
    result.firestore.estimatedSizeKb = Math.round(totalEstimatedKb * 10) / 10;
    result.firestore.estimatedSizeMb = estimatedMb;
    result.firestore.quotaUsedPercent = parseFloat(((estimatedMb / 1024) * 100).toFixed(2));
    result.firestore.isNearLimit = estimatedMb >= 850;

    // Firebase Cloud Storage inspection
    try {
      const { getApps } = require('firebase-admin/app');
      const { getStorage } = require('firebase-admin/storage');
      if (getApps().length > 0) {
        const app = getApps()[0];
        const storage = getStorage(app);
        const bucket = storage.bucket();
        if (bucket && bucket.name) {
          result.cloudStorage.configured = true;
          result.cloudStorage.bucketName = bucket.name;
          result.cloudStorage.status = 'active';
          result.cloudStorage.message = `Cloud Storage bucket "${bucket.name}" is attached.`;
        }
      }
    } catch (storageErr) {
      result.cloudStorage.message = 'No dedicated bucket configured; images served via direct publisher URLs.';
    }

    return result;
  } catch (err) {
    console.warn('[Firestore] Storage status check warning:', err.message);
    result.firestore.error = err.message;
    return result;
  }
}

module.exports = {
  initFirestore,
  loadAllSummariesFromFirestore,
  saveSummaryToFirestore,
  purgeOldestIfNearLimit,
  saveTrainingDataToFirestore,
  getArticleContentById,
  getTrainingData,
  updateTrainingDataStatus,
  getApprovedTrainingData,
  getStorageStatus,
};
