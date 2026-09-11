import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'feed_view.dart';
import 'dashboard_view.dart';
import 'regions_view.dart';
import 'bookmarks_view.dart';
import 'onboarding_screen.dart';
import '../widgets/ask_gemini_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Set<int> _visitedTabs = {0};
  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  void _onNavigateTab(int index, {bool resetFilters = false}) {
    setState(() => _visitedTabs.add(index));
    final provider = context.read<NewsProvider>();
    if (resetFilters) {
      provider.clearAllFilters();
    }
    provider.setNavIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = provider.currentNavIndex;
    _visitedTabs.add(currentIndex);

    final pages = [
      const FeedView(),
      _visitedTabs.contains(1)
          ? DashboardView(onNavigateTab: (idx) => _onNavigateTab(idx))
          : const SizedBox.shrink(),
      _visitedTabs.contains(2) ? const RegionsView() : const SizedBox.shrink(),
      _visitedTabs.contains(3) ? const BookmarksView() : const SizedBox.shrink(),
    ];

    final titles = [
      'PowerNews',
      'Dashboard',
      'States & DISCOMs',
      'Saved Articles',
    ];

    final int bookmarkCount = provider.bookmarks.length;
    final subheadings = [
      'India Power Sector Live',
      'Sector, Utilities & OEM Analytics',
      'Regional Grid & Utilities',
      '$bookmarkCount ${bookmarkCount == 1 ? 'Article' : 'Articles'} Saved',
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titles[provider.currentNavIndex],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: provider.currentNavIndex == 0
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          subheadings[provider.currentNavIndex],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: provider.currentNavIndex == 0
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Phase 5: Ask Gemini Grid AI Quick Access
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            tooltip: 'Ask Gemini Grid AI',
            onPressed: () => AskGeminiSheet.show(context),
          ),

          // App Features & Guide Icon
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            tooltip: 'App Features & Walkthrough',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),

          // Light / Dark Mode Toggle Icon
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF1E293B),
            ),
            tooltip: isDark ? 'Switch to Eye-Easing Light Mode' : 'Switch to Dark Mode',
            onPressed: () => provider.toggleTheme(),
          ),

          // Animated Refresh Feeds Button (Rotates smoothly on click)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: RotationTransition(
              turns: _refreshAnimController,
              child: const Icon(Icons.sync_rounded, size: 20),
            ),
            tooltip: 'Refresh News Feeds',
            onPressed: () async {
              _refreshAnimController.repeat();
              try {
                await provider.triggerFullRefresh();
              } finally {
                if (mounted) {
                  _refreshAnimController.animateTo(1.0, curve: Curves.easeOut).then((_) {
                    if (mounted) _refreshAnimController.reset();
                  });
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: provider.currentNavIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.currentNavIndex,
        onDestinationSelected: (index) {
          final current = provider.currentNavIndex;
          if (index != current) {
            // Reset all filters when moving from tab to tab
            provider.clearAllFilters();
          }
          if (index == 0) {
            // Selecting or reclicking News Feed tab resets filters and scrolls to top
            provider.clearAllFiltersAndScrollTop();
          }
          provider.setNavIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper_rounded, color: Color(0xFF2563EB)),
            label: 'News Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF2563EB)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF2563EB)),
            label: 'States',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB)),
            label: 'Bookmarks',
          ),
        ],
      ),
    );
  }
}
