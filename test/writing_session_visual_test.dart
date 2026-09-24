import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'package:surgo_flutter/features/writing_workspace/writing_controller.dart';
import 'package:surgo_flutter/features/writing_workspace/writing_source_chart.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
    await QuestionBank.load();
    for (final f in [
      ('VioletSans', 'violet-sans.ttf'),
      ('Arimo', 'Arimo-Bold.ttf')
    ]) {
      await (FontLoader(f.$1)..addFont(rootBundle.load('assets/fonts/${f.$2}')))
          .load();
    }
  });
  Finder key(String s) => find.byKey(ValueKey(s));
  test('chart matches source 300x190 and rounded 0..100 coordinate arithmetic',
      () {
    final app = AppState()..session['selWizCard'] = 't1';
    final task = WritingController(app).task;
    final rs = WritingChartPainter.barRects(task);
    expect(rs, hasLength(8));
    expect(rs.first, const Rect.fromLTWH(38.6, 89.1, 17.6, 74.9));
    expect(rs[1], const Rect.fromLTWH(62.3, 131.2, 17.6, 32.8));
    expect(rs.last, const Rect.fromLTWH(261.8, 43.9, 17.6, 120.1));
    expect((task['chartSeries'] as List).first['data'], [48, 66, 81, 92]);
  });
  for (final lang in UiLang.values) {
    for (final fixture in ['t2', 't1', 'letter', 'email']) {
      testWidgets(
          'confirm $fixture ${lang.name} source chrome prompt chart and transitions',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final app = AppState(
            current: SurgoPage.writingSession,
            lang: lang,
            examType: fixture == 'email' ? ExamType.toefl : ExamType.ielts)
          ..session['selWizCard'] = fixture;
        final c = WritingController(app), raw = c.task['prompt'] as String;
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: app,
            child: MaterialApp(
                theme: SurgoTheme.build(),
                home: const MediaQuery(
                    data: MediaQueryData(size: Size(390, 844)),
                    child: SurgoShell()))));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(t.getRect(key('writing-session-home')).top, 66);
        expect(t.getSize(key('writing-session-home')), const Size(24, 24));
        for (var i = 1; i <= 4; i++) {
          expect(t.getSize(key('writing-step-$i')), const Size(19, 19));
          expect(t.getRect(key('writing-step-$i')).top, 108);
        }
        expect(t.widget<SourceText>(key('writing-prompt')).data,
            raw.replaceAll(RegExp(r'\s+'), ' '));
        expect(c.task['prompt'], raw);
        expect(t.getRect(key('writing-prompt')).left, 39);
        expect(t.getSize(key('writing-prompt-card')).width, 354);
        if (fixture == 't1') {
          expect(key('writing-chart-open'), findsOneWidget);
          await t.ensureVisible(key('writing-chart-open'));
          await t.pumpAndSettle();
          await t.tap(key('writing-chart-open'));
          await t.pumpAndSettle();
          expect(find.byType(Dialog), findsOneWidget);
          expect(key('writing-chart-plot'), findsNWidgets(2));
          await t.tap(key('writing-chart-close'));
          await t.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing);
        } else {
          expect(key('writing-chart-open'), findsNothing);
        }
        await t.ensureVisible(key('writing-confirm'));
        await t.pumpAndSettle();
        expect(t.getRect(key('writing-session-home')).top, 66);
        c.args.add(1);
        c.vocab.add(1);
        c.step = 'vocab';
        await t.tap(key('writing-confirm'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.writingPlan);
        expect(c.step, 'analysis');
        expect(c.args, isEmpty);
        expect(c.vocab, isEmpty);
        app.go(SurgoPage.writingSession);
        await t.pumpAndSettle();
        await t.tap(key('writing-session-home'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.ielts);
        expect(t.takeException(), isNull);
      });
    }
  }
}
