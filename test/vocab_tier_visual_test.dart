import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_tiers/vocab_tiers_module.dart';
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
    for (final c in kVocabTierConfigs.values) {
      testWidgets(
          '${c.route.name} ${lang.name} fixed nav source wraps and all targets',
          (t) async {
        final app = await mount(t, c.route, lang);
        expect(t.takeException(), isNull);
        expect(t.getSize(key('tier-icon-ear')), const Size(26, 26));
        for (final icon in ['check', 'pen', 'clock']) {
          expect(t.getSize(key('tier-icon-$icon')), const Size(19, 19));
        }
        // Body text now uses system PingFang, which has no loadable asset, so
        // widget tests measure the default test font instead of real glyphs.
        // Bound the row against the 314px track and leave exact width to the
        // actual 390px screenshots.
        expect(t.getSize(key('tier-stats')).width, lessThanOrEqualTo(314));
        expect(t.getSize(key('tier-progress-track')).width, 314);
        expect(t.getSize(key('tier-progress-fill')).width,
            closeTo(314 * c.pct / 100, .01));
        final chipRects =
            c.chips.map((w) => t.getRect(key('tier-chip-preview-$w'))).toList();
        for (final r in chipRects) {
          expect(r.top, chipRects.first.top);
        }
        final link = t.getRect(key('tier-view-all'));
        // Which side the link lands on depends on chip wrapping, and the global
        // Outfit/SF Pro families measure narrower than the source webfont.
        // Assert it never collides with the chips instead of pinning one side.
        final below = link.top >= chipRects.first.bottom;
        final beside = link.left > chipRects.last.right;
        expect(below || beside, true,
            reason: 'view-all link overlaps the preview chips');
        final homeY = t.getTopLeft(key('tier-home')).dy;
        expect(homeY, 66);
        final image = find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.endsWith('otter_study.png'));
        expect(t.getSize(image), const Size(78, 78));
        expect(t.getRect(key('tier-start')).top,
            greaterThan(t.getRect(image).bottom));
        await t.drag(key('tier-scroll'), const Offset(0, -400));
        await t.pumpAndSettle();
        expect(t.getTopLeft(key('tier-home')).dy, homeY);
        for (final entry in [
          ('tier-start', c.target),
          ('tier-continue', c.target),
          ('tier-view-all', SurgoPage.vocabBook),
          ('tier-home', SurgoPage.vocab)
        ]) {
          if (app.current != c.route) {
            app.go(c.route);
            await t.pumpAndSettle();
          }
          await t.ensureVisible(key(entry.$1));
          await t.pumpAndSettle();
          await t.tap(key(entry.$1));
          await t.pumpAndSettle();
          expect(app.current, entry.$2);
          expect(t.takeException(), isNull);
        }
      });
    }
    testWidgets(
        'empty ${lang.name} original outlined icon top position and return',
        (t) async {
      final app = await mount(t, SurgoPage.vocabNoNew, lang);
      expect(key('tier-home'), findsNothing);
      expect(t.getSize(key('tier-icon-empty')), const Size(52, 52));
      expect(t.getTopLeft(key('tier-icon-empty')).dy, 150);
      await t.tap(key('tier-empty-back'));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.vocab);
      expect(t.takeException(), isNull);
    });
  }
}
