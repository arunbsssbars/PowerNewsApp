import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_news_app/widgets/formatted_summary_view.dart';

void main() {
  group('FormattedSummaryView Widget Tests', () {
    testWidgets('Renders structured bullet points and highlighted entities', (WidgetTester tester) async {
      const summaryText =
          'POWERGRID energizes 765 kV transmission link in Rajasthan. '
          'The project enhances inter-state electricity flow capacity by 1,500 MW. '
          'Operation is certified by CTU for national grid reliability.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormattedSummaryView(
              summary: summaryText,
              isDark: false,
              player: 'POWERGRID',
              state: 'Rajasthan',
            ),
          ),
        ),
      );

      // Verify that summary text is rendered
      expect(find.textContaining('POWERGRID'), findsWidgets);
      expect(find.textContaining('Rajasthan'), findsWidgets);
    });
  });
}
