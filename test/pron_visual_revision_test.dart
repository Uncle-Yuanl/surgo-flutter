import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/pron_practice/practice_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
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
        '${lang.name} pronunciation uses fixed home and source round controls; recording/judgment unchanged',
        (t) async {
      final app = await mount(t, SurgoPage.pronRepeat, lang);
      final home = find.byKey(const ValueKey('practice-home'));
      expect(t.getSize(home), const Size(24, 24));
      final y = t.getTopLeft(home).dy;
      expect(y, 66);
      expect(
          t.getSize(find.byKey(const ValueKey('mic-0'))), const Size(40, 40));
      final scroll = find
          .descendant(
              of: find.byKey(const ValueKey('practice-scroll')),
              matching: find.byType(Scrollable))
          .first;
      await t.drag(scroll, const Offset(0, -60));
      await t.pumpAndSettle();
      expect(t.getTopLeft(home).dy, y);
      await t.ensureVisible(find.byKey(const ValueKey('mic-0')));
      await t.tap(find.byKey(const ValueKey('mic-0')));
      await t.pump(const Duration(seconds: 2));
      expect((app.session['prRec'] as Map)[0]['rec'], true);
      await t.tap(find.byKey(const ValueKey('mic-0')));
      await t.pump();
      expect((app.session['prRec'] as Map)[0]['sec'], 2);
      final good = find
          .byWidgetPredicate((w) => w is PracticeButton && w.judgment == true)
          .first;
      await t.ensureVisible(good);
      await t.tap(good);
      await t.pump();
      expect((app.session['prRec'] as Map)[0]['judged'], true);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
    testWidgets(
        '${lang.name} completion keeps source title segments, picture width and side-by-side navigation',
        (t) async {
      final app = await mount(t, SurgoPage.pronCongrats, lang);
      final img = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/otter_welcome.png');
      expect(t.getSize(img).width, 180);
      final texts = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
          .join('\n');
      expect(
          texts,
          contains(lang == UiLang.zh
              ? '发音模块完成啦！'
              : 'Pronunciation moduleAll done!'));
      if(lang==UiLang.en){
        final label=find.text('Self-assessment');
        expect(t.getSize(label).height,lessThanOrEqualTo(41));
      }
      final row = find.byKey(const ValueKey('practice-congrats-actions'));
      final buttons =
          find.descendant(of: row, matching: find.byType(PracticeButton));
      expect(buttons, findsNWidgets(2));
      expect(t.getCenter(buttons.at(0)).dy,
          closeTo(t.getCenter(buttons.at(1)).dy, 1));
      await t.tap(buttons.at(0));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.pronCourse);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
