import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/ielts_reading/reading_feedback.dart';
import 'package:surgo_flutter/features/ielts_reading/review_passage.dart';
import 'package:surgo_flutter/features/ielts_reading/review_questions.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
    await QuestionBank.load();
    await SourceNodeTranslations.load();
    await ReadingFeedbackData.load();
    for (final (family, path) in [
      ('VioletSans', 'assets/fonts/violet-sans.ttf'),
      ('Arimo', 'assets/fonts/Arimo-Bold.ttf')
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(path));
      await loader.load();
    }
  });
  Future<AppState> mount(WidgetTester t,
      {bool mock = false, UiLang lang = UiLang.en, int passage = 1}) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.readingFeedback, lang: lang)
      ..session.addAll({
        'sessionMode': mock ? 'mock' : 'daily',
        'raPas': passage,
        'readDone': {0, 1, 2}
      });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: SurgoShell()))));
    await t.pumpAndSettle();
    return app;
  }

  test(
      'RF_DEMO preserves3passages9questions5correct independent of submitted40',
      () {
    final all = ReadingFeedbackData.passages!.values
        .expand((p) => p['qs'] as List)
        .toList();
    expect(all.length, 9);
    expect(all.where((q) => rfCorrect(q, mock: true)).length, 5);
    expect(all.map((q) => q['no']), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(all.map((q) => q['kind']).toSet(), {'opts', 'pills', 'input'});
  });
  for (final lang in UiLang.values) {
    testWidgets(
        'daily ${lang.name} source content, banner geometry and highlights',
        (t) async {
      await mount(t, lang: lang);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byType(RfQuestion), findsNWidgets(3));
      expect(find.byKey(const ValueKey('rf-passage-1')), findsNothing);
      expect(t.getRect(find.byKey(const ValueKey('rf-home'))),
          const Rect.fromLTWH(20, 66, 44, 44));
      expect(t.getRect(find.byKey(const ValueKey('rf-summary'))).top, 130);
      final p = t.widget<RfPassage>(find.byType(RfPassage));
      expect(p.mock, false);
      expect(p.paragraphs.length, 4);
      expect(t.takeException(), isNull);
    });
    testWidgets(
        'mock ${lang.name} passage tabs reset source route and keep fixed score',
        (t) async {
      final app = await mount(t, mock: true, lang: lang);
      expect(find.text('5/9'), findsOneWidget);
      for (final n in [2, 3, 1, 1]) {
        final before = app.revision;
        final finder = find.byKey(ValueKey('rf-passage-$n'));
        await t.ensureVisible(finder);
        await t.tap(finder);
        await t.pumpAndSettle();
        expect(app.revision, before + 1);
        expect(app.current, SurgoPage.readingFeedback);
        expect(app.session['raPas'], n);
        expect(find.text('5/9'), findsOneWidget);
        expect(find.byType(RfQuestion), findsNWidgets(3));
        final scroll = find
            .descendant(
                of: find.byKey(const ValueKey('reading-feedback-scroll')),
                matching: find.byType(Scrollable))
            .first;
        expect(t.state<ScrollableState>(scroll).position.pixels, 0);
        expect(
            t
                .widgetList<RfQuestion>(find.byType(RfQuestion))
                .map((q) => q.q['no']),
            [n * 3 - 2, n * 3 - 1, n * 3]);
        expect(t.takeException(), isNull);
      }
    });
  }
  testWidgets(
      'mock pills preserve source widths and input labels remain source nodes',
      (t) async {
    await mount(t, mock: true, passage: 2);
    final q4 = find.byKey(const ValueKey('rf-question-4'));
    final pills = find.descendant(of: q4, matching: find.byType(Wrap));
    final wrap = t.widget<Wrap>(pills);
    expect(wrap.spacing, 8);
    expect(t.getSize(find.byWidget(wrap.children[0])).width,
        closeTo(181.992, .001));
    expect(t.getSize(find.byWidget(wrap.children[1])).width,
        closeTo(129, .001));
    await mount(t, mock: true, passage: 3);
    final chips = find.descendant(
        of: find.byKey(const ValueKey('rf-question-8')),
        matching: find.byType(Text));
    final texts = t
        .widgetList<Text>(chips)
        .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
        .join('|');
    expect(texts, contains('printed'));
    expect(texts, contains('copied'));
    expect(texts, contains('我的作答: '));
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'weakest practice clears only source selection; home preserves exam',
      (t) async {
    var app = await mount(t, mock: true);
    app.examType = ExamType.toefl;
    app.session['selReadType'] = 'tfng';
    await t.pumpAndSettle();
    final practice = find.byKey(const ValueKey('rf-practice'));
    await t.ensureVisible(practice);
    await t.tap(practice);
    await t.pumpAndSettle();
    expect(app.examType, ExamType.ielts);
    expect(app.current, SurgoPage.readingDaily);
    expect(app.session['selReadType'], isNull);
    expect(app.session['sessionMode'], 'mock');
    app = await mount(t, mock: true);
    app.examType = ExamType.toefl;
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('rf-home')));
    await t.pumpAndSettle();
    expect(app.current, SurgoPage.ielts);
    expect(app.examType, ExamType.toefl);
    expect(t.takeException(), isNull);
  });
}
