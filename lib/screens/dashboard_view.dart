import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/ask_gemini_sheet.dart';

class DashboardView extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;

  const DashboardView({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Sleek, compact aspect ratios to avoid extra vertical spacing
    final double domainRatio = screenWidth < 380 ? 1.82 : 1.95;
    final double playerRatio = screenWidth < 380 ? 2.15 : 2.35;

    // 1. Sector & Grid Domains
    final sectors = [
      {
        'category': 'transmission',
        'title': 'Transmission & Grid',
        'subtitle': 'POWERGRID, CTU, ISTS & 765kV',
        'count': provider.categories['transmission'] ?? 0,
        'color': const Color(0xFF0284C7),
        'icon': Icons.electric_bolt_rounded,
      },
      {
        'category': 'renewables',
        'title': 'Renewables & BESS',
        'subtitle': 'Solar, Wind, Battery & H2',
        'count': provider.categories['renewables'] ?? 0,
        'color': const Color(0xFF10B981),
        'icon': Icons.solar_power_rounded,
      },
      {
        'category': 'generation',
        'title': 'Generation Plants',
        'subtitle': 'Thermal, Hydro & NTPC',
        'count': provider.categories['generation'] ?? 0,
        'color': const Color(0xFFD97706),
        'icon': Icons.factory_rounded,
      },
      {
        'category': 'distribution',
        'title': 'DISCOMs & Tariffs',
        'subtitle': 'Smart Meters, RDSS & Outages',
        'count': provider.categories['distribution'] ?? 0,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.power_rounded,
      },
      {
        'category': 'policy',
        'title': 'Policy & Regulatory',
        'subtitle': 'CERC, SERCs & MoP Orders',
        'count': provider.categories['policy'] ?? 0,
        'color': const Color(0xFFEC4899),
        'icon': Icons.gavel_rounded,
      },
      {
        'category': 'scada',
        'title': 'SCADA & Communication',
        'subtitle': 'Automation, RTUs, OPGW & IT-OT',
        'count': provider.categories['scada'] ?? 0,
        'color': const Color(0xFF0EA5E9),
        'icon': Icons.settings_input_antenna_rounded,
      },
      {
        'category': 'tenders',
        'title': 'Tenders & Bids',
        'subtitle': 'SECI, TBCB & Reverse Auctions',
        'count': provider.categories['tenders'] ?? 0,
        'color': const Color(0xFF06B6D4),
        'icon': Icons.assignment_turned_in_rounded,
      },
    ];

    // 2. Core Utilities & PSUs
    final utilities = [
      {'name': 'UPPCL', 'desc': 'UP Power Corp & DISCOMs', 'icon': Icons.location_city_rounded, 'color': const Color(0xFF2563EB)},
      {'name': 'POWERGRID', 'desc': 'National Transmission CTU', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF0284C7)},
      {'name': 'NTPC', 'desc': 'Thermal & Green Energy', 'icon': Icons.factory_rounded, 'color': const Color(0xFFD97706)},
      {'name': 'Tata Power', 'desc': 'Renewables, TPDDL & T&D', 'icon': Icons.business_rounded, 'color': const Color(0xFF059669)},
      {'name': 'Adani Power', 'desc': 'Thermal, Solar & AEML', 'icon': Icons.bolt_rounded, 'color': const Color(0xFF7C3AED)},
      {'name': 'Reliance Power', 'desc': 'Solar & Infrastructure', 'icon': Icons.solar_power_rounded, 'color': const Color(0xFFEA580C)},
      {'name': 'SECI', 'desc': 'Solar Energy Corp of India', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFF0D9488)},
      {'name': 'NHPC', 'desc': 'Hydro Power & Gencos', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF0284C7)},
      {'name': 'JSW Energy', 'desc': 'Thermal & Renewables', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFB45309)},
      {'name': 'Torrent Power', 'desc': 'Distribution & Generation', 'icon': Icons.electrical_services_rounded, 'color': const Color(0xFF4338CA)},
    ];

    // 3. Top 14 Most Popular Power Equipment OEMs & Engineering Giants
    final oems = [
      {'name': 'Siemens', 'desc': 'Siemens Energy, GIS & HVDC', 'icon': Icons.engineering_rounded, 'color': const Color(0xFF0284C7)},
      {'name': 'ABB', 'desc': 'ABB India, Switchgear & SCADA', 'icon': Icons.precision_manufacturing_rounded, 'color': const Color(0xFFDC2626)},
      {'name': 'Hitachi Energy', 'desc': 'Transformers & HVDC Links', 'icon': Icons.memory_rounded, 'color': const Color(0xFFE11D48)},
      {'name': 'Schneider', 'desc': 'Schneider Electric Smart Grid', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF16A34A)},
      {'name': 'BHEL', 'desc': 'Boilers, Turbines & EPC', 'icon': Icons.build_circle_rounded, 'color': const Color(0xFFD97706)},
      {'name': 'L&T Power', 'desc': 'Substations & Transmission', 'icon': Icons.construction_rounded, 'color': const Color(0xFF2563EB)},
      {'name': 'GE Vernova', 'desc': 'Grid Solutions & Turbines', 'icon': Icons.hub_rounded, 'color': const Color(0xFF7C3AED)},
      {'name': 'CG Power', 'desc': 'Transformers & Switchgear', 'icon': Icons.electric_bolt_rounded, 'color': const Color(0xFF059669)},
      {'name': 'KEC International', 'desc': 'Transmission & Substation EPC', 'icon': Icons.alt_route_rounded, 'color': const Color(0xFF0D9488)},
      {'name': 'Kalpataru (KPIL)', 'desc': 'Power Transmission & Infra', 'icon': Icons.foundation_rounded, 'color': const Color(0xFFEA580C)},
      {'name': 'Sterlite Power', 'desc': 'Corridors & Power Cables', 'icon': Icons.cable_rounded, 'color': const Color(0xFF9333EA)},
      {'name': 'Secure Meters', 'desc': 'Smart Metering & Telemetry', 'icon': Icons.speed_rounded, 'color': const Color(0xFF16A34A)},
      {'name': 'Genus Power', 'desc': 'Smart Electricity Meters', 'icon': Icons.electric_meter_rounded, 'color': const Color(0xFF7C3AED)},
      {'name': 'Waaree Energies', 'desc': 'Solar PV Modules & EPC', 'icon': Icons.solar_power_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    final int totalMonitoredPlayers = provider.players.isNotEmpty ? provider.players.length : 24;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Card (Compact & High-Contrast Typography)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0E1424), Color(0xFF182238)]
                      : const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2D47) : Colors.transparent,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'India Power Intelligence Hub',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Explore sector hubs, utilities, and equipment OEMs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Left KPI: Total Articles
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL ARTICLES',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${provider.totalNewsCount}+',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Curated Sector News',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right KPI: Monitored Players
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MONITORED PLAYERS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$totalMonitoredPlayers+',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'PSUs, Utilities & OEMs',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Phase 5: "Ask Gemini About the Grid" Interactive AI Analyst Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => AskGeminiSheet.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF1E1B4B), Color(0xFF312E81)]
                          : const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                      width: 1.2,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Ask Gemini Grid AI',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AI ANALYST',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Instant briefings on tariffs, 765kV orders, DISCOMs & BESS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section 1: Power Sector Domains
            Row(
              children: [
                Icon(Icons.category_rounded, size: 15.5, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Power Sector Domains',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sectors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: domainRatio,
              ),
              itemBuilder: (context, index) {
                final s = sectors[index];
                final color = s['color'] as Color;
                final int count = (s['count'] as int?) ?? 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (count == 0) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                            content: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No recent news for ${s['title']} in the past 7 days.',
                                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            action: SnackBarAction(
                              label: 'View Feed',
                              textColor: const Color(0xFF38BDF8),
                              onPressed: () {
                                provider.setCategory(s['category'] as String);
                                onNavigateTab(0);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      provider.setCategory(s['category'] as String);
                      onNavigateTab(0);
                    },
                    child: Opacity(
                      opacity: count == 0 ? 0.78 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161B22) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(s['icon'] as IconData, color: color, size: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? color.withOpacity(isDark ? 0.2 : 0.1)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(5),
                                    border: count > 0
                                        ? null
                                        : Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                  ),
                                  child: Text(
                                    '$count news',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: count > 0
                                          ? color
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                s['subtitle'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),

            const SizedBox(height: 16),

            // Section 2: Core Power Utilities & PSUs
            Row(
              children: [
                Icon(Icons.business_rounded, size: 15.5, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Power Utilities, PSUs & Gencos',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: utilities.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: playerRatio,
              ),
              itemBuilder: (context, index) {
                final u = utilities[index];
                final color = u['color'] as Color;
                final count = provider.players[u['name']] ?? 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (count == 0) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                            content: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No recent news for ${u['name']} in the past 7 days.',
                                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            action: SnackBarAction(
                              label: 'View Feed',
                              textColor: const Color(0xFF38BDF8),
                              onPressed: () {
                                provider.setPlayerFilter(u['name'] as String);
                                onNavigateTab(0);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      provider.setPlayerFilter(u['name'] as String);
                      onNavigateTab(0);
                    },
                    child: Opacity(
                      opacity: count == 0 ? 0.78 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161B22) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(u['icon'] as IconData, color: color, size: 13),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    u['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? color.withOpacity(isDark ? 0.22 : 0.12)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: count > 0
                                        ? null
                                        : Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: count > 0
                                          ? color
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Text(
                            u['desc'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),

            const SizedBox(height: 16),

            // Section 3: Equipment OEMs & Engineering Giants
            Row(
              children: [
                Icon(Icons.precision_manufacturing_rounded, size: 15.5, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Power Equipment OEMs & Engineering Giants',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: oems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: playerRatio,
              ),
              itemBuilder: (context, index) {
                final o = oems[index];
                final color = o['color'] as Color;
                final count = provider.players[o['name']] ?? 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (count == 0) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                            content: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No recent news for ${o['name']} in the past 7 days.',
                                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            action: SnackBarAction(
                              label: 'View Feed',
                              textColor: const Color(0xFF38BDF8),
                              onPressed: () {
                                provider.setPlayerFilter(o['name'] as String);
                                onNavigateTab(0);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      provider.setPlayerFilter(o['name'] as String);
                      onNavigateTab(0);
                    },
                    child: Opacity(
                      opacity: count == 0 ? 0.78 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161B22) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(o['icon'] as IconData, color: color, size: 13),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    o['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? color.withOpacity(isDark ? 0.22 : 0.12)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: count > 0
                                        ? null
                                        : Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: count > 0
                                          ? color
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Text(
                            o['desc'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
