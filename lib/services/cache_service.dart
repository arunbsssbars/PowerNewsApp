import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import 'database_service.dart';

/// CacheService now delegates to SQLite via DatabaseService.
/// Maintains the same public API so NewsProvider requires zero changes.
class CacheService {
  final DatabaseService _db = DatabaseService();
  static const int _retentionDays = 7;

  /// Save articles to SQLite with automatic 7-day (1 week only) auto-purge (EXCLUDING bookmarked articles)
  Future<void> cacheArticles(List<NewsArticle> newArticles) async {
    if (newArticles.isEmpty) return;
    try {
      await _db.upsertArticles(newArticles);
      await _db.purgeExpired(retentionDays: _retentionDays);
      final count = await _db.getArticleCount();
      debugPrint('[CacheService] Cached ${newArticles.length} articles locally (total: $count, bookmarks safeguarded)');
    } catch (e) {
      debugPrint('[CacheService] Error caching articles: $e');
    }
  }

  /// Retrieve cached articles from SQLite (preserving bookmarked articles regardless of age)
  Future<List<NewsArticle>> getCachedArticles() async {
    try {
      return await _db.getAllArticles(retentionDays: _retentionDays);
    } catch (e) {
      debugPrint('[CacheService] Error reading cached articles: $e');
      return [];
    }
  }

  /// Clear expired articles older than 7 days (1 week)
  Future<void> pruneExpiredCache() async {
    await _db.purgeExpired(retentionDays: _retentionDays);
  }

  /// Get the latest published_at for incremental sync
  Future<DateTime?> getLatestPublishedAt() async {
    return await _db.getLatestPublishedAt();
  }
}
