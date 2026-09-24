import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
  });
  Finder key(String s) => find.byKey(ValueKey(s));
  for (final page in [
    SurgoPage.vocabWord,
    SurgoPage.vocabWord2,
    SurgoPage.vocabWord3,
    SurgoPage.vocabWord4,
    SurgoPage.vocabPronWord,
    SurgoPage.vocabPronWord2
  ]) {
    for (final lang in UiLang.values) {
      testWidgets('${page.name} ${lang.name} vw layout and inert controls',
          (t) async {
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
        expect(t.takeException(), isNull);
        expect(t.getRect(key('word-main')).top, 106);
        expect(t.getSize(key('word-main')).width, 354);
        expect(t.widget<Container>(key('word-main')).padding,
            const EdgeInsets.fromLTRB(22, 22, 22, 26));
        // Container decoration adds borders itself: verify rendered coordinates,
        // not only padding constants (source DOM: main text x41,y129; definition x62).
        expect(t.getTopLeft(key('word-title')), const Offset(41, 129));
        expect(t.getRect(key('word-definition')).left, 41);
        expect(t.getRect(key('word-definition-title')).left, 62);
        expect(t.getRect(key('word-example')).width, 308);
        expect(t.widget<SourceText>(key('word-title')).style!.fontSize, 32);
        expect(t.getSize(key('word-icon-speaker')), const Size(22, 22));
        expect(t.getSize(key('word-icon-star')), const Size(17, 17));
        for (final name in ['word-icon-speaker', 'word-remove-label']) {
          expect(
              find.ancestor(
                  of: key(name), matching: find.byType(GestureDetector)),
              findsNothing);
        }
        expect(
            (t.widget<Container>(key('word-definition')).decoration!
                    as BoxDecoration)
                .color,
            const Color(0xfffdf6e3));
        expect(
            (t.widget<Container>(key('word-example')).decoration!
                    as BoxDecoration)
                .color,
            const Color(0xfff6f4ef));
        final y = t.getTopLeft(key('word-back')).dy;
        await t.drag(key('word-scroll'), const Offset(0, -1600));
        await t.pumpAndSettle();
        expect(t.getTopLeft(key('word-back')).dy, y);
        for (final icon in ['info', 'link', 'ban', 'family', 'speak']) {
          expect(t.getSize(key('word-icon-$icon')), const Size(18, 18));
        }
        await t.tap(key('word-back'));
        await t.pumpAndSettle();
        expect(
            app.current,
            page.name.startsWith('vocabPron')
                ? SurgoPage.vocabPron
                : SurgoPage.vocabBook);
        expect(t.takeException(), isNull);
      });
    }
  }
}
