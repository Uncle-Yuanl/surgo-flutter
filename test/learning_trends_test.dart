import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/features/report/learning_trends.dart';

void main() {
  group('LearningTrends Widget Tests', () {
    testWidgets('renders with valid IELTS data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title exists
      expect(find.text('这几周的变化'), findsOneWidget);

      // Check chart key exists
      expect(find.byKey(const ValueKey('trend-chart')), findsOneWidget);
    });

    testWidgets('renders empty state when no data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [null, null, null, null, null, null, null, null],
              practices: [0, 0, 0, 0, 0, 0, 0, 0],
              maxScore: 9.0,
              target: null,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check empty state message
      expect(find.text('暂无学习数据'), findsOneWidget);
    });

    testWidgets('handles null score gaps correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, null, null, 6.2, null, 6.5, 6.5, 6.5],
              practices: [10, 5, 0, 15, 8, 20, 18, 12],
              maxScore: 9.0,
              target: 7.0,
              chinese: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byKey(const ValueKey('trend-chart')), findsOneWidget);
      expect(find.text('These Weeks\' Changes'), findsOneWidget);
    });

    testWidgets('week selection tap works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no week selected
      expect(find.text('第 1 周'), findsNothing);

      // Tap on first week (index 0)
      final week0Finder = find.byKey(const ValueKey('trend-week-0'));
      expect(week0Finder, findsWidgets); // Multiple (chart and practice bars)

      await tester.tap(week0Finder.first);
      await tester.pumpAndSettle();

      // Should show week detail
      expect(find.text('第 1 周'), findsOneWidget);
      expect(find.text('分数:'), findsOneWidget);
      expect(find.text('练习:'), findsOneWidget);
    });

    testWidgets('week detail can be closed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to select a week
      await tester.tap(find.byKey(const ValueKey('trend-week-3')).first);
      await tester.pumpAndSettle();

      expect(find.text('第 4 周'), findsOneWidget);

      // Find and tap close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Week detail should be gone
      expect(find.text('第 4 周'), findsNothing);
    });

    testWidgets('displays insight card for positive trend',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for insight card with positive trend
      expect(find.text('这段时间在稳步上升'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('shows correct language for English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [5.0, 5.0, 5.0, 5.0, 5.5, 5.5, 5.5, 5.5],
              practices: [10, 10, 10, 10, 20, 20, 20, 20],
              maxScore: 9.0,
              target: 7.0,
              chinese: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('These Weeks\' Changes'), findsOneWidget);
      expect(find.text('Weekly Practice Count'), findsOneWidget);
    });

    testWidgets('displays TOEFL scale correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [4.0, 4.0, 4.0, 4.0, 4.5, 4.5, 4.5, 4.5],
              practices: [5, 5, 5, 5, 15, 15, 15, 15],
              maxScore: 6.0,
              target: 5.0,
              chinese: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without error with TOEFL scale
      expect(find.byKey(const ValueKey('trend-chart')), findsOneWidget);
    });

    testWidgets('handles all null scores with some practices',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [null, null, null, null, null, null, null, null],
              practices: [5, 10, 8, 12, 15, 20, 18, 16],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show practice bars
      expect(find.text('每周练习次数'), findsOneWidget);
      // Should not crash
      expect(find.byKey(const ValueKey('trend-chart')), findsOneWidget);
    });

    testWidgets('all 8 week buttons are accessible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: 7.0,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 8 weeks are accessible
      for (int i = 0; i < 8; i++) {
        final weekFinder = find.byKey(ValueKey('trend-week-$i'));
        expect(
            weekFinder, findsWidgets); // 2 widgets per week (chart + practice)
      }
    });

    testWidgets('widget asserts correct input lengths during build',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: LearningTrends(
              scores: [6.0, 6.0, 6.0],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9,
              target: 7,
              chinese: true)));
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('shows no score data for selected week with null score',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, null, 6.2, null, 6.5, null, 6.5, 6.5],
              practices: [10, 5, 12, 8, 20, 15, 18, 16],
              maxScore: 9.0,
              target: null,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on week with null score (index 1)
      await tester.tap(find.byKey(const ValueKey('trend-week-1')).first);
      await tester.pumpAndSettle();

      // Should show "no score data"
      expect(find.text('暂无分数'), findsOneWidget);
      expect(
          find.text('5 次'), findsOneWidget); // practice count should still show
    });

    testWidgets('handles no target line', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LearningTrends(
              scores: [6.0, 6.0, 6.0, 6.0, 6.5, 6.5, 6.5, 6.5],
              practices: [4, 4, 4, 4, 24, 36, 32, 24],
              maxScore: 9.0,
              target: null,
              chinese: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byKey(const ValueKey('trend-chart')), findsOneWidget);
      // Target label should not be present
      expect(find.textContaining('目标'), findsNothing);
    });
  });
}
