import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/morning_digest.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../services/audio_digest_service.dart';
import 'article_detail_screen.dart';

class MorningDigestSheet extends StatefulWidget {
  final MorningDigest digest;

  const MorningDigestSheet({super.key, required this.digest});

  static void show(BuildContext context, MorningDigest digest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MorningDigestSheet(digest: digest),
    );
  }

  @override
  State<MorningDigestSheet> createState() => _MorningDigestSheetState();
}

class _MorningDigestSheetState extends State<MorningDigestSheet> {
  final AudioDigestService _audioService = AudioDigestService();

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onAudioUpdate);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioUpdate);
    super.dispose();
  }

  void _onAudioUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    if (_audioService.isPlaying) {
      _audioService.pauseAudio();
    } else {
      _audioService.playAudioScript(widget.digest.audioScript);
    }
  }

  void _toggleSpeed() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.88),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header & Close Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.digest.title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.digest.items.length} Executive Insights • ${widget.digest.formattedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: () {
                    final title = widget.digest.title;
                    final date = widget.digest.formattedDate;
                    final items = widget.digest.items
                        .map((item) => "⚡ ${item.pillar.toUpperCase()}\n${item.headline}\n- ${item.bullet}")
                        .join('\n\n');
                    final shareText = "📰 *$title ($date)*\n\n$items\n\n_Generated by PowerNews AI_";
                    Share.share(shareText);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: () {
                    _audioService.stopAudio();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Audio Player Control Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
              ),
            ),
            child: Row(
              children: [
                // Play / Pause Circle
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _audioService.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Audio Info & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _audioService.isPlaying
                            ? 'Playing Audio Briefing...'
                            : (_audioService.isPaused ? 'Audio Paused' : 'Voice Executive Digest'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _audioService.isPlaying
                            ? 'Powered by On-Device Neural TTS'
                            : 'Listen to 2-minute grid summary',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Speed Selector Pill
                GestureDetector(
                  onTap: _toggleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSpeedLabel(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scrollable Story Bullet Cards
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: widget.digest.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = widget.digest.items[index];
                return _buildDigestCard(context, item, index + 1, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestCard(BuildContext context, MorningDigestItem item, int index, bool isDark) {
    Color pillarColor;
    switch (item.pillar.toLowerCase()) {
      case 'transmission & grid':
        pillarColor = const Color(0xFF0284C7);
        break;
      case 'renewables & generation':
        pillarColor = const Color(0xFF059669);
        break;
      case 'discoms & smart metering':
        pillarColor = const Color(0xFFD97706);
        break;
      case 'oems & equipment':
        pillarColor = const Color(0xFF7C3AED);
        break;
      default:
        pillarColor = const Color(0xFF2563EB);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final provider = Provider.of<NewsProvider>(context, listen: false);
        final article = provider.articles.firstWhere(
          (a) => a.id == item.articleId,
          orElse: () => NewsArticle(
            id: item.articleId,
            title: item.headline,
            summary: item.fullSummary ?? item.bullet,
            url: item.url ?? '',
            source: item.source,
            publishedAt: DateTime.now(),
            categories: [item.pillar.split(' ').first.toLowerCase()],
            state: item.state ?? 'National / Pan-India',
            player: item.player,
            sources: item.sources,
            coverageCount: item.coverageCount,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              articles: [article],
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pillar badge & Source row
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: pillarColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$index ${item.pillar.toUpperCase()}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: pillarColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Flexible(
                  child: Text(
                    item.source,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                if (item.coverageCount > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+${item.coverageCount - 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pillarColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Headline
            Text(
              item.headline,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            // Crisp bullet takeaway
            Text(
              item.bullet,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
