const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

// Import our API routes
const apiRoutes = require("./routes/apiRoutes");

// Initialize Express App
const app = express();

// Security and CORS
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// Mount the API
app.use("/", apiRoutes); // Firebase rewrites /api/** to / so we mount at /

// Export the API Function
exports.api = onRequest({
  region: "us-central1",
  minInstances: 0,
  maxInstances: 10,
  memory: "256MiB"
}, app);

// Export the Cron Job Function
exports.scrapeCron = onSchedule({
  schedule: "*/20 * * * *",
  timeZone: "Asia/Kolkata",
  region: "us-central1",
  timeoutSeconds: 300,
  memory: "512MiB" // A bit more memory for scraping/Gemini processing
}, async (event) => {
  console.log("[Cloud Scheduler] Waking up to sync RSS feeds...");
  
  const articleStore = require("./services/articleStore");
  const { syncFeeds } = require("./services/rssService");
  const { loadAllSummariesFromFirestore } = require("./services/firestoreService");

  try {
    // 1. Hydrate the local memory so the scraper knows what we already have
    console.log("[Cloud Scheduler] Hydrating articleStore...");
    const dbData = await loadAllSummariesFromFirestore(true);
    if (dbData && dbData.articles) {
      articleStore.setArticles(dbData.articles);
    }

    // 2. Run the sync (fetches RSS, summarizes with Gemini, saves to Firestore)
    console.log("[Cloud Scheduler] Running syncFeeds...");
    const updated = await syncFeeds(articleStore.getArticles(), articleStore);
    
    console.log(`[Cloud Scheduler] Successfully processed ${updated.length} active articles.`);
  } catch (error) {
    console.error("[Cloud Scheduler] Error during scheduled sync:", error);
  }
});

