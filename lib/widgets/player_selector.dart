import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class PlayerSelector extends StatelessWidget {
  const PlayerSelector({super.key});

  final List<String> players = const [
    'All',
    'UPPCL',
    'POWERGRID',
    'NTPC',
    'Tata Power',
    'Adani Power',
    'Siemens',
    'ABB',
    'Schneider',
    'Hitachi Energy',
    'BHEL',
    'L&T Power',
    'GE Vernova',
    'Reliance Power',
    'SECI',
    'BESCOM',
    'MSEDCL',
    'TANGEDCO',
    'Torrent Power',
    'NHPC',
    'JSW Energy',
    'CESC',
    'SJVN',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Icon(
                Icons.business_rounded,
                size: 14,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 5),
              Text(
                'Utilities, PSUs & OEMs',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: players.map((p) {
              final isSelected = (p == 'All' && (provider.selectedPlayer == 'All' || provider.selectedPlayer == 'All Players')) ||
                  provider.selectedPlayer.toLowerCase() == p.toLowerCase();
              final count = p == 'All'
                  ? provider.totalPlayerNewsCount
                  : (provider.players[p] ?? 0);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      provider.setPlayerFilter(p == 'All' ? 'All' : p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD97706)
                            : (isDark ? const Color(0xFF151D2E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD97706)
                              : (isDark ? const Color(0xFF222F46) : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                          if (count > 0 && p != 'All') ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : (isDark ? const Color(0xFF222F46) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
