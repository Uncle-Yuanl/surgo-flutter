import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/ielts_reading/reading_controller.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await ReadingData.load();
    await loadSurgoTestFonts();
  });
  Finder key(String name) => find.byKey(ValueKey(name));
  Future<AppState> mount(WidgetTester t,
      {bool single = false,
      UiLang lang = UiLang.en,
      String type = 'mc',
      int? auditSeconds}) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(
        current: single ? SurgoPage.typeSession : SurgoPage.readingSession,
        lang: lang);
    if (single) app.session['selReadType'] = type;
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
            key: UniqueKey(),
            theme: SurgoTheme.build(),
            home: MediaQuery(
                data: const MediaQueryData(size: Size(390, 844)),
                child: SurgoShell(readingAuditSeconds: auditSeconds)))));
    await t.pumpAndSettle();
    return app;
  }

  Future<void> tap(WidgetTester t, String name) async {
    await t.ensureVisible(key(name));
    await t.pumpAndSettle();
    await t.tap(key(name));
    await t.pumpAndSettle();
  }

  for (final single in [false, true]) {
    for (final lang in UiLang.values) {
      testWidgets('reading geometry $single ${lang.name}', (t) async {
        await mount(t, single: single, lang: lang);
        expect(t.getRect(key('reading-home')),
            const Rect.fromLTWH(20, 66, 24, 24));
        final clock = t.getRect(key('reading-clock'));
        expect(clock.top, 65);
        expect(t.widget<Text>(key('reading-clock')).style?.fontSize, 26);
        expect(clock.center.dx, 195);
        expect(clock.center.dy, t.getRect(key('reading-home')).center.dy);
        expect(clock.right, lessThan(280)); // Keep clear of global controls.
        expect(t.getRect(key('reading-article-scroll')).top,
            lang == UiLang.zh ? 124 : 119);
        final sheet = t.getRect(key('reading-sheet'));
        expect(sheet.height, closeTo(784 * (single ? .46 : .58), .1));
        expect(sheet.bottom, 844);
        expect(t.getSize(key('reading-option-0')).height, 54);
        expect(t.getSize(key('reading-previous')).width, closeTo(136.15, .1));
        expect(t.getSize(key('reading-next')).width, closeTo(197.85, .1));
        expect(find.byType(Scrollbar), findsNothing);
        expect(t.takeException(), isNull);
      });
    }
    testWidgets('reading navigation preserves source $single jump behavior',
        (t) async {
      final app = await mount(t, single: single);
      final rev = app.revision;
      await tap(t, 'reading-option-0');
      await tap(t, 'reading-nav-open');
      await tap(t, 'reading-nav-2');
      expect(app.session[single ? 'typeIdx' : 'readIdx'], single ? isNull : 2);
      expect(app.revision, rev);
      if (single) {
        expect(
            find.textContaining('1. What is most remarkable'), findsOneWidget);
        expect(app.session['typeDone'], {0});
      } else {
        expect(find.textContaining('3.'), findsWidgets);
        expect(app.session['readDone'], {0});
      }
      expect(t.takeException(), isNull);
    });
  }
  for (final single in [false, true]) {
    for (final lang in UiLang.values) {
      testWidgets(
          'reading expiry returns without resetting $single ${lang.name}',
          (t) async {
        final app = await mount(t, single: single, lang: lang, auditSeconds: 3);
        final route = app.current, revision = app.revision;
        await tap(t, 'reading-option-0');
        final selected = t.widget<Container>(find
            .descendant(
                of: key('reading-option-0'), matching: find.byType(Container))
            .first);
        final color = (selected.decoration as BoxDecoration).color;
        expect(color, isNot(Colors.white));
        await t.pump(const Duration(seconds: 3));
        await t.pumpAndSettle();
        expect(key('reading-overtime'), findsOneWidget);
        final video = find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'StyledLoopVideo');
        expect(t.getSize(video), const Size(212, 212));
        expect(t.getSize(key('reading-overtime-close')).height, 55);
        final panel = t.getRect(key('reading-overtime'));
        expect(panel.center, const Offset(195, 422));
        expect(panel.width, 330);
        expect(panel.left, greaterThanOrEqualTo(24));
        expect(t.widget<Container>(key('reading-overtime')).color,
            const Color(0xfffbfbfb));
        expect(t.widget<Dialog>(find.byType(Dialog)).backgroundColor,
            const Color(0xfffbfbfb));
        expect(find.byType(BottomSheet), findsNothing);
        await tap(t, 'reading-overtime-close');
        expect(key('reading-overtime'), findsNothing);
        expect(app.current, route);
        expect(app.revision, revision);
        expect(app.session[single ? 'typeDone' : 'readDone'], {0});
        final after = t.widget<Container>(find
            .descendant(
                of: key('reading-option-0'), matching: find.byType(Container))
            .first);
        expect((after.decoration as BoxDecoration).color, color);
        int seconds() {
          final parts = t
              .widget<Text>(key('reading-clock'))
              .data!
              .split(':')
              .map(int.parse)
              .toList();
          return parts[0] * 60 + parts[1];
        }

        final before = seconds();
        await t.pump(const Duration(seconds: 4));
        expect(seconds(), before + 4);
        expect(key('reading-overtime'), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      });
    }
  }

  testWidgets('reading header move preserves countdown and Home target',
      (t) async {
    for (final single in [false, true]) {
      final app = await mount(t, single: single);
      final start = t.widget<Text>(key('reading-clock')).data!;
      final numbers = start.split(':').map(int.parse).toList();
      await t.pump(const Duration(seconds: 3));
      final end = t
          .widget<Text>(key('reading-clock'))
          .data!
          .split(':')
          .map(int.parse)
          .toList();
      expect(numbers[0] * 60 + numbers[1] - (end[0] * 60 + end[1]), 3);
      await tap(t, 'reading-home');
      expect(app.current, SurgoPage.ielts);
      expect(t.takeException(), isNull);
    }
  });

  testWidgets(
      'reading refresh keeps fixed data but loses local selection and translation',
      (t) async {
    final app = await mount(t, lang: UiLang.zh);
    await tap(t, 'reading-option-0');
    await tap(t, 'reading-next');
    expect(find.text('BACK'), findsOneWidget);
    expect(find.textContaining('Answered 1 /'), findsOneWidget);
    await tap(t, 'reading-previous');
    expect(app.session['readIdx'], 0);
    final option = t.widget<Container>(find
        .descendant(
            of: key('reading-option-0'), matching: find.byType(Container))
        .first);
    expect((option.decoration as BoxDecoration).color, Colors.white);
    expect(t.takeException(), isNull);
  });
  testWidgets('reading sheet drag limits and independent article scroll',
      (t) async {
    await mount(t);
    final before = t.getRect(key('reading-sheet'));
    await t.drag(key('reading-article-scroll'), const Offset(0, -180));
    await t.pumpAndSettle();
    expect(t.getRect(key('reading-sheet')), before);
    await t.drag(key('reading-sheet-handle'), const Offset(0, 800));
    await t.pumpAndSettle();
    expect(t.getSize(key('reading-sheet')).height, 158);
    await t.drag(key('reading-sheet-handle'), const Offset(0, -1000));
    await t.pumpAndSettle();
    expect(t.getSize(key('reading-sheet')).height, 732);
    expect(t.getRect(key('reading-sheet')).top, 119);
    expect(t.getRect(key('reading-sheet')).bottom,
        851); // Caption remains above maximally raised sheet.
    expect(t.takeException(), isNull);
  });
  testWidgets(
      'single inline gap does not mark; boxed answer commits only on blur',
      (t) async {
    for (final type in ['scomplete', 'short']) {
      final app = await mount(t, single: true, type: type);
      expect(t.getSize(key('reading-input')).height, type == 'short' ? 37 : 20);
      await t.ensureVisible(key('reading-input'));
      await t.enterText(key('reading-input'), 'sample');
      await t.pump();
      expect(app.session['typeDone'], isEmpty);
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump();
      expect((app.session['typeDone'] as Set).isNotEmpty, type == 'short');
      expect(t.takeException(), isNull);
    }
  });
}
