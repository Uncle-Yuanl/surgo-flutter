import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
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
  for (final pron in [false, true]) {
    for (final lang in UiLang.values) {
      testWidgets(
          'book $pron ${lang.name} source grid fixed nav cards and targets',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final page = pron ? SurgoPage.vocabPron : SurgoPage.vocabBook;
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
        for (var i = 0; i < 4; i++) {
          final stat = t.getSize(key('book-stat-$i'));
          // Width stays on the source grid; height follows the label text,
          // which in English now wraps with system PingFang metrics (76 -> 80).
          expect(stat.width, 171);
          expect(stat.height, lang == UiLang.zh ? 76 : 80);
          expect(t.getSize(key('book-stat-icon-$i')), const Size(44, 44));
        }
        expect(t.getRect(key('book-stat-0')).top,
            t.getRect(key('book-stat-1')).top);
        expect(
            t.getRect(key('book-stat-2')).top -
                t.getRect(key('book-stat-0')).bottom,
            12);
        if (pron && lang == UiLang.en) {
          expect(t.getRect(key('book-review')).left, closeTo(200, .5));
          expect(t.getSize(key('book-review')), const Size(208, 39));
        } else {
          expect(t.getRect(key('book-review')).right, 370);
        }
        for (final name in ['filter', 'search', 'sort', 'view']) {
          expect(
              find.ancestor(
                  of: key('book-toolbar-$name'),
                  matching: find.byType(InkWell)),
              findsNothing);
        }
        final navY = t.getTopLeft(key('book-home')).dy;
        final routes = pron
            ? {
                'Identify': SurgoPage.vocabPronWord,
                'Adapt': SurgoPage.vocabPronWord2
              }
            : {
                'Identify': SurgoPage.vocabWord,
                'Adapt': SurgoPage.vocabWord2,
                'Analyse': SurgoPage.vocabWord3,
                'Context': SurgoPage.vocabWord4
              };
        for (final e in routes.entries) {
          if (app.current != page) {
            app.go(page);
            await t.pumpAndSettle();
          }
          final card = key('book-card-${e.key}');
          await t.ensureVisible(card);
          await t.pumpAndSettle();
          expect(t.getSize(card).width, 354);
          expect(t.getSize(key('book-speaker-${e.key}')), const Size(15, 15));
          expect(t.getTopLeft(key('book-home')).dy, navY);
          if (pron && e.key == 'Adapt') {
            final material = t.widget<Material>(
                find.ancestor(of: card, matching: find.byType(Material)).first);
            expect((material.shape! as RoundedRectangleBorder).side.color,
                const Color(0xffa7d98a));
          }
          await t.tap(card);
          await t.pumpAndSettle();
          expect(app.current, e.value);
        }
        app.go(page);
        await t.pumpAndSettle();
        await t.tap(key('book-review'));
        await t.pumpAndSettle();
        expect(app.current,
            pron ? SurgoPage.vocabPronStudy : SurgoPage.vocabStudy);
        app.go(page);
        await t.pumpAndSettle();
        await t.tap(key('book-home'));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocab);
        expect(t.takeException(), isNull);
      });
    }
  }
}
