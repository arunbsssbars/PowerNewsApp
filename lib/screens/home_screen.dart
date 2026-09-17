import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'feed_view.dart';
import 'dashboard_view.dart';
import 'bookmarks_view.dart';
import 'profile_view.dart';
import 'onboarding_screen.dart';
import '../widgets/ask_gemini_sheet.dart';
import '../widgets/about_sheet.dart';
import '../widgets/notifications_sheet.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';

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
    if (resetFilters && provider.isFiltered) {
      provider.resetFiltersInMemory();
    }
    provider.setNavIndex(index);
  }

  void _showAboutSheet(BuildContext context) {
    AboutSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = provider.currentNavIndex;
    _visitedTabs.add(currentIndex);

    final pages = [
      const FeedView(),
      _visitedTabs.contains(1)
          ? DashboardView(onNavigateTab: (idx) => _onNavigateTab(idx))
          : const SizedBox.shrink(),
      _visitedTabs.contains(2) ? const BookmarksView() : const SizedBox.shrink(),
      _visitedTabs.contains(3) ? const ProfileView() : const SizedBox.shrink(),
    ];

    final titles = [
      'PowerNews',
      'Dashboard',
      'Saved Briefings',
      'Profile & Account',
    ];

    final int bookmarkCount = provider.bookmarks.length;
    final subheadings = [
      'Power Intelligence',
      'Sector & Utilities',
      '$bookmarkCount ${bookmarkCount == 1 ? 'Article' : 'Articles'} Saved',
      auth.isAuthenticated
          ? (auth.isAdmin ? '👑 Verified Admin' : (auth.currentUser?.displayName ?? 'Active Account'))
          : 'Identity & Preferences',
    ];

    final safeIndex = currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/icons/app_icon.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titles[safeIndex],
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
                          color: safeIndex == 0
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          subheadings[safeIndex],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: safeIndex == 0
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
          // 1. Theme Mode Quick Toggle (Comfortable 36x36 touch target)
          Tooltip(
            message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => provider.toggleTheme(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 2. Refresh Button (Comfortable 36x36 touch target)
          Tooltip(
            message: 'Refresh Feeds',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
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
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _refreshAnimController,
                    child: Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3. Updated Article Notification Bell (Comfortable 36x36 touch target)
          Tooltip(
            message: provider.newArticlesCount > 0
                ? '${provider.newArticlesCount} new power sector updates available'
                : 'Feed Notifications',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                NotificationsSheet.show(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.newArticlesCount > 0
                        ? const Color(0xFF10B981).withOpacity(0.7)
                        : (isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0)),
                    width: provider.newArticlesCount > 0 ? 1.4 : 1.0,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      provider.newArticlesCount > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: provider.newArticlesCount > 0
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                    if (provider.newArticlesCount > 0)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 4. Three Dots Executive Menu (Comfortable 36x36 button, compact 185-215dp dropdown)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
              tooltip: 'More Options',
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(minWidth: 185, maxWidth: 215),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              elevation: 8,
              onSelected: (value) {
                if (value == 'admin_hq') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                } else if (value == 'account') {
                  _onNavigateTab(3);
                } else if (value == 'ai_desk') {
                  AskGeminiSheet.show(context);
                } else if (value == 'guide') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                } else if (value == 'editorial') {
                  _showAboutSheet(context);
                }
              },
              itemBuilder: (context) => [
                if (auth.isAdmin) ...[
                  const PopupMenuItem(
                    value: 'admin_hq',
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 17, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                ],
                PopupMenuItem(
                  value: 'account',
                  height: 42,
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 17, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Text(
                        auth.isAuthenticated ? 'Account & Profile' : 'Sign In with Google',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'ai_desk',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 17, color: Color(0xFF818CF8)),
                      SizedBox(width: 10),
                      Text(
                        'Ask AI Desk',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'guide',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 17, color: Color(0xFF38BDF8)),
                      SizedBox(width: 10),
                      Text(
                        'Tour & Guide',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'editorial',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 17, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Text(
                        'Editorial Desk',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          final current = provider.currentNavIndex;
          if (index == 0) {
            // Selecting or reclicking News Feed tab:
            // If any filter is currently applied, reset all filters completely and reload feed
            if (provider.isFiltered) {
              provider.clearAllFiltersAndScrollTop(reloadFromNetwork: true);
            } else {
              provider.onScrollToTopRequested?.call();
              if (provider.articles.isEmpty || provider.isNewsCacheExpired) {
                provider.fetchNews();
              }
            }
          } else if (index != current) {
            // When leaving feed for another tab, clear transient in-memory filters
            if (provider.isFiltered) {
              provider.resetFiltersInMemory();
            }
          }
          _onNavigateTab(index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper_rounded, color: Color(0xFF2563EB)),
            label: 'News Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded, color: Color(0xFF2563EB)),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB)),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: auth.isAuthenticated && auth.currentUser?.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      auth.currentUser!.photoUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        auth.isAdmin ? Icons.shield_outlined : Icons.person_outline_rounded,
                      ),
                    ),
                  )
                : Icon(
                    auth.isAdmin ? Icons.shield_outlined : Icons.person_outline_rounded,
                  ),
            selectedIcon: auth.isAuthenticated && auth.currentUser?.photoUrl != null
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        auth.currentUser!.photoUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          auth.isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                          color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  )
                : Icon(
                    auth.isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                    color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  ),
            label: auth.isAdmin ? 'Admin' : 'Profile',
          ),
        ],
      ),
    );
  }
}
