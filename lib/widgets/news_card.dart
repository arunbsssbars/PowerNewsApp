import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../screens/article_detail_screen.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final List<NewsArticle>? allArticles;
  final int itemIndex;

  const NewsCard({
    super.key,
    required this.article,
    this.allArticles,
    this.itemIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = article.getCategoryColor(context);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151D2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF222F46) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final list = allArticles ?? [article];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(
                    articles: list,
                    initialIndex: itemIndex,
                  ),
                ),
              );
            },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row: Category & Entity Badges on Left + Fixed Bookmark on Far Right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Expanded Badges Row on the Left
                    Expanded(
                      child: Row(
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: catColor.withOpacity(isDark ? 0.4 : 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(article.getCategoryIcon(), size: 12, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  article.primaryCategory.toUpperCase(),
                                  style: TextStyle(
                                    color: catColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Grid Persona Relevance Tag (if active persona and high relevance)
                          Consumer<NewsProvider>(
                            builder: (context, prov, _) {
                              final persona = prov.selectedPersona;
                              if (persona.id == 'all') return const SizedBox.shrink();
                              final score = persona.calculateRelevance(article.title, article.summary, article.primaryCategory, article.player);
                              if (score < 40.0) return const SizedBox.shrink();

                              return Flexible(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: persona.badgeColor.withOpacity(isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: persona.badgeColor.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(persona.icon, size: 10.5, color: persona.badgeColor),
                                      const SizedBox(width: 3.5),
                                      Flexible(
                                        child: Text(
                                          '${persona.shortLabel} Priority',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: persona.badgeColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bookmark Action Button (Fixed on the Far Right)
                    Selector<NewsProvider, bool>(
                      selector: (_, prov) => prov.isBookmarked(article.id),
                      builder: (context, isBookmarked, _) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.read<NewsProvider>().toggleBookmark(article);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              size: 21,
                              color: isBookmarked
                                  ? const Color(0xFFD97706)
                                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // News Headline
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.38,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),

                // Brief Summary
                if (article.summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    var cleanSummary = NewsArticle.cleanHtmlAndEntities(article.summary)
                        .replaceAll(RegExp(r'^[•\*\-\s]+'), '')
                        .replaceAll(RegExp(r'\n[•\*\-\s]+'), '  ')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();
                    final lower = cleanSummary.toLowerCase();
                    if (lower.startsWith('target=') || lower.startsWith('href=') || cleanSummary.length < 10) {
                      cleanSummary = article.title;
                    }
                    return Text(
                      cleanSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),

                // Footer Metadata Row: Source Attribution + Relative Time
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF222F46) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 10.5,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              article.source,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (article.coverageCount > 1 || article.sources.length > 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF0284C7).withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '+${(article.coverageCount > 1 ? article.coverageCount : article.sources.length) - 1} sources',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          article.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
