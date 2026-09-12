const path = require('path');

const PORT = process.env.PORT || 3000;

// Resolve CACHE_FILE at project root for backward compatibility with existing data
const CACHE_FILE = path.join(__dirname, '..', '..', 'ai-summaries-cache.json');

// 7 days retention window in milliseconds
const RETENTION_MS = 7 * 24 * 60 * 60 * 1000;

// Maximum AI summaries to keep in memory before pruning old entries
const MAX_CACHED_SUMMARIES = 2000;

// Gemini Rate Limit & Batching Constants
const GEMINI_BATCH_SIZE = 3;
const GEMINI_WAVE_DELAY_MS = 12000; // 3 per 12s = 15 RPM, within free-tier cap
const GEMINI_SAVE_EVERY = 5;

// Scraper Constants
const SCRAPER_USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
];

const APP_REDIRECT_URL_RE = /\/\/(?:play\.google\.com|apps\.apple\.com|itunes\.apple\.com|appgallery\.huawei\.com)|intent:\/\//i;

module.exports = {
  PORT,
  CACHE_FILE,
  RETENTION_MS,
  MAX_CACHED_SUMMARIES,
  GEMINI_BATCH_SIZE,
  GEMINI_WAVE_DELAY_MS,
  GEMINI_SAVE_EVERY,
  SCRAPER_USER_AGENTS,
  APP_REDIRECT_URL_RE,
};
