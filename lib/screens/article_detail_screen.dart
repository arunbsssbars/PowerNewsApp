import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../widgets/formatted_summary_view.dart';
import 'reader_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
  late PageController _pageController;
  late int _currentIndex;
  double _summaryFontSize = 14.5;
  String _summaryFontFamily = 'Default';
  double _summaryLineHeight = 1.55;
  final Set<String> _loadingAiArticleIds = {};
  final Map<String, String> _aiSummaries = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadTypographyPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.articles.isNotEmpty) {
        _fetchAiSummaryIfNeeded(widget.articles[_currentIndex]);
        if (_currentIndex + 1 < widget.articles.length) {
          _fetchAiSummaryIfNeeded(widget.articles[_currentIndex + 1]);
        }
        if (_currentIndex + 2 < widget.articles.length) {
          _fetchAiSummaryIfNeeded(widget.articles[_currentIndex + 2]);
        }
      }
    });
  }

  Future<void> _loadTypographyPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _summaryFontSize = prefs.getDouble('summary_font_size') ?? 14.5;
        _summaryFontFamily = prefs.getString('summary_font_family') ?? 'Default';
        _summaryLineHeight = prefs.getDouble('summary_line_height') ?? 1.55;
      });
    } catch (_) {}
  }

  Future<void> _saveTypographyPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('summary_font_size', _summaryFontSize);
      await prefs.setString('summary_font_family', _summaryFontFamily);
      await prefs.setDouble('summary_line_height', _summaryLineHeight);
    } catch (_) {}
  }

  void _showTypographyBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reading Typography & Style',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 1. Font Size Selector
                  Text(
                    'FONT SIZE: ${_summaryFontSize.toStringAsFixed(1)} pt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSizeOption(13.0, 'Small', setModalState),
                      const SizedBox(width: 8),
                      _buildSizeOption(14.5, 'Normal', setModalState),
                      const SizedBox(width: 8),
                      _buildSizeOption(16.5, 'Large', setModalState),
                      const SizedBox(width: 8),
                      _buildSizeOption(18.5, 'X-Large', setModalState),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Font Family Selector
                  Text(
                    'TYPEFACE STYLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFamilyOption('Default', 'Modern Sans', setModalState),
                      const SizedBox(width: 8),
                      _buildFamilyOption('Serif', 'Editorial Serif', setModalState),
                      const SizedBox(width: 8),
                      _buildFamilyOption('Mono', 'Tech Mono', setModalState),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Line Spacing Selector
                  Text(
                    'LINE SPACING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSpacingOption(1.35, 'Compact', setModalState),
                      const SizedBox(width: 8),
                      _buildSpacingOption(1.55, 'Standard', setModalState),
                      const SizedBox(width: 8),
                      _buildSpacingOption(1.85, 'Relaxed', setModalState),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSizeOption(double size, String label, StateSetter setModalState) {
    final isSelected = (_summaryFontSize - size).abs() < 0.2;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _summaryFontSize = size);
          setModalState(() {});
          _saveTypographyPrefs();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyOption(String familyKey, String label, StateSetter setModalState) {
    final isSelected = _summaryFontFamily == familyKey;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _summaryFontFamily = familyKey);
          setModalState(() {});
          _saveTypographyPrefs();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: familyKey == 'Serif' ? 'serif' : (familyKey == 'Mono' ? 'monospace' : null),
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpacingOption(double spacing, String label, StateSetter setModalState) {
    final isSelected = (_summaryLineHeight - spacing).abs() < 0.05;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _summaryLineHeight = spacing);
          setModalState(() {});
          _saveTypographyPrefs();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  void _fetchAiSummaryIfNeeded(NewsArticle article) async {
    final cached = _aiSummaries[article.id];
    if (cached != null && cached.contains('•') && cached.length > 30) return;
    if (article.summary.contains('•') && article.summary.length > 50) {
      _aiSummaries[article.id] = article.summary;
      return;
    }

    if (mounted) {
      setState(() => _loadingAiArticleIds.add(article.id));
    }
    try {
      final aiService = context.read<NewsProvider>().apiService;
      final aiSummary = await aiService.fetchArticleAiSummary(
        id: article.id,
        title: article.title,
        snippet: article.summary,
        category: article.primaryCategory,
        player: article.player,
        state: article.state,
        discom: article.discom,
        url: article.url,
      );

      if (aiSummary != null && aiSummary.trim().isNotEmpty && mounted) {
        final cleanAi = aiSummary.trim();
        setState(() {
          _aiSummaries[article.id] = cleanAi;
          final idx = widget.articles.indexWhere((a) => a.id == article.id);
          if (idx != -1) {
            final updated = NewsArticle(
              id: article.id,
              title: article.title,
              summary: cleanAi,
              url: article.url,
              source: article.source,
              publishedAt: article.publishedAt,
              categories: article.categories,
              player: article.player,
              city: article.city,
              state: article.state,
              discom: article.discom,
              fullText: article.fullText,
            );
            widget.articles[idx] = updated;
          }
        });

        // Persist summary to NewsProvider and SQLite so it's permanently available offline
        try {
          if (mounted) {
            context.read<NewsProvider>().updateArticleSummary(article.id, cleanAi);
          }
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingAiArticleIds.remove(article.id));
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openMobileSourceWebView(BuildContext context, NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(article: article),
      ),
    );
  }

  void _shareArticle(BuildContext context, NewsArticle article) {
    try {
      final shareText = '''⚡ *${article.title}*

📅 Published: ${article.formattedDateTime}
📰 Source: ${article.source}

📋 *Read full 50-word executive summary, SCADA updates & grid intelligence on the PowerNews App:*
📲 Download PowerNews App: https://github.com/powernews/app/releases''';
      Share.share(shareText, subject: article.title);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: '${article.title}\n\n${article.summary}'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('📋 Headline copied to clipboard!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('PowerNews Story')),
        body: const Center(child: Text('No article data found')),
      );
    }

    final currentArticle = widget.articles[_currentIndex];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<NewsProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Power Sector Intelligence',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_currentIndex + 1} of ${widget.articles.length} updates • Swipe left/right',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded, size: 21),
            tooltip: 'Customize Font & Style',
            onPressed: () => _showTypographyBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Briefing',
            onPressed: () => _shareArticle(context, currentArticle),
          ),
          Consumer<NewsProvider>(
            builder: (context, prov, _) {
              final isBookmarked = prov.isBookmarked(currentArticle.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFFD97706) : null,
                  size: 22,
                ),
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Article',
                onPressed: () {
                  prov.toggleBookmark(currentArticle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 900),
                      content: Text(isBookmarked ? 'Removed bookmark' : 'Article bookmarked offline'),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, prov, child) {
          final isMainFeed = widget.articles.isNotEmpty && prov.articles.isNotEmpty && widget.articles.first.id == prov.articles.first.id;
          final displayArticles = isMainFeed ? prov.articles : widget.articles;

          return PageView.builder(
            controller: _pageController,
            itemCount: displayArticles.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _fetchAiSummaryIfNeeded(displayArticles[index]);
              if (index + 1 < displayArticles.length) {
                _fetchAiSummaryIfNeeded(displayArticles[index + 1]);
              }
              if (index + 2 < displayArticles.length) {
                _fetchAiSummaryIfNeeded(displayArticles[index + 2]);
              }
              if (isMainFeed && index >= displayArticles.length - 3) {
                prov.fetchMoreNews();
              }
            },
            itemBuilder: (context, index) {
              final article = displayArticles[index];
              final catColor = article.getCategoryColor(context);

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Meta Badge Strip (Category + Player + Region)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                // Category Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(isDark ? 0.22 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: catColor.withOpacity(isDark ? 0.45 : 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(article.getCategoryIcon(), size: 11.5, color: catColor),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        article.primaryCategory.toUpperCase(),
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Utility / OEM Badge
                                if (article.player != null) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706).withOpacity(isDark ? 0.22 : 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.business_rounded, size: 11.5, color: Color(0xFFD97706)),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          article.player!,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // City Badge
                                if (article.city != null) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(isDark ? 0.22 : 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_city_rounded, size: 11.5, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          article.city!,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(width: 5),

                                // State / Pan-India Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151D2E) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2E3D59) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    article.discom != null ? '${article.state} (${article.discom})' : article.state,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Proper Polished Spacing Before Main Heading
                          const SizedBox(height: 14),

                          // Main Headline of Summary Screen
                          Text(
                            article.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.34,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),

                          // Proper Polished Spacing After Main Heading
                          const SizedBox(height: 14),

                          // Hero Summary & Highlights Box Covering Full Width
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF111827) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header: Analytics Icon + "Summary & Highlights" + Date Badge
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF38BDF8).withOpacity(0.15) : const Color(0xFF2563EB).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.insights_rounded,
                                        size: 13,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Summary & Highlights',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.1,
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // High-Contrast Professional Real Article Date & Time Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F2344) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF0284C7).withOpacity(0.7) : const Color(0xFF93C5FD),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 10,
                                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            article.formattedDateTime,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1D4ED8),
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // When AI summary is loading, show animated skeleton placeholder
                                if (_loadingAiArticleIds.contains(article.id) && !(_aiSummaries[article.id] ?? article.summary).contains('•'))
                                  _SummarySkeletonLoader(isDark: isDark)
                                else
                                  // Justified Full-Width Summary Content
                                  FormattedSummaryView(
                                    summary: _aiSummaries[article.id] ?? article.summary,
                                    isDark: isDark,
                                    player: article.player,
                                    city: article.city,
                                    state: article.state,
                                    title: article.title,
                                    fontSize: _summaryFontSize,
                                    fontFamily: _summaryFontFamily == 'Serif'
                                        ? 'serif'
                                        : (_summaryFontFamily == 'Mono' ? 'monospace' : null),
                                    lineHeight: _summaryLineHeight,
                                  ),

                                const SizedBox(height: 12),

                                // Highlighted Source Badge at bottom of summary
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151D2E) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF38BDF8).withOpacity(0.35) : const Color(0xFF2563EB).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.newspaper_rounded,
                                            size: 13,
                                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Source: ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              article.source,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (article.sources.length > 1) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Also reported by:',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            for (final s in article.sources.where((src) => src != article.source))
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Text(
                                                  s,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Sleek Bottom Action Row: Opens in Mobile In-App WebView Mode
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            // Swipe Navigation Micro-Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe_rounded,
                                    size: 12,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${index + 1}/${widget.articles.length}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // "Read Full Story" -> Opens Source in Mobile Mode (WebView)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _openMobileSourceWebView(context, article),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5).withOpacity(0.38),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_stories_rounded,
                                        size: 14.5,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Read Full Story',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.currentNavIndex,
        onDestinationSelected: (index) {
          provider.setNavIndex(index);
          if (index == 0) {
            provider.clearAllFiltersAndScrollTop();
          }
          Navigator.pop(context);
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

class _SummarySkeletonLoader extends StatefulWidget {
  final bool isDark;

  const _SummarySkeletonLoader({required this.isDark});

  @override
  State<_SummarySkeletonLoader> createState() => _SummarySkeletonLoaderState();
}

class _SummarySkeletonLoaderState extends State<_SummarySkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletSkeleton(baseColor, [1.0, 0.72]),
              const SizedBox(height: 12),
              _buildBulletSkeleton(baseColor, [1.0, 0.88]),
              const SizedBox(height: 12),
              _buildBulletSkeleton(baseColor, [0.95, 0.60]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulletSkeleton(Color color, List<double> widths) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5, right: 10),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widths.map((w) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                height: 12,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
