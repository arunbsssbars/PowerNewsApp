import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../models/morning_digest.dart';

class ApiService {
  static const String _clientSecret = String.fromEnvironment(
    'APP_CLIENT_SECRET',
    defaultValue: 'pwn_5a9b8c7d6e5f4g3h2i1j0',
  );

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _clientSecret,
  };

  static const String renderCloudHost = 'https://powernewsapp-backend.onrender.com';

  static const List<String> candidateHosts = [
    // 1. Production Render Cloud URL (Primary)
    renderCloudHost,
    // 2. Localhost fallback (only when user manually runs node server in terminal)
    'http://127.0.0.1:3000',
    'http://localhost:3000',
    'http://10.0.2.2:3000',
    'http://172.20.10.11:3000',
    'http://100.98.130.99:3000',
  ];

  String _activeHost = renderCloudHost;
  int _lastTotalCount = 0;

  String get activeHost => _activeHost;
  int get lastTotalCount => _lastTotalCount;

  void setCustomHost(String host) {
    _activeHost = host.trim();
  }

  Future<bool> checkAndSelectHost() async {
    // Probe candidate hosts in parallel (12s for cloud host to allow cold boot, 3s for local)
    final List<Future<String?>> probes = candidateHosts.map((host) async {
      try {
        final uri = Uri.parse('$host/api/health');
        final timeoutSec = host == renderCloudHost ? 12 : 3;
        final res = await http.get(uri, headers: _headers).timeout(Duration(seconds: timeoutSec));
        if (res.statusCode == 200) {
          try {
            final hData = json.decode(utf8.decode(res.bodyBytes));
            if (hData is Map && hData['totalArticles'] is num) {
              _lastTotalCount = (hData['totalArticles'] as num).toInt();
            }
          } catch (_) {}
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
      return true;
    }
    return false;
  }

  Future<List<NewsArticle>> getNews({
    String? category,
    String? player,
    String? state,
    String? city,
    String? discom,
    String? search,
    int page = 1,
    int limit = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (player != null) queryParams['player'] = player;
    if (state != null) queryParams['state'] = state;
    if (city != null) queryParams['city'] = city;
    if (discom != null) queryParams['discom'] = discom;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final isUnfiltered = category == null &&
        player == null &&
        state == null &&
        city == null &&
        discom == null &&
        (search == null || search.isEmpty);

    List<String> hostsToTry = [_activeHost, ...candidateHosts.where((h) => h != _activeHost)];

    for (final host in hostsToTry) {
      try {
        final uri = Uri.parse('$host/api/news').replace(queryParameters: queryParams);
        final timeoutSec = host == renderCloudHost ? 12 : 3;
        final response = await http.get(uri, headers: _headers).timeout(Duration(seconds: timeoutSec));

        if (response.statusCode == 200) {
          _activeHost = host;
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is Map && data.containsKey('articles')) {
            if (data.containsKey('total') && data['total'] is num) {
              final t = (data['total'] as num).toInt();
              // Only overwrite total count if this is an unfiltered query across all power sectors
              if (isUnfiltered && t > 0) {
                _lastTotalCount = t;
              }
            }
            final List<dynamic> articlesJson = data['articles'] ?? [];
            return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Failed fetching news from $host: $e');
      }
    }

    throw Exception('Could not connect to PowerNews cloud server ($renderCloudHost).');
  }


  Future<Map<String, int>> getPlayers() async {
    try {
      final uri = Uri.parse('$_activeHost/api/players');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
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
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
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
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 3));
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
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
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
        headers: _headers,
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

  Future<List<NewsArticle>> searchTopic(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse('$_activeHost/api/search-topic?q=${Uri.encodeComponent(trimmed)}');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(res.bodyBytes));
        if (data['articles'] is List) {
          final List<dynamic> list = data['articles'];
          return list.map((json) => NewsArticle.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error in live searchTopic: $e');
    }
    return [];
  }

  Future<bool> refreshBackend() async {
    try {
      final uri = Uri.parse('$_activeHost/api/refresh');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Error refreshing backend: $e');
      return false;
    }
  }
}
