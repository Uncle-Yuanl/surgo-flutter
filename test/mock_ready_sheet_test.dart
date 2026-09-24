import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/mock_intros/mock_intro_content.dart';
import 'package:surgo_flutter/features/mock_intros/mock_ready_sheet.dart';
import 'package:surgo_flutter/widgets/loop_video.dart';

import 'support/fonts.dart';

/// User 2026-09-24: the ready sheet must not touch the phone edges and the
/// illustration must be fully visible instead of cropped.
void main() {
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
  });

  Future<void> open(WidgetTester t) async {
    // MediaQuery alone does not resize the test surface; set the view.
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app = AppState();
    await t.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: app,
      child: const MaterialApp(
        home: Scaffold(body: _Host()),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('open-ready')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  /// The Dialog render box spans the whole screen; the visible card is the
  /// Material it lays out inside its insetPadding.
  Finder card() => find
      .descendant(of: find.byType(Dialog), matching: find.byType(Material))
      .first;

  testWidgets('ready sheet keeps a margin from the phone edges', (t) async {
    await open(t);
    final rect = t.getRect(card());
    expect(rect.left, greaterThanOrEqualTo(18));
    expect(rect.right, lessThanOrEqualTo(390 - 18));
    expect(rect.width, lessThan(390));
    expect(t.takeException(), isNull);
  });

  testWidgets('ready sheet shows the whole illustration', (t) async {
    await open(t);
    // BoxFit.contain keeps the clip inside the box, so nothing is cropped.
    final video = t.widget<LoopVideo>(find.byType(LoopVideo));
    expect(video.fit, BoxFit.contain);
    final box = t.getRect(find.byType(LoopVideo));
    final rect = t.getRect(card());
    expect(rect.contains(box.topLeft), true);
    expect(rect.contains(box.bottomRight), true);
    expect(t.takeException(), isNull);
  });
}

class _Host extends StatelessWidget {
  const _Host();
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          key: const ValueKey('open-ready'),
          onPressed: () =>
              showMockReadySheet(context, kMockReady['listening']!),
          child: const Text('open'),
        ),
      );
}
