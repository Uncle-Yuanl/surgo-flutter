import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/tf_listening_mock/controller.dart';
import 'package:surgo_flutter/features/tf_listening_mock/data.dart';
import 'package:surgo_flutter/features/tf_listening_mock/module.dart';

/// All 11 native TOEFL listening MOCK routes (7 parameterised question modules
/// + module-end / loading / module-2 intro / feedback). Same list the shell
/// resolves through buildTfListeningMockPage.
const _routes = <SurgoPage>[
  SurgoPage.tfListenQ,
  SurgoPage.tfConvQ,
  SurgoPage.tfAnnQ,
  SurgoPage.tfTalkQ,
  SurgoPage.tfM2P1Q,
  SurgoPage.tfM2P2Q,
  SurgoPage.tfM2P3Q,
  SurgoPage.tfModEnd,
  SurgoPage.tfModLoad,
  SurgoPage.tfMod2Intro,
  SurgoPage.tfListenFb,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> data;
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    data = await TfListeningMockData.load();
  });

  test('mock controller: forced single playback locks answering, then countdown auto-advances; grouped audio never replays; transition chain matches JSON', () {
    final modules = data['modules'] as Map<String, dynamic>;
    for (final entry in modules.entries) {
      final key = entry.key;
      final module = entry.value as Map<String, dynamic>;
      final c = TfMockController(AppState(), module);

      // Starts in forced playback; answering is impossible while it plays.
      expect(c.phase, 'play', reason: key);
      expect(c.playing, true, reason: key);
      c.pick('A');
      expect(c.picks, isEmpty, reason: key);

      // Playback ticks the recording to completion, then unlocks to the
      // answer countdown seeded with the module's answerSec.
      var guard = 0;
      while (c.phase == 'play' && guard++ < 1000) {
        c.audioTick();
      }
      expect(c.phase, 'answer', reason: key);
      expect(c.audio, c.curSec, reason: key);
      expect(c.left, c.answerSec, reason: key);

      // Now a pick is recorded.
      c.pick('B');
      expect(c.picks[0], 'B', reason: key);

      // Countdown returns true exactly on hitting zero.
      for (var i = 0; i < c.answerSec - 1; i++) {
        expect(c.tick(), false, reason: key);
      }
      expect(c.tick(), true, reason: key);
      expect(c.left, 0, reason: key);

      // Advance through the rest of the module. `next()` is only honoured once
      // the current segment has left the locked playback phase, so each hop
      // finishes playback first (unless a shared recording skipped it).
      while (!c.isLast) {
        final before = c.index;
        expect(c.next(), true, reason: key);
        expect(c.index, before + 1, reason: key);
        // grouped segments that reuse the previous recording skip playback.
        final prevAudio = (c.segments[c.index - 1] as Map)['audio'];
        final curAudio = (c.segments[c.index] as Map)['audio'];
        if (c.grouped && prevAudio != null && prevAudio == curAudio) {
          expect(c.phase, 'answer', reason: '$key grouped @${c.index}');
          expect(c.audio, c.curSec, reason: '$key grouped @${c.index}');
        } else {
          expect(c.phase, 'play', reason: '$key fresh @${c.index}');
          expect(c.audio, 0, reason: '$key fresh @${c.index}');
          // Locked: cannot skip during playback.
          c.next();
          expect(c.index, before + 1, reason: '$key locked @${c.index}');
          var g = 0;
          while (c.phase == 'play' && g++ < 1000) {
            c.audioTick();
          }
          expect(c.phase, 'answer', reason: '$key unlocked @${c.index}');
        }
      }
      // Leaving the last segment finishes the module.
      expect(c.isLast, true, reason: key);
      expect(c.next(), false, reason: key);
      // The transition token is exactly what the JSON declares.
      expect(c.nextRoute, module['next'], reason: key);
    }
  });

  test('mock controller: session round-trips index/phase/picks/notes so a resumed segment with a shared recording is not replayed', () {
    final module = (data['modules'] as Map<String, dynamic>)['conv'] as Map<String, dynamic>;
    final app = AppState();
    // Simulate having reached segment 1 (audio 0, shared with segment 0) mid-play.
    app.session.addAll({
      'tf2Idx': 1,
      'tf2Phase': 'play',
      'tf2Left': module['answerSec'],
      'tf2Audio': 0,
      '_tf2Picks': {0: 'C'},
      '_tf2Notes': {0: 'hi'},
    });
    final c = TfMockController(app, module);
    // grouped + shared audio => resumes straight into the answer phase.
    expect(c.index, 1);
    expect(c.phase, 'answer');
    expect(c.audio, c.curSec);
    expect(c.picks[0], 'C');
    expect(c.notes[0], 'hi');
  });

  testWidgets('all 11 mock listening route bodies render natively at 390px', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final page in _routes) {
      // The feature exposes every one of its 11 routes through this single
      // entry builder; verify each returns a real native body (never null /
      // never a placeholder) and renders without exceptions at 390px.
      final body = buildTfListeningMockPage(page);
      expect(body, isNotNull, reason: page.name);
      final state = AppState(current: page, examType: ExamType.toefl);
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
              key: ValueKey(page),
              home: Scaffold(
                  body: SingleChildScrollView(child: body!)))));
      // Resolve async data load + first frame without settling perpetual timers.
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: page.name);
    }
    // Dispose the last tree so no periodic/loading timers stay pending.
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump();
  });
}
