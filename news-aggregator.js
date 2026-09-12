// ============================================================
// POWERNEWS AGGREGATOR ENGINE (MULTI-UTILITY, PSU & OEM EDITION)
// Modularized Architecture: Entrypoint delegates to ./server/index.js
// ============================================================

// Global crash guards — prevent any unhandled rejection or uncaught error
// from killing the process and triggering Render restart alerts
process.on('uncaughtException', (err) => {
  console.error('[PowerNews] Uncaught Exception (process kept alive):', err.message, err.stack);
});

process.on('unhandledRejection', (reason) => {
  console.error('[PowerNews] Unhandled Promise Rejection (process kept alive):', reason);
});

const { startServer } = require('./server/index');

startServer();
