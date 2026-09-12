import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/news_article.dart';

/// SQLite-backed offline database for zero-latency cold start and full-text search.
/// Replaces the SharedPreferences JSON cache with a proper relational store.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  static const int _dbVersion = 1;
  static const String _dbName = 'powernews_offline.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _purgeUnsummarized(db);
    return db;
  }

  Future<void> _purgeUnsummarized(Database db) async {
    try {
      await db.delete(
        'articles',
        where: 'is_bookmarked = 0 AND (LOWER(TRIM(summary)) = LOWER(TRIM(title)) OR TRIM(summary) = \'\' OR summary LIKE ? OR summary LIKE ?)',
        whereArgs: ['%prohibited content policy%', '• A global renewable energy power plant step%'],
      );
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main articles table
    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        url TEXT NOT NULL,
        source TEXT NOT NULL,
        published_at TEXT NOT NULL,
        categories TEXT NOT NULL DEFAULT '[]',
        player TEXT,
        city TEXT,
        state TEXT NOT NULL DEFAULT 'National / Pan-India',
        discom TEXT,
        full_text TEXT,
        sources_json TEXT NOT NULL DEFAULT '[]',
        source_links_json TEXT NOT NULL DEFAULT '[]',
        coverage_count INTEGER NOT NULL DEFAULT 1,
        is_bookmarked INTEGER NOT NULL DEFAULT 0,
        cached_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Indexes for fast filtering and sorting
    await db.execute('CREATE INDEX idx_articles_published_at ON articles(published_at DESC)');
    await db.execute('CREATE INDEX idx_articles_category ON articles(categories)');
    await db.execute('CREATE INDEX idx_articles_state ON articles(state)');
    await db.execute('CREATE INDEX idx_articles_player ON articles(player)');
    await db.execute('CREATE INDEX idx_articles_bookmarked ON articles(is_bookmarked)');
    await db.execute('CREATE INDEX idx_articles_cached_at ON articles(cached_at)');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        searched_at TEXT NOT NULL,
        hit_count INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Sync metadata table
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    debugPrint('[DatabaseService] Created SQLite database v$_dbVersion');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations go here
    debugPrint('[DatabaseService] Upgraded database from v$oldVersion to v$newVersion');
  }

  // ──────────── Article CRUD ────────────

  /// Upsert articles into SQLite (merge new + existing, deduplicate by ID)
  Future<int> upsertArticles(List<NewsArticle> articles) async {
    if (articles.isEmpty) return 0;
    // Gatekeep: Reject empty summaries or raw titles masquerading as summaries
    final validArticles = articles.where((a) {
      final s = a.summary.trim();
      return s.isNotEmpty &&
          s.toLowerCase() != a.title.trim().toLowerCase() &&
          !s.contains('prohibited content policy') &&
          !s.startsWith('• A global renewable energy power plant step');
    }).toList();
    if (validArticles.isEmpty) return 0;

    final db = await database;
    final now = DateTime.now().toIso8601String();
    int count = 0;

    final batch = db.batch();
    for (final a in validArticles) {
      batch.rawInsert('''
        INSERT OR REPLACE INTO articles
          (id, title, summary, url, source, published_at, categories, player, city, state,
           discom, full_text, sources_json, source_links_json, coverage_count,
           is_bookmarked, cached_at, synced_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
          COALESCE((SELECT is_bookmarked FROM articles WHERE id = ?), 0),
          ?, ?)
      ''', [
        a.id, a.title, a.summary, a.url, a.source,
        a.publishedAt.toIso8601String(),
        json.encode(a.categories),
        a.player, a.city, a.state, a.discom, a.fullText,
        json.encode(a.sources),
        json.encode(a.sourceLinks.map((l) => {'source': l['source'], 'url': l['url']}).toList()),
        a.coverageCount,
        a.id, // for COALESCE subquery
        now, now,
      ]);
      count++;
    }
    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Upserted $count articles');
    return count;
  }

  /// Retrieve all cached articles within retention window (7 days / 1 week only), sorted by published_at DESC
  Future<List<NewsArticle>> getAllArticles({int retentionDays = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();

    final rows = await db.query(
      'articles',
      where: 'published_at >= ? OR is_bookmarked = 1',
      whereArgs: [cutoff],
      orderBy: 'published_at DESC',
    );

    return rows.map(_rowToArticle).where((a) {
      final s = a.summary.trim();
      return s.isNotEmpty &&
          s.toLowerCase() != a.title.trim().toLowerCase() &&
          !s.contains('prohibited content policy') &&
          !s.startsWith('• A global renewable energy power plant step');
    }).toList();
  }

  /// Delete any legacy non-AI summaries from local SQLite
  Future<int> purgeNonAiSummaries() async {
    final db = await database;
    final count = await db.delete(
      'articles',
      where: "summary LIKE '• %' OR summary LIKE '- %' OR summary LIKE '* %'",
    );
    if (count > 0) {
      debugPrint('[DatabaseService] Purged $count legacy bullet articles from SQLite');
    }
    return count;
  }

  /// Get only bookmarked articles
  Future<List<NewsArticle>> getBookmarkedArticles() async {
    final db = await database;
    final rows = await db.query(
      'articles',
      where: 'is_bookmarked = 1',
      orderBy: 'published_at DESC',
    );
    return rows.map(_rowToArticle).toList();
  }

  /// Toggle bookmark status for an article
  Future<bool> toggleBookmark(NewsArticle article) async {
    final db = await database;

    // Check if article exists
    final existing = await db.query('articles', where: 'id = ?', whereArgs: [article.id]);

    if (existing.isEmpty) {
      // Article not in DB yet — insert it as bookmarked
      final now = DateTime.now().toIso8601String();
      await db.rawInsert('''
        INSERT INTO articles
          (id, title, summary, url, source, published_at, categories, player, city, state,
           discom, full_text, sources_json, source_links_json, coverage_count,
           is_bookmarked, cached_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
      ''', [
        article.id, article.title, article.summary, article.url, article.source,
        article.publishedAt.toIso8601String(),
        json.encode(article.categories),
        article.player, article.city, article.state, article.discom, article.fullText,
        json.encode(article.sources),
        json.encode(article.sourceLinks.map((l) => {'source': l['source'], 'url': l['url']}).toList()),
        article.coverageCount,
        now,
      ]);
      return true;
    }

    // Toggle existing
    final currentlyBookmarked = (existing.first['is_bookmarked'] as int) == 1;
    await db.update(
      'articles',
      {'is_bookmarked': currentlyBookmarked ? 0 : 1},
      where: 'id = ?',
      whereArgs: [article.id],
    );
    return !currentlyBookmarked;
  }

  /// Check if an article is bookmarked
  Future<bool> isBookmarked(String articleId) async {
    final db = await database;
    final rows = await db.query(
      'articles',
      columns: ['is_bookmarked'],
      where: 'id = ?',
      whereArgs: [articleId],
    );
    if (rows.isEmpty) return false;
    return (rows.first['is_bookmarked'] as int) == 1;
  }

  /// Get the latest published_at timestamp for incremental sync
  Future<DateTime?> getLatestPublishedAt() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(published_at) as latest FROM articles WHERE is_bookmarked = 0',
    );
    final latest = result.first['latest'] as String?;
    if (latest == null) return null;
    try {
      return DateTime.parse(latest);
    } catch (_) {
      return null;
    }
  }

  /// Update the executive summary of an existing article (e.g. newly synthesized AI summary)
  Future<int> updateArticleSummary(String articleId, String summary) async {
    try {
      final db = await database;
      return await db.update(
        'articles',
        {'summary': summary},
        where: 'id = ?',
        whereArgs: [articleId],
      );
    } catch (e) {
      debugPrint('[DatabaseService] Error updating article summary: $e');
      return 0;
    }
  }

  /// Purge articles older than retentionDays (7 days / 1 week only, preserving bookmarks)
  Future<int> purgeExpired({int retentionDays = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();
    final deleted = await db.delete(
      'articles',
      where: 'published_at < ? AND is_bookmarked = 0',
      whereArgs: [cutoff],
    );
    if (deleted > 0) {
      debugPrint('[DatabaseService] Purged $deleted expired articles older than $retentionDays days');
    }
    return deleted;
  }

  /// Get total article count
  Future<int> getArticleCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM articles');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ──────────── Search History ────────────

  /// Save a search query
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO search_history (query, searched_at, hit_count)
      VALUES (?, ?, 1)
      ON CONFLICT(query) DO UPDATE SET
        searched_at = excluded.searched_at,
        hit_count = hit_count + 1
    ''', [query.trim().toLowerCase(), now]);
  }

  /// Get recent search queries (most recent first, limit 10)
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      'search_history',
      columns: ['query'],
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return rows.map((r) => r['query'] as String).toList();
  }

  /// Clear all search history
  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // ──────────── Sync Metadata ────────────

  Future<void> setSyncMeta(String key, String value) async {
    final db = await database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO sync_meta (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  Future<String?> getSyncMeta(String key) async {
    final db = await database;
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ──────────── Internal Helpers ────────────

  NewsArticle _rowToArticle(Map<String, Object?> row) {
    List<String> cats = [];
    try {
      cats = (json.decode(row['categories'] as String? ?? '[]') as List)
          .map((e) => e.toString())
          .toList();
    } catch (_) {}
    if (cats.isEmpty) cats = ['generation'];

    List<String> srcList = [];
    try {
      srcList = (json.decode(row['sources_json'] as String? ?? '[]') as List)
          .map((e) => e.toString())
          .toList();
    } catch (_) {}

    List<Map<String, String>> srcLinks = [];
    try {
      final decoded = json.decode(row['source_links_json'] as String? ?? '[]') as List;
      for (final item in decoded) {
        if (item is Map) {
          srcLinks.add({
            'source': item['source']?.toString() ?? '',
            'url': item['url']?.toString() ?? '',
          });
        }
      }
    } catch (_) {}

    DateTime publishedAt;
    try {
      publishedAt = DateTime.parse(row['published_at'] as String);
    } catch (_) {
      publishedAt = DateTime.now();
    }

    return NewsArticle(
      id: row['id'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String,
      url: row['url'] as String,
      source: row['source'] as String,
      publishedAt: publishedAt,
      categories: cats,
      player: row['player'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String? ?? 'National / Pan-India',
      discom: row['discom'] as String?,
      fullText: row['full_text'] as String?,
      sources: srcList,
      sourceLinks: srcLinks,
      coverageCount: row['coverage_count'] as int? ?? 1,
      isAiGenerated: true,
    );
  }

  /// Close the database and optionally delete it (for testing / cleanup)
  Future<void> close({bool deleteDb = true}) async {
    final db = _db;
    if (db != null) {
      final path = db.path;
      await db.close();
      _db = null;
      if (deleteDb && path != inMemoryDatabasePath) {
        try {
          await deleteDatabase(path);
        } catch (_) {}
      }
    }
  }
}
