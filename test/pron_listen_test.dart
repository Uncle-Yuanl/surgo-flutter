import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/pron_listen/pron_listen_controller.dart';
import 'package:surgo_flutter/features/pron_listen/pron_listen_page.dart';

/// pronListen（听辨）路由的原生实现测试。
///
/// 断言点锚定原型源常量与逻辑（app.js 6293-6368：PL_PAIRS / plPlayPair /
/// plPick / plAnswerLbl），确保迁移未偷改词对、答案、答对进阶与反馈文案。

/// 测试用假语音后端：立即回调，可断言被朗读的词序。
class _FakeSpeaker implements PlSpeaker {
  final List<String> spoken = <String>[];
  bool stopped = false;
  bool autoDone;
  VoidCallback? pendingDone;

  _FakeSpeaker({this.autoDone = true});

  @override
  Future<void> playPair(String a, String b, VoidCallback onDone) async {
    spoken..add(a)..add(b);
    if (autoDone) {
      onDone();
    } else {
      pendingDone = onDone; // 手动控制“播放中”窗口
    }
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

Future<void> _pump(WidgetTester tester, Widget body, AppState state) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Translator.load();
  });

  group('路由分发与源常量', () {
    test('buildPronListenPage 只认领 pronListen', () {
      expect(buildPronListenPage(SurgoPage.pronListen), isNotNull);
      expect(buildPronListenPage(SurgoPage.pronLesson), isNull);
      expect(buildPronListenPage(SurgoPage.pronRepeat), isNull);
      expect(buildPronListenPage(SurgoPage.ielts), isNull);
    });

    test('PL_PAIRS 词对/答案与原型一字对齐（app.js 6293-6298）', () {
      expect(kPlPairs.length, 4);
      expect(
        kPlPairs.map((p) => [p.a, p.b, p.ans]).toList(),
        [
          ['light', 'light', 'same'],
          ['light', 'right', 'diff'],
          ['collect', 'correct', 'diff'],
          ['glass', 'glass', 'same'],
        ],
      );
    });

    test('步骤条 = 讲解/听辨/单词跟读/句子练习/完成', () {
      expect(kPronListenSteps,
          ['讲解', '听辨', '单词跟读', '句子练习', '完成']);
    });
  });

  group('PronListenController 逻辑（plPick / plPlayPair）', () {
    test('答错：result=bad，picked 记录，不进阶', () {
      final c = PronListenController(speaker: _FakeSpeaker());
      // 第 1 题 ans=same，选 diff → 错。
      c.pick('diff');
      expect(c.result, 'bad');
      expect(c.picked, 'diff');
      expect(c.idx, 0);
      expect(c.answerLabel(), '相同'); // ans=same
      c.dispose();
    });

    testWidgets('答对进阶：1200ms 后 idx+1 且状态清空',
        (tester) async {
      final c = PronListenController(speaker: _FakeSpeaker());
      c.pick('same'); // 第 1 题 ans=same → ok
      expect(c.result, 'ok');
      expect(c.idx, 0);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(c.idx, 1);
      expect(c.picked, isNull);
      expect(c.result, isNull);
      c.dispose();
    });

    test('答对末题：不进阶（idx 保持最后一题）', () {
      // 用只含一题的列表模拟“末题”：原型 plIdx<PL_PAIRS.length-1 才进阶。
      final single = PronListenController(
        speaker: _FakeSpeaker(),
        pairs: const [PlPair('glass', 'glass', 'same')],
      );
      single.pick('same');
      expect(single.result, 'ok');
      expect(single.idx, 0); // 无下一题，不进阶
      single.dispose();
    });

    test('playPair：依次朗读 a、b 两个词，结束后 playing=false', () async {
      final spk = _FakeSpeaker(autoDone: true);
      final c = PronListenController(speaker: spk);
      await c.playPair();
      expect(spk.spoken, ['light', 'light']); // 第 1 题 a=b=light
      expect(c.playing, false);
      c.dispose();
    });

    test('playing 期间：pick 被忽略、重复 playPair 不叠加', () async {
      final spk = _FakeSpeaker(autoDone: false); // 不自动结束 → 停在播放中
      final c = PronListenController(speaker: spk);
      await c.playPair();
      expect(c.playing, true);
      // 原型 plPick：if(plPlaying) return;
      c.pick('same');
      expect(c.picked, isNull);
      expect(c.result, isNull);
      // 原型 plPlayPair：if(plPlaying) return; → 不再追加朗读
      await c.playPair();
      expect(spk.spoken, ['light', 'light']);
      // 结束播放
      spk.pendingDone?.call();
      expect(c.playing, false);
      c.dispose();
    });
  });

  group('PronListenPage 渲染与交互', () {
    testWidgets('渲染题号、选项与英文题干', (tester) async {
      final state = AppState();
      final c = PronListenController(speaker: _FakeSpeaker());
      await _pump(tester, PronListenPage(controller: c), state);

      expect(find.text('第 1/4 题'), findsOneWidget);
      expect(find.text('相同'), findsOneWidget);
      expect(find.text('不同'), findsOneWidget);
      expect(find.text('播放两个词'), findsOneWidget);
      expect(find.text('听辨：是同一个词还是不同的词？'),
          findsOneWidget);
      c.dispose();
    });

    testWidgets('答错显示反馈“再听一次，这组是相同的”', (tester) async {
      final state = AppState();
      final c = PronListenController(speaker: _FakeSpeaker());
      await _pump(tester, PronListenPage(controller: c), state);

      await tester.tap(find.text('不同')); // 第 1 题 ans=same → 错
      await tester.pump();
      expect(find.text('再听一次，这组是相同的'), findsOneWidget);
      c.dispose();
    });

    testWidgets('答对显示“正确！”并 1200ms 后进第 2 题', (tester) async {
      final state = AppState();
      final c = PronListenController(speaker: _FakeSpeaker());
      await _pump(tester, PronListenPage(controller: c), state);

      await tester.tap(find.text('相同')); // 第 1 题正确
      await tester.pump();
      expect(find.text('正确！'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('第 2/4 题'), findsOneWidget);
      c.dispose();
    });

    testWidgets('底部“下一步：单词跟读”跳 pronRepeat', (tester) async {
      final state = AppState();
      final c = PronListenController(speaker: _FakeSpeaker());
      await _pump(tester, PronListenPage(controller: c), state);

      await tester.tap(find.text('下一步：单词跟读'));
      await tester.pump();
      expect(state.current, SurgoPage.pronRepeat);
      c.dispose();
    });

    testWidgets('步骤条“讲解”跳 pronLesson、“单词跟读”跳 pronRepeat',
        (tester) async {
      final state = AppState();
      final c = PronListenController(speaker: _FakeSpeaker());
      await _pump(tester, PronListenPage(controller: c), state);

      await tester.tap(find.text('1 讲解'));
      await tester.pump();
      expect(state.current, SurgoPage.pronLesson);

      state.go(SurgoPage.pronListen);
      await tester.tap(find.text('3 单词跟读'));
      await tester.pump();
      expect(state.current, SurgoPage.pronRepeat);
      c.dispose();
    });

    testWidgets('播放两个词：朗读 a、b（flutter_tts 后端替身）', (tester) async {
      final state = AppState();
      final spk = _FakeSpeaker();
      final c = PronListenController(speaker: spk);
      await _pump(tester, PronListenPage(controller: c), state);

      await tester.tap(find.text('播放两个词'));
      await tester.pump();
      expect(spk.spoken, ['light', 'light']);
      c.dispose();
    });
  });
}
