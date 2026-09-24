import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/ielts_listening/listening_data.dart';
import 'package:surgo_flutter/features/ielts_listening/feedback_body.dart';
import 'package:surgo_flutter/features/ielts_listening/feedback_questions.dart';
import 'package:surgo_flutter/features/ielts_reading/review_style.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
    await QuestionBank.load();
    await IeltsListeningData.load();
    for (final (family, path) in [
      ('VioletSans', 'assets/fonts/violet-sans.ttf'),
      ('Arimo', 'assets/fonts/Arimo-Bold.ttf')
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(path));
      await loader.load();
    }
  });
  Future<AppState> mount(WidgetTester t,
      {UiLang lang = UiLang.en, bool mock = false, int part = 1}) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.listeningFeedback, lang: lang)
      ..session.addAll({
        'sessionMode': mock ? 'mock' : 'daily',
        'lisPart': 's$part',
        'lfPart': part
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

  for (final lang in UiLang.values) {
    testWidgets(
        'listening review ${lang.name} four daily parts fixed score exact content',
        (t) async {
      for (var p = 1; p <= 4; p++) {
        final app = await mount(t, lang: lang, part: p);
        expect(find.text('2/4'), findsOneWidget);
        expect(find.text('6.5'), findsOneWidget);
        expect(find.byType(ListeningReviewQuestion),
            findsNWidgets([4, 3, 2, 2][p - 1]));
        expect(find.byKey(ValueKey('lf-part-$p')), findsOneWidget);
        for (final other in [1, 2, 3, 4].where((n) => n != p)) {
          expect(find.byKey(ValueKey('lf-part-$other')), findsNothing);
        }
        expect(
            t
                .widget<ListeningReviewBody>(find.byType(ListeningReviewBody))
                .part,
            p);
        expect(t.getSize(find.byKey(const ValueKey('lf-play-inert'))),
            const Size(32, 32));
        expect(app.session['lfPart'], p);
        expect(t.takeException(), isNull);
      }
    });
    testWidgets(
        'listening mock ${lang.name} local180ms swap keeps scroll and skips applyLang',
        (t) async {
      final app = await mount(t, lang: lang, mock: true);
      final revision = app.revision;
      final tab = find.byKey(const ValueKey('lf-part-2'));
      await t.ensureVisible(tab);
      await t.pumpAndSettle();
      final scroll = find
          .descendant(
              of: find.byKey(const ValueKey('listening-feedback-scroll')),
              matching: find.byType(Scrollable))
          .first;
      final pos = t.state<ScrollableState>(scroll).position.pixels;
      await t.tap(tab);
      await t.pump(const Duration(milliseconds: 179));
      expect(find.text('Part 2'), findsOneWidget);
      expect(
          t.widget<ListeningReviewBody>(find.byType(ListeningReviewBody)).part,
          1);
      await t.pump(const Duration(milliseconds: 2));
      await t.pumpAndSettle();
      expect(app.revision, revision);
      expect(app.session['lfPart'], 2);
      expect(
          t.widget<ListeningReviewBody>(find.byType(ListeningReviewBody)).part,
          2);
      expect(t.state<ScrollableState>(scroll).position.pixels, closeTo(pos, 1));
      final scope = find
          .ancestor(
              of: find.byType(ListeningReviewBody),
              matching: find.byType(ReviewTextScope))
          .first;
      expect(t.widget<ReviewTextScope>(scope).raw, true);
      expect(find.text('Part 2'), findsOneWidget);
      expect(find.text('原文'), findsOneWidget);
      await t.ensureVisible(tab);
      await t.tap(tab);
      await t.pumpAndSettle();
      expect(app.revision, revision);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
      'speed only updates current label; rebuilt Part resets1X; play stays inert',
      (t) async {
    final app = await mount(t, mock: true);
    final play = find.byKey(const ValueKey('lf-play-inert'));
    await t.ensureVisible(play);
    await t.tap(play);
    await t.pump(const Duration(seconds: 3));
    expect(find.descendant(of: play, matching: find.byType(CustomPaint)),
        findsOneWidget);
    final speed = find.byKey(const ValueKey('lf-speed'));
    await t.ensureVisible(speed);
    // The shell's global settings/notification buttons float over y58..98 on the
    // right edge, so a control scrolled into that band is genuinely covered.
    // Nudge the strip below the band before tapping instead of tapping through.
    await t.drag(find.byKey(const ValueKey('listening-feedback-scroll')),
        const Offset(0, 45));
    await t.pumpAndSettle();
    await t.tap(speed);
    await t.pumpAndSettle();
    await t.tap(find.text('1.5X').last);
    await t.pumpAndSettle();
    expect(app.session['lisSpeed'], '1.5X');
    expect(find.text('1.5X'), findsOneWidget);
    final tab = find.byKey(const ValueKey('lf-part-2'));
    await t.ensureVisible(tab);
    await t.tap(tab);
    await t.pumpAndSettle();
    expect(find.text('1X'), findsOneWidget);
    expect(app.session['lisSpeed'], '1.5X');
    expect(t.takeException(), isNull);
  });
}
