import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/city_filter_sheet.dart';
import '../widgets/news_card.dart';
import '../widgets/morning_digest_card.dart';
import '../widgets/persona_selector.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  NewsProvider? _newsProvider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newsProvider = context.read<NewsProvider>();
    _newsProvider?.onScrollToTopRequested = _scrollToTop;
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > 600 && pos.extentAfter < 300) {
      final provider = context.read<NewsProvider>();
      if (!provider.isLoadingMore && provider.hasMore && !provider.isLoading) {
        provider.fetchMoreNews();
      }
    }
  }

  @override
  void dispose() {
    if (_newsProvider?.onScrollToTopRequested == _scrollToTop) {
      _newsProvider?.onScrollToTopRequested = null;
    }
    _newsProvider = null;
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCityFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityFilterSheet(),
    );
  }

  void _showServerConfigDialog(BuildContext context, NewsProvider provider) {
    final controller = TextEditingController(text: provider.activeServerHost);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter host IP or port if running on a custom LAN address:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'http://192.168.1.59:3000',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.fetchNews();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detectedCity = provider.detectedCity ?? 'Delhi / NCR';
    final isCityFiltered = provider.selectedCity != 'All Cities';

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => provider.fetchNews(isRefresh: true),
          color: const Color(0xFF2563EB),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Sleek Minimal Search Bar (Fixed first sliver, 0 layout shift)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => provider.setSearchQuery(val),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search player, tariff, substation, tender...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                  ),
                ),
              ),

              // Simplified & Modern GPS Location Bar (Compact & Clean)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Row(
                    children: [
                      // Location Pill (Tap to Choose Any City)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _showCityFilterSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                            decoration: BoxDecoration(
                              color: isCityFiltered
                                  ? const Color(0xFF2563EB).withOpacity(isDark ? 0.22 : 0.1)
                                  : (isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isCityFiltered
                                    ? const Color(0xFF2563EB).withOpacity(0.4)
                                    : (isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isCityFiltered ? provider.selectedCity : detectedCity,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCityFiltered
                                        ? const Color(0xFF2563EB)
                                        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Quick City Toggle Pill (Local City vs Pan-India)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (provider.selectedCity == detectedCity) {
                              provider.setCityFilter('All Cities');
                            } else {
                              provider.setCityFilter(detectedCity);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: provider.selectedCity == detectedCity
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF111827) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: provider.selectedCity == detectedCity
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.selectedCity == detectedCity ? Icons.check_circle_rounded : Icons.radar_rounded,
                                  size: 12,
                                  color: provider.selectedCity == detectedCity ? Colors.white : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.selectedCity == detectedCity ? 'Local Feed' : 'Filter $detectedCity',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: provider.selectedCity == detectedCity
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grid Persona Role Switcher
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 2),
                  child: PersonaSelector(),
                ),
              ),

              // Sector Categories & Custom Filters Scroller with + Button
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: CategorySelector(),
                ),
              ),

              // Active Filter Indicator (if filtered)
              if (provider.selectedPlayer != 'All' || provider.selectedState != 'All States')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                    child: Row(
                      children: [
                        if (provider.selectedPlayer != 'All') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Utility: ${provider.selectedPlayer}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => provider.setPlayerFilter('All'),
                                  child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (provider.selectedState != 'All States') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'State: ${provider.selectedState}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => provider.setStateFilter('All States'),
                                  child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                          onPressed: () => provider.clearFilters(),
                          child: const Text('Show All News', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Morning Executive Briefing Card (shown on primary feed when available)
              if (provider.morningDigest != null &&
                  provider.selectedPlayer == 'All' &&
                  provider.selectedState == 'All States' &&
                  provider.searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: MorningDigestCard(digest: provider.morningDigest!),
                ),

              // Offline Status Banner when serving cached database
              if (provider.isOffline && provider.articles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B13) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.35 : 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline Mode • Showing cached power updates (${provider.articles.length})',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => provider.fetchNews(isRefresh: true),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.25 : 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 12,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // News Articles List / Loading / Error States
              if ((provider.isLoading && provider.articles.isEmpty) || provider.isFilterLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerSkeletonCard(isDark),
                    childCount: 3,
                  ),
                )
              else if (provider.errorMessage != null && provider.articles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Target Server: ${provider.activeServerHost}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry Connection', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => provider.fetchNews(),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.settings_ethernet_rounded, size: 16),
                                label: const Text('Config IP', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => _showServerConfigDialog(context, provider),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (provider.articles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_outlined, size: 36, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.selectedPlayer != 'All'
                                ? 'No direct news for ${provider.selectedPlayer}'
                                : (provider.selectedCategory != 'All'
                                    ? 'No updates in ${provider.selectedCategory}'
                                    : 'No power news found matching filters'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            provider.selectedPlayer != 'All'
                                ? 'Search live Indian power news archive for ${provider.selectedPlayer}:'
                                : 'Try resetting filters to explore latest sector intelligence',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          if (provider.selectedPlayer != 'All') ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.travel_explore_rounded, size: 16),
                              label: Text('Search Live Web for ${provider.selectedPlayer}'),
                              onPressed: () {
                                final p = provider.selectedPlayer;
                                final query = (p.toLowerCase() == 'schneider') ? 'Schneider Electric power India' : '$p power India';
                                _searchController.text = p;
                                provider.setSearchQuery(query);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextButton.icon(
                            icon: const Icon(Icons.restart_alt_rounded, size: 16),
                            label: const Text('Show All Power News'),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearFilters();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = provider.articles[index];
                      return NewsCard(
                        key: ValueKey(article.id),
                        article: article,
                        allArticles: provider.articles,
                        itemIndex: index,
                      );
                    },
                    childCount: provider.articles.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),

                // Bottom Infinite Scrolling Loader / Offline Message / Caught Up Indicator
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: provider.isLoadingMore
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Loading more power updates...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                              ],
                            )
                          : provider.noInternetOnScroll
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFFD97706)),
                                      SizedBox(width: 6),
                                      Text(
                                        'No internet connection to fetch older news',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : (provider.articles.isNotEmpty && !provider.hasMore)
                                  ? Text(
                                      '✓ You are all caught up with latest power updates',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
        
        // New Articles Notification Pill
        if (provider.newArticlesCount > 0)
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Material(
                  elevation: 6,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF2563EB),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => provider.applyNewArticles(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '${provider.newArticlesCount} New Updates',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerSkeletonCard(bool isDark) {
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 220,
            height: 16,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 160,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
