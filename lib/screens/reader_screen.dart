import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../services/api_service.dart';
import '../services/audio_digest_service.dart';

enum ReaderThemeMode { system, sepia, dark, light }

class ReaderScreen extends StatefulWidget {
  final NewsArticle article;

  const ReaderScreen({super.key, required this.article});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ApiService _apiService = ApiService();
  final AudioDigestService _audioService = AudioDigestService();

  bool _isWebViewMode = false;
  bool _isLoadingContent = true;
  String? _fullText;

  // Reader Preferences
  double _fontSize = 16.5;
  final double _lineHeight = 1.65;
  String _fontFamily = 'System'; // 'System', 'Serif', 'Mono'
  ReaderThemeMode _themeMode = ReaderThemeMode.system;

  // WebView controller for raw mode
  late final WebViewController _webViewController;
  int _webViewProgress = 0;
  bool _isWebViewLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadArticleContent();
    _audioService.addListener(_onAudioStateChange);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChange);
    _audioService.stopAudio();
    super.dispose();
  }

  void _onAudioStateChange() {
    if (mounted) setState(() {});
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _webViewProgress = progress;
                _isWebViewLoading = progress < 100;
              });
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebViewLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  Future<void> _loadArticleContent() async {
    setState(() => _isLoadingContent = true);
    try {
      final content = await _apiService.fetchArticleFullContent(widget.article.url, widget.article.id);
      if (mounted) {
        setState(() {
          if (content != null && content['fullText'] != null && content['fullText']!.trim().length > 60) {
            _fullText = content['fullText'];
          }
          _isLoadingContent = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingContent = false);
    }
  }

  String _calculateReadingTime(String text) {
    final words = text.split(RegExp(r'\s+')).length;
    final minutes = (words / 190).ceil();
    return '$minutes min read';
  }

  void _toggleAnnouncer() {
    if (_audioService.isPlaying) {
      _audioService.pauseAudio();
    } else {
      final textToRead = _fullText != null && _fullText!.length > 100
          ? '${widget.article.title}. Reported by ${widget.article.source}. $_fullText'
          : '${widget.article.title}. Reported by ${widget.article.source}. ${widget.article.summary}';
      _audioService.playAudioScript(textToRead);
    }
  }

  void _cycleAnnouncerSpeed() {
    final current = _audioService.speechRate;
    double next = 1.0;
    if (current <= 1.05) {
      next = 1.25;
    } else if (current <= 1.3) {
      next = 1.5;
    } else if (current <= 1.55) {
      next = 1.75;
    } else {
      next = 1.0;
    }
    _audioService.setRate(next);
  }

  String _getSpeedLabel() {
    final rate = _audioService.speechRate;
    if (rate <= 1.1) return '1.0x';
    if (rate <= 1.35) return '1.25x';
    if (rate <= 1.6) return '1.5x';
    return '1.75x';
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.article.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open external browser: $e')),
        );
      }
    }
  }

  void _shareArticle() {
    try {
      Share.share(
        '⚡ *${widget.article.title}*\n\n📅 Published: ${widget.article.formattedDateTime}\n📰 Source: ${widget.article.source}\n\nRead full story & grid intelligence on PowerNews App:\n${widget.article.url}',
        subject: widget.article.title,
      );
    } catch (_) {
      Clipboard.setData(ClipboardData(text: widget.article.url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📋 Link copied to clipboard!')),
      );
    }
  }

  void _showAppearanceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reader Appearance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),

                  // Font Size
                  Row(
                    children: [
                      const Text('Text Size', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.text_decrease_rounded),
                        onPressed: _fontSize > 13
                            ? () {
                                setState(() => _fontSize -= 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                      Text(
                        '${_fontSize.toInt()} pt',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase_rounded),
                        onPressed: _fontSize < 24
                            ? () {
                                setState(() => _fontSize += 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Theme Palette
                  const Text('Color Palette', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeChip('Default', ReaderThemeMode.system, isDark, setSheetState),
                      const SizedBox(width: 8),
                      _buildThemeChip('Sepia', ReaderThemeMode.sepia, isDark, setSheetState),
                      const SizedBox(width: 8),
                      _buildThemeChip('Night', ReaderThemeMode.dark, isDark, setSheetState),
                      const SizedBox(width: 8),
                      _buildThemeChip('Light', ReaderThemeMode.light, isDark, setSheetState),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Font Family
                  const Text('Typography', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFontChip('Modern', 'System', setSheetState),
                      const SizedBox(width: 8),
                      _buildFontChip('Editorial', 'Serif', setSheetState),
                      const SizedBox(width: 8),
                      _buildFontChip('Tech', 'Mono', setSheetState),
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

  Widget _buildThemeChip(String label, ReaderThemeMode mode, bool isDark, StateSetter setSheetState) {
    final isSelected = _themeMode == mode;
    Color chipBg;
    Color chipText;

    switch (mode) {
      case ReaderThemeMode.sepia:
        chipBg = const Color(0xFFFBF0D9);
        chipText = const Color(0xFF5F4B32);
        break;
      case ReaderThemeMode.dark:
        chipBg = const Color(0xFF0F172A);
        chipText = const Color(0xFFF8FAFC);
        break;
      case ReaderThemeMode.light:
        chipBg = Colors.white;
        chipText = const Color(0xFF0F172A);
        break;
      case ReaderThemeMode.system:
        chipBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        chipText = isDark ? Colors.white : const Color(0xFF0F172A);
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _themeMode = mode);
          setSheetState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: chipText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontChip(String label, String fontKey, StateSetter setSheetState) {
    final isSelected = _fontFamily == fontKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _fontFamily = fontKey);
          setSheetState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : null,
                fontFamily: fontKey == 'Serif' ? 'serif' : (fontKey == 'Mono' ? 'monospace' : null),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveBackgroundColor(bool isSystemDark) {
    switch (_themeMode) {
      case ReaderThemeMode.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderThemeMode.dark:
        return const Color(0xFF0D1117);
      case ReaderThemeMode.light:
        return const Color(0xFFFAFAFA);
      case ReaderThemeMode.system:
        return isSystemDark ? const Color(0xFF0D1117) : Colors.white;
    }
  }

  Color _resolveTextColor(bool isSystemDark) {
    switch (_themeMode) {
      case ReaderThemeMode.sepia:
        return const Color(0xFF4A3B2C);
      case ReaderThemeMode.dark:
        return const Color(0xFFE6EDF3);
      case ReaderThemeMode.light:
        return const Color(0xFF1E293B);
      case ReaderThemeMode.system:
        return isSystemDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F172A);
    }
  }

  String? _resolveFontFamily() {
    if (_fontFamily == 'Serif') return 'serif';
    if (_fontFamily == 'Mono') return 'monospace';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final theme = Theme.of(context);
    final isSystemDark = theme.brightness == Brightness.dark;

    final bgColor = _resolveBackgroundColor(isSystemDark);
    final textColor = _resolveTextColor(isSystemDark);
    final fontFamily = _resolveFontFamily();

    return Scaffold(
      backgroundColor: _isWebViewMode ? (isSystemDark ? const Color(0xFF0F172A) : Colors.white) : bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: _isWebViewMode ? null : bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: (isSystemDark ? Colors.white : Colors.black).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab(
                  icon: Icons.chrome_reader_mode_rounded,
                  label: 'Reader',
                  isActive: !_isWebViewMode,
                  onTap: () => setState(() => _isWebViewMode = false),
                ),
                _buildModeTab(
                  icon: Icons.language_rounded,
                  label: 'Web',
                  isActive: _isWebViewMode,
                  onTap: () => setState(() => _isWebViewMode = true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Appearance Settings (in Reader mode)
          if (!_isWebViewMode)
            IconButton(
              icon: const Icon(Icons.format_size_rounded, size: 20),
              tooltip: 'Appearance',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: () => _showAppearanceSheet(context),
            ),

          // Bookmark Button
          Consumer<NewsProvider>(
            builder: (context, prov, _) {
              final isBookmarked = prov.isBookmarked(article.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFFD97706) : null,
                  size: 20,
                ),
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () => prov.toggleBookmark(article),
              );
            },
          ),

          // Share Button
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 19),
            tooltip: 'Share',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: _shareArticle,
          ),

          // More Options Menu (Open in Browser, Copy Link, Reload)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'More Options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onSelected: (val) {
              if (val == 'browser') {
                _openInExternalBrowser();
              } else if (val == 'copy') {
                Clipboard.setData(ClipboardData(text: article.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(seconds: 2),
                    content: Text('📋 Link copied to clipboard!'),
                  ),
                );
              } else if (val == 'refresh_web') {
                _webViewController.reload();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Open in Browser', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Copy Article Link', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (_isWebViewMode)
                const PopupMenuItem(
                  value: 'refresh_web',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Reload Page', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isWebViewMode
          ? _buildWebViewContent(isSystemDark)
          : _buildReaderContent(article, bgColor, textColor, fontFamily, isSystemDark),
      bottomNavigationBar: !_isWebViewMode ? _buildAnnouncerBar(isSystemDark) : null,
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewContent(bool isDark) {
    return Column(
      children: [
        if (_isWebViewLoading)
          LinearProgressIndicator(
            value: _webViewProgress > 0 ? _webViewProgress / 100.0 : null,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            color: const Color(0xFF2563EB),
            minHeight: 2.5,
          ),
        Expanded(
          child: WebViewWidget(controller: _webViewController),
        ),
      ],
    );
  }

  Widget _buildReaderContent(
    NewsArticle article,
    Color bgColor,
    Color textColor,
    String? fontFamily,
    bool isDark,
  ) {
    if (_isLoadingContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 18),
              Text(
                'Extracting clean story from publisher...',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    final hasFullStory = _fullText != null && _fullText!.trim().length > 60;
    final textContent = hasFullStory ? _fullText! : article.summary;
    final paragraphs = textContent.split(RegExp(r'\n{2,}|\n(?=•|[A-Z])')).map((p) => p.trim()).filterEmpty();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta Header (Category + State + Read Time)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.primaryCategory.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (article.player != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.player!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 12, color: textColor.withOpacity(0.55)),
              const SizedBox(width: 4),
              Text(
                _calculateReadingTime(textContent),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            article.title,
            style: TextStyle(
              fontSize: _fontSize + 5,
              fontWeight: FontWeight.w900,
              height: 1.3,
              color: textColor,
              fontFamily: fontFamily,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Source & Published Date Row
          Row(
            children: [
              Icon(Icons.newspaper_rounded, size: 13, color: textColor.withOpacity(0.6)),
              const SizedBox(width: 5),
              Text(
                article.source,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Text('•', style: TextStyle(color: textColor.withOpacity(0.4))),
              const SizedBox(width: 10),
              Text(
                article.formattedDateTime,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: textColor.withOpacity(0.12), height: 1),
          const SizedBox(height: 18),

          // Fallback notice if full text was behind Cloudflare/Paywall
          if (!hasFullStory)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Publisher paywall protected. Displaying verified intelligence summary. Toggle "Web" above for full site.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ),
                ],
              ),
            ),

          // Clean Article Paragraphs
          for (final para in paragraphs) ...[
            Text(
              para,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeight,
                color: textColor.withOpacity(0.92),
                fontFamily: fontFamily,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // End of article divider
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 1, color: textColor.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('⚡ PowerNews Intelligence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.5))),
                ),
                Container(width: 40, height: 1, color: textColor.withOpacity(0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncerBar(bool isDark) {
    final isPlaying = _audioService.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Audio Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),

            // Announcer Label
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlaying ? 'Playing Article Audio...' : 'Listen to Story',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'High-quality Indian English voice',
                    style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Speed Multiplier Chip
            InkWell(
              onTap: _cycleAnnouncerSpeed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                ),
                child: Text(
                  _getSpeedLabel(),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Play / Pause Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 17),
              label: Text(
                isPlaying ? 'Pause' : 'Listen',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _toggleAnnouncer,
            ),
          ],
        ),
      ),
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<String> filterEmpty() {
    return where((element) => element is String && (element as String).trim().isNotEmpty).cast<String>();
  }
}
