import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/ielts_mock_listening_module.dart';
import 'package:surgo_flutter/features/ielts_mock_listening/mock_listening_data.dart';
import 'package:surgo_flutter/widgets/primitives.dart';

Widget host(AppState app) => ChangeNotifierProvider.value(value: app,
  child: MaterialApp(home: Scaffold(body: Consumer<AppState>(builder: (_, s, __) =>
    mockListeningPartOf.containsKey(s.current)
      ? MockListeningPage(key: ValueKey('${s.current}-${s.revision}'), page: s.current)
      : Text(s.current.name)))));
Finder get questions => find.descendant(of: find.byKey(const ValueKey('mock-listening-questions')), matching: find.byType(Scrollable)).first;
Future<void> mount(WidgetTester t, AppState app) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(host(app));
  await t.pumpAndSettle();
}
Future<void> submit(WidgetTester t) async {
  await t.scrollUntilVisible(find.text('提交 →'), 500, scrollable: questions);
  await t.ensureVisible(find.text('提交 →'));
  await t.tap(find.text('提交 →'));
  await t.pump();
}
String tip(WidgetTester t) => t.widget<Text>(find.textContaining('第 4 部分结束')).data!;
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await MockListeningData.load();
  });
  testWidgets('home continues or exits without marking; exit stops both clocks', (t) async {
    final app = AppState(current: SurgoPage.mockListeningQ4);
    await mount(t, app);
    await submit(t);
    await t.scrollUntilVisible(find.byKey(const ValueKey('mock-listening-home')), -500, scrollable: questions);
    await t.tap(find.byKey(const ValueKey('mock-listening-home')));
    await t.pumpAndSettle();
    expect(find.text('确定要退出考试吗？'), findsOneWidget);
    expect(find.text('确定要现在结束考试吗？结束后将无法返回。'), findsNothing);
    final before = app.session['mockLeft'] as int;
    await t.pump(const Duration(seconds: 2));
    expect(app.session['mockLeft'], before - 2);
    await t.tap(find.text('继续考试'));
    await t.pumpAndSettle();
    expect(app.current, SurgoPage.mockListeningQ4);
    await t.tap(find.byKey(const ValueKey('mock-listening-home')));
    await t.pumpAndSettle();
    await t.tap(find.text('退出考试'));
    await t.pumpAndSettle();
    final stopped = app.session['mockLeft'];
    await t.pump(const Duration(seconds: 125));
    expect(app.current, SurgoPage.ielts);
    expect(app.session['mockLeft'], stopped);
    expect(find.byType(Dialog), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('repeat Part4 submit resets 118s; marks only below zero', (t) async {
    final app = AppState(current: SurgoPage.mockListeningQ4);
    await mount(t, app);
    await submit(t);
    expect(tip(t), endsWith('(01:58)'));
    await t.pump(const Duration(seconds: 10));
    expect(tip(t), endsWith('(01:48)'));
    // 重复提交：去掉提示卡后版式上移，直接 tap 会打空，先滚到按钮。
    await submit(t);
    expect(tip(t), endsWith('(01:58)'));
    await t.pump(const Duration(seconds: 118));
    expect(tip(t), endsWith('(00:00)'));
    expect(find.byType(Dialog), findsNothing);
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.byType(Dialog), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 250));
    await t.pumpAndSettle();
    expect(app.current, SurgoPage.listeningFeedback);
    expect(t.takeException(), isNull);
  });
  testWidgets('early end retains main clock during marking, then stops on navigation', (t) async {
    final app = AppState(current: SurgoPage.mockListeningQ2);
    await mount(t, app);
    await t.tap(find.text('结束考试')); await t.pumpAndSettle();
    final end = find.descendant(of: find.byType(Dialog), matching: find.byWidgetPredicate((w) => w is SurgoButton && w.label == '结束考试'));
    await t.tap(end); await t.pump();
    await t.pump(); // Start the newly mounted marking ticker before advancing time.
    final before = app.session['mockLeft'] as int;
    await t.pump(const Duration(seconds: 1));
    expect(app.session['mockLeft'], before - 1);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 250));
    await t.pumpAndSettle();
    expect(app.current, SurgoPage.listeningFeedback);
    final stopped = app.session['mockLeft'];
    await t.pump(const Duration(seconds: 5));
    expect(app.session['mockLeft'], stopped);
  });
  testWidgets('expiry replaces exit modal instead of leaving one underneath', (t) async {
    final app = AppState(current: SurgoPage.mockListeningQ2)..session['mockLeft'] = 2;
    await mount(t, app);
    await t.tap(find.byKey(const ValueKey('mock-listening-home')));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('确定要退出考试吗？'), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 250));
    await t.pumpAndSettle();
    expect(app.current, SurgoPage.listeningFeedback);
    expect(find.byType(Dialog), findsNothing);
  });
  testWidgets('number nav opens from the sheet button and shows progress', (t) async {
    // 用户 2026-09-24：模拟考版式改回与听力日常训练一致 —— 题目放可拖拽面板，
    // 面板把手上带「Answered n / 10」与「☰ 题号」，题号仍是弹窗，不是常驻面板。
    final app = AppState(current: SurgoPage.mockListeningQ);
    await mount(t, app);
    expect(find.byKey(const ValueKey('mock-listening-sheet-handle')), findsOneWidget);
    expect(find.byKey(const ValueKey('mock-dot-1')), findsNothing);

    await t.tap(find.byKey(const ValueKey('mock-listening-nav-open')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mock-dot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('mock-dot-10')), findsOneWidget);
    // 图 2 统一样式：标题、图例、交卷按钮。
    expect(find.text('题号导航'), findsOneWidget);
    expect(find.text('未作答'), findsOneWidget);
    expect(find.text('交卷'), findsOneWidget);

    // 关掉面板后题目滚动位置不变。
    final qState = t.state<ScrollableState>(questions);
    final offset = qState.position.pixels;
    Navigator.of(t.element(find.byKey(const ValueKey('mock-dot-1')))).pop();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mock-dot-1')), findsNothing);
    expect(qState.position.pixels, offset);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });
}
