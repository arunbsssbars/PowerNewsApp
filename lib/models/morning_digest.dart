class MorningDigestItem {
  final String pillar;
  final String articleId;
  final String headline;
  final String bullet;
  final String? fullSummary;
  final String source;
  final List<String> sources;
  final int coverageCount;
  final String? state;
  final String? player;
  final String? url;

  MorningDigestItem({
    required this.pillar,
    required this.articleId,
    required this.headline,
    required this.bullet,
    this.fullSummary,
    required this.source,
    this.sources = const [],
    this.coverageCount = 1,
    this.state,
    this.player,
    this.url,
  });

  factory MorningDigestItem.fromJson(Map<String, dynamic> json) {
    List<String> srcList = [];
    if (json['sources'] is List) {
      srcList = (json['sources'] as List).map((e) => e.toString()).toList();
    }
    if (srcList.isEmpty && json['source'] != null) {
      srcList = [json['source'].toString()];
    }

    return MorningDigestItem(
      pillar: json['pillar']?.toString() ?? 'Sector News',
      articleId: json['articleId']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      bullet: json['bullet']?.toString() ?? '',
      fullSummary: json['fullSummary']?.toString(),
      source: json['source']?.toString() ?? 'PowerNews',
      sources: srcList,
      coverageCount: json['coverageCount'] is int ? json['coverageCount'] as int : 1,
      state: json['state']?.toString(),
      player: json['player']?.toString(),
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pillar': pillar,
      'articleId': articleId,
      'headline': headline,
      'bullet': bullet,
      'fullSummary': fullSummary,
      'source': source,
      'sources': sources,
      'coverageCount': coverageCount,
      'state': state,
      'player': player,
      'url': url,
    };
  }
}

class MorningDigest {
  final String date;
  final String title;
  final String subtitle;
  final String audioScript;
  final List<MorningDigestItem> items;

  MorningDigest({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.audioScript,
    required this.items,
  });

  factory MorningDigest.fromJson(Map<String, dynamic> json) {
    List<MorningDigestItem> itemList = [];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemList.add(MorningDigestItem.fromJson(item));
        } else if (item is Map) {
          itemList.add(MorningDigestItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MorningDigest(
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Daily Power Executive Briefing',
      subtitle: json['subtitle']?.toString() ?? 'Key Grid, DISCOM & OEM Developments',
      audioScript: json['audioScript']?.toString() ?? '',
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'subtitle': subtitle,
      'audioScript': audioScript,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
