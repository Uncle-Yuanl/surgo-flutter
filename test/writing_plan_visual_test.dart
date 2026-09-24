import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/writing_workspace/writing_controller.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
  });
  test(
      'source parasByArg supports both array and object, preserving both argument branches',
      () {
    for (final fixture in ['t1', 't2']) {
      final c = WritingController(AppState()..session['selWizCard'] = fixture);
      for (var i = 0; i < 2; i++) {
        c.pickArg(i);
        final by = c.plan['parasByArg'];
        expect(c.paras, by is List ? by[i] : by['$i']);
        expect(c.paras.length, 4);
      }
    }
  });
  Finder key(String s) => find.byKey(ValueKey(s));
  Future<void> visibleTap(WidgetTester t, String id) async {
    await t.ensureVisible(key(id));
    await t.pumpAndSettle();
    await t.tap(key(id));
    await t.pumpAndSettle();
  }

  Future<AppState> mount(WidgetTester t, UiLang lang, String fixture) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(
        current: SurgoPage.writingPlan,
        lang: lang,
        examType: fixture == 'email' ? ExamType.toefl : ExamType.ielts)
      ..session['selWizCard'] = fixture;
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
            theme: SurgoTheme.build(),
            home: const MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: SurgoShell()))));
    await t.pumpAndSettle();
    return app;
  }

  for (final lang in UiLang.values) {
    testWidgets(
        'plan ${lang.name} gated steps, source selection lifecycle and footer',
        (t) async {
      final app = await mount(t, lang, 't2');
      final c = WritingController(app);
      expect(t.getRect(key('plan-panel-analysis')).top, 137);
      expect(t.getSize(key('plan-panel-analysis')).width, 354);
      final pit = t.widget<Container>(key('plan-pitfall'));
      expect((pit.decoration as BoxDecoration).color, const Color(0xfffdecef));
      expect(t.getRect(key('writing-plan-home')).top, 66);
      await visibleTap(t, 'plan-row-arg');
      expect(c.step, 'arg');
      if (lang == UiLang.zh) {
        expect(find.text('应禁止动物实验'), findsOneWidget);
      }
      await visibleTap(t, 'plan-row-para');
      expect(c.step, 'arg');
      expect(find.byType(AlertDialog), findsOneWidget);
      final dialogContext = t.element(find.byType(AlertDialog));
      Navigator.of(dialogContext).pop();
      await t.pumpAndSettle();
      await visibleTap(t, 'plan-next');
      expect(c.step, 'arg');
      expect(find.byType(AlertDialog), findsOneWidget);
      Navigator.of(t.element(find.byType(AlertDialog))).pop();
      await t.pumpAndSettle();
      final revision = app.revision;
      await visibleTap(t, 'plan-arg-1');
      expect(c.args, {1});
      expect(app.revision, greaterThan(revision));
      await visibleTap(t, 'plan-next');
      expect(c.step, 'para');
      expect(c.paras.first['text'], contains('qualified'));
      expect(t.getRect(key('writing-plan-home')).top, 66);
      await visibleTap(t, 'plan-next');
      expect(c.step, 'vocab');
      expect(key('plan-add-vocab'), findsNothing);
      final before = app.revision;
      await visibleTap(t, 'plan-vocab-0');
      expect(c.vocab, {0});
      expect(app.revision, before);
      expect(key('plan-add-vocab'), findsOneWidget);
      await t.ensureVisible(key('plan-add-vocab'));
      await t.pumpAndSettle();
      expect(t.getSize(key('plan-add-vocab')).height, 52);
      expect(t.getSize(key('plan-next')).height, 52);
      expect(t.getSize(key('plan-prev')).height, 47);
      final nextText = find.descendant(
          of: key('plan-next'), matching: find.byType(RichText));
      // Test renderer rounds the 16.8px line box to17; two lines would be34.
      expect(t.getSize(nextText).height,17);
      expect(t.getSize(key('plan-next')).width,
          greaterThan(t.getSize(key('plan-add-vocab')).width));
      final selection = Set<int>.from(c.vocab);
      await visibleTap(t, 'plan-add-vocab');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(c.vocab, selection);
      Navigator.of(t.element(find.byType(AlertDialog))).pop();
      await t.pumpAndSettle();
      await visibleTap(t, 'plan-vocab-0');
      expect(c.vocab, isEmpty);
      expect(key('plan-add-vocab'), findsNothing);
      await visibleTap(t, 'plan-prev');
      expect(c.step, 'para');
      await visibleTap(t, 'plan-next');
      expect(c.step, 'vocab');
      await visibleTap(t, 'plan-next');
      expect(app.current, SurgoPage.writingCompose);
      expect(c.tab, 'topics');
      expect(t.takeException(), isNull);
    });
    for (final fixture in ['t1', 'letter', 'email']) {
      testWidgets(
          'plan $fixture ${lang.name} data panels and unchanged prev/home',
          (t) async {
        final app = await mount(t, lang, fixture);
        final c = WritingController(app);
        final source = c.task['prompt'];
        for (final step in WritingController.steps) {
          c.step = step;
          app.go(SurgoPage.writingPlan);
          await t.pumpAndSettle();
          expect(key('plan-panel-$step'), findsOneWidget);
          expect(t.takeException(), isNull);
          expect(c.task['prompt'], source);
        }
        c.step = 'analysis';
        app.go(SurgoPage.writingPlan);
        await t.pumpAndSettle();
        await visibleTap(t, 'plan-prev');
        expect(app.current, SurgoPage.writingSession);
        app.go(SurgoPage.writingPlan);
        await t.pumpAndSettle();
        await visibleTap(t, 'writing-plan-home');
        expect(app.current, SurgoPage.ielts);
        expect(t.takeException(), isNull);
      });
    }
  }
}
