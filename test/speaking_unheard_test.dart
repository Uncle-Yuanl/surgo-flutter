// 考官的提问读不出声音时（手机浏览器没有语音引擎、iOS 丢弃不是点击触发的朗读、音频被拦下），
// 口语页不能卡住：把题目显示出来，流程照常往下走。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/ielts_mock_speaking/controller.dart';
import 'package:surgo_flutter/features/ielts_mock_speaking/page.dart';
import 'package:surgo_flutter/features/oral_daily/controller.dart';
import 'package:surgo_flutter/features/oral_daily/page.dart';

/// 读不出来、立刻报失败的朗读；[manual] 为 true 时由测试决定何时结束。
class MuteSpeech implements OralSpeech {
  MuteSpeech({this.manual = false});
  final bool manual;
  VoidCallback? end;
  int calls = 0;
  @override
  Future<void> speak(String text, {required VoidCallback started, required VoidCallback ended, required ValueChanged<String> failed}) async {
    calls++;
    end = ended;
    if (!manual) failed('no speech');
  }

  @override
  Future<void> stop() async {}
}

Widget host(AppState app, Widget page) => ChangeNotifierProvider.value(value: app, child: MaterialApp(home: Scaffold(body: page)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> mock;
  setUpAll(() async {
    await QuestionBank.load();
    await Translator.load();
    mock = await IeltsMockSpeakingData.load();
  });

  testWidgets('daily Part 1: an unheard question is shown and can be answered', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.oralExam)..session['selWizCard'] = 'p1';
    final c = OralController(app, speech: MuteSpeech());
    addTearDown(c.dispose);
    await t.pumpWidget(host(app, OralDailyPage(controller: c)));
    c.start();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump();
    final first = c.task.questions.first;
    expect(c.phase, 'ready');
    expect(c.unheard, first);
    expect(find.byKey(const ValueKey('oral-unheard')), findsOneWidget);
    expect(find.text(first), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('oral-mic')));
    await t.pump(const Duration(seconds: 2));
    expect(c.phase, 'rec');
    await t.tap(find.byKey(const ValueKey('oral-mic')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('oral-submit')));
    await t.pump();
    // 下一题：上一题的文字先收起，读不出来再显示这一题的。
    expect(c.index, 1);
    expect(c.unheard, isNull);
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
    expect(c.unheard, c.task.questions[1]);
    expect(t.takeException(), isNull);
    c.quit();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('daily Part 3: an unheard question is shown, the timed rounds keep going', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.oralDiscuss)..session['selWizCard'] = 'p3';
    final c = OralController(app, speech: MuteSpeech());
    addTearDown(c.dispose);
    await t.pumpWidget(host(app, OralDailyPage(discussion: true, controller: c)));
    c.start();
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    expect(c.unheard, c.task.questions.first);
    expect(app.current, SurgoPage.oralDiscuss);
    expect(find.byKey(const ValueKey('oral-unheard')), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(c.turn, 'answer');
    expect(t.takeException(), isNull);
    c.quit();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mock Part 1: an unheard question is shown and recording starts', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.mockSpeakingQ);
    await t.pumpWidget(host(app, IeltsMockSpeakingPage(speech: MuteSpeech())));
    await t.pump();
    await t.pump(const Duration(milliseconds: 260));
    await t.pump();
    expect(find.byKey(const ValueKey('ims-unheard-0')), findsOneWidget);
    expect(find.text(mock['SPQ']['p1']['qs'][0] as String), findsOneWidget);
    await t.pump(const Duration(milliseconds: 900));
    expect(find.text('已自动开始录音'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mock Part 1: replaying the question while the examiner is asking does not leave the mic dead', (t) async {
    final speech = MuteSpeech(manual: true);
    final c = IeltsMockSpeakingController(AppState(), mock, speech: speech, mark: () {});
    c.start();
    await t.pump(const Duration(milliseconds: 260));
    expect(c.busy, true);
    await c.play(0); // 手点重播：作废了自动那一次朗读
    expect(c.busy, true);
    speech.end!();
    expect(c.busy, false);
    expect(c.recording, true);
    c.dispose();
  });

  testWidgets('browser speech that never starts is reported as failed after 2.5 s', (t) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // 接口调用都成功，但从不回「开始 / 结束 / 出错」—— 手机上读不出声音时就是这样。
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
    addTearDown(() => messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), null));
    final speech = NativeOralSpeech();
    final seen = <String>[];
    await speech.speak('What is a typical morning like for you?',
        started: () => seen.add('started'), ended: () => seen.add('ended'), failed: (why) => seen.add('failed'));
    await t.pump(const Duration(milliseconds: 2499));
    expect(seen, isEmpty);
    await t.pump(const Duration(milliseconds: 1));
    expect(seen, ['failed']);

    // stop() 之后不再报。
    seen.clear();
    await speech.speak('Do you prefer to plan your day?',
        started: () => seen.add('started'), ended: () => seen.add('ended'), failed: (why) => seen.add('failed'));
    await speech.stop();
    await t.pump(const Duration(seconds: 5));
    expect(seen, isEmpty);
  });
}
