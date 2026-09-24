import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/writing_review/review_widgets.dart';
import 'package:surgo_flutter/features/writing_review/review_annotations.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();

    await loadSurgoTestFonts();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-opsz-wght.ttf')))
        .load();
    await (FontLoader('Arimo')
          ..addFont(rootBundle.load('assets/fonts/Arimo-Bold.ttf')))
        .load();
  });

  Finder key(String s) => find.byKey(ValueKey(s));

  Future<AppState> mount(WidgetTester t, UiLang lang, int task) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    rootBundle.evict('assets/data/writing_review.json');
    final app = AppState(
        current: SurgoPage.writingFeedback,
        lang: lang,
        examType: ExamType.ielts)
      ..session['wfTask'] = task
      ..session['wfTab'] = 'mark';
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
            theme: SurgoTheme.build(),
            home: const MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: SurgoShell()))));
    // Allow the large asset's real isolate decode to complete before fake time.
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pumpAndSettle();
    return app;
  }

  Future<void> visibleTap(WidgetTester t, String id) async {
    await t.ensureVisible(key(id));
    // Allow the large asset's real isolate decode to complete before fake time.
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pumpAndSettle();
    await t.tap(key(id));
    // Allow the large asset's real isolate decode to complete before fake time.
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pumpAndSettle();
  }

  testWidgets(
      'review long essays use scoped licensed font and source dimensions',
      (t) async {
    for (final task in [1, 2]) {
      final app = await mount(t, UiLang.en, task);
      for (final tab in ['mark', 'l1']) {
        if (tab == 'l1') {
          app.session['wfTab'] = 'l1';
          app.go(SurgoPage.writingFeedback);
          await t.pump();
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await t.pumpAndSettle();
        }
        final sourceText = t.widget<SourceText>(find.descendant(
            of: key('review-essay'), matching: find.byType(SourceText)));
        expect(sourceText.style?.fontFamily, 'Inter');
        // 用户 2026-09-24 要求批改结果页小字放大：作文正文 12 -> 13.5。
        expect(sourceText.style?.fontSize, 13.5);
        expect(sourceText.style?.height, 1.85);
        final highlightPainter = TextPainter(
            textDirection: TextDirection.ltr,
            text: const TextSpan(
                text: 'increased',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontVariations: [
                      FontVariation('wght', 700),
                      FontVariation('opsz', 14)
                    ])))
          ..layout();
        expect(highlightPainter.width, inInclusiveRange(47, 51));
        highlightPainter.dispose();
        final size = t.getSize(key('review-essay'));
        expect(size.width, 318);
        // The user asked (2026-09-24) to enlarge review body text from 12 to
        // 13.5, so this paragraph no longer matches the source webfont height:
        // the larger size also adds line breaks, pushing it past a pure ratio.
        // Guard against runaway drift with the measured heights instead.
        // Actual screenshots remain required for fidelity.
        final expected = task == 1
            ? (tab == 'mark' ? 557.0 : 551.0)
            : (tab == 'mark' ? 890.0 : 887.0);
        expect(size.height, closeTo(expected, 46));
        expect(t.widget<Text>(key('review-annotation-1')).style?.fontFamily,
            'Inter');
        expect(t.takeException(), isNull);
      }
    }
  });

  for (final lang in UiLang.values) {
    testWidgets('review ${lang.name} geometry and home navigation', (t) async {
      final app = await mount(t, lang, 1);
      final zh = lang == UiLang.zh;

      // Home button geometry
      expect(t.getRect(key('review-home')).left, 20);
      expect(t.getRect(key('review-home')).top, 66);
      expect(t.getSize(key('review-home')).width, 44);
      expect(t.getSize(key('review-home')).height, 44);

      // Title position
      expect(t.getRect(key('review-title')).top, closeTo(136, 2));

      // Overall card geometry
      expect(t.getRect(key('review-overall')).left, 18);
      expect(t.getSize(key('review-overall')).width, 354);
      final overallTop = t.getRect(key('review-overall')).top;
      if (!zh) {
        expect(overallTop, closeTo(174, 2));
      } else {
        // CJK metrics with test font unreliable, just check reasonable range
        expect(overallTop, greaterThan(170));
        expect(overallTop, lessThan(195));
      }

      // Score chips in same row (horizontal wrap)
      final first = t.getRect(find.text('T1 6.0'));
      final second = t.getRect(find.text('T2 6.5'));
      final score = t.getRect(find.text('6.5').first);
      expect(first.top, second.top);
      expect(first.top, inInclusiveRange(score.top, score.bottom));
      expect(first.left, greaterThan(score.right));

      // Home navigation
      await visibleTap(t, 'review-home');
      expect(app.current, SurgoPage.ielts);

      expect(t.takeException(), isNull);
    });

    for (final task in [1, 2]) {
      testWidgets(
          'review ${lang.name} task$task data and prompt from QuestionBank',
          (t) async {
        final app = await mount(t, lang, task);

        // Check prompt loaded from QuestionBank
        expect(key('review-prompt'), findsOneWidget);
        final writing = QuestionBank.instance.skill('writing', app.examType);
        final prompt = writing['daily']?[task == 1 ? 'task1' : 'task2']
                ?['prompt'] as String? ??
            '';
        expect(prompt.isNotEmpty, true);
        final renderedPrompt = t.widget<SourceText>(find.descendant(
            of: key('review-prompt'), matching: find.byType(SourceText)));
        expect(renderedPrompt.data, prompt.replaceAll(RegExp(r'\s+'), ' '));
        app.session['weDraft'] =
            'UNIQUE USER DRAFT MUST NOT BECOME DEMO FEEDBACK';
        final essay = t.widget<ReviewEssay>(find.byType(ReviewEssay));
        expect(essay.source, isNot(contains('UNIQUE USER DRAFT')));
        expect(
            essay.source, contains(task == 1 ? 'internet access' : 'animal'));

        // Check essay with annotations
        expect(key('review-essay'), findsOneWidget);

        // Check annotation numbers have distinct colors (mark tab)
        if (task == 2) {
          // Task 2 has annotations 1,2 in mark mode (yellow)
          expect(key('review-annotation-1'), findsOneWidget);
          expect(key('review-annotation-2'), findsOneWidget);
          final ann1 = t.widget<Text>(key('review-annotation-1'));
          expect(ann1.style?.color, const Color(0xffc96a1f));
        }

        expect(t.takeException(), isNull);
      });

      testWidgets(
          'review ${lang.name} task$task tab switching with scroll reset',
          (t) async {
        final app = await mount(t, lang, task);

        // Initial state: mark tab active, l1 inactive
        expect(app.session['wfTab'], 'mark');
        final scrollKey = key('writing-review-scroll');
        expect(scrollKey, findsOneWidget);

        // Scroll down
        await t.drag(scrollKey, const Offset(0, -200));
        // Allow the large asset's real isolate decode to complete before fake time.
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pumpAndSettle();

        final revision1 = app.revision;

        // Switch to l1 tab
        await visibleTap(t, 'review-tab-l1');
        expect(app.session['wfTab'], 'l1');
        expect(app.revision, greaterThan(revision1));

        // Check l1-specific content
        expect(key('review-essay'), findsOneWidget);

        // Check annotation color in l1 mode (purple)
        if (task == 2) {
          expect(key('review-annotation-1'), findsOneWidget);
          final ann1L1 = t.widget<Text>(key('review-annotation-1'));
          expect(ann1L1.style?.color, const Color(0xff6b5fc7));
        }

        // Active tab handler should be null (disabled)
        final l1Tab = t.widget<ReviewTab>(key('review-tab-l1'));
        expect(l1Tab.onTap, isNull);
        expect(t.getRect(key('review-home')).top, 66);
        expect(key('review-prompt'), findsNothing);

        // Mark tab should now have handler
        final markTab = t.widget<ReviewTab>(key('review-tab-mark'));
        expect(markTab.onTap, isNotNull);

        final revision2 = app.revision;

        // Switch back to mark
        await visibleTap(t, 'review-tab-mark');
        expect(app.session['wfTab'], 'mark');
        expect(app.revision, greaterThan(revision2));

        expect(t.takeException(), isNull);
      });

      testWidgets('review ${lang.name} task$task task switching', (t) async {
        final app = await mount(t, lang, task);

        final otherTask = task == 1 ? 2 : 1;
        final revision1 = app.revision;

        // Switch task
        await visibleTap(t, 'review-task-$otherTask');
        expect(app.session['wfTask'], otherTask);
        expect(app.revision, greaterThan(revision1));

        // Source task pills both keep handlers, including the active task.
        expect(t.widget<ReviewTab>(key('review-task-$otherTask')).onTap,
            isNotNull);
        expect(t.widget<ReviewTab>(key('review-task-$task')).onTap, isNotNull);
        expect(t.getRect(key('review-home')).top, 66);
        final beforeRepeat = app.revision;
        await visibleTap(t, 'review-task-$otherTask');
        expect(app.revision, greaterThan(beforeRepeat));
        expect(app.session['wfTask'], otherTask);

        expect(t.takeException(), isNull);
      });
    }

    testWidgets('review ${lang.name} practice button navigation', (t) async {
      final app = await mount(t, lang, 1);
      app.examType = ExamType.toefl;
      app.go(SurgoPage.writingFeedback);
      // Allow the large asset's real isolate decode to complete before fake time.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();
      final prompt = t.widget<SourceText>(find.descendant(
          of: key('review-prompt'), matching: find.byType(SourceText)));
      expect(prompt.data, ''); // Source TOEFL daily has no task1 field.

      // Scroll to practice button
      await t.ensureVisible(key('review-practice'));
      // Allow the large asset's real isolate decode to complete before fake time.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();

      // Tap practice button
      await t.tap(key('review-practice'));
      // Allow the large asset's real isolate decode to complete before fake time.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();

      // Should navigate to writingDaily with IELTS
      expect(app.current, SurgoPage.writingDaily);
      expect(app.examType, ExamType.ielts);

      expect(t.takeException(), isNull);
    });

    testWidgets('review ${lang.name} end home button navigation', (t) async {
      final app = await mount(t, lang, 2);

      // Scroll to bottom
      await t.ensureVisible(key('review-end-home'));
      // Allow the large asset's real isolate decode to complete before fake time.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();

      // Tap end home button
      await t.tap(key('review-end-home'));
      // Allow the large asset's real isolate decode to complete before fake time.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();

      // Should navigate to ielts
      expect(app.current, SurgoPage.ielts);

      expect(t.takeException(), isNull);
    });
  }
}
