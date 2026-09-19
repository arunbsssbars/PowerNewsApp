import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/executive_card_view.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late final PageController _pageController;
  NewsProvider? _newsProvider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newsProvider = context.read<NewsProvider>();
    _newsProvider?.onScrollToTopRequested = _scrollToTop;
  }

  void _scrollToTop() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    if (_newsProvider?.onScrollToTopRequested == _scrollToTop) {
      _newsProvider?.onScrollToTopRequested = null;
    }
    _newsProvider = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final articles = provider.articles;

    // 1. Initial Loading State: Skeleton Shimmer Card
    if (provider.isLoading && articles.isEmpty) {
      return _buildSkeletonLoader(isDark);
    }

    // 2. Error State
    if (provider.errorMessage != null && articles.isEmpty) {
      return _buildErrorState(context, provider, isDark);
    }

    // 3. Empty State (Filter mismatch or zero articles)
    if (articles.isEmpty) {
      return _buildEmptyState(context, provider, isDark);
    }

    // 4. Main Executive Card Stream (Vertical PageView)
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: articles.length,
          onPageChanged: (index) {
            HapticFeedback.selectionClick();
            provider.markArticleAsSeen(articles[index].id);
            if (index >= articles.length - 2 && provider.hasMore && !provider.isLoadingMore) {
              provider.fetchMoreNews();
            }
          },
          itemBuilder: (context, index) {
            final article = articles[index];
            return ExecutiveCardView(
              article: article,
              currentIndex: index,
              totalCount: articles.length,
              onNextCard: () {
                if (index < articles.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            );
          },
        ),

        // Floating Filter Indicator Pill (when category/player/state filter is active)
        if (provider.isFiltered)
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0x2EFFFFFF) : const Color(0x1F000000),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 13,
                      color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getActiveFilterLabel(provider),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.resetFiltersInMemory();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating Offline Mode Pill
        if (provider.isOffline)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 12, color: Colors.amberAccent),
                    SizedBox(width: 6),
                    Text(
                      'Offline Cache Mode',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getActiveFilterLabel(NewsProvider p) {
    if (p.selectedCategory != 'All') return p.selectedCategory;
    if (p.selectedPlayer != 'All' && p.selectedPlayer != 'All Players') return p.selectedPlayer;
    if (p.selectedState != 'All States') return p.selectedState;
    if (p.selectedDiscom != 'All DISCOMs') return p.selectedDiscom;
    if (p.searchQuery.isNotEmpty) return '"${p.searchQuery}"';
    return 'Filtered';
  }

  Widget _buildSkeletonLoader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final placeholderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 12, color: placeholderColor),
                  const SizedBox(height: 14),
                  Container(width: double.infinity, height: 18, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: 220, height: 18, color: placeholderColor),
                  const SizedBox(height: 20),
                  Container(width: double.infinity, height: 12, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: placeholderColor),
                  const SizedBox(height: 8),
                  Container(width: 280, height: 12, color: placeholderColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, NewsProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 30,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Executive Briefings Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isFiltered
                  ? 'No stories match the active filter. Tap below to reset and view all sector intelligence.'
                  : 'Feed is refreshing or no briefings available in retention period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (provider.isFiltered)
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  provider.resetFiltersInMemory();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, NewsProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent.shade100),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Could not connect to power news cloud network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.retryConnection(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
