import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../screens/article_detail_screen.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  String _selectedFilter = 'All Updates';

  final List<String> _filterCategories = [
    'All Updates',
    '⚡ Grid & Breaking',
    '🏛️ Policy & Govt',
    '🌱 Renewables',
  ];

  List<NewsArticle> _filterArticles(List<NewsArticle> articles) {
    if (_selectedFilter == 'All Updates') {
      return articles;
    } else if (_selectedFilter == '⚡ Grid & Breaking') {
      return articles.where((a) {
        final text = '${a.title} ${a.summary} ${a.primaryCategory} ${a.player}'.toLowerCase();
        return text.contains('grid') ||
            text.contains('transmission') ||
            text.contains('substation') ||
            text.contains('frequency') ||
            text.contains('blackout') ||
            text.contains('power cut') ||
            text.contains('outage') ||
            text.contains('fault') ||
            text.contains('high voltage') ||
            text.contains('powergrid') ||
            text.contains('posoco') ||
            text.contains('grid-india');
      }).toList();
    } else if (_selectedFilter == '🏛️ Policy & Govt') {
      return articles.where((a) {
        final text = '${a.title} ${a.summary} ${a.primaryCategory} ${a.player}'.toLowerCase();
        return text.contains('policy') ||
            text.contains('cerc') ||
            text.contains('cea') ||
            text.contains('ministry') ||
            text.contains('mop') ||
            text.contains('tariff') ||
            text.contains('order') ||
            text.contains('guideline') ||
            text.contains('circular') ||
            text.contains('rbi') ||
            text.contains('serc') ||
            text.contains('tender') ||
            text.contains('discom');
      }).toList();
    } else if (_selectedFilter == '🌱 Renewables') {
      return articles.where((a) {
        final text = '${a.title} ${a.summary} ${a.primaryCategory} ${a.player}'.toLowerCase();
        return text.contains('solar') ||
            text.contains('renewable') ||
            text.contains('green') ||
            text.contains('wind') ||
            text.contains('storage') ||
            text.contains('bess') ||
            text.contains('hydro') ||
            text.contains('ev ') ||
            text.contains('clean energy');
      }).toList();
    }
    return articles;
  }

  String _cleanSummarySnippet(String summary) {
    var cleaned = NewsArticle.cleanHtmlAndEntities(summary);
    cleaned = cleaned
        .replaceAll(RegExp(r'^[•●▪▫\-\*\s]+'), '')
        .replaceAll(RegExp(r'\b(href|target)=["\S]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length > 110) {
      cleaned = '${cleaned.substring(0, 107)}...';
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NewsProvider>();
    final notificationArticles = provider.notificationArticles;
    final filtered = _filterArticles(notificationArticles);
    final newCount = provider.newArticlesCount;

    final primaryTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E293B).withOpacity(0.55) : const Color(0xFFF8FAFC);
    final cardBorderColor = isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  // Bell Icon Box with Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        if (newCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Sector Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (newCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$newCount NEW',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ] else if (notificationArticles.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2563EB).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'ALL READ',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          newCount > 0
                              ? '$newCount new updates • Real-time grid dispatches'
                              : (notificationArticles.isNotEmpty
                                  ? 'Recent updates • Real-time grid dispatches'
                                  : 'You\'re completely up to date with the grid'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Option to Clear / Mark all read
                  if (newCount > 0 || notificationArticles.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        provider.markAllNotificationsAsRead();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 3),
                            Text(
                              'Mark Read',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    color: secondaryTextColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.7),

            // Filter Tabs Row
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _filterCategories[index];
                  final isSelected = cat == _selectedFilter;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selectedFilter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : secondaryTextColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Notification Items List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: secondaryTextColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notificationArticles.isEmpty
                                  ? 'All caught up! No new notifications'
                                  : 'No updates found for this filter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notificationArticles.isEmpty
                                  ? 'New power sector dispatches and breaking alerts will appear here.'
                                  : 'Select another category tab or check for new updates below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: secondaryTextColor),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                setState(() => _selectedFilter = 'All Updates');
                                provider.fetchNews(isRefresh: true);
                              },
                              icon: const Icon(Icons.sync_rounded, size: 16),
                              label: const Text('Check for Updates', style: TextStyle(fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final article = filtered[index];
                        final isNewItem = provider.isArticleNew(article.id);
                        final categoryColor = article.getCategoryColor(context);
                        final categoryIcon = article.getCategoryIcon();

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              provider.markArticleAsRead(article.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArticleDetailScreen(
                                    articles: filtered,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isNewItem
                                    ? (isDark
                                        ? const Color(0xFF0F291E).withOpacity(0.6)
                                        : const Color(0xFFECFDF5))
                                    : cardBgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isNewItem
                                      ? const Color(0xFF10B981).withOpacity(0.5)
                                      : cardBorderColor,
                                  width: isNewItem ? 1.3 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Icon Column
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(isDark ? 0.2 : 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      size: 19,
                                      color: categoryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Main Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Meta Badges Row (Overflow-safe)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  // Category Chip
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: categoryColor.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      article.primaryCategory.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: categoryColor,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ),

                                                  if (article.player != null && article.player!.isNotEmpty && article.player != 'All') ...[
                                                    const SizedBox(width: 5),
                                                    Flexible(
                                                      child: Text(
                                                        '• ${article.player}',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: secondaryTextColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],

                                                  if (isNewItem) ...[
                                                    const SizedBox(width: 5),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF10B981),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'NEW',
                                                        style: TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.white,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    const SizedBox(width: 5),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'READ',
                                                        style: TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: secondaryTextColor,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            // Time Ago
                                            Text(
                                              article.timeAgo,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: secondaryTextColor.withOpacity(0.85),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        // Headline
                                        Text(
                                          article.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: primaryTextColor,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        if (article.summary.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _cleanSummarySnippet(article.summary),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: secondaryTextColor,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Chevron
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: secondaryTextColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
