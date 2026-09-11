import 'package:flutter_test/flutter_test.dart';
import 'package:power_news_app/models/morning_digest.dart';

void main() {
  group('MorningDigest Model Tests', () {
    test('Correctly parses valid JSON into MorningDigest object', () {
      final json = {
        'date': '2026-09-03',
        'title': 'Daily Power Executive Briefing',
        'subtitle': '5 Key Developments',
        'audioScript': 'Good morning. Here is your daily Power Executive Briefing...',
        'items': [
          {
            'pillar': 'Transmission & Grid',
            'articleId': 'grid-01',
            'headline': 'POWERGRID commissions 765kV substation',
            'bullet': 'Substation strengthens inter-regional transfer capacity to 120 GW.',
            'source': 'Power Line',
            'sources': ['Power Line', 'ET EnergyWorld'],
            'coverageCount': 2,
            'state': 'Rajasthan',
            'player': 'POWERGRID'
          }
        ]
      };

      final digest = MorningDigest.fromJson(json);

      expect(digest.date, '2026-09-03');
      expect(digest.title, 'Daily Power Executive Briefing');
      expect(digest.items.length, 1);

      final item = digest.items.first;
      expect(item.pillar, 'Transmission & Grid');
      expect(item.articleId, 'grid-01');
      expect(item.headline, 'POWERGRID commissions 765kV substation');
      expect(item.sources.length, 2);
      expect(item.coverageCount, 2);
      expect(item.player, 'POWERGRID');
    });

    test('Gracefully handles missing items and empty structures', () {
      final json = <String, dynamic>{
        'date': '2026-09-03',
      };

      final digest = MorningDigest.fromJson(json);
      expect(digest.date, '2026-09-03');
      expect(digest.items, isEmpty);
      expect(digest.title, contains('Daily Power'));
    });
  });
}
