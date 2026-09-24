import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_pron_study/vocab_pron_study_module.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
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
    for (final d in kVocabPronStudyData.values) {
      testWidgets(
          '${d.route.name} ${lang.name} source card and static state actions',
          (t) async {
        final app = await mount(t, d.route, lang);
        final card = t.widget<Container>(key('vp-card'));
        expect(card.padding, const EdgeInsets.fromLTRB(24, 44, 24, 52));
        expect((card.decoration! as BoxDecoration).border, isNull);
        expect(t.getRect(key('vp-card')).top, lang == UiLang.zh ? 96 : 92);
        expect(t.getSize(key('vp-spk')), const Size(30, 30));
        expect(
            find.ancestor(
                of: key('vp-spk'), matching: find.byType(GestureDetector)),
            findsNothing);
        final word = t.widget<SourceText>(key('vp-word'));
        expect(word.data, d.word);
        expect(word.style!.fontSize, 44);
        expect(key('vp-example'),
            d.example == null ? findsNothing : findsOneWidget);
        if (d.phase == VocabPronPhase.judge) {
          final bad = t.getRect(key('vp-judge-bad')),
              good = t.getRect(key('vp-judge-good'));
          expect(bad.top, good.top);
          expect(bad.height, 52);
          expect(good.left - bad.right, 16);
          for (final control in [
            'vp-judge-bad',
            'vp-judge-good',
            'vp-retake'
          ]) {
            if (app.current != d.route) {
              app.go(d.route);
              await t.pumpAndSettle();
            }
            await t.tap(key(control));
            await t.pumpAndSettle();
            expect(app.current, control == 'vp-retake' ? d.retake : d.forward);
          }
        } else {
          final control =
              d.phase == VocabPronPhase.recording ? 'vp-mic-rec' : 'vp-mic';
          expect(t.getSize(key(control)), const Size(88, 88));
          expect(t.getSize(key('vp-mic-icon')), const Size(36, 36));
          expect(
              find.ancestor(
                  of: key('vp-manual'), matching: find.byType(GestureDetector)),
              findsNothing);
          await t.pump(const Duration(seconds: 30));
          expect(app.current,
              d.route); // source static mock recording: no timer/auto score
          await t.tap(key(control));
          await t.pumpAndSettle();
          expect(app.current, d.forward);
        }
        app.go(d.route);
        await t.pumpAndSettle();
        await t.tap(key('vocab-detail-exit'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocabPron);
        expect(t.takeException(), isNull);
      });
    }
    testWidgets(
        'pron completion ${lang.name} original fixed counts and footer targets',
        (t) async {
      final app = await mount(t, SurgoPage.vocabPronDone, lang);
      expect(t.getSize(key('vocab-done-image')).width, 180);
      for (final count in ['30', '14', '32']) {
        expect(find.text(count), findsOneWidget);
      }
      expect(t.widget<SourceText>(key('vocab-done-title')).span!.toPlainText(),
          '今天的发音复习完成啦！');
      expect(t.getRect(key('vocab-done-back')).top,
          t.getRect(key('vocab-done-review')).top);
      await t.tap(key('vocab-done-review'));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPronStudy);
      app.go(SurgoPage.vocabPronDone);
      await t.pumpAndSettle();
      await t.tap(key('vocab-done-back'));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPron);
      expect(t.takeException(), isNull);
    });
  }
}
