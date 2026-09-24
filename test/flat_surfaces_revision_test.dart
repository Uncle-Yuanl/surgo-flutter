import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/widgets/phone_frame.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/ielts_reading/reading_overtime.dart';
import 'package:surgo_flutter/widgets/styled_loop_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
  });
  test('only semantic radar shader remains; no gradient image referenced', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final uses = <String>[];
    for (final f in files) {
      final s = f.readAsStringSync();
      for (final m
          in RegExp(r'(?:Linear|Radial|Sweep)Gradient\s*\(').allMatches(s)) {
        uses.add('${f.path}:${m.group(0)}');
      }
      expect(s, isNot(contains("'assets/images/app_bg.png'")), reason: f.path);
      expect(RegExp(r'gradient\s*:').hasMatch(s), false, reason: f.path);
    }
    expect(uses.length, 1);
    expect(uses.single, contains('report_page.dart:RadialGradient('));
  });
  testWidgets(
      'overtime dialog centered inside desktop phone rather than whole window',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    late BuildContext inside;
    await t.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
            home: PhoneFrame(
                background: Colors.white,
                child: Navigator(
                    onGenerateRoute: (_) =>
                        MaterialPageRoute<void>(builder: (ctx) {
                          inside = ctx;
                          return const Material();
                        }))))));
    await t.pumpAndSettle();
    showReadingOvertime(inside);
    await t.pumpAndSettle();
    final phone = t.getRect(find.byType(Navigator).last),
        dialog = t.getRect(find.byKey(const ValueKey('reading-overtime')));
    expect(dialog.center.dx, closeTo(phone.center.dx, .01));
    expect(dialog.center.dy, closeTo(phone.center.dy, .01));
    expect(phone.contains(dialog.topLeft), true);
    expect(phone.contains(dialog.bottomRight), true);
    expect(
        t.widget<StyledLoopVideo>(find.byType(StyledLoopVideo)).brightness, 1);
    expect(t.widget<Dialog>(find.byType(Dialog)).backgroundColor,
        readingOvertimeBackground);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
}
