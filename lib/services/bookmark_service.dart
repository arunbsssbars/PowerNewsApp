import '../models/news_article.dart';
import 'database_service.dart';

/// BookmarkService now delegates to SQLite via DatabaseService.
/// Maintains the same public API so NewsProvider requires zero changes.
class BookmarkService {
  final DatabaseService _db = DatabaseService();

  Future<List<NewsArticle>> getBookmarks() async {
    return await _db.getBookmarkedArticles();
  }

  Future<bool> isBookmarked(String id) async {
    return await _db.isBookmarked(id);
  }

  Future<void> toggleBookmark(NewsArticle article) async {
    await _db.toggleBookmark(article);
  }
}
