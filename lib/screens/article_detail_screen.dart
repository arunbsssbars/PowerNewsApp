import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/executive_card_view.dart';

class ArticleDetailScreen extends StatefulWidget {
  final List<NewsArticle> articles;
  final int initialIndex;

  const ArticleDetailScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.articles.isEmpty ? 0 : widget.articles.length - 1);
    _currentPage = _currentIndex.toDouble();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(_onPageScroll);

    // Pre-mark current article as seen/read in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.articles.isNotEmpty && mounted) {
        final provider = context.read<NewsProvider>();
        provider.markArticleAsSeen(widget.articles[_currentIndex].id);
        provider.markArticleAsRead(widget.articles[_currentIndex].id);
      }
    });
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = _pageController.page ?? _currentIndex.toDouble();
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NewsProvider>();

    if (widget.articles.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Executive Briefing'),
        ),
        body: const Center(
          child: Text('No briefings available.'),
        ),
      );
    }

    final currentArticle = widget.articles[_currentIndex];
    final isBookmarked = provider.isBookmarked(currentArticle.id);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Executive Briefing',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.articles.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked
                  ? const Color(0xFF2563EB)
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              size: 20,
            ),
            tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Briefing',
            onPressed: () {
              HapticFeedback.selectionClick();
              provider.toggleBookmark(currentArticle);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              size: 19,
            ),
            tooltip: 'Share Briefing',
            onPressed: () {
              HapticFeedback.selectionClick();
              Share.share(
                '⚡ ${currentArticle.title}\n\n${currentArticle.summary}\n\nVia PowerNews: ${currentArticle.url}',
                subject: currentArticle.title,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: widget.articles.length,
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
          provider.markArticleAsSeen(widget.articles[index].id);
          provider.markArticleAsRead(widget.articles[index].id);
        },
        itemBuilder: (context, index) {
          final article = widget.articles[index];
          final double pageOffset = _currentPage - index;

          // Physics-based interpolation: Scale (0.92 to 1.0), Opacity (0.70 to 1.0)
          final double scale = (1.0 - (pageOffset.abs() * 0.08)).clamp(0.92, 1.0);
          final double opacity = (1.0 - (pageOffset.abs() * 0.30)).clamp(0.70, 1.0);
          final double translationY = pageOffset * 10.0;

          return Transform.translate(
            offset: Offset(0, translationY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: ExecutiveCardView(
                  article: article,
                  currentIndex: index,
                  totalCount: widget.articles.length,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
