const cheerio = require('cheerio');
const { SCRAPER_USER_AGENTS, APP_REDIRECT_URL_RE } = require('../config/constants');

let googleDecoder = null;
try {
  const { GoogleDecoder } = require('google-news-url-decoder');
  googleDecoder = new GoogleDecoder();
} catch (err) {
  console.warn('[GoogleDecoder] Could not load google-news-url-decoder:', err.message);
}

/**
 * Senior Developer Standard: Zero-dependency Bounded LRU Map
 * Automatically evicts the least-recently used items when capacity is reached.
 * Prevents memory leaks and stabilizes heap allocation.
 */
class BoundedLRUMap {
  constructor(maxSize = 75) {
    this.maxSize = maxSize;
    this.map = new Map();
  }

  get(key) {
    if (!this.map.has(key)) return undefined;
    const value = this.map.get(key);
    // Refresh recency
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }

  set(key, value) {
    if (this.map.has(key)) {
      this.map.delete(key);
    } else if (this.map.size >= this.maxSize) {
      // Evict oldest entry
      const oldestKey = this.map.keys().next().value;
      this.map.delete(oldestKey);
    }
    this.map.set(key, value);
  }

  has(key) {
    return this.map.has(key);
  }

  clear() {
    this.map.clear();
  }

  get size() {
    return this.map.size;
  }
}

// Bounded in-memory caches to prevent memory creep
const decodedUrlCache = new BoundedLRUMap(200);
const articleBodyCache = new BoundedLRUMap(75);

/**
 * Resolves obfuscated Google News redirect URLs into direct canonical publisher URLs
 */
async function resolvePublisherUrl(url) {
  if (!url || !url.startsWith('http')) return url;
  if (decodedUrlCache.has(url)) {
    return decodedUrlCache.get(url);
  }

  if (googleDecoder && (url.includes('news.google.com/rss/articles/') || url.includes('news.google.com/articles/'))) {
    try {
      const decodedPromise = googleDecoder.decode(url);
      const timeoutPromise = new Promise(r => setTimeout(() => r(null), 2000));
      const decoded = await Promise.race([decodedPromise, timeoutPromise]);
      if (decoded && decoded.status && decoded.decoded_url) {
        const targetUrl = decoded.decoded_url;
        decodedUrlCache.set(url, targetUrl);
        return targetUrl;
      }
    } catch (_) {
      // Fallback to original URL
    }
  }
  return url;
}

/**
 * Scrapes the authentic body of an article from its web URL using Cheerio selectors.
 * Memory-optimized: Frees raw HTML strings and limits paragraph buffers.
 */
async function scrapeFullArticle(url) {
  if (!url || !url.startsWith('http')) return null;

  if (articleBodyCache.has(url)) {
    return articleBodyCache.get(url);
  }

  const targetUrl = await resolvePublisherUrl(url);

  if (articleBodyCache.has(targetUrl)) {
    const cached = articleBodyCache.get(targetUrl);
    articleBodyCache.set(url, cached);
    return cached;
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const ua = SCRAPER_USER_AGENTS[Math.floor(Math.random() * SCRAPER_USER_AGENTS.length)];
    const response = await fetch(targetUrl, {
      signal: controller.signal,
      redirect: 'follow',
      headers: {
        'User-Agent': ua,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'DNT': '1',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Referer': new URL(targetUrl).origin + '/',
      },
    });

    const finalUrl = response.url || targetUrl;
    if (APP_REDIRECT_URL_RE.test(finalUrl)) {
      clearTimeout(timeout);
      return null;
    }
    clearTimeout(timeout);

    if (!response.ok) return null;

    // Memory optimization: fetch text and free reference after loading Cheerio
    let html = await response.text();
    const $ = cheerio.load(html);
    html = null; // Mark giant raw HTML string for immediate V8 garbage collection

    // Strip non-content and marketing/boilerplate elements
    $('script, style, noscript, nav, header, footer, aside, form, svg, iframe, .ads, .advertisement, .social-share, .comments, .related-posts, .subscribe-box, .comment-box, .newsletter, .disclaimer, .partner-content').remove();

    // Cascading article text selectors
    let paragraphs = [];
    const selectors = [
      '.artText p',
      '.artText',
      '[data-articlebody] p',
      '[data-articlebody]',
      '.entry-content p',
      '.entry-content',
      '.mh-post-content p',
      '.mh-post-content',
      'article p',
      'main p',
      '.post-content p',
      '.story-content p',
      '.article-body p',
      '.article-content p',
      '.story_details p',
      '.body-content p',
      '.Normal',
      'p'
    ];

    const isBoilerplate = (txt) => {
      const lower = txt.toLowerCase();
      return (
        lower.startsWith('by commenting') ||
        lower.startsWith('see whats happening') ||
        lower.startsWith('see what\'s happening') ||
        lower.startsWith('read and get insights') ||
        lower.startsWith('explore and discuss') ||
        lower.startsWith('recognise work that') ||
        lower.startsWith('recognize work that') ||
        lower.startsWith('click here') ||
        lower.startsWith('read more') ||
        lower.startsWith('subscribe') ||
        lower.startsWith('follow us') ||
        lower.startsWith('advertisement') ||
        lower.startsWith('copyright') ||
        lower.startsWith('sign in') ||
        lower.startsWith('download the app') ||
        lower.includes('prohibited content policy') ||
        lower.includes('all rights reserved')
      );
    };

    for (const selector of selectors) {
      const elements = $(selector);
      if (elements.length >= 1) {
        const candidateParagraphs = [];
        elements.each((_, el) => {
          const text = $(el).text().trim();
          if (text.length > 35 && !isBoilerplate(text)) {
            if (text.length > 300) {
              const sentences = text.split(/(?<=[.!?])\s+/);
              let chunk = '';
              for (const s of sentences) {
                if ((chunk + ' ' + s).length > 250) {
                  if (chunk.trim().length > 35 && !isBoilerplate(chunk.trim())) candidateParagraphs.push(chunk.trim());
                  chunk = s;
                } else {
                  chunk += (chunk ? ' ' : '') + s;
                }
              }
              if (chunk.trim().length > 35 && !isBoilerplate(chunk.trim())) candidateParagraphs.push(chunk.trim());
            } else {
              candidateParagraphs.push(text);
            }
          }
        });
        if (candidateParagraphs.length >= 2 || (candidateParagraphs.length === 1 && candidateParagraphs[0].length >= 70)) {
          paragraphs = candidateParagraphs;
          break;
        }
      }
    }

    if (paragraphs.length > 0) {
      paragraphs = Array.from(new Set(paragraphs));
      const fullText = paragraphs.slice(0, 10).join('\n\n');
      const cleanSummary = paragraphs.slice(0, 2).join(' ');

      const result = {
        summary: cleanSummary.length > 400 ? cleanSummary.slice(0, 390) + '...' : cleanSummary,
        fullText: fullText,
      };

      // Store in Bounded LRU cache
      articleBodyCache.set(url, result);
      articleBodyCache.set(targetUrl, result);
      return result;
    }
  } catch (_) {
    // Network or CORS/Cloudflare challenge error - non-fatal
  }
  return null;
}

module.exports = {
  scrapeFullArticle,
  resolvePublisherUrl,
  articleBodyCache,
  decodedUrlCache,
};
