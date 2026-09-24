import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/report/report_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Translator.load();
  });

  /// ReportPage 产出自然高度内容，滚动由 shell 的单一 SingleChildScrollView
  /// 负责。测试里用同一模式包一层滚动容器，再配合 ensureVisible 把目标滚入视口
  /// 后交互——不再依赖页面内嵌滚动或假设视口无限高。
  Future<void> pumpReport(WidgetTester tester, AppState state) {
    return tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: state,
          child: const Scaffold(
            body: SingleChildScrollView(child: ReportPage()),
          ),
        ),
      ),
    );
  }

  testWidgets('ReportPage renders with fixture data', (tester) async {
    final state = AppState();
    await pumpReport(tester, state);

    // 验证整体得分显示 6.3
    expect(find.textContaining('6.3'), findsAtLeastNWidgets(1));

    // 验证四轴名称
    expect(find.text('写作'), findsWidgets);
    expect(find.text('阅读'), findsWidgets);
    expect(find.text('听力'), findsWidgets);
    expect(find.text('口语'), findsWidgets);

    // 验证四科分数（含固定的 6.3 六舍五入行为外的源始值）
    expect(find.text('6.5'), findsWidgets); // writing
    expect(find.text('5.5'), findsWidgets); // reading
    expect(find.text('7.0'), findsWidgets); // listening
    expect(find.text('6.0'), findsWidgets); // speaking
  });

  testWidgets('Subscribe button toggles', (tester) async {
    final state = AppState();
    await pumpReport(tester, state);

    // 订阅条在页尾，先滚入视口
    await tester.ensureVisible(find.text('订阅'));
    await tester.pumpAndSettle();

    expect(find.text('订阅'), findsOneWidget);
    expect(find.text('已订阅'), findsNothing);

    // 点击切换
    await tester.tap(find.text('订阅'));
    await tester.pump();

    expect(find.text('已订阅'), findsOneWidget);
    expect(find.text('订阅'), findsNothing);

    // 再次点击切回
    await tester.ensureVisible(find.text('已订阅'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已订阅'));
    await tester.pump();

    expect(find.text('订阅'), findsOneWidget);
  });

  testWidgets('Reading goal CTA sets examType=ielts and navigates', (tester) async {
    final state = AppState(examType: ExamType.ielts);
    await pumpReport(tester, state);

    // 找到"Reading 阅读"目标卡并滚入视口
    final goalCard = find.byKey(const ValueKey('report-goal'));
    expect(goalCard, findsOneWidget);
    await tester.ensureVisible(goalCard);
    await tester.pumpAndSettle();

    // 点击
    await tester.tap(goalCard);
    await tester.pump();

    // 原型 onclick="examType='ielts';selReadType=null;go('readingDaily')"
    expect(state.examType, ExamType.ielts);
    expect(state.current, SurgoPage.readingDaily);
    expect(state.session['selReadType'], isNull);
  });

  testWidgets('Radar chart renders with CustomPainter inside a 236x236 box', (tester) async {
    final state = AppState();
    await pumpReport(tester, state);

    // 雷达图 CustomPaint 存在（页面其它地方不使用 CustomPaint）
    expect(find.byType(CustomPaint), findsWidgets);

    // Source SVG is 236×236 inside a 238px-high wrapper. Assert the actual
    // painter's render bounds, not the old wrapper implementation.
    final radar = find.byWidgetPredicate((w) => w is CustomPaint &&
      w.painter != null && w.size == const Size(236, 236));
    expect(radar, findsOneWidget);
    expect(tester.getSize(radar), const Size(236, 236));
  });

  testWidgets('Overall score calculation is correct', (tester) async {
    final state = AppState();
    await pumpReport(tester, state);

    // (6.5 + 5.5 + 7.0 + 6.0) / 4 = 6.25 → toStringAsFixed(1) = "6.3"
    expect(find.textContaining('6.3'), findsAtLeastNWidgets(1));

    // 原型先把 overall 四舍五入为字符串6.3，再计算差距：7 - 6.3 = 0.7。
    expect(find.textContaining('0.7'), findsWidgets);
  });
}
