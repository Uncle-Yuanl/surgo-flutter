import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/features/report/learning_advice.dart';

void main() {
  group('LearningAdvice Widget', () {
    testWidgets('renders with initial state', (tester) async {
      String selectedSkill = kSkillListening;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningAdvice(
                chinese: true,
                selectedSkill: selectedSkill,
                onSelectSkill: (skill) => selectedSkill = skill,
                onPractice: (skill, rank) {
                  // Practice callback test
                },
              ),
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('可以进步的地方'), findsOneWidget);

      // Verify teacher comment card
      expect(find.text('老师给你的点评'), findsOneWidget);

      // Verify skill tabs
      expect(
          find.byKey(const ValueKey('advice-tab-listening')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-reading')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-writing')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-speaking')), findsOneWidget);

      // Verify practice buttons exist for 3 items
      expect(find.byKey(const ValueKey('advice-practice-listening-1')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('advice-practice-listening-2')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('advice-practice-listening-3')),
          findsOneWidget);

      // Verify more suggestions
      expect(find.byKey(const ValueKey('advice-more')), findsOneWidget);
    });

    testWidgets('switches skills when tabs are tapped', (tester) async {
      String selectedSkill = kSkillListening;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: LearningAdvice(
                    chinese: true,
                    selectedSkill: selectedSkill,
                    onSelectSkill: (skill) {
                      setState(() => selectedSkill = skill);
                    },
                    onPractice: (skill, rank) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(selectedSkill, kSkillListening);

      // Tap reading tab
      await tester.tap(find.byKey(const ValueKey('advice-tab-reading')));
      await tester.pumpAndSettle();

      // Practice buttons should now be for reading
      expect(find.byKey(const ValueKey('advice-practice-reading-1')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('advice-practice-reading-2')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('advice-practice-reading-3')),
          findsOneWidget);

      // Tap writing tab
      await tester.tap(find.byKey(const ValueKey('advice-tab-writing')));
      await tester.pumpAndSettle();

      // Practice buttons should now be for writing
      expect(find.byKey(const ValueKey('advice-practice-writing-1')),
          findsOneWidget);
    });

    testWidgets('calls onPractice with correct parameters', (tester) async {
      String? practicedSkill;
      int? practicedRank;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningAdvice(
                chinese: true,
                selectedSkill: kSkillListening,
                onSelectSkill: (_) {},
                onPractice: (skill, rank) {
                  practicedSkill = skill;
                  practicedRank = rank;
                },
              ),
            ),
          ),
        ),
      );

      // Tap first practice button
      await tester
          .tap(find.byKey(const ValueKey('advice-practice-listening-1')));
      await tester.pumpAndSettle();

      expect(practicedSkill, kSkillListening);
      expect(practicedRank, 1);

      // Third card is below the viewport; scroll to the actual tap target.
      await tester.ensureVisible(
          find.byKey(const ValueKey('advice-practice-listening-3')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('advice-practice-listening-3')));
      await tester.pumpAndSettle();

      expect(practicedSkill, kSkillListening);
      expect(practicedRank, 3);
    });

    testWidgets('expands and collapses teacher comment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningAdvice(
                chinese: true,
                selectedSkill: kSkillListening,
                onSelectSkill: (_) {},
                onPractice: (_, __) {},
              ),
            ),
          ),
        ),
      );

      // Find teacher expand button
      final expandButton = find.byKey(const ValueKey('teacher-expand'));
      expect(expandButton, findsOneWidget);

      // Tap to expand
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Tap again to collapse
      await tester.tap(expandButton);
      await tester.pumpAndSettle();
    });

    testWidgets('expands and collapses more suggestions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningAdvice(
                chinese: true,
                selectedSkill: kSkillListening,
                onSelectSkill: (_) {},
                onPractice: (_, __) {},
              ),
            ),
          ),
        ),
      );

      // Find more suggestions button
      final moreButton = find.byKey(const ValueKey('advice-more'));
      expect(moreButton, findsOneWidget);

      // Tap to expand
      await tester.ensureVisible(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Tap again to collapse
      await tester.ensureVisible(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
    });

    testWidgets('renders in English mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningAdvice(
                chinese: false,
                selectedSkill: kSkillListening,
                onSelectSkill: (_) {},
                onPractice: (_, __) {},
              ),
            ),
          ),
        ),
      );

      // Verify English title
      expect(find.text('Areas for Improvement'), findsOneWidget);

      // Verify English skill labels
      expect(find.text('Listening'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Writing'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
    });

    testWidgets('wraps correctly in narrow layout', (tester) async {
      // Set a narrow screen size
      await tester.binding.setSurfaceSize(const Size(320, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LearningAdvice(
                  chinese: true,
                  selectedSkill: kSkillListening,
                  onSelectSkill: (_) {},
                  onPractice: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all skill tabs are present
      expect(
          find.byKey(const ValueKey('advice-tab-listening')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-reading')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-writing')), findsOneWidget);
      expect(find.byKey(const ValueKey('advice-tab-speaking')), findsOneWidget);

      // Verify practice buttons are still interactive
      expect(find.byKey(const ValueKey('advice-practice-listening-1')),
          findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('displays all skill constants correctly', (tester) async {
      // Test that all exported skill constants are valid
      expect(kSkillListening, 'listening');
      expect(kSkillReading, 'reading');
      expect(kSkillWriting, 'writing');
      expect(kSkillSpeaking, 'speaking');
    });

    testWidgets('all demo advice data is accessible', (tester) async {
      // Test that all skills have demo data
      for (final skill in [
        kSkillListening,
        kSkillReading,
        kSkillWriting,
        kSkillSpeaking
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LearningAdvice(
                  chinese: true,
                  selectedSkill: skill,
                  onSelectSkill: (_) {},
                  onPractice: (_, __) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify 3 practice buttons exist for each skill
        expect(
            find.byKey(ValueKey('advice-practice-$skill-1')), findsOneWidget);
        expect(
            find.byKey(ValueKey('advice-practice-$skill-2')), findsOneWidget);
        expect(
            find.byKey(ValueKey('advice-practice-$skill-3')), findsOneWidget);
      }
    });
  });
}
