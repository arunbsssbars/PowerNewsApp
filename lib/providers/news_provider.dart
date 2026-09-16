import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import '../models/morning_digest.dart';
import '../models/grid_persona.dart';
import '../services/api_service.dart';
import '../services/bookmark_service.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class NewsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BookmarkService _bookmarkService = BookmarkService();
  final CacheService _cacheService = CacheService();
  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();
  Timer? _warmupTimer;
  Timer? _autoRefreshTimer;

  static const String _prefGuideKey = 'has_seen_swipe_guide_v2';
  static const String _prefCustomFiltersKey = 'custom_power_filters_v1';
  static const String _prefPersonaKey = 'selected_grid_persona_v1';
  static const String _prefSeenArticlesKey = 'powernews_seen_article_ids_v2';
  static const String _prefReadArticlesKey = 'powernews_read_article_ids_v2';
  static const String _prefNewArticlesKey = 'powernews_new_article_ids_v2';
  static const int _pageSize = 15;

  List<NewsArticle> _articles = [];
  List<NewsArticle> _cachedFullList = [];
  List<NewsArticle> _bookmarks = [];
  List<String> _customFilters = ['Smart Meter', 'Battery Storage', '765 kV Substation', 'Solar Tender'];
  String? _activeCustomFilter;
  MorningDigest? _morningDigest;
  bool _isLoadingDigest = false;

  GridPersona _selectedPersona = GridPersona.all;
  bool _personaOnlyFilter = false;

  List<String> _recentSearches = [];

  Map<String, int> _categories = {};
  Map<String, int> _states = {};
  Map<String, int> _cities = {};
  Map<String, int> _players = {};
  Map<String, int> _discoms = {};
  Map<String, int> _sources = {};

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isFilterLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  bool _isLocating = false;
  bool _isOffline = false;
  bool _isRetrying = false;
  bool _noInternetOnScroll = false;
  String? _errorMessage;
  bool _hasInitialDataLoaded = false;
  final Set<String> _seenArticleIds = {};
  final Set<String> _readArticleIds = {};
  final Set<String> _newArticleIds = {};
  final List<NewsArticle> _notificationArticles = [];

  VoidCallback? onScrollToTopRequested;

  String _selectedCategory = 'All';
  String _selectedPlayer = 'All';
  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String? _detectedCity;
  String _selectedDiscom = 'All DISCOMs';
  String _searchQuery = '';
  ThemeMode _themeMode = ThemeMode.light;
  bool _hasSeenSwipeGuide = false;
  int _currentNavIndex = 0;
  DateTime? _lastNewsFetchTime;
  static const Duration _newsCacheTtl = Duration(minutes: 10);

  // Getters
  int get currentNavIndex => _currentNavIndex;
  List<NewsArticle> get articles => _articles;
  List<NewsArticle> get bookmarks => _bookmarks;
  List<String> get customFilters => _customFilters;
  String? get activeCustomFilter => _activeCustomFilter;
  Map<String, int> get categories => _categories;
  Map<String, int> get states => _states;
  Map<String, int> get cities => _cities;
  Map<String, int> get players => _players;
  Map<String, int> get discoms => _discoms;
  Map<String, int> get sources => _sources;

  int get totalNewsCount {
    int maxCount = _apiService.lastTotalCount;
    if (_cachedFullList.length > maxCount) {
      maxCount = _cachedFullList.length;
    }
    if (_categories.isNotEmpty) {
      final catSum = _categories.values.fold(0, (s, c) => s + c);
      if (catSum > maxCount) {
        maxCount = catSum;
      }
    }
    if (_articles.length > maxCount) {
      maxCount = _articles.length;
    }
    return maxCount;
  }

  int get totalStateNewsCount {
    if (_states.isNotEmpty) {
      final total = _states.values.fold(0, (sum, count) => sum + count);
      if (total > 0) return total;
    }
    return totalNewsCount;
  }

  int get totalDiscomNewsCount {
    if (_discoms.isNotEmpty) {
      final total = _discoms.values.fold(0, (sum, count) => sum + count);
      if (total > 0) return total;
    }
    return totalNewsCount;
  }

  int get totalPlayerNewsCount {
    if (_players.isNotEmpty) {
      final total = _players.values.fold(0, (sum, count) => sum + count);
      if (total > 0) return total;
    }
    return totalNewsCount;
  }

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isFilterLoading => _isFilterLoading;
  bool get hasMore => _hasMore;
  bool get isLocating => _isLocating;
  bool get isOffline => _isOffline;
  bool get isRetrying => _isRetrying;
  bool get noInternetOnScroll => _noInternetOnScroll;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedPlayer => _selectedPlayer;
  String get selectedState => _selectedState;
  String get selectedCity => _selectedCity;
  String? get detectedCity => _detectedCity;
  String get selectedDiscom => _selectedDiscom;
  String get searchQuery => _searchQuery;
  ThemeMode get themeMode => _themeMode;
  String get activeServerHost => _apiService.activeHost;
  ApiService get apiService => _apiService;
  bool get hasSeenSwipeGuide => _hasSeenSwipeGuide;
  MorningDigest? get morningDigest => _morningDigest;
  bool get isLoadingDigest => _isLoadingDigest;
  GridPersona get selectedPersona => _selectedPersona;
  bool get personaOnlyFilter => _personaOnlyFilter;
  List<String> get recentSearches => _recentSearches;
  List<NewsArticle> get notificationArticles => List.unmodifiable(_notificationArticles);
  int get newArticlesCount => _notificationArticles.where((a) => !_readArticleIds.contains(a.id)).length;
  bool isArticleNew(String id) => _newArticleIds.contains(id) && !_readArticleIds.contains(id);
  bool get hasInitialDataLoaded => _hasInitialDataLoaded;
  bool get isNewsCacheExpired {
    if (_lastNewsFetchTime == null) return true;
    return DateTime.now().difference(_lastNewsFetchTime!) > _newsCacheTtl;
  }
  bool get isFiltered =>
      _selectedCategory != 'All' ||
      (_selectedPlayer != 'All' && _selectedPlayer != 'All Players') ||
      _selectedState != 'All States' ||
      _selectedCity != 'All Cities' ||
      _selectedDiscom != 'All DISCOMs' ||
      _searchQuery.isNotEmpty ||
      _activeCustomFilter != null ||
      _personaOnlyFilter;

  NewsProvider() {
    init();
  }

  Future<void> fetchMorningDigest() async {
    _isLoadingDigest = true;
    notifyListeners();
    try {
      final digest = await _apiService.fetchMorningDigest();
      if (digest != null && digest.items.isNotEmpty) {
        _morningDigest = digest;
      }
    } catch (e) {
      debugPrint('[NewsProvider] Error loading morning digest: $e');
    } finally {
      _isLoadingDigest = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    _isLoading = true;

    // 0. Cleanup of any legacy non-AI summaries from SQLite
    try {
      await _dbService.purgeNonAiSummaries();
    } catch (e) {
      debugPrint('[NewsProvider] Cleanup error (non-fatal): $e');
    }

    // 1. Unified Instant Cache & Local Preference Loading in ONE consolidated pass
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenSwipeGuide = prefs.getBool(_prefGuideKey) ?? false;
      final savedFilters = prefs.getStringList(_prefCustomFiltersKey);
      if (savedFilters != null && savedFilters.isNotEmpty) {
        _customFilters = savedFilters;
      }
      final savedPersonaId = prefs.getString(_prefPersonaKey);
      if (savedPersonaId != null) {
        _selectedPersona = GridPersona.fromId(savedPersonaId);
      }

      final savedSeen = prefs.getStringList(_prefSeenArticlesKey);
      if (savedSeen != null && savedSeen.isNotEmpty) {
        _seenArticleIds.addAll(savedSeen);
      }
      final savedRead = prefs.getStringList(_prefReadArticlesKey);
      if (savedRead != null && savedRead.isNotEmpty) {
        _readArticleIds.addAll(savedRead);
      }
      final savedNew = prefs.getStringList(_prefNewArticlesKey);
      if (savedNew != null && savedNew.isNotEmpty) {
        _newArticleIds.addAll(savedNew);
      }

      // Load bookmarks and search history from SQLite
      _bookmarks = await _bookmarkService.getBookmarks();
      _recentSearches = await _dbService.getRecentSearches();

      // Load cached articles from SQLite (instant — no JSON parsing overhead)
      final cached = await _cacheService.getCachedArticles();
      if (cached.isNotEmpty) {
        _cachedFullList = _applyFiltersTo(cached);
        _articles = _cachedFullList.take(_pageSize).toList();
        _hasMore = _cachedFullList.length > _pageSize;
        _recomputeCountsFromLocalCache(cached);
        _hasInitialDataLoaded = true;
        _isLoading = false;
        _lastNewsFetchTime = DateTime.now();

        // Ensure all existing cached articles are marked seen so old articles are NEVER flagged new
        _seenArticleIds.addAll(cached.map((a) => a.id));

        // Purge any IDs that are already read from _newArticleIds
        _newArticleIds.removeWhere((id) => _readArticleIds.contains(id));

        // Reconstitute notification articles from existing cache
        if (_newArticleIds.isNotEmpty) {
          final cachedMap = {for (var a in cached) a.id: a};
          for (final id in _newArticleIds) {
            final art = cachedMap[id];
            if (art != null && !_notificationArticles.any((n) => n.id == id)) {
              _notificationArticles.add(art);
            }
          }
          // Prune any stale IDs that no longer exist in cached articles
          _newArticleIds.removeWhere((id) => !cachedMap.containsKey(id));
        }
        _persistNotificationState();
      } else {
        _hasInitialDataLoaded = false;
        _isLoading = true;
      }
    } catch (e) {
      debugPrint('[NewsProvider] Cache init error: $e');
    } finally {
      if (_articles.isNotEmpty) {
        _isLoading = false;
      }
      notifyListeners(); // Single consolidated notification!
    }

    // On first launch or empty cache, fetch immediately so user sees loader then news
    if (_articles.isEmpty) {
      fetchNews();
    }

    // 2. Smoothly warmup background network tasks after UI is painted
    _warmupBackgroundServices();
  }

  void _warmupBackgroundServices() {
    _warmupTimer?.cancel();
    _warmupTimer = Timer(const Duration(milliseconds: 700), () async {
      try {
        _cacheService.pruneExpiredCache();
        autoDetectLocation();
        await _apiService.checkAndSelectHost();
        await fetchMetadata();
        await fetchMorningDigest();
        await fetchNews(isRefresh: _articles.isNotEmpty);
      } catch (e) {
        debugPrint('[NewsProvider] Background network warmup completed: $e');
        if (_articles.isEmpty) {
          fetchNews();
        }
      }
      _startAutoRefreshPolling();
    });
  }

  void _startAutoRefreshPolling() {
    _autoRefreshTimer?.cancel();
    // Background polling every 90 seconds while user is actively reading or using the app
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 90), (timer) async {
      if (_isOffline || _isRefreshing || _isLoading) return;
      try {
        // Fetch unfiltered national grid stream to discover freshly scraped & AI-summarized articles
        final latestNews = await _apiService.getNews(limit: 15);
        if (latestNews.isNotEmpty && _seenArticleIds.isNotEmpty) {
          bool hasNew = false;
          final cutoffRecent = DateTime.now().subtract(const Duration(hours: 36));
          for (final a in latestNews) {
            if (!_seenArticleIds.contains(a.id) &&
                !_articles.any((cur) => cur.id == a.id) &&
                !_readArticleIds.contains(a.id)) {
              _seenArticleIds.add(a.id);
              // Only alert if the article has an authentic AI summary and was published recently
              if (a.publishedAt.isAfter(cutoffRecent) && a.summary.length >= 50) {
                _newArticleIds.add(a.id);
                if (!_notificationArticles.any((n) => n.id == a.id)) {
                  _notificationArticles.insert(0, a);
                }
                hasNew = true;
              }
            }
          }
          if (hasNew) {
            _persistNotificationState();
            notifyListeners();
          }
        }
      } catch (e) {
        // Silently fail background poll
      }
    });
  }

  Future<void> applyNewArticles() async {
    // 1. Immediately mark pending notifications as read to dismiss button without UI lag
    _readArticleIds.addAll(_newArticleIds);
    _readArticleIds.addAll(_notificationArticles.map((a) => a.id));
    _newArticleIds.clear();
    // Do NOT clear _notificationArticles - keep them in user's notification list
    _persistNotificationState();
    notifyListeners();

    // 2. Clear filters and trigger smooth scroll to top
    clearFilters(reloadFromNetwork: false);
    onScrollToTopRequested?.call();

    // 3. Fetch latest news to populate feed
    await fetchNews(isRefresh: true);

    // 4. Ensure all newly loaded articles in the feed are recorded as seen
    for (final a in _articles) {
      _seenArticleIds.add(a.id);
    }
    _newArticleIds.clear();
    await _persistNotificationState();
    notifyListeners();
  }

  void markArticleAsRead(String id) {
    _readArticleIds.add(id);
    _newArticleIds.remove(id);
    _persistNotificationState();
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _readArticleIds.addAll(_newArticleIds);
    _readArticleIds.addAll(_notificationArticles.map((a) => a.id));
    _newArticleIds.clear();
    // Retain _notificationArticles in notification sheet
    _persistNotificationState();
    notifyListeners();
  }

  void clearAllNotifications() {
    _readArticleIds.addAll(_notificationArticles.map((a) => a.id));
    _newArticleIds.clear();
    _notificationArticles.clear();
    _persistNotificationState();
    notifyListeners();
  }

  void clearNewArticlesCount() {
    markAllNotificationsAsRead();
  }

  Future<void> _persistNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenList = _seenArticleIds.toList();
      final cappedSeen = seenList.length > 350 ? seenList.sublist(seenList.length - 350) : seenList;
      await prefs.setStringList(_prefSeenArticlesKey, cappedSeen);

      final readList = _readArticleIds.toList();
      final cappedRead = readList.length > 200 ? readList.sublist(readList.length - 200) : readList;
      await prefs.setStringList(_prefReadArticlesKey, cappedRead);

      await prefs.setStringList(_prefNewArticlesKey, _newArticleIds.toList());
    } catch (e) {
      debugPrint('[NewsProvider] Error persisting notification state: $e');
    }
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCustomFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefCustomFiltersKey);
    if (saved != null && saved.isNotEmpty) {
      _customFilters = saved;
      notifyListeners();
    }
  }

  Future<void> addCustomFilter(String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _customFilters.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      setCustomFilter(trimmed);
      return;
    }
    _customFilters.add(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefCustomFiltersKey, _customFilters);
    setCustomFilter(trimmed);
  }

  Future<void> removeCustomFilter(String tag) async {
    _customFilters.remove(tag);
    if (_activeCustomFilter == tag) {
      _activeCustomFilter = null;
      _searchQuery = '';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefCustomFiltersKey, _customFilters);
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  Future<void> reorderCustomFilters(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = _customFilters.removeAt(oldIndex);
    _customFilters.insert(newIndex, item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefCustomFiltersKey, _customFilters);
    notifyListeners();
  }

  void setCustomFilter(String? tag) {
    if (_activeCustomFilter == tag) {
      _activeCustomFilter = null;
      _searchQuery = '';
    } else {
      _activeCustomFilter = tag;
      _selectedCategory = 'All';
      _selectedPlayer = 'All';
      _selectedState = 'All States';
      _selectedCity = 'All Cities';
      _selectedDiscom = 'All DISCOMs';
      _searchQuery = tag ?? '';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  Future<void> dismissSwipeGuide() async {
    _hasSeenSwipeGuide = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGuideKey, true);
    notifyListeners();
  }

  Future<void> autoDetectLocation() async {
    _detectedCity = await _locationService.detectUserCity();
    notifyListeners();
  }

  Future<String?> refreshLiveGPSLocation() async {
    _isLocating = true;
    notifyListeners();

    try {
      final detected = await _locationService.detectLiveGPSLocation();
      if (detected != null && detected.isNotEmpty) {
        _detectedCity = detected;
      }
    } finally {
      _isLocating = false;
      notifyListeners();
    }
    return _detectedCity;
  }

  Future<void> setUserCity(String city) async {
    _detectedCity = city;
    await _locationService.setPreferredCity(city);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setNavIndex(int index) {
    if (_currentNavIndex == index) return;
    _currentNavIndex = index;
    notifyListeners();
  }

  void markArticleAsSeen(String articleId) {
    _seenArticleIds.add(articleId);
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _activeCustomFilter = null;
    if (category != 'All') {
      _selectedPlayer = 'All';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  void setPlayerFilter(String player) {
    if (_selectedPlayer == player) return;
    _selectedPlayer = player;
    _activeCustomFilter = null;
    if (player != 'All' && player != 'All Players') {
      _selectedCategory = 'All';
      _selectedState = 'All States';
      _selectedCity = 'All Cities';
      _selectedDiscom = 'All DISCOMs';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  void setStateFilter(String state) {
    if (_selectedState == state) return;
    _selectedState = state;
    _selectedCity = 'All Cities';
    _activeCustomFilter = null;
    if (state != 'All States') {
      _selectedPlayer = 'All';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  void setCityFilter(String city) {
    if (_selectedCity == city) return;
    _selectedCity = city;
    _activeCustomFilter = null;
    if (city != 'All Cities') {
      _selectedPlayer = 'All';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  void setDiscomFilter(String discom) {
    if (_selectedDiscom == discom) return;
    _selectedDiscom = discom;
    _activeCustomFilter = null;
    if (discom != 'All DISCOMs') {
      _selectedPlayer = 'All';
    }
    _isFilterLoading = true;
    _articles.clear();
    notifyListeners();
    fetchNews();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _activeCustomFilter = null;
    if (query.trim().isNotEmpty) {
      _selectedPlayer = 'All';
      // Persist search query to SQLite history
      _dbService.saveSearchQuery(query).then((_) async {
        _recentSearches = await _dbService.getRecentSearches();
      });
    }

    // Tier 1: Instant local in-memory search over verified cached articles (0 network latency)
    if (_cachedFullList.isNotEmpty) {
      _articles = _applyFiltersTo(_cachedFullList).take(_pageSize).toList();
      _hasMore = _cachedFullList.length > _pageSize;
      _isFilterLoading = false;
      notifyListeners();
    } else {
      _isFilterLoading = true;
      notifyListeners();
      fetchNews();
    }
  }

  Future<void> searchLiveWeb(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _isFilterLoading = true;
    notifyListeners();

    try {
      final liveResults = await _apiService.searchTopic(trimmed);
      if (liveResults.isNotEmpty) {
        _articles = _sortArticles(liveResults);
        _hasMore = false;
        await _cacheService.cacheArticles(liveResults);
        final allCached = await _cacheService.getCachedArticles();
        _cachedFullList = _applyFiltersTo(allCached);
        _recomputeCountsFromLocalCache(allCached);
      }
    } catch (e) {
      debugPrint('[NewsProvider] Error searching live web: $e');
    } finally {
      _isFilterLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearSearchHistory() async {
    await _dbService.clearSearchHistory();
    _recentSearches = [];
    notifyListeners();
  }

  void setPersona(GridPersona persona) async {
    if (_selectedPersona == persona) return;
    _selectedPersona = persona;
    _sortAndApplyPersonaToArticles();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPersonaKey, persona.id);
    } catch (_) {}
  }

  void togglePersonaOnlyFilter() {
    _personaOnlyFilter = !_personaOnlyFilter;
    if (_isOffline && _cachedFullList.isNotEmpty) {
      _articles = _applyFiltersTo(_cachedFullList).take(_pageSize).toList();
    } else {
      fetchNews();
    }
    notifyListeners();
  }

  void resetFiltersInMemory({bool notify = true}) {
    _selectedCategory = 'All';
    _selectedPlayer = 'All';
    _selectedState = 'All States';
    _selectedCity = 'All Cities';
    _selectedDiscom = 'All DISCOMs';
    _selectedPersona = GridPersona.all;
    _personaOnlyFilter = false;
    _activeCustomFilter = null;
    _searchQuery = '';
    _isFilterLoading = false;

    _cacheService.getCachedArticles().then((allCached) {
      if (allCached.isNotEmpty) {
        _cachedFullList = _applyFiltersTo(allCached);
        _articles = _cachedFullList.take(_pageSize).toList();
        _hasMore = _cachedFullList.length > _pageSize;
        _errorMessage = null;
        if (notify) notifyListeners();
      } else {
        fetchNews();
      }
    });

    if (notify) {
      notifyListeners();
    }
  }

  void clearFilters({bool reloadFromNetwork = true}) {
    _selectedCategory = 'All';
    _selectedPlayer = 'All';
    _selectedState = 'All States';
    _selectedCity = 'All Cities';
    _selectedDiscom = 'All DISCOMs';
    _selectedPersona = GridPersona.all;
    _personaOnlyFilter = false;
    _activeCustomFilter = null;
    _searchQuery = '';
    _isFilterLoading = true;
    _errorMessage = null;
    notifyListeners();

    _cacheService.getCachedArticles().then((allCached) {
      if (allCached.isNotEmpty) {
        _cachedFullList = _applyFiltersTo(allCached);
        _articles = _cachedFullList.take(_pageSize).toList();
        _hasMore = _cachedFullList.length > _pageSize;
        _isFilterLoading = false;
        notifyListeners();
      }
      if (reloadFromNetwork || _articles.isEmpty) {
        fetchNews(isRefresh: true);
      }
    });
  }

  void clearAllFilters({bool reloadFromNetwork = true}) =>
      clearFilters(reloadFromNetwork: reloadFromNetwork);

  void clearAllFiltersAndScrollTop({bool reloadFromNetwork = true}) {
    clearFilters(reloadFromNetwork: reloadFromNetwork);
    onScrollToTopRequested?.call();
  }

  void updateArticleSummary(String articleId, String newSummary) {
    final trimmed = newSummary.trim();
    if (trimmed.isEmpty) return;

    final artIdx = _articles.indexWhere((a) => a.id == articleId);
    if (artIdx != -1) {
      final old = _articles[artIdx];
      _articles[artIdx] = NewsArticle(
        id: old.id,
        title: old.title,
        summary: trimmed,
        url: old.url,
        source: old.source,
        publishedAt: old.publishedAt,
        categories: old.categories,
        player: old.player,
        city: old.city,
        state: old.state,
        discom: old.discom,
        fullText: old.fullText,
        sources: old.sources,
        sourceLinks: old.sourceLinks,
        coverageCount: old.coverageCount,
      );
    }

    final fullIdx = _cachedFullList.indexWhere((a) => a.id == articleId);
    if (fullIdx != -1) {
      final old = _cachedFullList[fullIdx];
      _cachedFullList[fullIdx] = NewsArticle(
        id: old.id,
        title: old.title,
        summary: trimmed,
        url: old.url,
        source: old.source,
        publishedAt: old.publishedAt,
        categories: old.categories,
        player: old.player,
        city: old.city,
        state: old.state,
        discom: old.discom,
        fullText: old.fullText,
        sources: old.sources,
        sourceLinks: old.sourceLinks,
        coverageCount: old.coverageCount,
      );
    }

    _dbService.updateArticleSummary(articleId, trimmed);
    notifyListeners();
  }

  Future<void> fetchMetadata() async {
    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getStates(),
        _apiService.getCities(),
        _apiService.getPlayers(),
        _apiService.getDiscoms(),
        _apiService.getSources(),
      ]);
      _categories = results[0];
      _states = results[1];
      _cities = results[2];
      _players = results[3];
      _discoms = results[4];
      _sources = results[5];

      // Merge counts with locally cached/synced articles
      final cached = await _cacheService.getCachedArticles();
      _recomputeCountsFromLocalCache(cached);

      notifyListeners();
    } catch (e) {
      debugPrint('[NewsProvider] Error loading metadata from server, computing from local cache: $e');
      final cached = await _cacheService.getCachedArticles();
      _recomputeCountsFromLocalCache(cached);
      notifyListeners();
    }
  }

  static final Map<String, List<String>> _playerAliases = {
    'UPPCL': ['uppcl', 'puvvnl', 'mvvnl', 'dvvnl', 'pvvnl', 'uttar pradesh power corporation'],
    'POWERGRID': ['power grid corporation', 'powergrid', 'pgcil', 'power grid corp'],
    'NTPC': ['ntpc limited', 'ntpc green', 'ntpc ltd', 'ntpc'],
    'Tata Power': ['tata power', 'tpddl', 'tpsodl', 'tpnodl', 'tpwodl', 'tpcodl', 'tata power renewable', 'tata power solar'],
    'Adani Power': ['adani power', 'adani green', 'adani electricity', 'aeml', 'adani energy solutions'],
    'Siemens': ['siemens energy', 'siemens limited', 'siemens india', 'siemens transformer', 'siemens gis', 'siemens grid', 'siemens'],
    'ABB': ['abb india', 'abb power', 'abb switchgear', 'abb substation', 'abb rtu', 'abb scada', 'abb'],
    'Schneider': ['schneider electric', 'schneider grid', 'schneider smart grid', 'schneider switchgear', 'schneider energy', 'schneider power'],
    'Hitachi Energy': ['hitachi energy', 'hitachi energy india', 'hitachi hvdc', 'hitachi power grid', 'hitachi scada', 'hitachi'],
    'BHEL': ['bhel', 'bharat heavy electricals', 'bhel turbine', 'bhel boiler', 'bhel transformer', 'bhel substation'],
    'L&T Power': ['larsen & toubro', 'l&t power', 'l&t transmission', 'l&t substation', 'l&t energy', 'l&t construction', 'l&t', 'larsen'],
    'GE Vernova': ['ge vernova', 'ge power india', 'ge grid solutions', 'ge power', 'ge t&d india', 'ge t&d', 'ge vernova india'],
    'CG Power': ['cg power', 'crompton greaves', 'cg power and industrial', 'cg power & industrial'],
    'KEC International': ['kec international', 'kec transmission', 'rpg group kec', 'kec'],
    'Kalpataru (KPIL)': ['kalpataru projects', 'kpil', 'kalpataru power transmission', 'kalpataru'],
    'Sterlite Power': ['sterlite power', 'sterlite grid', 'sterlite transmission', 'sterlite'],
    'Secure Meters': ['secure meters', 'secure smart meter', 'secure meter', 'secure'],
    'Genus Power': ['genus power infrastructures', 'genus smart meter', 'genus power', 'genus'],
    'Waaree Energies': ['waaree energies', 'waaree solar', 'waaree module', 'waaree'],
    'Reliance Power': ['reliance power', 'reliance infra', 'reliance new energy', 'rpower'],
    'SECI': ['solar energy corporation of india', 'seci'],
    'JSW Energy': ['jsw energy', 'jsw neo'],
    'Torrent Power': ['torrent power'],
    'NHPC': ['nhpc limited', 'nhpc ltd', 'nhpc'],
  };

  static bool matchesPlayer(NewsArticle a, String player) {
    if (player == 'All' || player == 'All Players') return true;
    if (a.player != null && a.player!.toLowerCase() == player.toLowerCase()) return true;
    final pLower = player.toLowerCase();
    final aliases = _playerAliases[player] ?? [pLower];
    final titleLower = a.title.toLowerCase();
    final summaryLower = a.summary.toLowerCase();
    return aliases.any((alias) =>
      (a.player != null && a.player!.toLowerCase().contains(alias)) ||
      titleLower.contains(alias) ||
      summaryLower.contains(alias)
    );
  }

  void _recomputeCountsFromLocalCache(List<NewsArticle> cachedArticles) {
    if (cachedArticles.isEmpty) return;

    final Map<String, int> mergedPlayers = Map.from(_players);
    final Map<String, int> mergedCategories = Map.from(_categories);
    final Map<String, int> mergedStates = Map.from(_states);
    final Map<String, int> mergedDiscoms = Map.from(_discoms);

    // List of known player keys to ensure they are scanned
    final knownPlayers = {
      'Siemens', 'ABB', 'Schneider', 'Hitachi Energy', 'BHEL', 'L&T Power',
      'GE Vernova', 'CG Power', 'KEC International', 'Kalpataru (KPIL)',
      'Sterlite Power', 'Secure Meters', 'Genus Power', 'Waaree Energies',
      'UPPCL', 'POWERGRID', 'NTPC', 'Tata Power', 'Adani Power', 'Reliance Power',
      'SECI', 'NHPC', 'JSW Energy', 'Torrent Power',
      ...mergedPlayers.keys
    };

    for (final player in knownPlayers) {
      final count = cachedArticles.where((a) => matchesPlayer(a, player)).length;
      if (count > (mergedPlayers[player] ?? 0)) {
        mergedPlayers[player] = count;
      }
    }

    final knownCats = {'generation', 'transmission', 'distribution', 'renewables', 'policy', 'scada', 'tenders'};
    for (final cat in knownCats) {
      final count = cachedArticles.where((a) => a.categories.contains(cat)).length;
      if (count > (mergedCategories[cat] ?? 0)) {
        mergedCategories[cat] = count;
      }
    }

    for (final a in cachedArticles) {
      if (a.state.isNotEmpty && a.state != 'National / Pan-India') {
        mergedStates[a.state] = (mergedStates[a.state] ?? 0);
      }
      if (a.discom != null && a.discom!.isNotEmpty) {
        mergedDiscoms[a.discom!] = (mergedDiscoms[a.discom!] ?? 0);
      }
    }

    for (final st in mergedStates.keys.toList()) {
      final count = cachedArticles.where((a) => a.state == st).length;
      if (count > (mergedStates[st] ?? 0)) {
        mergedStates[st] = count;
      }
    }

    for (final disc in mergedDiscoms.keys.toList()) {
      final count = cachedArticles.where((a) => a.discom == disc).length;
      if (count > (mergedDiscoms[disc] ?? 0)) {
        mergedDiscoms[disc] = count;
      }
    }

    _players = mergedPlayers;
    _categories = mergedCategories;
    _states = mergedStates;
    _discoms = mergedDiscoms;
  }

  void _sortAndApplyPersonaToArticles() {
    _articles = _sortArticles(_articles);
  }

  List<NewsArticle> _sortArticles(List<NewsArticle> list) {
    final copy = List<NewsArticle>.from(list);
    copy.sort((a, b) {
      if (_selectedPersona != GridPersona.all) {
        final relB = _selectedPersona.calculateRelevance(b.title, b.summary, b.primaryCategory, b.player);
        final relA = _selectedPersona.calculateRelevance(a.title, a.summary, a.primaryCategory, a.player);
        if ((relB - relA).abs() >= 15.0) {
          return relB.compareTo(relA);
        }
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return copy;
  }

  List<NewsArticle> _applyFiltersTo(List<NewsArticle> list) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final filtered = list.where((a) {
      if (!a.isStrictlyPowerSector) {
        return false;
      }
      // Enforce 7-day (1 week only) retention cutoff
      if (a.publishedAt.isBefore(cutoff)) {
        return false;
      }
      if (_selectedPersona != GridPersona.all && _personaOnlyFilter) {
        if (_selectedPersona.calculateRelevance(a.title, a.summary, a.primaryCategory, a.player) < 30.0) {
          return false;
        }
      }
      if (_selectedCategory != 'All' && !a.categories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())) {
        return false;
      }
      if (_selectedPlayer != 'All' && _selectedPlayer != 'All Players' && !matchesPlayer(a, _selectedPlayer)) {
        return false;
      }
      if (_selectedState != 'All States' && a.state != _selectedState) {
        return false;
      }
      if (_selectedCity != 'All Cities' && a.city != _selectedCity) {
        return false;
      }
      if (_selectedDiscom != 'All DISCOMs' && a.discom != _selectedDiscom) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!a.title.toLowerCase().contains(q) && !a.summary.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Strict AI Summary Gate: ONLY genuine narrative AI summaries (non-bullet, >= 75 chars)
      final sum = a.summary.trim();
      if (sum.length < 75 || sum.startsWith('• ') || sum.startsWith('- ') || sum.startsWith('* ')) {
        return false;
      }
      if (sum.toLowerCase() == a.title.trim().toLowerCase()) {
        return false;
      }
      if (sum.contains('prohibited content policy') ||
          sum.contains('all rights reserved') ||
          sum.startsWith('• A global renewable energy power plant step')) {
        return false;
      }
      return true;
    }).toList();

    return _sortArticles(filtered);
  }

  Future<void> retryConnection() async {
    if (_isRetrying) return;
    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[NewsProvider] Retrying host handshake and reconnecting...');
      await _apiService.checkAndSelectHost();
      await fetchNews(isRefresh: true);
    } catch (e) {
      debugPrint('[NewsProvider] Retry connection failed: $e');
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  Future<void> fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      notifyListeners();
    } else {
      _isLoading = _articles.isEmpty;
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
      _noInternetOnScroll = false;
      if (_isLoading || _isFilterLoading) {
        notifyListeners();
      }
    }

    try {
      final news = await _apiService.getNews(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        player: (_selectedPlayer == 'All' || _selectedPlayer == 'All Players') ? null : _selectedPlayer,
        state: _selectedState == 'All States' ? null : _selectedState,
        city: _selectedCity == 'All Cities' ? null : _selectedCity,
        discom: _selectedDiscom == 'All DISCOMs' ? null : _selectedDiscom,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
        limit: _pageSize,
      );

      // Filter out low-grade or non-AI stubs so feed contains 100% verified AI summaries
      final cleanNews = news.where((a) {
        final s = a.summary.trim();
        return s.length >= 75 &&
            !s.startsWith('• ') &&
            !s.startsWith('- ') &&
            !s.startsWith('* ') &&
            s.toLowerCase() != a.title.trim().toLowerCase() &&
            !s.contains('prohibited content policy') &&
            !s.startsWith('• A global renewable energy power plant step');
      }).toList();

      final sorted = _sortArticles(cleanNews);

      if (sorted.isEmpty) {
        final allCached = await _cacheService.getCachedArticles();
        final localMatches = _applyFiltersTo(allCached);
        if (localMatches.isNotEmpty) {
          _cachedFullList = localMatches;
          _articles = _cachedFullList.take(_pageSize).toList();
          _hasMore = _cachedFullList.length > _pageSize;
        } else {
          _articles = [];
          _hasMore = false;
        }
      } else {
        _articles = sorted;
        _hasMore = news.length == _pageSize;
        // Strictly persist ONLY verified AI-summarized articles into local cache
        await _cacheService.cacheArticles(cleanNews);
      }

      // Mark all articles fetched directly into the feed as seen
      _seenArticleIds.addAll(cleanNews.map((a) => a.id));

      if (isRefresh) {
        // When refreshing the feed, loaded articles are now visible; clear their pending unread status
        _readArticleIds.addAll(cleanNews.map((a) => a.id));
        _newArticleIds.removeWhere((id) => cleanNews.any((a) => a.id == id));
      }
      _persistNotificationState();

      _lastNewsFetchTime = DateTime.now();
      _isOffline = false;
      _isLoading = false;
      _isFilterLoading = false;
      _isRefreshing = false;
      _errorMessage = null;
      _hasInitialDataLoaded = true;
      final allCached = await _cacheService.getCachedArticles();
      if (!isFiltered) {
        _cachedFullList = _applyFiltersTo(allCached.isNotEmpty ? allCached : sorted);
      }
      _recomputeCountsFromLocalCache(allCached.isNotEmpty ? allCached : sorted);
      notifyListeners();
    } catch (e) {
      final hasInternet = await _checkHasInternet();
      // Only declare offline mode if device truly has no internet connectivity
      _isOffline = !hasInternet;
      _hasInitialDataLoaded = true;
      final cached = await _cacheService.getCachedArticles();
      if (cached.isNotEmpty) {
        final filteredCached = _applyFiltersTo(cached);
        if (filteredCached.isNotEmpty) {
          _cachedFullList = filteredCached;
          _articles = _cachedFullList.take(_pageSize).toList();
          _hasMore = _cachedFullList.length > _pageSize;
        } else {
          _cachedFullList = [];
          _articles = [];
          _hasMore = false;
        }
        _errorMessage = null;
      } else if (_articles.isNotEmpty) {
        _errorMessage = null;
      } else {
        _errorMessage = hasInternet
            ? 'Connecting to power news network...'
            : 'No internet connection. Tap retry to reconnect.';
      }

      _isLoading = false;
      _isFilterLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> _checkHasInternet() async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final result2 = await InternetAddress.lookup('1.1.1.1').timeout(const Duration(seconds: 3));
        return result2.isNotEmpty && result2[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> fetchMoreNews() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    _noInternetOnScroll = false;
    notifyListeners();

    // 1. Instant Local Pagination: Ensure local cache only emits strictly verified AI summaries
    final startIndex = _currentPage * _pageSize;
    if (_cachedFullList.length > startIndex) {
      final nextBatch = _cachedFullList
          .skip(startIndex)
          .take(_pageSize)
          .where((a) {
            final s = a.summary.trim();
            return s.length >= 75 &&
                !s.startsWith('• ') &&
                !s.startsWith('- ') &&
                !s.startsWith('* ');
          })
          .toList();
          
      _currentPage++;
      if (nextBatch.isNotEmpty) {
        _articles.addAll(nextBatch);
      }
      _hasMore = _cachedFullList.length > _currentPage * _pageSize;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    // 2. Offline: If cache is exhausted, mark hasMore false
    if (_isOffline) {
      _hasMore = false;
      _isLoadingMore = false;
      _noInternetOnScroll = true;
      notifyListeners();
      return;
    }

    // 3. Online: Fetch next page from backend
    try {
      final nextPage = _currentPage + 1;
      final moreNews = await _apiService.getNews(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        player: (_selectedPlayer == 'All' || _selectedPlayer == 'All Players') ? null : _selectedPlayer,
        state: _selectedState == 'All States' ? null : _selectedState,
        city: _selectedCity == 'All Cities' ? null : _selectedCity,
        discom: _selectedDiscom == 'All DISCOMs' ? null : _selectedDiscom,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: nextPage,
        limit: _pageSize,
      );

      _currentPage = nextPage;

      final cleanMore = moreNews.where((a) {
        final s = a.summary.trim();
        return s.length >= 75 &&
            !s.startsWith('• ') &&
            !s.startsWith('- ') &&
            !s.startsWith('* ') &&
            s.toLowerCase() != a.title.trim().toLowerCase() &&
            !s.contains('prohibited content policy') &&
            !s.startsWith('• A global renewable energy power plant step');
      }).toList();

      if (cleanMore.isNotEmpty) {
        _articles.addAll(cleanMore);
        await _cacheService.cacheArticles(cleanMore);
      }
      _hasMore = moreNews.length == _pageSize;
      
      // If we filtered out the entire page but there is more, we could recursively fetch, 
      // but for safety we just rely on the next scroll event or a "load more" trigger.
      
    } catch (e) {
      _noInternetOnScroll = true;
      debugPrint('[NewsProvider] Error fetching more news: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> triggerFullRefresh() async {
    _isRefreshing = true;
    notifyListeners();
    await _apiService.refreshBackend();
    await fetchMetadata();
    await fetchNews(isRefresh: true);
  }

  Future<void> loadBookmarks() async {
    _bookmarks = await _bookmarkService.getBookmarks();
    notifyListeners();
  }

  bool isBookmarked(String id) {
    if (id.isEmpty) return false;
    return _bookmarks.any((article) => article.id == id);
  }

  Future<void> toggleBookmark(NewsArticle article) async {
    await _bookmarkService.toggleBookmark(article);
    await loadBookmarks();
  }
}
