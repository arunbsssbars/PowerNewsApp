import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/news_provider.dart';
import '../models/grid_persona.dart';
import '../models/news_article.dart';
import '../screens/reader_screen.dart';
import '../services/audio_digest_service.dart';

class GeminiQAItem {
  final String question;
  final String answer;
  final List<Map<String, dynamic>> sources;
  final DateTime timestamp;

  GeminiQAItem({
    required this.question,
    required this.answer,
    required this.sources,
    required this.timestamp,
  });
}

class AskGeminiSheet extends StatefulWidget {
  const AskGeminiSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AskGeminiSheet(),
    );
  }

  @override
  State<AskGeminiSheet> createState() => _AskGeminiSheetState();
}

class _AskGeminiSheetState extends State<AskGeminiSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioDigestService _audioService = AudioDigestService();

  bool _isLoading = false;
  String? _activeQuestion;
  final List<GeminiQAItem> _history = [];
  String? _currentlySpeakingAnswerId;

  final List<String> _suggestedPrompts = [
    'Recent 765 kV substation orders in India',
    'Smart meter deployment progress & DISCOM AT&C losses',
    'Latest SECI & state solar tender tariffs',
    'Grid-scale BESS battery storage projects',
    'Key CERC regulatory orders and NEP guidelines',
  ];

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onAudioChange);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAudioChange() {
    if (mounted) setState(() {});
  }

  Future<void> _ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || _isLoading) return;

    // Clear textbox immediately after user submits the query
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _activeQuestion = q;
    });

    _scrollToBottom();

    final prov = context.read<NewsProvider>();
    final persona = prov.selectedPersona != GridPersona.all ? prov.selectedPersona.id : null;

    final response = await prov.apiService.askGeminiGridQA(q, persona: persona);

    if (mounted) {
      setState(() {
        _isLoading = false;
        String answer;
        List<Map<String, dynamic>> sources = [];

        if (response != null && response['answer'] != null) {
          answer = response['answer'].toString();
          if (response['groundingArticles'] is List) {
            sources = List<Map<String, dynamic>>.from(response['groundingArticles']);
          }
        } else {
          answer = 'Could not generate an AI briefing at this time. Please check your network connection and try again.';
        }

        _history.add(GeminiQAItem(
          question: q,
          answer: answer,
          sources: sources,
          timestamp: DateTime.now(),
        ));
        _activeQuestion = null;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSpeakAnswer(String answerText, int itemIndex) {
    final speechId = 'item_$itemIndex';
    if (_audioService.isPlaying && _currentlySpeakingAnswerId == speechId) {
      _audioService.pauseAudio();
      setState(() => _currentlySpeakingAnswerId = null);
    } else {
      // Clean speech from asterisks and bullet symbols for natural audio delivery
      final cleaned = answerText
          .replaceAll(RegExp(r'\*\*'), '')
          .replaceAll(RegExp(r'•|—|-'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      _audioService.playAudioScript(cleaned);
      setState(() => _currentlySpeakingAnswerId = speechId);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Grid briefing copied to clipboard!'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareQA(GeminiQAItem item) {
    try {
      Share.share(
        '⚡ *PowerNews Grid AI Briefing*\n\n❓ *Question:* ${item.question}\n\n💡 *Answer:*\n${item.answer}\n\nVia PowerNews App',
        subject: item.question,
      );
    } catch (_) {
      _copyToClipboard(item.answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prov = context.watch<NewsProvider>();
    final persona = prov.selectedPersona;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask Gemini Grid AI',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        persona != GridPersona.all
                            ? 'Role Persona: ${persona.shortLabel}'
                            : 'National Sector Intelligence • 24/7 Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: persona != GridPersona.all ? persona.badgeColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_history.isNotEmpty)
                  IconButton(
                    tooltip: 'New Conversation',
                    onPressed: () {
                      setState(() {
                        _history.clear();
                        _activeQuestion = null;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 21),
                  ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 21),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body: Conversation or Suggestions
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const BouncingScrollPhysics(),
              children: [
                // If conversation is empty and not loading, show suggested questions
                if (_history.isEmpty && !_isLoading) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'POPULAR GRID QUESTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_suggestedPrompts.length, (idx) {
                    final p = _suggestedPrompts[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _ask(p),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 15,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                // Conversation History Items
                for (int i = 0; i < _history.length; i++) ...[
                  _buildQuestionBubble(_history[i].question, isDark),
                  const SizedBox(height: 10),
                  _buildAnswerCard(_history[i], i, isDark),
                  const SizedBox(height: 20),
                ],

                // Active loading state
                if (_isLoading) ...[
                  if (_activeQuestion != null) ...[
                    _buildQuestionBubble(_activeQuestion!, isDark),
                    const SizedBox(height: 10),
                  ],
                  _buildThinkingCard(isDark),
                ],

                // Follow-up suggestions after an answer
                if (_history.isNotEmpty && !_isLoading) ...[
                  const SizedBox(height: 4),
                  _buildFollowUpSection(isDark),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything about India\'s power grid...',
                        hintStyle: TextStyle(fontSize: 12.5),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isLoading ? null : () => _ask(_controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBubble(String question, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini is analyzing the national power grid...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consulting CEA norms, PGCIL, state DISCOMs & live reports',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(GeminiQAItem item, int index, bool isDark) {
    final speechId = 'item_$index';
    final isSpeakingThis = _audioService.isPlaying && _currentlySpeakingAnswerId == speechId;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeakingThis
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSpeakingThis ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151D2E) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF222F46) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'GRID INTELLIGENCE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Announcer Listen Button
                IconButton(
                  tooltip: isSpeakingThis ? 'Pause Announcer' : 'Listen to Briefing',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    isSpeakingThis ? Icons.pause_circle_filled_rounded : Icons.volume_up_rounded,
                    size: 19,
                    color: isSpeakingThis ? const Color(0xFF6366F1) : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  onPressed: () => _toggleSpeakAnswer(item.answer, index),
                ),

                // Copy Button
                IconButton(
                  tooltip: 'Copy Briefing',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 17,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _copyToClipboard(item.answer),
                ),

                // Share Button
                IconButton(
                  tooltip: 'Share',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.share_rounded,
                    size: 17,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _shareQA(item),
                ),
              ],
            ),
          ),

          // Formatted Structured Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFormattedAnswerContent(item.answer, isDark),
          ),

          // Grounding Sources Section
          if (item.sources.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D2E) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF222F46) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.source_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'CITED SECTOR SOURCES (${item.sources.length})',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(item.sources.length, (sIdx) {
                    final s = item.sources[sIdx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final art = NewsArticle(
                            id: s['id']?.toString() ?? '',
                            title: s['title']?.toString() ?? '',
                            summary: '',
                            url: s['url']?.toString() ?? '',
                            source: s['source']?.toString() ?? 'PowerNews',
                            publishedAt: DateTime.tryParse(s['publishedAt']?.toString() ?? '') ?? DateTime.now(),
                            categories: ['General'],
                            state: 'National',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(article: art),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s['title']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s['source']?.toString() ?? 'News',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedAnswerContent(String answer, bool isDark) {
    final lines = answer.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Check if line represents a bullet point with a title
        final bulletMatch = RegExp(r'^[•\*\-]\s*\*\*(.*?)\*\*\s*(?:[—:\-]\s*)?(.*)$').firstMatch(line);

        if (bulletMatch != null) {
          final title = bulletMatch.group(1)?.trim() ?? '';
          final body = bulletMatch.group(2)?.trim() ?? '';

          IconData iconData = Icons.arrow_right_rounded;
          Color accentColor = const Color(0xFF6366F1);

          final titleLower = title.toLowerCase();
          if (titleLower.contains('happening') || titleLower.contains('what')) {
            iconData = Icons.bolt_rounded;
            accentColor = const Color(0xFFF59E0B);
          } else if (titleLower.contains('figure') || titleLower.contains('fact') || titleLower.contains('data')) {
            iconData = Icons.insert_chart_rounded;
            accentColor = const Color(0xFF0284C7);
          } else if (titleLower.contains('impact') || titleLower.contains('regulat') || titleLower.contains('grid')) {
            iconData = Icons.account_balance_rounded;
            accentColor = const Color(0xFF8B5CF6);
          } else if (titleLower.contains('stakeholder') || titleLower.contains('discom') || titleLower.contains('oem')) {
            iconData = Icons.people_alt_rounded;
            accentColor = const Color(0xFF0D9488);
          } else if (titleLower.contains('outlook') || titleLower.contains('next') || titleLower.contains('step')) {
            iconData = Icons.rocket_launch_rounded;
            accentColor = const Color(0xFF10B981);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(iconData, size: 15, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildParsedText(body, textColor),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Regular narrative paragraph
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildParsedText(line, textColor),
          );
        }
      }).toList(),
    );
  }

  Widget _buildParsedText(String text, Color baseColor) {
    // Parse **bold** markdown segments
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i.isOdd) {
        // Bold token
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: baseColor,
          ),
        ));
      } else {
        // Normal token
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: baseColor.withOpacity(0.9),
          ),
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildFollowUpSection(bool isDark) {
    final suggestions = [
      'What are the DISCOM financial implications?',
      'Which OEMs and vendors are leading this?',
      'What is the latest CERC / CEA regulatory stance?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUGGESTED FOLLOW-UPS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: suggestions.map((s) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _ask(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 13, color: Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    Text(
                      s,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
