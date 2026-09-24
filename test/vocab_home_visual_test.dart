import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_home/vocab_home_page.dart';
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
  for (final lang in UiLang.values) {
    for (final exam in ExamType.values) {
      testWidgets(
          'vocab ${lang.name} ${exam.name} fixed nav source layout and routes',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final app =
            AppState(current: SurgoPage.vocab, lang: lang, examType: exam);
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: app,
            child: MaterialApp(
                theme: SurgoTheme.build(),
                home: const MediaQuery(
                    data: MediaQueryData(size: Size(390, 844)),
                    child: SurgoShell()))));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(t.getRect(key('vh-title')).top, 112);
        expect(t.getRect(key('vh-home')).top, 66);
        expect(t.getSize(key('vh-home')), const Size(24, 24));
        expect(t.getSize(key('vh-ring')), const Size(64, 64));
        expect(
            t.getSize(key('vh-stats')), Size(354, lang == UiLang.zh ? 75 : 71));
        expect(t.getSize(key('vh-book')), const Size(354, 76));
        expect(t.getSize(key('vh-pron')), const Size(354, 76));
        expect(
            find.ancestor(
                of: key('vh-review-inert'),
                matching: find.byWidgetPredicate((w)=>w is GestureDetector&&w.onTap!=null)),
            findsNothing);
        await t.tap(key('vh-review-inert'));await t.pumpAndSettle();
        expect(app.current,SurgoPage.vocab);
        expect(
            find.text(lang == UiLang.en
                ? '\u{1f3a4} Pronunciation review (0)'
                : '\u{1f3a4} 发音复习 (0)'),
            findsOneWidget);
        final rich = find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText() ==
                (lang == UiLang.en ? 'words\ndue today' : '个单词\n需今日复习'));
        expect(rich, findsOneWidget);
        for (final tier in kVocabTiers) {
          final tile = key('vh-${tier.route.name}');
          await t.ensureVisible(tile);
          await t.pumpAndSettle();
          expect(t.getSize(tile), Size(354, lang == UiLang.zh ? 158 : 144));
          expect(t.getSize(key('vh-track-${tier.route.name}')),
              const Size(320, 5));
          expect(t.getSize(key('vh-fill-${tier.route.name}')).width,
              closeTo(320 * tier.percent / 100, .01));
          expect(t.getRect(key('vh-home')).top, 66);
        }
        final targets = <String, SurgoPage>{
          'vh-test': SurgoPage.vocabTest,
          'vh-review-start': SurgoPage.vocabStudy,
          'vh-book': SurgoPage.vocabBook,
          'vh-pron': SurgoPage.vocabPron,
          for (final tier in kVocabTiers) 'vh-${tier.route.name}': tier.route,
          'vh-home': SurgoPage.ielts
        };
        for (final entry in targets.entries) {
          if (app.current != SurgoPage.vocab) {
            app.go(SurgoPage.vocab);
            await t.pumpAndSettle();
          }
          await t.ensureVisible(key(entry.key));
          await t.pumpAndSettle();
          await t.tap(key(entry.key));
          await t.pumpAndSettle();
          expect(app.current, entry.value);
          expect(t.takeException(), isNull);
        }
      });
    }
  }
}
