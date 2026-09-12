
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String url;
  final String source;
  final DateTime publishedAt;
  final List<String> categories;
  final String? player;
  final String? city;
  final String state;
  final String? discom;
  final String? fullText;
  final List<String> sources;
  final List<Map<String, String>> sourceLinks;
  final int coverageCount;
  final bool isAiGenerated;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.categories,
    this.player,
    this.city,
    required this.state,
    this.discom,
    this.fullText,
    this.sources = const [],
    this.sourceLinks = const [],
    this.coverageCount = 1,
    this.isAiGenerated = true,
  });

  static String cleanHtmlAndEntities(String input) {
    if (input.isEmpty) return '';
    String text = input;

    // Step 1: Decode HTML entities first so encoded tags/characters become standard
    text = text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#038;', '&')
        .replaceAll('&apos;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&hellip;', '...')
        .replaceAll('&#8230;', '...');

    // Step 2: Strip ALL HTML tags completely (e.g. <a ...>, </a>, <p>, etc.)
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Step 3: Strip any residual HTML attributes or fragments (e.g. href="...", target="_blank")
    text = text
        .replaceAll(RegExp(r'\b(href|target|color|style|class|rel|data-[a-z-]+)=["' "'" r'][^"' "'" r']*["' "'" r']', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(href|target|color)=[^ >\s]+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(_blank|_self|_parent|_top)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'https?:\/\/[^\s<>"' "'" r']+', caseSensitive: false), ' ');

    // Step 4: Strip RSS artifacts, boilerplate and excess whitespace
    text = text
        .replaceAll(RegExp(r'View Full Coverage on Google News', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'The post .*? appeared first on .*?(\.|$)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'Listen to this article', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'Follow us on (Google News|WhatsApp|Twitter|Telegram)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\[\.\.\.\]'), ' ')
        .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return text;
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    List<String> cats = [];
    if (json['categories'] is List) {
      cats = (json['categories'] as List).map((e) => e.toString()).toList();
    }
    if (cats.isEmpty) cats = ['generation'];

    DateTime parsedDate;
    try {
      parsedDate = json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    String rawTitle = cleanHtmlAndEntities((json['title'] ?? '').toString().trim());
    // Strip trailing source name from title if present (e.g. " - Times of India")
    rawTitle = rawTitle.replaceAll(
      RegExp(r'\s*-\s*[a-zA-Z0-9\.\-\s]+(?:\.com|\.in|\.org|Times of India|The Hindu|Economic Times|Mercom India|ET EnergyWorld|Mint)$', caseSensitive: false),
      '',
    ).trim();

    String rawSummary = cleanHtmlAndEntities((json['summary'] ?? '').toString().trim());
    final summaryLower = rawSummary.toLowerCase();
    if (rawSummary.isEmpty ||
        rawSummary.length < 15 ||
        summaryLower.contains('href=') ||
        summaryLower.contains('target=') ||
        summaryLower.contains('_blank') ||
        summaryLower.contains('<a') ||
        summaryLower.contains('</a>')) {
      rawSummary = rawTitle;
    }

    List<String> srcList = [];
    if (json['sources'] is List) {
      srcList = (json['sources'] as List).map((e) => e.toString()).toList();
    }
    if (srcList.isEmpty && json['source'] != null) {
      srcList = [json['source'].toString()];
    }

    List<Map<String, String>> srcLinks = [];
    if (json['sourceLinks'] is List) {
      for (final item in json['sourceLinks']) {
        if (item is Map) {
          srcLinks.add({
            'source': item['source']?.toString() ?? '',
            'url': item['url']?.toString() ?? '',
          });
        }
      }
    }

    final coverage = json['coverageCount'] is int
        ? json['coverageCount'] as int
        : (srcList.length > 1 ? srcList.length : 1);

    final rawUrl = (json['url'] ?? '').toString().trim();

    return NewsArticle(
      id: (json['id'] != null && json['id'].toString().isNotEmpty)
          ? json['id'].toString()
          : (rawUrl.isNotEmpty ? rawUrl : rawTitle).hashCode.abs().toString(),
      title: rawTitle,
      summary: rawSummary,
      url: rawUrl,
      source: (json['source'] ?? 'PowerNews Feed').toString().trim(),
      publishedAt: parsedDate,
      categories: cats,
      player: json['player']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString() ?? 'National / Pan-India',
      discom: json['discom']?.toString(),
      fullText: json['fullText']?.toString(),
      sources: srcList,
      sourceLinks: srcLinks,
      coverageCount: coverage,
      isAiGenerated: json['isAiGenerated'] == true ||
          json['isAiSummary'] == true ||
          (json['isAiGenerated'] == null && json['isAiSummary'] == null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'url': url,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'categories': categories,
      'player': player,
      'city': city,
      'state': state,
      'discom': discom,
      'fullText': fullText,
      'sources': sources,
      'sourceLinks': sourceLinks,
      'coverageCount': coverageCount,
      'isAiGenerated': isAiGenerated,
    };
  }

  String get primaryCategory => categories.isNotEmpty ? categories.first : 'general';

  /// Strict date format: e.g. 01-Sep-26
  String get formattedDate {
    return DateFormat('dd-MMM-yy').format(publishedAt);
  }

  /// Strict date + time format: e.g. 01-Sep-26 • 09:30 PM
  String get formattedDateTime {
    try {
      return DateFormat('dd-MMM-yy • hh:mm a').format(publishedAt);
    } catch (_) {
      return formattedDate;
    }
  }

  /// Compact date format: e.g. 01 Sep • 09:30 PM
  String get compactDate {
    try {
      return DateFormat('dd MMM • hh:mm a').format(publishedAt);
    } catch (_) {
      return formattedDate;
    }
  }

  Color getCategoryColor(BuildContext context) {
    final cat = primaryCategory.toLowerCase();
    switch (cat) {
      case 'transmission':
        return const Color(0xFF0284C7); // Sky Blue / High Voltage
      case 'renewables':
        return const Color(0xFF059669); // Clean Emerald
      case 'generation':
        return const Color(0xFFD97706); // Warm Amber / Thermal
      case 'distribution':
        return const Color(0xFF7C3AED); // Violet / DISCOM
      case 'policy':
        return const Color(0xFFDB2777); // Rose / Regulatory
      case 'tenders':
        return const Color(0xFF0891B2); // Cyan / Procurement
      case 'scada':
        return const Color(0xFF0284C7); // Electric Cyan / Telecommunication
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData getCategoryIcon() {
    final cat = primaryCategory.toLowerCase();
    switch (cat) {
      case 'transmission':
        return Icons.electric_bolt_rounded;
      case 'renewables':
        return Icons.solar_power_rounded;
      case 'generation':
        return Icons.factory_rounded;
      case 'distribution':
        return Icons.power_rounded;
      case 'policy':
        return Icons.gavel_rounded;
      case 'tenders':
        return Icons.assignment_turned_in_rounded;
      case 'scada':
        return Icons.settings_input_antenna_rounded;
      default:
        return Icons.flash_on_rounded;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formattedDate;
    }
  }

  int get readTimeMinutes {
    final words = ('$title $summary').split(' ').length;
    final minutes = (words / 150).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Ensures only genuine Indian power sector, grid, utility, OEM & energy articles are displayed
  bool get isStrictlyPowerSector {
    final text = '$title $summary ${categories.join(" ")} ${player ?? ""} ${discom ?? ""}'.toLowerCase();

    // Check negative irrelevant patterns
    const negativeTerms = [
      'cricket', 'football', 'ipl', 'actor', 'actress', 'movie', 'cinema',
      'celebrity', 'power play', 'powerlifting', 'horsepower', 'box office',
      'star power', 'murder', 'robbery', 'gold price', 'silver price',
      'mutual fund', 'sensex', 'nifty', 'share price'
    ];

    for (final neg in negativeTerms) {
      if (text.contains(neg)) {
        return false;
      }
    }

    // Check positive power sector identifiers
    const sectorKeywords = [
      'power', 'electricity', 'grid', 'utility', 'substation', 'transmission',
      'discom', 'transformer', 'switchgear', 'scada', 'solar', 'wind', 'bess',
      'renewable', 'battery', 'tariff', 'feeder', 'meter', 'cerc', 'serc',
      'uppcl', 'ntpc', 'pgcil', 'powergrid', 'nhpc', 'bhel', 'siemens',
      'abb', 'schneider', 'hitachi', 'tangedco', 'bescom', 'msedcl', 'energy'
    ];

    return sectorKeywords.any((kw) => text.contains(kw));
  }
}
