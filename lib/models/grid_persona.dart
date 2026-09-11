import 'package:flutter/material.dart';

enum GridPersona {
  all(
    id: 'all',
    title: 'All Sector Roles',
    shortLabel: 'All Roles',
    subtitle: 'Complete national power sector overview',
    icon: Icons.grid_view_rounded,
    badgeColor: Color(0xFF2563EB),
    keywords: [],
    categories: [],
  ),
  discom(
    id: 'discom',
    title: 'DISCOM & Utility Ops',
    shortLabel: 'DISCOM Ops',
    subtitle: 'Smart metering, AT&C loss reduction, tariffs & billing',
    icon: Icons.electric_meter_rounded,
    badgeColor: Color(0xFF0284C7),
    keywords: [
      'smart meter',
      'at&c',
      'discom',
      'uppcl',
      'bses',
      'tata power',
      'bbps',
      'billing',
      'substation',
      'loss reduction',
      'rdss',
      'consumer',
      'prepaid',
      'dhabol',
      'distribution',
      'tariff',
      'feeder',
      'outage'
    ],
    categories: ['Distribution & DISCOMs', 'Tenders & Contracts'],
  ),
  transmission(
    id: 'transmission',
    title: 'Transmission & Substation Head',
    shortLabel: 'Grid & Substation',
    subtitle: '765kV/400kV lines, substations, transformers & SCADA',
    icon: Icons.alt_route_rounded,
    badgeColor: Color(0xFF7C3AED),
    keywords: [
      'powergrid',
      'pgcil',
      '765kv',
      '400kv',
      '220kv',
      'substation',
      'transformer',
      'transmission',
      'hvdc',
      'inter-regional',
      'evacuation',
      'grid stability',
      'scada',
      'grid controller',
      'posoco',
      'grid-india',
      'transmission line',
      'bay',
      'switchyard'
    ],
    categories: ['Transmission & Grid', 'Tenders & Contracts'],
  ),
  renewables(
    id: 'renewables',
    title: 'Renewables & Clean Energy Developer',
    shortLabel: 'Solar & Wind',
    subtitle: 'SECI tenders, solar/wind PPAs, BESS storage & ALMM',
    icon: Icons.wb_sunny_rounded,
    badgeColor: Color(0xFF059669),
    keywords: [
      'solar',
      'wind',
      'bess',
      'storage',
      'seci',
      'ppa',
      'green hydrogen',
      'almm',
      'module',
      'rooftop',
      'renewable',
      'hybrid',
      'ireda',
      'clean energy',
      'capacity',
      'tender',
      'waaree',
      'adani green',
      'suzlon'
    ],
    categories: ['Renewables & Green Energy', 'Tenders & Contracts'],
  ),
  oem(
    id: 'oem',
    title: 'OEM & Equipment Vendor',
    shortLabel: 'OEMs & Equipment',
    subtitle: 'BHEL, Siemens, ABB, Inox Wind, Switchgear & Cables',
    icon: Icons.precision_manufacturing_rounded,
    badgeColor: Color(0xFFD97706),
    keywords: [
      'bhel',
      'siemens',
      'abb',
      'schneider',
      'inox wind',
      'havells',
      'genus',
      'secure meters',
      'switchgear',
      'cable',
      'transformer',
      'turbine',
      'epc',
      'order',
      'contract',
      'manufacturing',
      'equipment',
      'supply',
      'hitachi'
    ],
    categories: ['Thermal & Hydro Power', 'Tenders & Contracts', 'Renewables & Green Energy'],
  ),
  policy(
    id: 'policy',
    title: 'Policy & Regulatory Analyst',
    shortLabel: 'Policy & Regs',
    subtitle: 'CERC, CEA, UPERC, NEP guidelines & Power Exchanges',
    icon: Icons.gavel_rounded,
    badgeColor: Color(0xFFDC2626),
    keywords: [
      'cerc',
      'cea',
      'uperc',
      'mop',
      'ministry',
      'tariff',
      'regulation',
      'order',
      'iex',
      'pxil',
      'power exchange',
      'guideline',
      'policy',
      'rpo',
      'nep',
      'amendment',
      'regulator',
      'serc'
    ],
    categories: ['Policy & Regulations', 'Financial & Corporate'],
  );

  const GridPersona({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
    required this.keywords,
    required this.categories,
  });

  final String id;
  final String title;
  final String shortLabel;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;
  final List<String> keywords;
  final List<String> categories;

  static GridPersona fromId(String? id) {
    if (id == null) return GridPersona.all;
    return GridPersona.values.firstWhere(
      (p) => p.id == id,
      orElse: () => GridPersona.all,
    );
  }

  /// Calculates relevance score (0 to 100) for a given article against this persona
  double calculateRelevance(String title, String summary, String category, String? player) {
    if (this == GridPersona.all) return 100.0;

    double score = 0.0;
    final text = '${title.toLowerCase()} ${summary.toLowerCase()} ${(player ?? '').toLowerCase()}';

    // Category match
    if (categories.contains(category)) {
      score += 35.0;
    }

    // Keyword matches
    int keywordMatches = 0;
    for (final kw in keywords) {
      if (text.contains(kw)) {
        keywordMatches++;
      }
    }

    if (keywordMatches > 0) {
      score += (keywordMatches * 15.0).clamp(0.0, 65.0);
    }

    return score.clamp(0.0, 100.0);
  }
}
