import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news_app/providers/news_provider.dart';
import 'package:power_news_app/widgets/ask_gemini_sheet.dart';
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

  group('AskGeminiSheet Widget Tests', () {
    testWidgets('Renders header, prompt suggestions, and input bar', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NewsProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AskGeminiSheet(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // 1. Header elements
      expect(find.text('Ask Gemini Grid AI'), findsOneWidget);

      // 2. Prompt suggestions
      expect(find.text('POPULAR GRID QUESTIONS'), findsOneWidget);
      expect(find.text('Recent 765 kV substation orders in India'), findsOneWidget);
      expect(find.text('Grid-scale BESS battery storage projects'), findsOneWidget);

      // 3. Input bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}
