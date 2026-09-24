import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/writing_review/review_widgets.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
    await QuestionBank.load();
    for (final font in {
      'VioletSans': 'violet-sans.ttf',
      'Arimo': 'Arimo-Bold.ttf'
    }.entries) {
      await (FontLoader(font.key)
            ..addFont(rootBundle.load('assets/fonts/${font.value}')))
          .load();
    }
  });
  const targets = {
    SurgoPage.writingImprove: SurgoPage.writingBands,
    SurgoPage.writingBands: SurgoPage.writingL1Error,
    SurgoPage.writingL1Error: SurgoPage.writingL1Detail,
    SurgoPage.writingL1Detail: SurgoPage.ielts,
  };
  Future<AppState> mount(WidgetTester t, SurgoPage page, UiLang lang) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    rootBundle.evict('assets/data/writing_legacy.json');
    rootBundle.evict('assets/data/writing_review.json');
    final app = AppState(current: page, lang: lang);
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
            theme: SurgoTheme.build(),
            home: const MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: SurgoShell()))));
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pumpAndSettle();
    return app;
  }

  for (final lang in UiLang.values) {
    for (final page in targets.keys) {
      testWidgets('legacy ${page.name} ${lang.name} source nav and end route',
          (t) async {
        final app = await mount(t, page, lang);
        final home = find
            .byWidgetPredicate(
                (w) => w is SvgPicture && w.width == 20 && w.height == 20)
            .first;
        expect(t.getRect(home).center, const Offset(42, 88));
        final tabs = t
            .widgetList<RichText>(find.byType(RichText))
            .where((w) => w.text.toPlainText().contains('WRITING MARK'));
        if (lang == UiLang.en) expect(tabs.first.text.style?.fontSize, 11);
        final next = find.byKey(const ValueKey('writing-legacy-next'));
        expect(t.widget<ReviewButton>(next).onTap, isNotNull);
        await t.ensureVisible(next);
        await t.pumpAndSettle();
        await t.tap(next);
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pumpAndSettle();
        expect(app.current, targets[page]);
        expect(t.takeException(), isNull);
      });
    }
  }
  for (final page in targets.keys) {
    testWidgets('legacy ${page.name} inert tabs and return handlers',
        (t) async {
      final app = await mount(t, page, UiLang.en);
      Future<void> tapKey(String name) async {
        final f = find.byKey(ValueKey(name));
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pumpAndSettle();
      }

      for (final label in ['IMPROVE', 'L1 ERROR']) {
        final inert = label == 'L1 ERROR' ||
            page == SurgoPage.writingImprove ||
            page == SurgoPage.writingBands;
        final f = find.byKey(ValueKey('writing-legacy-tab-$label'));
        final handler = find.descendant(of: f, matching: find.byType(InkWell));
        expect(handler, inert ? findsNothing : findsOneWidget);
        if (inert) {
          final rev = app.revision;
          await tapKey('writing-legacy-tab-$label');
          expect(app.revision, rev);
        }
      }
      if (page == SurgoPage.writingBands || page == SurgoPage.writingL1Detail) {
        await tapKey('writing-legacy-back');
        expect(
            app.current,
            page == SurgoPage.writingBands
                ? SurgoPage.writingImprove
                : SurgoPage.writingL1Error);
        app.go(page);
        await t.pump();
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pumpAndSettle();
      }
      await tapKey('writing-legacy-tab-WRITING MARK');
      expect(app.current, SurgoPage.writingFeedback);
      app.go(page);
      await t.pump();
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pumpAndSettle();
      await tapKey('writing-legacy-home');
      expect(app.current, SurgoPage.ielts);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('legacy bands source star rows have no extra trailing gap',
      (t) async {
    await mount(t, SurgoPage.writingBands, UiLang.en);
    final stars = find.byWidgetPredicate(
        (w) => w is SvgPicture && w.width == 19 && w.height == 19);
    expect(stars, findsNWidgets(12));
    final first = t.getRect(stars.at(0)), last = t.getRect(stars.at(4));
    expect(
        last.right - first.left, 115); // 5*19 + 4*5, then source 24px padding.
    // Headings above this row use Outfit per the user's global font choice, so
    // the row starts 10px lower than the source webfont measurement (255).
    expect(first.top, closeTo(265, 2));
    final body = t.widgetList<RichText>(find.byType(RichText)).firstWhere(
      (w) => w.text.toPlainText().startsWith('A data table'));
    // Body copy family per the user's global font choice.
    expect(body.text.style?.fontFamily, 'PingFang SC');
    expect(find.byType(Scrollbar), findsNothing);
  });
  testWidgets('legacy corrected text preserves arrow and smaller nested bold',
      (t) async {
    await mount(t, SurgoPage.writingImprove, UiLang.en);
    final node = t.widgetList<SourceText>(find.byType(SourceText)).firstWhere(
        (w) => w.span != null && w.span!.toPlainText().startsWith('→'));
    expect(node.style?.fontSize, 12);
    final span = node.span! as TextSpan;
    expect((span.children![1] as TextSpan).style?.fontSize, 10);
    expect((span.children![1] as TextSpan).style?.fontWeight, FontWeight.w700);
    expect(t.takeException(), isNull);
  });
}
