import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
  });
  Future<AppState> mount(WidgetTester t, UiLang lang) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.prep, lang: lang);
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

  testWidgets('profile shadow never paints the transparent avatar interior',
      (t) async {
    await mount(t, UiLang.en);
    final f = find
        .ancestor(
            of: find.byKey(const ValueKey('profile-avatar')),
            matching: find.byType(CustomPaint))
        .first;
    final painter = t.widget<CustomPaint>(f).painter!;
    await t.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xffffebbc), BlendMode.src);
      canvas.translate(80, 80);
      painter.paint(canvas, const Size(104, 104));
      final pic = recorder.endRecording();
      final image = await pic.toImage(264, 264);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      for (final point in [const Offset(132, 132), const Offset(132, 95)]) {
        final idx = (point.dy.toInt() * 264 + point.dx.toInt()) * 4;
        expect(bytes.buffer.asUint8List(idx, 4), [255, 235, 188, 255]);
      }
      image.dispose();
      pic.dispose();
    });
  });

  for (final lang in UiLang.values) {
    testWidgets(
        'profile ${lang.name} avatar transparent center and source gaps',
        (t) async {
      await mount(t, lang);
      final avatar = find.byKey(const ValueKey('profile-avatar'));
      expect(t.getRect(avatar), const Rect.fromLTWH(143, 120, 104, 104));
      final c = t.widget<Container>(avatar);
      expect((c.decoration as BoxDecoration).color, isNull);
      expect((c.decoration as BoxDecoration).border,
          Border.all(color: Colors.white, width: 4));
      final stats = t.getRect(find.byKey(const ValueKey('profile-stats')));
      // Name/handle above use Outfit per the user's global font choice, which is
      // 5px taller than the source webfont measurement (293).
      expect(stats.top, 298);
      // Container render box includes its 24px bottom margin.
      expect(stats.height - 24, lang == UiLang.zh ? 124 : 115);
      final scroll = t.widget<SingleChildScrollView>(
          find.byKey(const ValueKey('profile-scroll')));
      expect(scroll.padding, const EdgeInsets.fromLTRB(18, 8, 18, 120));
      expect(find.byType(Scrollbar), findsNothing);
      expect(t.takeException(), isNull);
    });
    testWidgets(
        'profile ${lang.name} four native source alerts do not change state',
        (t) async {
      final app = await mount(t, lang);
      final rev = app.revision;
      for (final label in ['考试信息', '账号安全', '语言设置', '帮助与支持']) {
        final f = find.byKey(ValueKey('profile-$label'));
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.pumpAndSettle();
        expect(find.text('（原型）$label'), findsOneWidget);
        expect(app.revision, rev);
        final rect = t.getRect(find.byType(AlertDialog));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
        await t.tap(find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextButton)));
        await t.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }
      expect(t.takeException(), isNull);
    });
  }
}
