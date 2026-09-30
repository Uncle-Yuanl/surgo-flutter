// 演示用真实数据带着录音（audio：{ asset, sec }）。放不了音频的地方（原生端、widget 测试：
// demoAudio.available 为 false）页面必须和原型一样：模考页画写死的进度、不碰播放器，
// 回顾页的播放键点了没反应。真的放音频的那一路只在浏览器里有，用无头浏览器验证
// （tool/demo_export/README.md「验证」）。
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/ielts_listening/feedback_audio.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/ielts_mock_listening_module.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/mock_listening_data.dart';
import 'package:surgo_flutter/widgets/demo_audio.dart';

const clip = {'asset': 'assets/data/aud_mock_listening_p2.mp3', 'sec': 152.9};

Widget host(AppState app, Widget page) => ChangeNotifierProvider.value(
    value: app, child: MaterialApp(home: Scaffold(body: page)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockListeningData data;
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    // 原型数据的每个 Part 加上录音，就是导出的真实数据的形状。
    final raw = jsonDecode(jsonEncode((await MockListeningData.load()).raw))
        as Map<String, dynamic>;
    for (final part in raw['parts'] as List) {
      part['audio'] = clip;
    }
    data = MockListeningData.cache = MockListeningData(raw);
  });

  test('no player here: this is the path under test', () {
    expect(demoAudio.available, false);
  });

  test('mock exam controller leaves the recording alone', () {
    final app = AppState(current: SurgoPage.mockListeningQ2);
    final c = MockListeningController(app, data, 2);
    expect(c.meta['audio'], clip);
    expect(c.clip, isNull);
    c.audioTick();
    c.endAudio();
    expect(c.audioOver, false);
    expect(c.audioAt, 0);
  });

  testWidgets('mock exam page keeps the fixed bar, time and title', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.mockListeningQ2);
    await t.pumpWidget(
        host(app, buildIeltsMockListeningPage(SurgoPage.mockListeningQ2)!));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 5));
    expect(find.text('第 2 部分播放中'), findsOneWidget);
    expect(find.text('播放已完成'), findsNothing);
    expect(find.text('01:12/07:00'), findsOneWidget);
    expect(
        t
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .17);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('review bar stays inert and shows the recording length',
      (t) async {
    final app = AppState(current: SurgoPage.listeningFeedback);
    await t.pumpWidget(host(
        app, const ListeningReviewAudio(duration: '05:48', clip: clip)));
    final play = find.byKey(const ValueKey('lf-play-inert'));
    expect(play, findsOneWidget);
    expect(find.byKey(const ValueKey('lf-play')), findsNothing);
    await t.tap(play);
    await t.pump(const Duration(seconds: 2));
    expect(find.descendant(of: play, matching: find.byType(CustomPaint)),
        findsOneWidget);
    expect(find.text('02:32'), findsOneWidget);
    expect(find.text('05:48'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
