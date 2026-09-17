const fs = require('fs');
const path = require('path');
const { HIGH_VALUE_KEYWORDS } = require('../config/rules');
const { initFirestore } = require('./firestoreService');

const LOCAL_KEYWORDS_FILE = path.join(__dirname, '..', 'data', 'dynamic_keywords.json');

// In-memory set of dynamic keywords for 0ms lookup
let dynamicKeywords = new Set();
let isInitialized = false;

/**
 * Initializes keywords from Cloud Firestore with local JSON fallback.
 */
async function initKeywords() {
  if (isInitialized) return getActiveKeywords();

  // 1. Try loading from Cloud Firestore
  try {
    const db = initFirestore();
    if (db) {
      const doc = await db.collection('system_config').doc('keywords').get();
      if (doc.exists && Array.isArray(doc.data().dynamicKeywords)) {
        doc.data().dynamicKeywords.forEach(k => {
          if (k && typeof k === 'string') dynamicKeywords.add(k.trim().toLowerCase());
        });
        isInitialized = true;
        console.log(`[Keyword Service] Loaded ${dynamicKeywords.size} dynamic keywords from Cloud Firestore.`);
        return getActiveKeywords();
      }
    }
  } catch (err) {
    console.warn('[Keyword Service] Firestore keyword load notice:', err.message);
  }

  // 2. Fallback to local JSON file if offline or not in Firestore
  try {
    if (fs.existsSync(LOCAL_KEYWORDS_FILE)) {
      const raw = fs.readFileSync(LOCAL_KEYWORDS_FILE, 'utf8');
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        parsed.forEach(k => {
          if (k && typeof k === 'string') dynamicKeywords.add(k.trim().toLowerCase());
        });
      }
    }
  } catch (_) {}

  isInitialized = true;
  return getActiveKeywords();
}

/**
 * Persists current dynamic keywords to Cloud Firestore and local JSON.
 */
async function persistKeywords() {
  const list = Array.from(dynamicKeywords);

  // 1. Save to Cloud Firestore
  try {
    const db = initFirestore();
    if (db) {
      await db.collection('system_config').doc('keywords').set({
        dynamicKeywords: list,
        updatedAt: new Date().toISOString(),
      }, { merge: true });
    }
  } catch (err) {
    console.warn('[Keyword Service] Could not persist to Firestore:', err.message);
  }

  // 2. Save to local fallback file
  try {
    const dir = path.dirname(LOCAL_KEYWORDS_FILE);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(LOCAL_KEYWORDS_FILE, JSON.stringify(list, null, 2), 'utf8');
  } catch (_) {}
}

/**
 * Returns foundational base keywords.
 */
function getBaseKeywords() {
  return HIGH_VALUE_KEYWORDS.map(k => k.trim().toLowerCase());
}

/**
 * Returns user-added or auto-discovered dynamic keywords.
 */
function getDynamicKeywords() {
  return Array.from(dynamicKeywords);
}

/**
 * Returns complete unified list of base + dynamic keywords.
 */
function getActiveKeywords() {
  const unified = new Set(getBaseKeywords());
  dynamicKeywords.forEach(k => unified.add(k));
  return Array.from(unified);
}

/**
 * Manually adds a new keyword to the system.
 */
async function addKeyword(rawKeyword) {
  if (!rawKeyword || typeof rawKeyword !== 'string') return false;
  const kw = rawKeyword.trim().toLowerCase();
  if (kw.length < 2) return false;

  const baseSet = new Set(getBaseKeywords());
  if (baseSet.has(kw) || dynamicKeywords.has(kw)) return false; // Already present

  dynamicKeywords.add(kw);
  await persistKeywords();
  console.log(`[Keyword Service] Added new keyword: "${kw}"`);
  return true;
}

/**
 * Batch adds multiple keywords.
 */
async function addKeywordsBatch(keywordsList) {
  if (!Array.isArray(keywordsList) || keywordsList.length === 0) return [];
  const baseSet = new Set(getBaseKeywords());
  const newlyAdded = [];

  for (const raw of keywordsList) {
    if (!raw || typeof raw !== 'string') continue;
    const kw = raw.trim().toLowerCase();
    if (kw.length < 2) continue;

    if (!baseSet.has(kw) && !dynamicKeywords.has(kw)) {
      dynamicKeywords.add(kw);
      newlyAdded.push(kw);
    }
  }

  if (newlyAdded.length > 0) {
    await persistKeywords();
    console.log(`[Keyword Service] Batch added ${newlyAdded.length} new keywords: ${newlyAdded.join(', ')}`);
  }

  return newlyAdded;
}

/**
 * Removes a dynamically added keyword.
 */
async function removeKeyword(rawKeyword) {
  if (!rawKeyword) return false;
  const kw = rawKeyword.trim().toLowerCase();
  if (dynamicKeywords.has(kw)) {
    dynamicKeywords.delete(kw);
    await persistKeywords();
    console.log(`[Keyword Service] Removed dynamic keyword: "${kw}"`);
    return true;
  }
  return false;
}

/**
 * Automatically discovers missing keywords using Gemini AI and commits them to the database.
 */
async function autoDiscoverAndAddKeywords(articles) {
  const { discoverNewKeywordsFromNews } = require('./geminiService');
  const currentActive = getActiveKeywords();
  
  const discoveryResult = await discoverNewKeywordsFromNews(articles, currentActive);
  if (!discoveryResult.success || !Array.isArray(discoveryResult.suggestedKeywords)) {
    return {
      success: false,
      error: discoveryResult.error || 'Discovery failed to return suggestions',
      addedKeywords: [],
    };
  }

  // Automatically commit the new suggested keywords into the active keyword store
  const added = await addKeywordsBatch(discoveryResult.suggestedKeywords);
  
  return {
    success: true,
    suggestedCount: discoveryResult.suggestedKeywords.length,
    newlyAdded: added,
    totalActiveKeywords: getActiveKeywords().length,
  };
}

// Auto-initialize on load
initKeywords().catch(() => {});

module.exports = {
  initKeywords,
  getBaseKeywords,
  getDynamicKeywords,
  getActiveKeywords,
  addKeyword,
  addKeywordsBatch,
  removeKeyword,
  autoDiscoverAndAddKeywords,
};
