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
    final borderColor = isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000);
    final metaColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final size = MediaQuery.of(context).size;
    final imageHeight = (size.height * 0.21).clamp(140.0, 200.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Media Area: Publisher Lead Image with smooth fallback
            _buildLeadImage(imageHeight, isDark, catColor),

            // 2. Main Executive Intelligence Content (Non-scrolling body)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minimalist Breadcrumb Meta Row
                    _buildMinimalMetaRow(catColor, metaColor, isDark),
                    const SizedBox(height: 10),

                    // Executive Headline (15-16pt bold, max 2 lines, tight letter spacing)
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Strict 60-Word Brief with highlighted numbers/metrics
                    Expanded(
                      child: FormattedSummaryView(
                        summary: article.summary,
                        isDark: isDark,
                        title: article.title,
                        player: article.player,
                        city: article.city,
                        state: article.state,
                        fontSize: 15,
                        lineHeight: 1.48,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating / Docked Executive Action Bar
            _buildDockedActionBar(context, isDark, isBookmarked, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadImage(double height, bool isDark, Color catColor) {
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
              cacheWidth: 1080,
              filterQuality: FilterQuality.medium,
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

          // Subtle Gradient Scrim at bottom of image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    (isDark ? const Color(0xFF111827) : Colors.white).withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Source Tag on top right
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.newspaper_rounded, size: 11, color: Colors.white.withOpacity(0.85)),
                  const SizedBox(width: 4),
                  Text(
                    article.source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
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
          size: 44,
          color: catColor.withOpacity(0.65),
        ),
      ),
    );
  }

  Widget _buildMinimalMetaRow(Color catColor, Color metaColor, bool isDark) {
    final elements = <Widget>[];

    // 1. Category
    elements.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(article.getCategoryIcon(), size: 12, color: catColor),
          const SizedBox(width: 4),
          Text(
            article.primaryCategory.toUpperCase(),
            style: TextStyle(
              color: catColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
              fontSize: 10.5,
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
              fontSize: 10.5,
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
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: elements,
    );
  }

  Widget _buildDot(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '•',
        style: TextStyle(color: color.withOpacity(0.6), fontSize: 11),
      ),
    );
  }

  Widget _buildDockedActionBar(
    BuildContext context,
    bool isDark,
    bool isBookmarked,
    NewsProvider provider,
  ) {
    final borderColor = isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Counter Progress pill: "3 / 48"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${currentIndex + 1} / $totalCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),

          const Spacer(),

          // Bookmark Pill Button
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isBookmarked ? AppTheme.lightAccent : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              size: 21,
            ),
            tooltip: isBookmarked ? 'Bookmarked' : 'Save Briefing',
            onPressed: () {
              HapticFeedback.selectionClick();
              provider.toggleBookmark(article);
            },
          ),

          // Share Pill Button
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              size: 20,
            ),
            tooltip: 'Share Briefing',
            onPressed: () => _shareArticle(context),
          ),

          const SizedBox(width: 4),

          // Prominent "Read Full Story ↗" Action Pill
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(article: article),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0284C7), const Color(0xFF2563EB)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Read Full Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
