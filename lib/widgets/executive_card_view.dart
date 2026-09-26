import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import 'formatted_summary_view.dart';
import '../screens/reader_screen.dart';

class ExecutiveCardView extends StatelessWidget {
  final NewsArticle article;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onNextCard;

  const ExecutiveCardView({
    super.key,
    required this.article,
    required this.currentIndex,
    required this.totalCount,
    this.onNextCard,
  });

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.clamp(1, 59);
      return '${mins}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}';
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'transmission':
        return AppTheme.sectorTransmission;
      case 'renewables':
      case 'solar':
      case 'wind':
        return AppTheme.sectorRenewables;
      case 'generation':
        return AppTheme.sectorGeneration;
      case 'distribution':
      case 'discom':
        return AppTheme.sectorDistribution;
      case 'policy':
        return AppTheme.sectorPolicy;
      case 'tenders':
        return AppTheme.sectorTenders;
      default:
        return AppTheme.sectorTransmission;
    }
  }

  void _shareArticle(BuildContext context) {
    HapticFeedback.selectionClick();
    final title = article.title;
    final url = article.url.trim().isNotEmpty ? article.url : 'https://powernews.app';
    final shareText = '$title\n\n⚡ PowerNews India Briefing\n$url';
    Share.share(shareText, subject: title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _getCategoryColor(article.primaryCategory);
    final provider = context.watch<NewsProvider>();
    final isBookmarked = provider.isBookmarked(article.id);

    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final metaColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final size = MediaQuery.of(context).size;
    // Balanced lead image height (allocated 30% of screen height to perfectly fill card without bottom gaps)
    final imageHeight = (size.height * 0.30).clamp(150.0, 260.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Media Area: Publisher Lead Image with professional glass capsule control bar at bottom
          _buildLeadImage(context, imageHeight, isDark, catColor, isBookmarked, provider),

          // 2. Main Executive Intelligence Content (Non-scrolling body, justified text, guaranteed fit)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimalist Breadcrumb Meta Row
                  _buildMinimalMetaRow(catColor, metaColor, isDark),
                  const SizedBox(height: 12),

                  // Executive Headline (High-contrast 18.5pt bold)
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18.5,
                      height: 1.30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Strict 60-Word Brief with full width, justified alignment, and fitted height (no scroll)
                  Expanded(
                    child: FormattedSummaryView(
                      summary: article.summary,
                      isDark: isDark,
                      title: article.title,
                      player: article.player,
                      city: article.city,
                      state: article.state,
                      fontSize: 16.5,
                      lineHeight: 1.54,
                      isScrollable: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadImage(
    BuildContext context,
    double height,
    bool isDark,
    Color catColor,
    bool isBookmarked,
    NewsProvider provider,
  ) {
    final imgUrl = article.imageUrl?.trim();
    final hasValidImage = imgUrl != null && imgUrl.startsWith('http');

    return Container(
      width: double.infinity,
      height: height,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasValidImage)
            Image.network(
              imgUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildFallbackBanner(isDark, catColor),
            )
          else
            _buildFallbackBanner(isDark, catColor),

          // Multi-Stop Cinematic Gradient Scrim at bottom of image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 85,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Top Right: Publisher Source Tag
          Positioned(
            top: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.newspaper_rounded, size: 11, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 4),
                  Text(
                    article.source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Professional Unified Glass Capsule Control Bar at Bottom of Image
          Positioned(
            left: 10,
            right: 10,
            bottom: 7,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Article Counter Badge (e.g. "3 / 48")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          size: 12.5,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          '${currentIndex + 1} / $totalCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtle vertical divider
                  Container(
                    width: 0.8,
                    height: 16,
                    color: Colors.white.withOpacity(0.18),
                  ),

                  const Spacer(),

                  // 2. Bookmark Action
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.toggleBookmark(article);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          size: 17,
                          color: isBookmarked ? const Color(0xFFF59E0B) : Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 3. Share Action
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _shareArticle(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Icon(
                          Icons.share_outlined,
                          size: 16.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // 4. "Read Story ↗" Action Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(article: article),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withOpacity(0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_outward_rounded, size: 11.5, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(bool isDark, Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withOpacity(isDark ? 0.18 : 0.12),
            isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          article.getCategoryIcon(),
          size: 40,
          color: catColor.withOpacity(0.65),
        ),
      ),
    );
  }

  Widget _buildMinimalMetaRow(Color catColor, Color metaColor, bool isDark) {
    final elements = <Widget>[];

    // 1. Category Tag
    elements.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
        decoration: BoxDecoration(
          color: catColor.withOpacity(isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: catColor.withOpacity(0.35), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(article.getCategoryIcon(), size: 11, color: catColor),
            const SizedBox(width: 4),
            Text(
              article.primaryCategory.toUpperCase(),
              style: TextStyle(
                color: catColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );

    // 2. Key Player (if known)
    if (article.player != null &&
        article.player!.isNotEmpty &&
        article.player != 'Power Sector Stakeholder') {
      elements.add(_buildDot(metaColor));
      elements.add(
        Flexible(
          child: Text(
            article.player!,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // 3. State or DISCOM (if known)
    final geo = article.discom ?? (article.state != 'National / Pan-India' ? article.state : null);
    if (geo != null && geo.isNotEmpty) {
      elements.add(_buildDot(metaColor));
      elements.add(
        Flexible(
          child: Text(
            geo,
            style: TextStyle(
              color: metaColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // 4. Relative Time
    elements.add(_buildDot(metaColor));
    elements.add(
      Text(
        _formatRelativeTime(article.publishedAt),
        style: TextStyle(
          color: metaColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Row(
      children: elements,
    );
  }

  Widget _buildDot(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '•',
        style: TextStyle(color: color.withOpacity(0.55), fontSize: 11),
      ),
    );
  }
}
