/**
 * Backfill Image URLs for Firestore ai_summaries collection
 * Fetches existing documents that lack an imageUrl, scrapes their publisher page for og:image / twitter:image,
 * and updates the Firestore document with { imageUrl: scraped.imageUrl }.
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { initFirestore } = require('../services/firestoreService');
const { scrapeFullArticle } = require('../services/scraperService');

async function runBackfill() {
  console.log('--- Starting Image URL Backfill for Firestore ai_summaries ---');
  const db = initFirestore();
  if (!db) {
    console.error('[Error] Firestore could not be initialized. Check serviceAccountKey.json.');
    process.exit(1);
  }

  let snapshot;
  try {
    snapshot = await db.collection('ai_summaries').get();
  } catch (err) {
    if (err.message && err.message.includes('RESOURCE_EXHAUSTED')) {
      console.warn('\n[Firestore Notice] Cloud Firestore daily free-tier quota is currently exhausted for today.');
      console.warn('The quota automatically resets daily at midnight Pacific Time (PST).');
      console.warn('All new incoming articles and future sync cycles will automatically extract and include `imageUrl`.');
      console.warn('You can run this backfill script at any time after quota reset: `node server/scripts/backfill_image_urls.js`\n');
      process.exit(0);
    }
    throw err;
  }

  console.log(`[Firestore] Found ${snapshot.size} total documents in 'ai_summaries'.`);

  const docsToUpdate = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.imageUrl && data.url && data.url.startsWith('http')) {
      docsToUpdate.push({ id: doc.id, url: data.url, title: data.title || '', ref: doc.ref });
    }
  });

  console.log(`[Firestore] Found ${docsToUpdate.length} documents needing imageUrl.`);

  let updatedCount = 0;
  let missingImageCount = 0;
  let failedScrapeCount = 0;

  for (let i = 0; i < docsToUpdate.length; i++) {
    const item = docsToUpdate[i];
    console.log(`[${i + 1}/${docsToUpdate.length}] Scraping image for: "${item.title.slice(0, 45)}" (${item.url.slice(0, 50)})...`);

    try {
      const scraped = await scrapeFullArticle(item.url);
      if (scraped && scraped.imageUrl) {
        await item.ref.set({ imageUrl: scraped.imageUrl }, { merge: true });
        console.log(`  -> SUCCESS: Stored image URL: ${scraped.imageUrl}`);
        updatedCount++;
      } else {
        console.log('  -> No lead image found on page.');
        missingImageCount++;
      }
    } catch (err) {
      console.warn(`  -> FAILED scraping: ${err.message}`);
      failedScrapeCount++;
    }

    // Small delay between requests to be polite to publisher servers
    await new Promise(r => setTimeout(r, 400));
  }

  console.log('\n--- Backfill Summary ---');
  console.log(`Total scanned: ${snapshot.size}`);
  console.log(`Already had imageUrl: ${snapshot.size - docsToUpdate.length}`);
  console.log(`Successfully backfilled: ${updatedCount}`);
  console.log(`No image present on page: ${missingImageCount}`);
  console.log(`Failed / timeout: ${failedScrapeCount}`);
  console.log('------------------------\n');
  process.exit(0);
}

runBackfill().catch(err => {
  console.error('[Backfill Fatal Error]:', err);
  process.exit(1);
});
