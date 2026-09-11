import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';

class SourceWebViewScreen extends StatefulWidget {
  final NewsArticle article;

  const SourceWebViewScreen({super.key, required this.article});

  @override
  State<SourceWebViewScreen> createState() => _SourceWebViewScreenState();
}

class _SourceWebViewScreenState extends State<SourceWebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('[SourceWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.article.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open browser: $e')),
        );
      }
    }
  }

  void _shareArticle() {
    try {
      Share.share(
        '⚡ *${widget.article.title}*\n\n📅 Published: ${widget.article.formattedDateTime}\n📰 Source: ${widget.article.source}\n\n📋 Read full 50-word executive summary, SCADA updates & grid intelligence on the PowerNews App:\n📲 Download PowerNews App: https://github.com/powernews/app/releases',
        subject: widget.article.title,
      );
    } catch (_) {
      Clipboard.setData(
        ClipboardData(
          text: widget.article.title,
        ),
      );
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
    final article = widget.article;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              article.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          // Refresh Webpage
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload Page',
            onPressed: () => _controller.reload(),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Link',
            onPressed: _shareArticle,
          ),
          // Bookmark
          Consumer<NewsProvider>(
            builder: (context, prov, _) {
              final isBookmarked = prov.isBookmarked(article.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFFD97706) : null,
                  size: 22,
                ),
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark',
                onPressed: () => prov.toggleBookmark(article),
              );
            },
          ),
          // Open in Chrome / External
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 19),
            tooltip: 'Open in Chrome / Browser',
            onPressed: _openInExternalBrowser,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Loading Progress Bar
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
              minHeight: 2.5,
            ),
          // Mobile In-App Web View
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
