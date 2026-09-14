const cheerio = require('cheerio');
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');
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
  constructor(maxSize = 100) {
    this.maxSize = maxSize;
    this.map = new Map();
  }

  get(key) {
    if (!this.map.has(key)) return undefined;
    const value = this.map.get(key);
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }

  set(key, value) {
    if (this.map.has(key)) {
      this.map.delete(key);
    } else if (this.map.size >= this.maxSize) {
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

// Bounded in-memory caches
const decodedUrlCache = new BoundedLRUMap(250);
const articleBodyCache = new BoundedLRUMap(100);

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
      const timeoutPromise = new Promise(r => setTimeout(() => r(null), 2500));
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

function isBoilerplate(txt) {
  if (!txt) return true;
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
    lower.startsWith('download rate card') ||
    lower.includes('prohibited content policy') ||
    lower.includes('all rights reserved') ||
    lower.includes('please leave this field empty') ||
    lower.includes('verify code (required)')
  );
}

function normalizeHdImageUrl(rawImg) {
  if (!rawImg || typeof rawImg !== 'string') return null;
  let img = rawImg.trim();

  // 1. Upgrade WordPress scaled thumbnails (-150x150.jpg, -300x200.jpg -> .jpg)
  img = img.replace(/-\d{2,4}x\d{2,4}(\.(?:jpe?g|png|webp))$/i, '$1');

  // 2. Upgrade Indiatimes/ET thumbnails (width-150,height-112 -> width-1200,height-900)
  if (img.includes('indiatimes.com') || img.includes('economictimes')) {
    img = img.replace(/width-\d+,height-\d+/i, 'width-1200,height-900');
  }

  // 3. Upgrade generic width/size query params (e.g. ?w=150, ?width=150)
  img = img.replace(/([?&])(w|width|h|height)=\d{1,3}(&|$)/gi, '$1$2=1200$3');

  return img;
}

/**
 * Image Optimization Microservice Pipeline
 * Converts publisher OpenGraph (og:image) HD images into modern 16:9 WebP responsive variants (1080p and 720p).
 * Uses high-performance Cloudflare edge image CDN (wsrv) to deliver 0-RAM instant transformation.
 */
function optimizeImageUrlTo16x9Webp(rawUrl, { width = 1080, height = 608, quality = 82 } = {}) {
  if (!rawUrl || typeof rawUrl !== 'string' || !rawUrl.startsWith('http')) return rawUrl;
  if (rawUrl.includes('wsrv.nl')) return rawUrl; // already optimized

  const cleanUrl = normalizeHdImageUrl(rawUrl);
  return `https://wsrv.nl/?url=${encodeURIComponent(cleanUrl)}&w=${width}&h=${height}&fit=cover&a=attention&output=webp&q=${quality}`;
}

function getImageResponsiveVariants(rawUrl) {
  if (!rawUrl || typeof rawUrl !== 'string' || !rawUrl.startsWith('http')) return null;
  const cleanUrl = normalizeHdImageUrl(rawUrl);
  return {
    raw: cleanUrl,
    hd1080: optimizeImageUrlTo16x9Webp(cleanUrl, { width: 1080, height: 608, quality: 82 }),
    hd720: optimizeImageUrlTo16x9Webp(cleanUrl, { width: 720, height: 405, quality: 80 }),
  };
}

function extractLeadImage(document, html, targetUrl) {
  let img = null;
  if (document && document.querySelector) {
    const og = document.querySelector('meta[property="og:image"]')
      || document.querySelector('meta[name="twitter:image"]')
      || document.querySelector('meta[name="thumbnail"]');
    if (og && og.getAttribute('content')) {
      img = og.getAttribute('content').trim();
    }
  }
  if (!img && html) {
    const ogMatch = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"'>]+)["']/i)
      || html.match(/<meta[^>]+content=["']([^"'>]+)["'][^>]+property=["']og:image["']/i)
      || html.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"'>]+)["']/i)
      || html.match(/<meta[^>]+content=["']([^"'>]+)["'][^>]+name=["']twitter:image["']/i);
    if (ogMatch && ogMatch[1]) {
      img = ogMatch[1].trim();
    }
  }
  if (img) {
    if (img.startsWith('//')) {
      img = 'https:' + img;
    } else if (img.startsWith('/') && targetUrl) {
      try {
        img = new URL(targetUrl).origin + img;
      } catch (_) {}
    }
    const lower = img.toLowerCase();
    if (
      img.startsWith('http') &&
      !lower.includes('1x1') &&
      !lower.includes('pixel') &&
      !lower.includes('favicon') &&
      !lower.includes('logo_small') &&
      !lower.includes('80x80')
    ) {
      return normalizeHdImageUrl(img);
    }
  }
  return null;
}

/**
 * Modern semantic content extraction via Mozilla Readability & LinkeDOM
 */
function extractWithReadability(html, targetUrl) {
  try {
    const { document } = parseHTML(html);
    const leadImage = extractLeadImage(document, html, targetUrl);
    const reader = new Readability(document, { charThreshold: 120 });
    const parsed = reader.parse();

    if (parsed && parsed.textContent) {
      const text = parsed.textContent.replace(/\s+/g, ' ').trim();
      if (text.length >= 150 && !isBoilerplate(text)) {
        const sentences = text.split(/(?<=[.!?])\s+/);
        const snippet = sentences.slice(0, 2).join(' ').trim();
        return {
          summary: snippet.length > 380 ? snippet.slice(0, 375) + '...' : snippet,
          fullText: text.slice(0, 4500),
          imageUrl: leadImage ? optimizeImageUrlTo16x9Webp(leadImage) : null,
        };
      }
    }
  } catch (_) {}
  return null;
}

/**
 * Fallback extraction using selective Cheerio selectors
 */
function extractWithCheerio(html, targetUrl) {
  try {
    const leadImage = extractLeadImage(null, html, targetUrl);
    const $ = cheerio.load(html);
    $('script, style, noscript, nav, header, footer, aside, form, svg, iframe, .ads, .advertisement, .social-share, .comments, .related-posts, .subscribe-box, .comment-box, .newsletter, .disclaimer, .partner-content').remove();

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

    for (const selector of selectors) {
      const elements = $(selector);
      if (elements.length >= 1) {
        const candidateParagraphs = [];
        elements.each((_, el) => {
          const text = $(el).text().trim();
          if (text.length > 35 && !isBoilerplate(text)) {
            candidateParagraphs.push(text);
          }
        });

        if (candidateParagraphs.length >= 2 || (candidateParagraphs.length === 1 && candidateParagraphs[0].length >= 120)) {
          const uniqueParas = Array.from(new Set(candidateParagraphs));
          const fullText = uniqueParas.slice(0, 10).join('\n\n');
          const cleanSummary = uniqueParas.slice(0, 2).join(' ');

          if (fullText.length >= 150) {
            return {
              summary: cleanSummary.length > 380 ? cleanSummary.slice(0, 375) + '...' : cleanSummary,
              fullText: fullText.slice(0, 4500),
              imageUrl: leadImage ? optimizeImageUrlTo16x9Webp(leadImage) : null,
            };
          }
        }
      }
    }
  } catch (_) {}
  return null;
}

/**
 * Free Cloudflare/WAF bypass fallback using Jina Reader (https://r.jina.ai/<url>)
 * Zero-cost, returns authentic markdown content with no infrastructure setup.
 */
async function fetchWithJina(targetUrl) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6500);

    const jinaUrl = `https://r.jina.ai/${encodeURI(targetUrl)}`;
    const response = await fetch(jinaUrl, {
      signal: controller.signal,
      headers: {
        'Accept': 'text/plain',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
      },
    });
    clearTimeout(timeout);

    if (response.ok) {
      let rawMarkdown = await response.text();
      const imgMatch = rawMarkdown.match(/!\[[^\]]*\]\((https?:\/\/[^\s\)]+)\)/i);
      const leadImage = imgMatch ? imgMatch[1] : null;

      // Remove Jina header annotations (Title:, URL Source:, Markdown Content:)
      rawMarkdown = rawMarkdown
        .replace(/^Title:[^\n]*\n+/i, '')
        .replace(/^URL Source:[^\n]*\n+/i, '')
        .replace(/^Markdown Content:\n+/i, '')
        .replace(/\[!\[[^\]]*\]\([^\)]*\)\]\([^\)]*\)/g, ' ')
        .replace(/!\[[^\]]*\]\([^\)]*\)/g, ' ')
        .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')
        .replace(/[#*`_>~]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();

      if (rawMarkdown.length >= 150 && !isBoilerplate(rawMarkdown)) {
        const sentences = rawMarkdown.split(/(?<=[.!?])\s+/);
        const summary = sentences.slice(0, 2).join(' ').trim();
        return {
          summary: summary.length > 380 ? summary.slice(0, 375) + '...' : summary,
          fullText: rawMarkdown.slice(0, 4500),
          imageUrl: leadImage ? optimizeImageUrlTo16x9Webp(leadImage) : null,
        };
      }
    }
  } catch (_) {}
  return null;
}

/**
 * Scrapes authentic article body from a publisher URL with multi-tiered resilience:
 * 1. Mozilla Readability (semantic content score)
 * 2. Cheerio (heuristic selector fallback)
 * 3. Jina Reader (free Cloudflare/JS bypass fallback)
 *
 * Guaranteed No-Body Guard: Returns NULL if authentic body is < 150 characters.
 * Never fabricates or returns headline-only stubs.
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
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'DNT': '1',
        'Upgrade-Insecure-Requests': '1',
        'Referer': new URL(targetUrl).origin + '/',
      },
    });

    const finalUrl = response.url || targetUrl;
    clearTimeout(timeout);

    if (APP_REDIRECT_URL_RE.test(finalUrl)) {
      return null;
    }

    let extractedResult = null;

    if (response.ok) {
      let html = await response.text();
      // Tier 1: Mozilla Readability
      extractedResult = extractWithReadability(html, finalUrl);

      // Tier 2: Cheerio cascading selectors
      if (!extractedResult) {
        extractedResult = extractWithCheerio(html, finalUrl);
      }
      html = null; // Free HTML memory immediately
    }

    // Tier 3: Jina Reader Proxy (handles 403, Cloudflare bot-challenge, or JS-rendered pages)
    if (!extractedResult && (response.status === 403 || response.status === 429 || !response.ok || !extractedResult)) {
      extractedResult = await fetchWithJina(targetUrl);
    }

    // Strict No-Body Guard: If authentic body < 150 chars, drop article body
    if (extractedResult && extractedResult.fullText && extractedResult.fullText.length >= 150) {
      articleBodyCache.set(url, extractedResult);
      articleBodyCache.set(targetUrl, extractedResult);
      return extractedResult;
    }
  } catch (_) {
    // Network or abort error: Try Jina fallback once before failing
    try {
      const jinaResult = await fetchWithJina(targetUrl);
      if (jinaResult && jinaResult.fullText && jinaResult.fullText.length >= 150) {
        articleBodyCache.set(url, jinaResult);
        articleBodyCache.set(targetUrl, jinaResult);
        return jinaResult;
      }
    } catch (_) {}
  }

  return null;
}

module.exports = {
  scrapeFullArticle,
  resolvePublisherUrl,
  optimizeImageUrlTo16x9Webp,
  getImageResponsiveVariants,
  articleBodyCache,
  decodedUrlCache,
  BoundedLRUMap,
};
