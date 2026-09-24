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
    final font=FontLoader('VioletSans')..addFont(rootBundle.load('assets/fonts/violet-sans.ttf'));
    await font.load(); // Ahem test font cannot verify actual English wrapping.
  });
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
    testWidgets(
        '${lang.name} lesson has fixed 24px home, source pair rules and inner scroll',
        (t) async {
      await mount(t, SurgoPage.pronLesson, lang);
      final home = find.byKey(const ValueKey('practice-home'));
      expect(t.getSize(home), const Size(24, 24));
      final y = t.getTopLeft(home).dy;
      final inner = find
          .descendant(
              of: find.byKey(const ValueKey('pron-page-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await t.drag(inner, const Offset(0, -250));
      await t.pumpAndSettle();
      expect(t.getTopLeft(home).dy, y);
      expect(find.text('light'), findsOneWidget);
      expect(find.text('correct'), findsOneWidget);
      final lineContainers =
          t.widgetList<Container>(find.byType(Container)).where((w) {
        final d = w.decoration;
        return d is BoxDecoration &&
            d.border is Border &&
            (d.border as Border).bottom.width == 1;
      });
      expect(lineContainers.length, 2);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
    testWidgets(
        '${lang.name} listening uses source wrap positions and live wrong-answer style',
        (t) async {
      await mount(t, SurgoPage.pronListen, lang);
      final play = find.byKey(const ValueKey('listen-play'));
      final same = find.byKey(const ValueKey('listen-same'));
      final diff = find.byKey(const ValueKey('listen-diff'));
      expect(t.getTopLeft(play).dy, closeTo(t.getTopLeft(same).dy, 1));
      if (lang == UiLang.zh) {
        expect(t.getTopLeft(diff).dy, closeTo(t.getTopLeft(play).dy, 1));
      } else {
        expect(t.getTopLeft(diff).dy, greaterThan(t.getBottomLeft(play).dy));
      }
      await t.tap(diff);
      await t.pump();
      expect(find.byKey(const ValueKey('listen-operations')), findsOneWidget);
      final selected = t.widget<Material>(diff);
      expect(selected.color, const Color(0xfffdf3d6));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
