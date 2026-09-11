// ============================================================
// POWERNEWS AGGREGATOR ENGINE (MULTI-UTILITY, PSU & OEM EDITION)
// Modularized Architecture: Entrypoint delegates to ./server/index.js
// ============================================================

const { startServer } = require('./server/index');

startServer();
