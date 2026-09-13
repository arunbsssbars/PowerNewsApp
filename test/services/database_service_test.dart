import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news_app/models/news_article.dart';
import 'package:power_news_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService().close();
  });

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService();
      try {
        final db = await dbService.database;
        await db.delete('articles');
        await db.delete('search_history');
        await db.delete('sync_meta');
      } catch (_) {}
    });

    test('Upsert and retrieve articles', () async {
      final articles = [
        NewsArticle(
          id: 'db-1',
          title: 'PowerGrid commissions 765kV line',
          summary: 'New transmission line connects western and northern grid.',
          url: 'http://test.com/powergrid',
          source: 'PowerLine',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          categories: ['Transmission & Grid'],
          player: 'PowerGrid',
          state: 'Rajasthan',
        ),
        NewsArticle(
          id: 'db-2',
          title: 'SECI floats 1GW solar tender',
          summary: 'SECI announces new renewable energy tender.',
          url: 'http://test.com/seci',
          source: 'Mercom India',
          publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
          categories: ['Renewables & Green Energy'],
          player: 'SECI',
          state: 'Gujarat',
        ),
      ];

      final count = await dbService.upsertArticles(articles);
      expect(count, 2);

      final retrieved = await dbService.getAllArticles();
      expect(retrieved.length, 2);
      // Most recent first
      expect(retrieved.first.id, 'db-2');
      expect(retrieved.last.id, 'db-1');
    });

    test('Bookmark toggle works correctly', () async {
      final article = NewsArticle(
        id: 'bm-test-1',
        title: 'BHEL wins 800MW order',
        summary: 'BHEL secures major thermal power order.',
        url: 'http://test.com/bhel',
        source: 'ET Energy',
        publishedAt: DateTime.now(),
        categories: ['Thermal & Hydro Power'],
        player: 'BHEL',
        state: 'Madhya Pradesh',
      );

      // Toggle on
      final isNowBookmarked = await dbService.toggleBookmark(article);
      expect(isNowBookmarked, true);
      expect(await dbService.isBookmarked('bm-test-1'), true);

      // Toggle off
      final isNowUnbookmarked = await dbService.toggleBookmark(article);
      expect(isNowUnbookmarked, false);
      expect(await dbService.isBookmarked('bm-test-1'), false);
    });

    test('Search history saves and retrieves', () async {
      await dbService.saveSearchQuery('smart meter');
      await dbService.saveSearchQuery('765kv substation');
      await dbService.saveSearchQuery('solar tender');

      final searches = await dbService.getRecentSearches();
      expect(searches.length, 3);
      expect(searches.first, 'solar tender'); // Most recent first
    });

    test('Search history deduplicates and increments hit count', () async {
      await dbService.saveSearchQuery('smart meter');
      await dbService.saveSearchQuery('solar tender');
      await dbService.saveSearchQuery('smart meter'); // duplicate

      final searches = await dbService.getRecentSearches();
      expect(searches.length, 2); // only 2 unique queries
      expect(searches.first, 'smart meter'); // updated timestamp pushes it first
    });

    test('Clear search history removes all entries', () async {
      await dbService.saveSearchQuery('test query 1');
      await dbService.saveSearchQuery('test query 2');
      await dbService.clearSearchHistory();

      final searches = await dbService.getRecentSearches();
      expect(searches.isEmpty, true);
    });

    test('Purge expired removes old non-bookmarked articles', () async {
      final oldArticle = NewsArticle(
        id: 'old-purge-1',
        title: 'Old news',
        summary: 'This should be purged.',
        url: 'http://test.com/old',
        source: 'Old Source',
        publishedAt: DateTime.now().subtract(const Duration(days: 45)),
        categories: ['generation'],
        state: 'National',
      );

      await dbService.upsertArticles([oldArticle]);
      final purged = await dbService.purgeExpired(retentionDays: 30);
      expect(purged, 1);
    });

    test('Bookmarked articles survive purge', () async {
      final oldBookmarked = NewsArticle(
        id: 'old-bm-survive',
        title: 'Important saved article',
        summary: 'This is bookmarked and should survive purge.',
        url: 'http://test.com/bm-survive',
        source: 'CERC',
        publishedAt: DateTime.now().subtract(const Duration(days: 60)),
        categories: ['policy'],
        state: 'National',
      );

      await dbService.upsertArticles([oldBookmarked]);
      await dbService.toggleBookmark(oldBookmarked); // Bookmark it
      final purged = await dbService.purgeExpired(retentionDays: 30);
      expect(purged, 0); // should NOT be purged

      final bookmarks = await dbService.getBookmarkedArticles();
      expect(bookmarks.any((a) => a.id == 'old-bm-survive'), true);
    });

    test('Sync metadata stores and retrieves values', () async {
      await dbService.setSyncMeta('last_sync', '2026-09-03T10:00:00Z');
      final value = await dbService.getSyncMeta('last_sync');
      expect(value, '2026-09-03T10:00:00Z');
    });

    test('getLatestPublishedAt returns correct timestamp', () async {
      final articles = [
        NewsArticle(
          id: 'lat-1',
          title: 'First article',
          summary: 'First.',
          url: 'http://a.com',
          source: 'S',
          publishedAt: DateTime(2026, 9, 1),
          categories: ['generation'],
          state: 'National',
        ),
        NewsArticle(
          id: 'lat-2',
          title: 'Second article',
          summary: 'Second.',
          url: 'http://b.com',
          source: 'S',
          publishedAt: DateTime(2026, 9, 3),
          categories: ['generation'],
          state: 'National',
        ),
      ];

      await dbService.upsertArticles(articles);
      final latest = await dbService.getLatestPublishedAt();
      expect(latest, isNotNull);
      expect(latest!.day, 3);
      expect(latest.month, 9);
    });

    test('Persists and retrieves imageUrl correctly', () async {
      final articleWithImage = NewsArticle(
        id: 'img-test-1',
        title: 'NTPC inaugurates 500MW solar park',
        summary: 'Massive solar park commissioned with state of the art bifacial modules.',
        url: 'http://test.com/ntpc-solar',
        source: 'PowerLine',
        publishedAt: DateTime.now(),
        categories: ['renewables'],
        imageUrl: 'https://powerline.net.in/wp-content/uploads/2026/09/ntpc_solar.jpg',
        state: 'Gujarat',
      );

      await dbService.upsertArticles([articleWithImage]);
      final retrieved = await dbService.getAllArticles();
      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'img-test-1');
      expect(retrieved.first.imageUrl, 'https://powerline.net.in/wp-content/uploads/2026/09/ntpc_solar.jpg');
    });
  });
}
