import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/widgets/correction_dialog.dart';
import 'package:surgo_flutter/widgets/styled_loop_video.dart';

import 'support/fonts.dart';

/// User 2026-09-24: the exit-exam dialog must match the other dialogs (the
/// reading overtime sheet) and reuse the timeup illustration.
void main() {
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
  });

  Future<AppState> open(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app = AppState();
    await t.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: app,
      child: const MaterialApp(home: Scaffold(body: _Host())),
    ));
    await t.tap(find.byKey(const ValueKey('open-exit')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    return app;
  }

  testWidgets('exit dialog uses the shared sheet style, not AlertDialog',
      (t) async {
    await open(t);
    expect(find.byType(AlertDialog), findsNothing);
    final card = t.getRect(find.byKey(const ValueKey('exam-exit')));
    expect(card.width, 330);
    // Same inset as the overtime sheet: centred, clear of the phone edges.
    expect(card.left, greaterThanOrEqualTo(24));
    expect(card.right, lessThanOrEqualTo(390 - 24));
    expect(find.text('确定要退出考试吗？'), findsOneWidget);
    expect(find.text('进度将为你保留，下次可以接着作答。'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('exit dialog reuses the timeup illustration', (t) async {
    await open(t);
    final video = t.widget<StyledLoopVideo>(find.byType(StyledLoopVideo));
    expect(video.asset, 'assets/video/timeup.mp4');
    expect(video.width, 212);
    expect(video.height, 212);
    expect(t.takeException(), isNull);
  });

  testWidgets('stay closes the dialog and leave goes home', (t) async {
    final app = await open(t);
    await t.tap(find.byKey(const ValueKey('exam-exit-stay')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('exam-exit')), findsNothing);

    await t.tap(find.byKey(const ValueKey('open-exit')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const ValueKey('exam-exit-leave')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('exam-exit')), findsNothing);
    expect(app.current, SurgoPage.ielts);
    // Source resets these recording flags on exit.
    expect(app.session['spqRec'], false);
    expect(app.session['spqBusy'], false);
  });
}

class _Host extends StatelessWidget {
  const _Host();
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          key: const ValueKey('open-exit'),
          onPressed: () => showExamExit(context),
          child: const Text('open'),
        ),
      );
}
