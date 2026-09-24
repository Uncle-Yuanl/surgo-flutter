import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/report/report_page.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
  });
  Future<AppState> mount(WidgetTester t, UiLang lang) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.report, lang: lang);
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child:
            MaterialApp(theme: SurgoTheme.build(), home: const SurgoShell())));
    await t.pumpAndSettle();
    return app;
  }

  testWidgets('report radar grows for 850ms and settles without changing data',
      (t) async {
    final app = await mount(t, UiLang.en);
    final animation = find.byType(TweenAnimationBuilder<double>);
    expect(t.widget<TweenAnimationBuilder<double>>(animation).duration,
        const Duration(milliseconds: 850));
    app.go(SurgoPage.report);
    await t.pump();
    // AnimatedSwitcher retains the previous page during its 280ms transition.
    final paint = find.descendant(of:find.byKey(ValueKey('report-${app.revision}')),
      matching:find.byKey(const ValueKey('report-radar-paint')));
    dynamic painter = t.widget<CustomPaint>(paint).painter;
    expect(painter.growth, 0);
    expect(painter.alpha, 0);
    await t.pump(const Duration(milliseconds: 425));
    painter = t.widget<CustomPaint>(paint).painter;
    expect(painter.growth, const Cubic(.34, 1.4, .5, 1).transform(.5));
    await t.pump(const Duration(milliseconds: 425));
    painter = t.widget<CustomPaint>(paint).painter;
    expect(painter.growth, 1);
    expect(painter.alpha, 1);
    expect(app.current, SurgoPage.report);
    expect(t.takeException(), isNull);
  });

  for (final lang in UiLang.values) {
    testWidgets('report ${lang.name} full review and fixed source fixture',
        (t) async {
      await mount(t, lang);
      final w =
          t.widget<Text>(find.byKey(const ValueKey('report-review-body')));
      final s = w.textSpan!.toPlainText();
      expect(s, contains('6.3'));
      expect(s, contains('0.7'));
      if (lang == UiLang.en) {
        expect(s, contains('in a month.'));
        expect(s, contains('strength — detail'));
        expect(s, contains('breakthrough — read'));
        expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(s), false);
      }
      expect(find.byType(ReportBackground), findsOneWidget);
      final d = t.widget<DecoratedBox>(find.descendant(
          of: find.byType(ReportBackground),
          matching: find.byType(DecoratedBox)));
      final surface = d.decoration as BoxDecoration;
      expect(surface.gradient, isNull);
      expect(surface.color, const Color(0xfffbf7ef));
      expect(
          t.getSize(find.byKey(const ValueKey('report-compare'))).width, 306);
      expect(find.byType(Scrollbar), findsNothing);
      final labels = t
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .toList();
      if (lang == UiLang.en) {
        expect(labels, contains('Your Listeningthan 88% of your peers'));
        expect(labels, contains('Your ReadingAhead of only 34% of your peers'));
      }
      expect(t.takeException(), isNull);
    });
    testWidgets(
        'report ${lang.name} subscription source local mutation resets on render',
        (t) async {
      final app = await mount(t, lang);
      final f = find.byKey(const ValueKey('report-subscribe'));
      final rev = app.revision;
      for (final text in ['已订阅', '订阅']) {
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.pumpAndSettle();
        expect(
            find.descendant(of: f, matching: find.text(text)), findsOneWidget);
        expect(app.revision, rev);
      }
      app.go(SurgoPage.report);
      await t.pumpAndSettle();
      expect(
          find.descendant(
              of: f,
              matching: find.text(lang == UiLang.en ? 'Subscribe' : '订阅')),
          findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
