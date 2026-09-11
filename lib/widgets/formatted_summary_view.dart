import 'package:flutter/material.dart';
import '../models/news_article.dart';

class FormattedSummaryView extends StatelessWidget {
  final String summary;
  final bool isDark;
  final String? player;
  final String? city;
  final String? state;
  final String? title;
  final double fontSize;
  final String? fontFamily;
  final double lineHeight;

  const FormattedSummaryView({
    super.key,
    required this.summary,
    required this.isDark,
    this.player,
    this.city,
    this.state,
    this.title,
    this.fontSize = 14.0,
    this.fontFamily,
    this.lineHeight = 1.55,
  });

  @override
  Widget build(BuildContext context) {
    final cleanSummary = NewsArticle.cleanHtmlAndEntities(summary);
    final isHeadlineDuplicate = title != null && cleanSummary.trim().toLowerCase() == title!.trim().toLowerCase();
    if (cleanSummary.isEmpty || isHeadlineDuplicate) {
      return Text(
        'This power sector update covers key grid, generation, transmission, and utility developments.',
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: lineHeight,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
      );
    }

    // Clean any residual prefixes/headings from lines
    final rawLines = cleanSummary
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    List<String> points = [];

    if (rawLines.length > 1) {
      points = rawLines.map((l) {
        return l
            .replaceFirst(RegExp(r'^(📌|⚡|🏢|🔹|🔸|•|\*|-)\s*'), '')
            .replaceFirst(RegExp(r'^(Key Action|Metrics & Scope|Grid & Utility Impact|Action|Metrics|Scope|Impact|Overview|Key Focus|Operating Entity|Geographic Impact):\s*', caseSensitive: false), '')
            .trim();
      }).where((l) => l.length > 5).toList();
    } else {
      // Split single paragraph into distinct sentences
      points = cleanSummary
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .map((s) => s.replaceFirst(RegExp(r'^(📌|⚡|🏢|🔹|🔸|•|\*|-)\s*'), ''))
          .map((s) => s.replaceFirst(RegExp(r'^(Key Action|Metrics & Scope|Grid & Utility Impact|Action|Metrics|Scope|Impact|Overview|Key Focus|Operating Entity|Geographic Impact):\s*', caseSensitive: false), ''))
          .where((s) => s.length > 5)
          .toList();
    }

    if (points.isEmpty) {
      points = [cleanSummary];
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: points.map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: fontSize * 0.45, right: 10),
                  child: Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: fontFamily,
                      height: lineHeight,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
