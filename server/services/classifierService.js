const crypto = require('crypto');
const { RETENTION_MS } = require('../config/constants');
const {
  UTILITY_PLAYER_RULES,
  CITY_RULES,
  STATE_RULES,
  DISCOM_RULES,
  CATEGORY_RULES,
  IRRELEVANT_PATTERNS,
  CORE_POWER_ANCHORS,
} = require('../config/rules');

function generateArticleId(item, title) {
  const seed = ((item && (item.guid || item.link)) || title || Math.random().toString()).trim();
  return crypto.createHash('sha256').update(seed).digest('hex').slice(0, 20);
}

function cleanHeadline(text) {
  if (!text) return '';
  return text
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#039;/gi, "'")
    .replace(/&#x27;/gi, "'")
    .replace(/&#038;/gi, '&')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&#8216;|&#8217;/gi, "'")
    .replace(/&#8220;|&#8221;/gi, '"')
    .replace(/&#8211;|&#8212;/gi, ' - ')
    .replace(/&hellip;|&#8230;/gi, '...')
    .replace(/\b(target|href|color|style|class|rel|data-[a-z-]+)=["'][^"']*["']/gi, ' ')
    .replace(/\b(target|href|color)=[^ >\s]+/gi, ' ')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\b(_blank|_self|_parent|_top)\b/gi, ' ')
    .replace(/\s*-\s*[a-zA-Z0-9\.\-\s]+(?:\.com|\.in|\.org|\.net|Times of India|Economic Times|ET EnergyWorld|Mercom India|Power Line Magazine|Power Line|The Hindu|Mint|Business Standard|Financial Express)$/i, '')
    .replace(/&[a-zA-Z0-9#]+;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function cleanText(text) {
  if (!text) return '';
  return text
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#039;/gi, "'")
    .replace(/&#x27;/gi, "'")
    .replace(/&#038;/gi, '&')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&#8216;|&#8217;/gi, "'")
    .replace(/&#8220;|&#8221;/gi, '"')
    .replace(/&#8211;|&#8212;/gi, ' - ')
    .replace(/&hellip;|&#8230;/gi, '...')
    .replace(/\b(target|href|color|style|class|rel|data-[a-z-]+)=["'][^"']*["']/gi, ' ')
    .replace(/\b(target|href|color)=[^ >\s]+/gi, ' ')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\b(_blank|_self|_parent|_top)\b/gi, ' ')
    .replace(/https?:\/\/[^\s<>"']+/gi, ' ')
    .replace(/View Full Coverage on Google News/gi, ' ')
    .replace(/The post .*? appeared first on .*?(\.|$)/gi, '')
    .replace(/Listen to this article/gi, '')
    .replace(/Follow us on (Google News|WhatsApp|Twitter|Telegram)/gi, '')
    .replace(/\[\.\.\.\]/g, '')
    .replace(/\s*-\s*[a-zA-Z0-9\.\-\s]+(?:\.com|\.in|\.org|timesofindia|The Hindu|Economic Times|Mercom India)/gi, '')
    .replace(/&[a-zA-Z0-9#]+;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function parsePublisherDate(rawDate, fallbackDate) {
  if (rawDate) {
    try {
      const d = new Date(rawDate);
      const time = d.getTime();
      if (!isNaN(time) && time <= Date.now() + 24 * 60 * 60 * 1000) {
        return d.toISOString();
      }
    } catch (_) { }
  }
  if (fallbackDate) {
    try {
      const fd = new Date(fallbackDate);
      if (!isNaN(fd.getTime())) return fd.toISOString();
    } catch (_) { }
  }
  return new Date().toISOString();
}

function filterArticlesRetention7Days(articles) {
  if (!articles || articles.length === 0) return [];
  const cutoff = Date.now() - RETENTION_MS;
  return articles.filter(a => {
    try {
      const pubTime = new Date(a.publishedAt).getTime();
      return !isNaN(pubTime) && pubTime >= cutoff;
    } catch (_) {
      return false;
    }
  });
}

function cleanSummaryOutput(text) {
  if (!text) return '';
  return text
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 0)
    .map(line => {
      if (/^[•\-\*]\s*/.test(line)) {
        return line.replace(/^[•\-\*]\s*/, '• ');
      }
      if (/^\d+[\.\)]\s*/.test(line)) {
        return line.replace(/^\d+[\.\)]\s*/, '');
      }
      return line;
    })
    .join('\n');
}

function extractCleanSnippet(title, rawSnippet) {
  let cleaned = cleanText(rawSnippet || '');
  const cleanTitleStr = cleanHeadline(title);

  if (/\b(target|href|_blank|color=)\b/i.test(cleaned) || cleaned.length < 15) {
    return cleanTitleStr;
  }

  if (cleaned.length > 40 && !cleaned.toLowerCase().startsWith(cleanTitleStr.toLowerCase().slice(0, 30))) {
    return `${cleanTitleStr}. ${cleaned}`;
  } else if (cleaned.length > 25) {
    return cleaned;
  }
  return cleanTitleStr;
}

function matchesKeyword(text, kw) {
  if (!text || !kw) return false;
  if (kw.length <= 4) {
    const escaped = kw.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
    return new RegExp('\\b' + escaped + '\\b', 'i').test(text);
  }
  return text.toLowerCase().includes(kw.toLowerCase());
}

function isPowerSectorNews(title, summary, isStrictFeed) {
  const fullText = `${title} ${summary}`;

  for (const pattern of IRRELEVANT_PATTERNS) {
    if (pattern.test(fullText)) {
      return false;
    }
  }

  const hasAnchor = CORE_POWER_ANCHORS.some((anchor) => matchesKeyword(fullText, anchor));
  const hasCategory = CATEGORY_RULES.some((rule) =>
    rule.keywords.some((kw) => matchesKeyword(fullText, kw))
  );
  const hasPlayer = UTILITY_PLAYER_RULES.some((rule) =>
    rule.keywords.some((kw) => matchesKeyword(fullText, kw))
  );
  const hasDiscom = DISCOM_RULES.some((rule) =>
    rule.keywords.some((kw) => matchesKeyword(fullText, kw))
  );

  return (hasAnchor || hasCategory || hasPlayer || hasDiscom);
}

function extractCategories(text) {
  const matched = [];
  for (const rule of CATEGORY_RULES) {
    if (rule.keywords.some((kw) => matchesKeyword(text, kw))) {
      matched.push(rule.category);
    }
  }
  return matched;
}

function extractPlayer(text) {
  for (const rule of UTILITY_PLAYER_RULES) {
    if (rule.keywords.some((kw) => matchesKeyword(text, kw))) {
      return rule.player;
    }
  }
  return null;
}

function extractCityStateAndDiscom(text) {
  const lower = text.toLowerCase();

  let detectedCity = null;
  let detectedState = null;
  let detectedDiscom = null;

  for (const rule of CITY_RULES) {
    if (rule.aliases.some((alias) => lower.includes(alias.toLowerCase()))) {
      detectedCity = rule.city;
      detectedState = rule.state;
      detectedDiscom = rule.discom;
      break;
    }
  }

  if (!detectedState) {
    for (const rule of STATE_RULES) {
      if (rule.aliases.some((alias) => lower.includes(alias.toLowerCase()))) {
        detectedState = rule.state;
        break;
      }
    }
  }

  if (!detectedDiscom) {
    for (const rule of DISCOM_RULES) {
      if (rule.keywords.some((kw) => lower.includes(kw.toLowerCase()))) {
        detectedDiscom = rule.discom;
        break;
      }
    }
  }

  return {
    city: detectedCity,
    state: detectedState || 'National / Pan-India',
    discom: detectedDiscom || null
  };
}

module.exports = {
  generateArticleId,
  cleanHeadline,
  cleanText,
  parsePublisherDate,
  filterArticlesRetention7Days,
  cleanSummaryOutput,
  extractCleanSnippet,
  matchesKeyword,
  isPowerSectorNews,
  extractCategories,
  extractPlayer,
  extractCityStateAndDiscom,
};
