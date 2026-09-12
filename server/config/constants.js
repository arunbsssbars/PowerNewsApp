const path = require('path');

// Server Port
const PORT = process.env.PORT || process.env.SERVER_PORT || 3000;
const SERVER_PORT = PORT;

// Paths & Caches
const CACHE_FILE = path.join(__dirname, '..', '..', 'ai-summaries-cache.json');
const API_HEALTH_PATH = process.env.API_HEALTH_PATH || '/api/health';
const API_TIMEOUT_SECONDS = parseInt(process.env.API_TIMEOUT_SECONDS, 10) || 4;

// App Environment & Feature Flags
const APP_ENV = process.env.APP_ENV || 'production';
const DEBUG_LOGGING = process.env.DEBUG_LOGGING === 'true';

// Article Retention Window
const ARTICLE_RETENTION_DAYS = parseInt(process.env.ARTICLE_RETENTION_DAYS, 10) || 7;
const RETENTION_MS = ARTICLE_RETENTION_DAYS * 24 * 60 * 60 * 1000;

// Maximum AI summaries to keep in memory before pruning old entries
const MAX_CACHED_SUMMARIES = 2000;

// Pagination & Digest Constants
const PAGE_SIZE = parseInt(process.env.PAGE_SIZE, 10) || 25;
const DEFAULT_PAGE_SIZE = PAGE_SIZE;
const DIGEST_MAX_ARTICLES = parseInt(process.env.DIGEST_MAX_ARTICLES, 10) || 20;

// Auto-refresh & Background Audio
const AUTO_REFRESH_INTERVAL_MINUTES = parseInt(process.env.AUTO_REFRESH_INTERVAL_MINUTES, 10) || 2;
const BGM_VOLUME = parseFloat(process.env.BGM_VOLUME) || 0.12;

// Gemini Rate Limit & Batching Constants
const GEMINI_BATCH_SIZE = 1;
const GEMINI_WAVE_DELAY_MS = 5000; // 1 per 5s = 12 RPM (safely under free-tier 15 RPM cap)
const GEMINI_SAVE_EVERY = 5;

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
  SERVER_PORT,
  CACHE_FILE,
  API_HEALTH_PATH,
  API_TIMEOUT_SECONDS,
  APP_ENV,
  DEBUG_LOGGING,
  ARTICLE_RETENTION_DAYS,
  RETENTION_MS,
  MAX_CACHED_SUMMARIES,
  PAGE_SIZE,
  DEFAULT_PAGE_SIZE,
  DIGEST_MAX_ARTICLES,
  AUTO_REFRESH_INTERVAL_MINUTES,
  BGM_VOLUME,
  GEMINI_BATCH_SIZE,
  GEMINI_WAVE_DELAY_MS,
  GEMINI_SAVE_EVERY,
  SCRAPER_USER_AGENTS,
  APP_REDIRECT_URL_RE,
};
