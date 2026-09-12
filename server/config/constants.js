const path = require('path');

// Server Port (Dynamic in production, e.g. Render sets PORT=10000)
const PORT = process.env.PORT || 3000;

// Article Retention Window: 7 days in milliseconds
const RETENTION_MS = 7 * 24 * 60 * 60 * 1000;

// Default articles per page (matches Flutter mobile client default of 15)
const DEFAULT_PAGE_SIZE = 15;

// Maximum AI summaries to keep in memory
const MAX_CACHED_SUMMARIES = 2000;

// Gemini Rate Limit & Batching Constants (tuned for free-tier 15 RPM safety)
const GEMINI_BATCH_SIZE = 1;
const GEMINI_WAVE_DELAY_MS = 5000;

// Scraper Constants
const SCRAPER_USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
];

const APP_REDIRECT_URL_RE = /\/\/(?:play\.google\.com|apps\.apple\.com|itunes\.apple\.com|appgallery\.huawei\.com)|intent:\/\//i;

module.exports = {
  PORT,
  RETENTION_MS,
  DEFAULT_PAGE_SIZE,
  MAX_CACHED_SUMMARIES,
  GEMINI_BATCH_SIZE,
  GEMINI_WAVE_DELAY_MS,
  SCRAPER_USER_AGENTS,
  APP_REDIRECT_URL_RE,
};
