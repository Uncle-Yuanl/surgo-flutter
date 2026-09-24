import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/theme/tokens.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/mock_listening_data.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/ielts_mock_listening_module.dart';

// Wraps the exported page builder like the shell would, minus the shared
// scaffold we are not allowed to touch here.
Widget _host(AppState state, SurgoPage page) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        home:
            Scaffold(body: SafeArea(child: buildIeltsMockListeningPage(page)!)),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockListeningData data;
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    data = await MockListeningData.load();
  });

  test('exported data matches app.js mockListeningQ*View exactly', () {
    expect(data.parts.length, 4);
    // shared 30:00 exam clock (startMockTimer) + 118s review (submitMockPart4)
    expect(data.sharedTimerSec, 30 * 60);
    expect(data.reviewSec, 118);
    // Part 1: 6 single-choice + 4 fills, audio 00:00/07:00
    final p1 = data.part(1);
    expect((p1['mc'] as List).length, 6);
    expect((p1['fills'] as List).length, 4);
    expect(p1['mc'][0]['q'], 'The customer wants to book the hall for a');
    expect((p1['mc'][0]['opts'] as List),
        ['birthday party.', 'wedding reception.', 'company event.']);
    expect(p1['audioTime'], '00:00/07:00');
    // Part 2: table (12 rows, gaps 11-16) + map labels 17-20 + svg present
    final p2 = data.part(2);
    expect((p2['table'] as List).length, 12);
    expect((p2['mapQs'] as List).map((q) => q['n']).toList(), [17, 18, 19, 20]);
    expect(p2['tableTitle'], 'MISSING PERSON DESCRIPTION');
    expect(data.mapSvg.contains('<svg'), true);
    expect(p2['audioTime'], '01:12/07:00');
    // Part 3: matching box (6) + match Qs 21-25 + MC 26-30
    final p3 = data.part(3);
    expect((p3['matchBox'] as List).length, 6);
    expect((p3['match'] as List).map((q) => q['n']).toList(),
        [21, 22, 23, 24, 25]);
    expect(
        (p3['mc'] as List).map((q) => q['n']).toList(), [26, 27, 28, 29, 30]);
    // Part 4: notes 31-36 + sentences 37-40
    final p4 = data.part(4);
    expect((p4['notes'] as List).length, 6);
    expect((p4['sents'] as List).length, 4);
    expect(p4['notesTitle'], 'SURVEY METHODS');
    expect(p4['sents'][3]['head'], 'Results must not be used for');
    expect(p4['sents'][3]['tail'], 'purposes.');
  });

  test('mark label follows source template 正在批改任务 N / 4, Part N', () {
    expect(data.markLabel(1), '正在批改任务 1 / 4, Part 1');
    expect(data.markLabel(4), '正在批改任务 4 / 4, Part 4');
  });

  test('Part 1 always resets; Parts 2–4 continue source mockLeft', () {
    final s = AppState();
    // enter Part 1 -> reset to 30:00
    final c1 = MockListeningController(s, data, 1);
    expect(c1.left, 1800);
    for (var i = 0; i < 100; i++) {
      s.session['mockLeft'] = c1.left - 1;
    }
    expect(c1.left, 1700);
    // enter Part 2 with the SAME session -> continues, no reset
    final c2 = MockListeningController(s, data, 2);
    expect(c2.left, 1700);
    // Actual render hook calls startMockTimer(true) on EVERY Part 1 entry.
    final c1b = MockListeningController(s, data, 1);
    expect(c1b.left, 1800);
  });

  test('source answers and dots belong only to the current rendered part', () {
    final s = AppState();
    final c1 = MockListeningController(s, data, 1);
    c1.pickMc(1, 1);
    c1.fill(7, 'deposit');
    expect(c1.done.containsAll({1, 7}), true);
    expect(c1.dots, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    final c2 = MockListeningController(s, data, 2);
    // Source re-creates blank inputs/dots; no cross-part answers object exists.
    expect(c2.done, isEmpty);
    expect(c2.ans, isEmpty);
    expect(c2.dots, [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
    c2.fill(11, 'tall');
    c2.pickMatch(17, 'A');
    expect(c2.answeredAll, 2);
    // clearing text removes from done
    c2.fill(11, '');
    expect(c2.done.contains(11), false);
    c2.fill(11, '  ');
    expect(c2.ans[11], '  ');
    expect(c2.done.contains(11), false);
    final again = MockListeningController(s, data, 1);
    expect(again.ans, isEmpty);
    expect(again.done, isEmpty);
  });

  test('timer tick expires at 0 and stays', () {
    final s = AppState()..session['mockLeft'] = 2;
    // fresh part 2 controller must not reset
    final c = MockListeningController(s, data, 2);
    expect(c.left, 2);
    expect(c.tick(), false); // ->1
    expect(c.tick(), true); // ->0 expired
    expect(c.tick(), true); // stays expired
    expect(c.left, 0);
  });

  testWidgets('Part 1 page renders exact Qs at 390px with next button',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final state = AppState(current: SurgoPage.mockListeningQ);
    await t.pumpWidget(_host(state, SurgoPage.mockListeningQ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('第 1 部分播放中'), findsOneWidget);
    expect(find.text('第 1-6 题'), findsOneWidget);
    await t.scrollUntilVisible(find.text('第 7-10 题'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('第 7-10 题'), findsOneWidget);
    await t.scrollUntilVisible(find.text('进入下一部分 →'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('进入下一部分 →'), findsOneWidget);
    // pick an option -> answer sheet reflects it
    await t.scrollUntilVisible(find.text('birthday party.'), -400,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('birthday party.'));
    await t.pump();
    await t.tap(find.text('birthday party.'));
    await t.pump();
    // 答题卡改为顶部「☰ 题号」弹出，先打开再查进度点。
    await t.ensureVisible(find.byKey(const ValueKey('mock-listening-nav-open')));
    await t.tap(find.byKey(const ValueKey('mock-listening-nav-open')));
    await t.pumpAndSettle();
    final dot = t.widget<Container>(find.byKey(const ValueKey('mock-dot-1')));
    expect((dot.decoration as BoxDecoration).color, SurgoColors.yellow);
    expect(state.session.containsKey('mockDone'), false);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Part 2 renders table + map svg at 390px', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final state = AppState(current: SurgoPage.mockListeningQ2);
    await t.pumpWidget(_host(state, SurgoPage.mockListeningQ2));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('MISSING PERSON DESCRIPTION'), findsOneWidget);
    await t.scrollUntilVisible(find.text('第 17-20 题'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('第 17-20 题'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Part 3 renders matching box + MC at 390px', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final state = AppState(current: SurgoPage.mockListeningQ3);
    await t.pumpWidget(_host(state, SurgoPage.mockListeningQ3));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('第 21-25 题'), findsOneWidget);
    await t.scrollUntilVisible(find.text('第 26-30 题'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('第 26-30 题'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Part 4 submit runs review countdown then feedback', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final state = AppState(current: SurgoPage.mockListeningQ4);
    await t.pumpWidget(_host(state, SurgoPage.mockListeningQ4));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('SURVEY METHODS'), findsOneWidget);
    await t.scrollUntilVisible(find.text('提交 →'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('提交 →'), findsOneWidget);
    await t.ensureVisible(find.text('提交 →'));
    await t.tap(find.text('提交 →'));
    await t.pump();
    // review window text shows up (第 4 部分结束…)
    await t.pump(const Duration(seconds: 1));
    await t.scrollUntilVisible(find.textContaining('第 4 部分结束'), -400,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('第 4 部分结束'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump();
  });
}
