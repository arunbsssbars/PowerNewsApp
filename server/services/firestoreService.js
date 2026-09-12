const fs = require('fs');
const path = require('path');

let db = null;
let isInitialized = false;

function initFirestore() {
  if (isInitialized) return db;

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
 * Loads all AI summaries from Cloud Firestore into an in-memory dictionary.
 */
async function loadAllSummariesFromFirestore() {
  const database = initFirestore();
  if (!database) return {};

  try {
    const snapshot = await database.collection('ai_summaries').get();
    const map = {};
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data && data.summary && typeof data.summary === 'string' && data.summary.length >= 60) {
        map[doc.id] = data.summary;
      }
    });
    console.log(`[Firestore] Loaded ${Object.keys(map).length} AI summaries from Cloud Firestore.`);
    return map;
  } catch (err) {
    console.warn('[Firestore] Error reading summaries from cloud:', err.message);
    return {};
  }
}

/**
 * Persists a single AI summary document to Cloud Firestore.
 */
async function saveSummaryToFirestore(id, summary, metadata = {}) {
  const database = initFirestore();
  if (!database || !id || !summary) return;

  try {
    await database.collection('ai_summaries').doc(id).set({
      summary: summary.trim(),
      title: metadata.title || '',
      category: metadata.category || '',
      player: metadata.player || null,
      state: metadata.state || null,
      discom: metadata.discom || null,
      updatedAt: new Date().toISOString(),
    }, { merge: true });
  } catch (err) {
    console.warn(`[Firestore] Failed saving summary ${id}:`, err.message);
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


