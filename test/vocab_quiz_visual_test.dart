import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_quiz/vocab_quiz_module.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
    final buttonFont = FontLoader('Arimo')
      ..addFont(rootBundle.load('assets/fonts/Arimo-Bold.ttf'));
    await buttonFont.load();
  });
  Finder key(String s) => find.byKey(ValueKey(s));
  Future<AppState> mount(WidgetTester t, SurgoPage page, UiLang lang) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: page, lang: lang);
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
    testWidgets('${lang.name} intro source card, ruler and three exits',
        (t) async {
      final app = await mount(t, SurgoPage.vocabTest, lang);
      expect(t.getSize(key('vocab-test-ruler')), const Size(64, 64));
      final card = t.getRect(key('vocab-test-card'));
      // QuizCard includes the source 24px top margin; white begins at y130.
      expect(card.left, 18);
      expect(card.width, 354);
      expect(card.top, 106);
      expect(t.getSize(key('vocab-test-start')).width, 280);
      for (final control in [
        'vocab-test-start',
        'vocab-test-skip',
        'vocab-test-home'
      ]) {
        if (app.current != SurgoPage.vocabTest) {
          app.go(SurgoPage.vocabTest);
          await t.pumpAndSettle();
        }
        await t.tap(key(control));
        await t.pumpAndSettle();
        expect(app.current,
            control.endsWith('start') ? SurgoPage.vocabTestQ : SurgoPage.vocab);
      }
      expect(t.takeException(), isNull);
    });
    testWidgets('${lang.name} quiz node translation and all original branches',
        (t) async {
      final app = await mount(t, SurgoPage.vocabTestQ, lang);
      expect(t.getSize(key('vocab-quiz-speaker')), const Size(26, 26));
      expect(
          find.ancestor(
              of: key('vocab-quiz-speaker'),
              matching: find.byType(GestureDetector)),
          findsNothing);
      final word = t.widget<SourceText>(key('vocab-quiz-word'));
      expect(word.data, 'Identify');
      expect(word.style!.fontSize, 32);
      expect(
          find.text(
              lang == UiLang.en ? 'identify; confirm; recognise' : '识别；确认；认出'),
          findsOneWidget);
      final a = t.getRect(key('vocab-option-A')),
          b = t.getRect(key('vocab-option-B'));
      expect(a.width, 354);
      expect(b.top - a.bottom, 12);
      for (final o in kVocabQuizOptions) {
        if (app.current != SurgoPage.vocabTestQ) {
          app.go(SurgoPage.vocabTestQ);
          await t.pumpAndSettle();
        }
        await t.tap(key('vocab-option-${o.key}'));
        await t.pumpAndSettle();
        expect(app.current,
            o.correct ? SurgoPage.vocabTier2 : SurgoPage.vocabTier1);
      }
      for (final control in ['skip', 'exit']) {
        app.go(SurgoPage.vocabTestQ);
        await t.pumpAndSettle();
        await t.tap(key('vocab-quiz-$control'));
        await t.pumpAndSettle();
        expect(app.current,
            control == 'skip' ? SurgoPage.vocabTier1 : SurgoPage.vocab);
      }
      expect(t.takeException(), isNull);
    });
    for (final pass in [true, false]) {
      testWidgets(
          '${lang.name} result $pass horizontal actions and fixed target',
          (t) async {
        final page = pass ? SurgoPage.vocabTestPass : SurgoPage.vocabTestFail;
        final app = await mount(t, page, lang);
        expect(t.getSize(key('vocab-result-target')), const Size(48, 48));
        final start = t.getRect(key('vocab-result-start')),
            back = t.getRect(key('vocab-result-back'));
        expect(start.top, back.top);
        expect(start.height, back.height);
        expect(back.left - start.right, 12);
        await t.tap(key('vocab-result-start'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocabStudy4);
        app.go(page);
        await t.pumpAndSettle();
        await t.tap(key('vocab-result-back'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocab);
        expect(t.takeException(), isNull);
      });
    }
    testWidgets(
        '${lang.name} completion original stats and side-by-side actions',
        (t) async {
      final app = await mount(t, SurgoPage.vocabDone, lang);
      expect(t.getSize(key('vocab-done-image')).width, 180);
      for (final value in ['2', '1', '32']) {
        expect(find.text(value), findsOneWidget);
        final icon = t.widget<Container>(key('vocab-done-stat-$value'));
        expect(icon.constraints!.maxWidth, 48);
        expect(icon.constraints!.maxHeight, 48);
        // Container render bounds also include its 10px external margin.
        expect(t.getSize(key('vocab-done-stat-$value')), const Size(48, 58));
      }
      final back = t.getRect(key('vocab-done-back')),
          review = t.getRect(key('vocab-done-review'));
      expect(back.top, review.top);
      expect(review.left - back.right, 12);
      final title = t.widget<SourceText>(key('vocab-done-title'));
      expect(title.span!.toPlainText(), '今天的词汇复习完成啦！');
      await t.tap(key('vocab-done-review'));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy);
      app.go(SurgoPage.vocabDone);
      await t.pumpAndSettle();
      await t.tap(key('vocab-done-back'));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.vocab);
      expect(t.takeException(), isNull);
    });
  }
}
