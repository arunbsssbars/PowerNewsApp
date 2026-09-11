import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import '../models/morning_digest.dart';

class ApiService {
  static const List<String> candidateHosts = [
    // 1. Production Render Cloud URL (Works worldwide on 4G/5G/Wi-Fi)
    'https://powernewsapp-backend.onrender.com',
    // 2. ADB Reverse Tunnel (Instantaneous, zero firewall restrictions over Wi-Fi debugging)
    'http://127.0.0.1:3000',
    'http://localhost:3000',
    // 3. Direct Wi-Fi LAN / Hotspot
    'http://172.20.10.11:3000',
    // 3. Tailscale Mesh Network
    'http://100.98.130.99:3000',
    // 4. Alternate Wi-Fi Networks
    'http://10.82.41.239:3000',
    'http://192.168.1.12:3000',
    'http://192.168.1.59:3000',
    'http://10.0.2.2:3000',
  ];

  String _activeHost = 'http://127.0.0.1:3000';

  String get activeHost => _activeHost;

  void setCustomHost(String host) {
    _activeHost = host.trim();
  }

  Future<bool> checkAndSelectHost() async {
    // Probe candidate hosts in parallel with 4s timeout for cloud TLS handshake
    final List<Future<String?>> probes = candidateHosts.map((host) async {
      try {
        final uri = Uri.parse('$host/api/health');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return host;
        }
      } catch (_) {}
      return null;
    }).toList();

    final results = await Future.wait(probes);
    // Prioritize by order of definition in candidateHosts (production cloud first)
    String? workingHost;
    for (final host in candidateHosts) {
      if (results.contains(host)) {
        workingHost = host;
        break;
      }
    }

    if (workingHost != null) {
      _activeHost = workingHost;
      debugPrint('[ApiService] Connected successfully to host: $_activeHost');
      return true;
    }

    _activeHost = candidateHosts.first;
    return false;
  }

  Future<List<NewsArticle>> getNews({
    String? category,
    String? player,
    String? state,
    String? city,
    String? discom,
    String? search,
    String? source,
    int limit = 50,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (player != null && player.isNotEmpty && player != 'All Players' && player != 'All') {
      queryParams['player'] = player;
    }
    if (state != null && state.isNotEmpty && state != 'All States') {
      queryParams['state'] = state;
    }
    if (city != null && city.isNotEmpty && city != 'All Cities') {
      queryParams['city'] = city;
    }
    if (discom != null && discom.isNotEmpty && discom != 'All DISCOMs') {
      queryParams['discom'] = discom;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (source != null && source.isNotEmpty && source != 'All Sources') {
      queryParams['source'] = source;
    }

    List<String> hostsToTry = [_activeHost, ...candidateHosts.where((h) => h != _activeHost)];

    for (final host in hostsToTry) {
      try {
        final uri = Uri.parse('$host/api/news').replace(queryParameters: queryParams);
        final response = await http.get(uri).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          _activeHost = host;
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is Map && data.containsKey('articles')) {
            final List<dynamic> articlesJson = data['articles'] ?? [];
            return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Failed fetching news from $host: $e');
      }
    }

    // Direct Public Internet Fallback
    final publicArticles = await _fetchDirectPublicRSS(
      category: category,
      player: player,
      state: state,
      city: city,
      search: search,
    );

    if (publicArticles.isNotEmpty) {
      return publicArticles;
    }

    throw Exception('Could not fetch news from server or direct internet sources.');
  }

  Future<List<NewsArticle>> _fetchDirectPublicRSS({
    String? category,
    String? player,
    String? state,
    String? city,
    String? search,
  }) async {
    final queryParts = <String>[];
    if (search != null && search.isNotEmpty) {
      queryParts.add(search);
    } else if (player != null && player.isNotEmpty && player != 'All' && player != 'All Players') {
      queryParts.add('$player power sector India');
    } else if (category != null && category.isNotEmpty && category != 'All') {
      queryParts.add('$category power sector India');
    } else if (state != null && state.isNotEmpty && state != 'All States') {
      queryParts.add('$state power electricity discom');
    } else if (city != null && city.isNotEmpty && city != 'All Cities') {
      queryParts.add('$city electricity power discom');
    } else {
      queryParts.add('India power sector electricity transmission distribution renewable');
    }

    final query = queryParts.join(' ');
    final encoded = Uri.encodeComponent(query);
    final url = 'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en';

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final xml = utf8.decode(res.bodyBytes);
        return _parseRssXml(xml, defaultCategory: category, defaultPlayer: player, defaultState: state, defaultCity: city);
      }
    } catch (e) {
      debugPrint('[ApiService] Direct public RSS fetch error: $e');
    }
    return [];
  }

  List<NewsArticle> _parseRssXml(String xml, {String? defaultCategory, String? defaultPlayer, String? defaultState, String? defaultCity}) {
    final articles = <NewsArticle>[];
    final itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final matches = itemPattern.allMatches(xml);

    for (final m in matches) {
      final itemBlock = m.group(1) ?? '';
      final titleMatch = RegExp(r'<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true).firstMatch(itemBlock);
      final linkMatch = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true).firstMatch(itemBlock);
      final pubDateMatch = RegExp(r'<(?:pubDate|dc:date|published|updated)>(.*?)</(?:pubDate|dc:date|published|updated)>', caseSensitive: false, dotAll: true).firstMatch(itemBlock);
      final descMatch = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(itemBlock);

      var title = (titleMatch?.group(1) ?? '').trim();
      final link = (linkMatch?.group(1) ?? '').trim();
      final pubDateStr = (pubDateMatch?.group(1) ?? '').trim();
      var desc = (descMatch?.group(1) ?? '').replaceAll(RegExp(r'<[^>]*>'), ' ').trim();

      if (title.isEmpty) continue;

      var source = 'Power Intelligence';
      if (title.contains(' - ')) {
        final parts = title.split(' - ');
        if (parts.length > 1) {
          source = parts.last.trim();
          title = parts.sublist(0, parts.length - 1).join(' - ').trim();
        }
      }

      DateTime pubDate;
      try {
        DateTime? parsed = DateTime.tryParse(pubDateStr);
        if (parsed == null && pubDateStr.isNotEmpty) {
          final formats = [
            'EEE, dd MMM yyyy HH:mm:ss Z',
            'EEE, dd MMM yyyy HH:mm:ss zzz',
            'EEE, dd MMM yyyy HH:mm:ss',
            'yyyy-MM-ddTHH:mm:ssZ',
            'yyyy-MM-ddTHH:mm:ss.SSSZ',
            'dd MMM yyyy HH:mm:ss',
          ];
          for (final fmt in formats) {
            try {
              parsed = DateFormat(fmt, 'en_US').parse(pubDateStr);
              break;
            } catch (_) {}
          }
        }
        pubDate = parsed ?? DateTime.now();
        if (pubDate.isAfter(DateTime.now().add(const Duration(hours: 24)))) {
          pubDate = DateTime.now();
        }
      } catch (_) {
        pubDate = DateTime.now();
      }

      // Enforce 7-day retention cutoff (previous 1 week only)
      if (pubDate.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        continue;
      }

      final id = (link.isNotEmpty ? link.hashCode : title.hashCode).abs().toString();
      final cat = (defaultCategory != null && defaultCategory != 'All') ? defaultCategory.toLowerCase() : 'generation';

      articles.add(NewsArticle(
        id: id,
        title: title,
        summary: desc.isNotEmpty ? desc : title,
        url: link.isNotEmpty ? link : 'https://news.google.com',
        source: source,
        publishedAt: pubDate,
        categories: [cat],
        player: defaultPlayer,
        state: defaultState ?? 'National / Pan-India',
        city: defaultCity,
      ));
    }
    return articles;
  }

  Future<Map<String, int>> getPlayers() async {
    try {
      final uri = Uri.parse('$_activeHost/api/players');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching players: $e');
    }
    return {};
  }

  Future<Map<String, int>> getCities() async {
    try {
      final uri = Uri.parse('$_activeHost/api/cities');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching cities: $e');
    }
    return {};
  }

  Future<Map<String, int>> getCategories() async {
    try {
      final uri = Uri.parse('$_activeHost/api/categories');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching categories: $e');
    }
    return {};
  }

  Future<Map<String, int>> getStates() async {
    try {
      final uri = Uri.parse('$_activeHost/api/states');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching states: $e');
    }
    return {};
  }

  Future<Map<String, int>> getDiscoms() async {
    try {
      final uri = Uri.parse('$_activeHost/api/discoms');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching discoms: $e');
    }
    return {};
  }

  Future<Map<String, int>> getSources() async {
    try {
      final uri = Uri.parse('$_activeHost/api/sources');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching sources: $e');
    }
    return {};
  }

  Future<Map<String, String>?> fetchArticleFullContent(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;

    // 1. Try local aggregator endpoint
    try {
      final uri = Uri.parse('$_activeHost/api/article-content?url=${Uri.encodeComponent(url)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['fullText'] != null) {
          return {
            'summary': (data['summary'] ?? '').toString(),
            'fullText': (data['fullText'] ?? '').toString(),
          };
        }
      }
    } catch (_) {}

    // 2. Direct client-side web scraper fallback
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final html = utf8.decode(res.bodyBytes, allowMalformed: true);
        final pPattern = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true, caseSensitive: false);
        final matches = pPattern.allMatches(html);
        final paragraphs = <String>[];

        for (final m in matches) {
          final pText = (m.group(1) ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          if (pText.length > 40 &&
              !RegExp(r'^(click here|read more|subscribe|follow us|advertisement|copyright|sign in)', caseSensitive: false).hasMatch(pText)) {
            paragraphs.add(pText);
          }
        }

        if (paragraphs.isNotEmpty) {
          final uniqueParas = paragraphs.toSet().toList();
          return {
            'summary': uniqueParas.take(2).join(' '),
            'fullText': uniqueParas.take(8).join('\n\n'),
          };
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> fetchArticleAiSummary({
    required String id,
    required String title,
    String? snippet,
    String? category,
    String? player,
    String? state,
    String? discom,
    String? url,
  }) async {
    final queryParams = {
      'id': id,
      'title': title,
      if (snippet != null) 'snippet': snippet,
      if (category != null) 'category': category,
      if (player != null) 'player': player,
      if (state != null) 'state': state,
      if (discom != null) 'discom': discom,
      if (url != null) 'url': url,
    };

    // Try active host first with a generous 12s timeout to accommodate on-demand article scraping + Gemini generation
    try {
      final uri = Uri.parse('$_activeHost/api/article-summary').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['summary'] != null) {
          return data['summary'].toString();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Primary host $_activeHost failed for AI summary: $e');
    }

    // Try at most one candidate fallback host with short 3s timeout
    final fallbackHost = candidateHosts.firstWhere((h) => h != _activeHost, orElse: () => '');
    if (fallbackHost.isNotEmpty) {
      try {
        final uri = Uri.parse('$fallbackHost/api/article-summary').replace(queryParameters: queryParams);
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = json.decode(utf8.decode(res.bodyBytes));
          if (data['success'] == true && data['summary'] != null) {
            _activeHost = fallbackHost;
            return data['summary'].toString();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<MorningDigest?> fetchMorningDigest() async {
    try {
      final uri = Uri.parse('$_activeHost/api/morning-digest');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic>) {
          return MorningDigest.fromJson(data);
        } else if (data is Map) {
          return MorningDigest.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching morning digest: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> askGeminiGridQA(String question, {String? persona}) async {
    try {
      final uri = Uri.parse('$_activeHost/api/ask-gemini');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': question,
          'persona': persona,
        }),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic> && data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error asking Gemini Grid QA: $e');
    }
    return null;
  }

  Future<bool> refreshBackend() async {
    try {
      final uri = Uri.parse('$_activeHost/api/refresh');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Error refreshing backend: $e');
      return false;
    }
  }
}
