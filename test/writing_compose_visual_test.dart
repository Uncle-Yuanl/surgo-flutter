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
  Finder key(String s) => find.byKey(ValueKey(s));
  Future<AppState> mount(WidgetTester t, UiLang lang, String fixture,
      {bool essay = false}) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(
        current: SurgoPage.writingCompose,
        lang: lang,
        examType: fixture == 'email' ? ExamType.toefl : ExamType.ielts)
      ..session
          .addAll({'selWizCard': fixture, 'weTab': essay ? 'essay' : 'topics'});
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

  Future<void> tap(WidgetTester t, String s) async {
    await t.ensureVisible(key(s));
    await t.pumpAndSettle();
    await t.tap(key(s));
    await t.pumpAndSettle();
  }

  for (final lang in UiLang.values) {
    for (final fixture in ['t2', 't1', 'letter', 'email']) {
      testWidgets(
          'compose $fixture ${lang.name} bounds, modules, draft and inactive source clock',
          (t) async {
        final app = await mount(t, lang, fixture);
        final c = WritingController(app);
        expect(t.getRect(key('compose-home')).top, 60);
        expect(t.getSize(key('compose-home')), const Size(40, 40));
        expect(t.getRect(key('compose-cta')),
            const Rect.fromLTWH(18, 772, 354, 56));
        await tap(t, 'compose-fold');
        expect(app.session['wePlanOpen'], true);
        for (final mod in ['analysis', 'arg', 'para', 'vocab']) {
          await tap(t, 'compose-module-$mod');
          expect(key('plan-panel-$mod'), findsOneWidget);
          expect(t.takeException(), isNull);
        }
        await tap(t, 'compose-module-arg');
        final revision = app.revision;
        if (fixture == 'email') {
          expect(key('plan-arg-0'), findsNothing);
          expect(c.plan, isEmpty);
        } else {
          await tap(t, 'plan-arg-0');
          expect(c.args, {0});
          expect(app.revision, greaterThan(revision));
        }
        expect(app.session['wePlanMod'], 'arg');
        await tap(t, 'compose-fold');
        expect(app.session['wePlanMod'], '');
        await tap(t, 'compose-cta');
        expect(c.tab, 'essay');
        expect(
            t.getRect(key('compose-editor')),
            const Rect.fromLTWH(
                18, 114, 354, 658)); // external bottom16 included
        expect(t.getRect(key('compose-clock-box')).left, 36);
        expect(find.text('00:00:00'), findsOneWidget);
        expect(
            find.text(lang == UiLang.zh
                ? '0 词 / ${c.task['minWords']} 词'
                : '0 words / ${c.task['minWords']}words'),
            findsOneWidget);
        final field=t.widget<TextField>(key('essay-input'));
        expect(field.style!.letterSpacing,0);
        expect(field.style!.fontWeight,FontWeight.w400);
        expect(field.decoration!.contentPadding,EdgeInsets.zero);
        expect(field.cursorWidth,1);
        expect(field.cursorColor,const Color(0xff1c1a17));
        const draft = "I can't re-use 2026 ideas. 中文";
        await t.enterText(key('essay-input'), draft);
        await t.pump();
        expect(c.draft, draft);
        expect(
            find.text(
                '${WritingController.words(draft)} words / ${c.task['minWords']}words'),
            findsOneWidget);
        await t.pump(const Duration(seconds: 3));
        expect(find.text('00:00:00'), findsOneWidget);
        await tap(t, 'compose-tab-TOPICS');
        expect(c.draft, draft);
        await tap(t, 'compose-tab-WRITE ESSAY');
        expect(find.text('00:00:00'), findsOneWidget);
        expect(t.widget<TextField>(key('essay-input')).controller!.text, draft);
        final count = WritingController.words(draft);
        expect(
            find.text(lang == UiLang.zh
                ? '$count 词 / ${c.task['minWords']} 词'
                : '$count words / ${c.task['minWords']}words'),
            findsOneWidget);
        await tap(t, 'compose-tab-WRITE ESSAY');
        expect(find.text('00:00:00'), findsOneWidget);
        await tap(t, 'compose-home');
        expect(app.current, SurgoPage.ielts);
        await t.pump(const Duration(seconds: 5));
        expect(t.takeException(), isNull);
      });
    }
    testWidgets(
        'compose ${lang.name} zero words still submits fixed marking target',
        (t) async {
      final app = await mount(t, lang, 't2', essay: true);
      await t.tap(key('compose-cta'));
      await t.pump();
      expect(find.byType(Dialog), findsOneWidget);
      await t.pump(); // start the dialog ticker on its first rendered frame
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle(); // finish progress before starting its200ms tail
      expect(find.text('100%'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 250));
      // Verify navigation without waiting for the unrelated feedback page's
      // async resource/animation readiness (it may animate indefinitely).
      await t.pump(const Duration(milliseconds: 400));
      expect(app.current, SurgoPage.writingFeedback);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
      expect(t.takeException(), isNull);
    });
    testWidgets(
        'compose ${lang.name} preserves source inactive clock after20min',
        (t) async {
      final app = await mount(t, lang, 'email', essay: true);
      await t.pump(const Duration(seconds: 1203));
      expect(find.text('00:00:00'), findsOneWidget);
      expect(key('writing-overtime'), findsNothing);
      await tap(t, 'compose-home');
      expect(app.current, SurgoPage.ielts);
      expect(t.takeException(), isNull);
    });
  }
}
