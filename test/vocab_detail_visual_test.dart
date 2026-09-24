import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_details/vocab_details_module.dart';
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
  for (final data in kVocabDetailData.values) {
    for (final lang in UiLang.values) {
      testWidgets(
          '${data.route.name} ${lang.name} source geometry, content, recall and exit',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final app = AppState(current: data.route, lang: lang);
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: app,
            child: MaterialApp(
                theme: SurgoTheme.build(),
                home: const MediaQuery(
                    data: MediaQueryData(size: Size(390, 844)),
                    child: SurgoShell()))));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final card = t.widget<Container>(key('vocab-detail-card'));
        final dec = card.decoration! as BoxDecoration;
        expect(dec.border, isNull);
        expect(dec.boxShadow, isNotEmpty);
        expect(card.padding, const EdgeInsets.all(20));
        expect(t.getSize(key('vocab-detail-card')).width, 354);
        final word = t.widget<SourceText>(key('vocab-detail-word'));
        expect(word.data, data.word);
        expect(word.style!.fontSize, 28);
        expect(t.getSize(key('vocab-detail-speaker')), const Size(18, 18));
        expect(
            find.ancestor(
                of: key('vocab-detail-speaker'),
                matching: find.byType(GestureDetector)),
            findsNothing);
        final ys = ['exit', 'demo', 'progress', 'count']
            .map((s) => t.getCenter(key('vocab-detail-$s')).dy)
            .toList();
        expect(
            ys.reduce((a, b) => a > b ? a : b) -
                ys.reduce((a, b) => a < b ? a : b),
            lessThan(.1));
        final def = t.widget<Container>(key('vocab-detail-definition'));
        expect(def.padding, const EdgeInsets.fromLTRB(19, 14, 16, 14));
        expect(app.session[kVocabDetailPageKey], data.route);
        for (final label in ['没想起', '有点模糊', '认识']) {
          if (app.current != data.route) {
            app.go(data.route);
            await t.pumpAndSettle();
          }
          final button = key('vocab-detail-recall-$label');
          await t.ensureVisible(button);
          await t.pumpAndSettle();
          final siblings = ['没想起', '有点模糊', '认识']
              .map((s) => t.getRect(key('vocab-detail-recall-$s')))
              .toList();
          expect(siblings[0].top, siblings[1].top);
          expect(siblings[1].top, siblings[2].top);
          expect(siblings[1].left - siblings[0].right, closeTo(10, .01));
          expect(siblings[0].height,
              greaterThanOrEqualTo(lang == UiLang.zh ? 61 : 69));
          if (lang == UiLang.en) {
            for (final english in ["Didn't recall", 'A bit fuzzy', 'Know it']) {
              expect(find.text(english), findsOneWidget);
            }
          }
          await t.drag(key('vocab-detail-scroll'), const Offset(0, -1500));
          await t.pumpAndSettle();
          expect(
              t.getRect(key('vocab-detail-recall')).bottom, closeTo(844, .1));
          expect(t.takeException(), isNull);
          await t.tap(button);
          await t.pumpAndSettle();
          expect(app.current, data.recallTarget);
        }
        app.go(data.route);
        await t.pumpAndSettle();
        await t.ensureVisible(key('vocab-detail-exit'));
        await t.pumpAndSettle();
        await t.tap(key('vocab-detail-exit'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocab);
        expect(t.takeException(), isNull);
      });
    }
  }
}
