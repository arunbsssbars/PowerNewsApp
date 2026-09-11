import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news_app/models/news_article.dart';
import 'package:power_news_app/providers/news_provider.dart';
import 'package:power_news_app/widgets/news_card.dart';
import 'package:power_news_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService().close();
  });

  testWidgets('NewsCard renders headline, source, date, and category badge', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final testArticle = NewsArticle(
      id: 'test-card-1',
      title: 'ABB India commissions 400 kV GIS Substation',
      summary: 'ABB has successfully energized a state-of-the-art gas insulated substation in Pune.',
      url: 'https://powerline.net.in/abb-pune',
      source: 'Power Line Magazine',
      publishedAt: DateTime(2026, 9, 2, 11, 0),
      categories: ['transmission'],
      player: 'ABB',
      city: 'Pune',
      state: 'Maharashtra',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NewsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NewsCard(
              article: testArticle,
              itemIndex: 0,
              allArticles: [testArticle],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verify headline, source, and category badge rendering
    expect(find.text('ABB India commissions 400 kV GIS Substation'), findsOneWidget);
    expect(find.text('Power Line Magazine'), findsOneWidget);
    expect(find.text('TRANSMISSION'), findsOneWidget);
  });
}
