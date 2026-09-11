import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news_app/models/news_article.dart';
import 'package:power_news_app/services/cache_service.dart';
import 'package:power_news_app/services/bookmark_service.dart';
import 'package:power_news_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    // Reset the singleton database between tests
    await DatabaseService().close();
  });

  group('CacheService Tests', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService();
    });

    test('Caches and retrieves fresh articles', () async {
      final articles = [
        NewsArticle(
          id: 'fresh-1',
          title: 'ABB commissions digital substation',
          summary: 'ABB India installs state-of-the-art digital substation.',
          url: 'http://test.com/abb',
          source: 'Power Line Magazine',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
          categories: ['transmission'],
          player: 'ABB',
          state: 'Maharashtra',
        ),
      ];

      await cacheService.cacheArticles(articles);
      final retrieved = await cacheService.getCachedArticles();

      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'fresh-1');
      expect(retrieved.first.player, 'ABB');
    });

    test('Enforces 7-day retention purge on retrieval and caching', () async {
      final oldArticle = NewsArticle(
        id: 'old-1',
        title: 'Power outage from 12 days ago',
        summary: 'Power was restored.',
        url: 'http://test.com/old',
        source: 'News',
        publishedAt: DateTime.now().subtract(const Duration(days: 12)),
        categories: ['distribution'],
        state: 'UP',
      );

      final freshArticle = NewsArticle(
        id: 'fresh-2',
        title: 'New tariff order announced',
        summary: 'CERC releases new norms.',
        url: 'http://test.com/fresh',
        source: 'Policy',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        categories: ['policy'],
        state: 'National',
      );

      await cacheService.cacheArticles([oldArticle, freshArticle]);
      final retrieved = await cacheService.getCachedArticles();

      // Only fresh article <= 7 days must be preserved
      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'fresh-2');
    });

    test('Safeguards bookmarked articles from 7-day purge', () async {
      final oldBookmarkedArticle = NewsArticle(
        id: 'bookmarked-old-1',
        title: 'Crucial grid policy guideline',
        summary: 'Important 765kV grid policy saved by engineer.',
        url: 'http://test.com/policy-doc',
        source: 'CERC',
        publishedAt: DateTime.now().subtract(const Duration(days: 20)),
        categories: ['policy'],
        state: 'National',
      );

      final oldUnbookmarkedArticle = NewsArticle(
        id: 'unbookmarked-old-2',
        title: 'Expired event update',
        summary: 'Tender from 15 days ago expired.',
        url: 'http://test.com/tender-expired',
        source: 'UPPCL',
        publishedAt: DateTime.now().subtract(const Duration(days: 15)),
        categories: ['tenders'],
        state: 'UP',
      );

      // Bookmark the first old article
      final bookmarkService = BookmarkService();
      await bookmarkService.toggleBookmark(oldBookmarkedArticle);

      // Cache both old articles
      await cacheService.cacheArticles([oldBookmarkedArticle, oldUnbookmarkedArticle]);
      final retrieved = await cacheService.getCachedArticles();

      // Bookmarked article MUST be preserved despite being 20 days old!
      expect(retrieved.any((a) => a.id == 'bookmarked-old-1'), isTrue);
      // Unbookmarked old article MUST be purged
      expect(retrieved.any((a) => a.id == 'unbookmarked-old-2'), isFalse);
    });
  });
}
