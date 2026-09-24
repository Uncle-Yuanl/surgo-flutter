import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/mock_intros/mock_intro_module.dart';

import 'support/fonts.dart';

/// User 2026-09-24: the three "preparation" pages become the ready dialog.
void main() {
  setUpAll(() async {
    await loadSurgoTestFonts();
    await Translator.load();
  });

  Future<AppState> mount(WidgetTester t, SurgoPage page,
      {ExamType exam = ExamType.ielts}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final app = AppState()..examType = exam;
    app.go(page);
    await t.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
              // A fresh key per mount: without it Flutter reuses the previous
              // State and the dialog never reopens for the next route.
              child: MockIntroPage(key: ValueKey(page), page: page)),
        ),
      ),
    ));
    await t.pump();
    // The dialog is pushed from a post-frame callback; give it a frame to mount.
    await t.pump(const Duration(milliseconds: 100));
    return app;
  }

  /// The sheet runs a 2s progress animation plus a 220ms tail before it pops.
  Future<void> finish(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 2100));
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
  }

  const intros = {
    SurgoPage.mockReadingIntro: SurgoPage.mockReadingQ,
    SurgoPage.mockListeningIntro: SurgoPage.mockListeningQ,
    SurgoPage.mockSpeakingIntro: SurgoPage.mockSpeakingQ,
  };

  testWidgets('each preparation route shows the ready dialog, not a full page',
      (t) async {
    for (final page in intros.keys) {
      final app = await mount(t, page);
      // The dialog is on screen and the old full page is gone.
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('准备好了吗？'), findsOneWidget);
      expect(find.byKey(const ValueKey('mock-intro-start')), findsNothing);
      expect(find.byKey(const ValueKey('mock-ready-intro')), findsOneWidget);
      expect(app.current, page);
      // Let it finish so the next iteration starts clean.
      await finish(t);
    }
  });

  testWidgets('dialog completion enters the answering page and resets state',
      (t) async {
    for (final entry in intros.entries) {
      final app = await mount(t, entry.key);
      await finish(t);
      expect(app.current, entry.value);
    }
    // Source resets carried over from the old full-page start().
    final reading = await mount(t, SurgoPage.mockReadingIntro);
    await finish(t);
    expect(reading.session['mrPas'], 1);
    expect(reading.session['mrLeft'], 3600);
  });

  testWidgets('TOEFL branch also uses the dialog and its own routes',
      (t) async {
    final app =
        await mount(t, SurgoPage.mockReadingIntro, exam: ExamType.toefl);
    expect(find.byType(Dialog), findsOneWidget);
    await finish(t);
    expect(app.current, SurgoPage.tfRead1Q);
    expect(app.session['tfR1Left'], 1800);
  });

  testWidgets('list pages keep their full-page layout', (t) async {
    await mount(t, SurgoPage.mockReading);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('mock-intro-start')), findsOneWidget);
  });

  testWidgets('ready dialog copy differs per subject', (t) async {
    await mount(t, SurgoPage.mockSpeakingIntro);
    expect(find.textContaining('仅 Part 2 提供 1 分钟准备时间'), findsOneWidget);
    await finish(t);
  });
}
