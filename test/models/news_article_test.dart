import 'package:flutter_test/flutter_test.dart';
import 'package:power_news_app/models/news_article.dart';

void main() {
  group('NewsArticle Model Tests', () {
    test('Correctly parses valid JSON', () {
      final json = {
        'id': 'art-101',
        'title': 'POWERGRID commissions 765 kV D/C line in Rajasthan - Economic Times',
        'summary': 'POWERGRID has successfully energized a high-voltage 765 kV transmission link in Rajasthan.',
        'url': 'https://powerline.net.in/article-101',
        'source': 'Power Line Magazine',
        'publishedAt': '2026-09-01T12:00:00.000Z',
        'categories': ['transmission'],
        'player': 'POWERGRID',
        'city': 'Jaipur',
        'state': 'Rajasthan',
        'discom': 'JVVNL',
        'imageUrl': 'https://powerline.net.in/wp-content/uploads/2026/09/line.jpg',
      };

      final article = NewsArticle.fromJson(json);

      expect(article.id, 'art-101');
      // Verify source stripping from title
      expect(article.title, 'POWERGRID commissions 765 kV D/C line in Rajasthan');
      expect(article.source, 'Power Line Magazine');
      expect(article.player, 'POWERGRID');
      expect(article.city, 'Jaipur');
      expect(article.state, 'Rajasthan');
      expect(article.discom, 'JVVNL');
      expect(article.imageUrl, 'https://powerline.net.in/wp-content/uploads/2026/09/line.jpg');
      expect(article.primaryCategory, 'transmission');
      expect(article.formattedDate, '01-Sep-26');
    });

    test('Gracefully handles missing, null, and empty fields', () {
      final json = <String, dynamic>{
        'title': 'Solar Tender floated by SECI',
      };

      final article = NewsArticle.fromJson(json);

      expect(article.id.isNotEmpty, true);
      expect(article.title, 'Solar Tender floated by SECI');
      expect(article.summary, 'Solar Tender floated by SECI');
      expect(article.source, 'PowerNews Feed');
      expect(article.categories, ['generation']); // default fallback
      expect(article.state, 'National / Pan-India');
      expect(article.player, isNull);
      expect(article.city, isNull);
      expect(article.discom, isNull);
    });

    test('toJson produces expected structure', () {
      final article = NewsArticle(
        id: 'art-202',
        title: 'NTPC Green Energy IPO filed',
        summary: 'NTPC Green Energy Ltd files draft papers for IPO.',
        url: 'https://mercomindia.com/ntpc-green',
        source: 'Mercom India',
        publishedAt: DateTime.utc(2026, 9, 2, 10, 30),
        categories: ['renewables', 'generation'],
        player: 'NTPC',
        city: 'New Delhi',
        state: 'Delhi',
        discom: null,
        imageUrl: 'https://mercomindia.com/wp-content/uploads/ntpc.jpg',
      );

      final json = article.toJson();

      expect(json['id'], 'art-202');
      expect(json['title'], 'NTPC Green Energy IPO filed');
      expect(json['player'], 'NTPC');
      expect(json['categories'], ['renewables', 'generation']);
      expect(json['publishedAt'], '2026-09-02T10:30:00.000Z');
      expect(json['sources'], isEmpty);
      expect(json['coverageCount'], 1);
      expect(json['imageUrl'], 'https://mercomindia.com/wp-content/uploads/ntpc.jpg');
    });

    test('formattedDateTime handles edge cases', () {
      final article = NewsArticle(
        id: '1',
        title: 'Test',
        summary: 'Summary',
        url: 'http://test.com',
        source: 'Source',
        publishedAt: DateTime(2026, 9, 2, 14, 45),
        categories: ['transmission'],
        state: 'National',
      );

      expect(article.formattedDateTime, contains('02-Sep-26'));
      expect(article.formattedDateTime, contains('02:45 PM'));
    });
  });
}
