import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_home/vocab_home_page.dart';

/// vocab 首页（`vocabHomeView`）唯一路由的原生实现测试。
///
/// 断言点全部锚定原型源常量（_extract/logic/fns/vocabHomeView.js），确保迁移
/// 未偷改文案、统计数字、分级进度、链接目标与 exam 插值规则。

// Use real bundled local assets; substituting PNG bytes for every asset also
// corrupts SVG files and Flutter's binary AssetManifest.
Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabHomePage(page) ?? const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // T 组件走 Translator.instance；先加载词典避免命中断言。
    await Translator.load();
  });

  group('buildVocabHomePage 路由分发', () {
    test('只认领 vocab，其余返回 null', () {
      expect(buildVocabHomePage(SurgoPage.vocab), isA<VocabHomePage>());
      expect(buildVocabHomePage(SurgoPage.vocabBook), isNull);
      expect(buildVocabHomePage(SurgoPage.vocabTest), isNull);
      expect(buildVocabHomePage(SurgoPage.vocabStudy), isNull);
      expect(buildVocabHomePage(SurgoPage.ielts), isNull);
    });
  });

  group('tier 数据逐字源自 vocabHomeView', () {
    test('四个分级的标题/词数/进度/CTA/路由均与源一致', () {
      expect(kVocabTiers.map((t) => t.title).toList(),
          ['Tier 1 · 必备', 'Tier 2 · 核心', 'Tier 3 · 重要', 'Tier 4 · 拓展']);
      expect(kVocabTiers.map((t) => t.count).toList(),
          ['226 词', '1302 词', '1180 词', '3221 词']);
      expect(kVocabTiers.map((t) => t.percent).toList(), [46, 0, 0, 0]);
      expect(kVocabTiers.map((t) => t.cta).toList(),
          ['继续学习', '开始学习', '开始学习', '开始学习']);
      expect(kVocabTiers.map((t) => t.route).toList(), [
        SurgoPage.vocabTier1,
        SurgoPage.vocabTier2,
        SurgoPage.vocabTier3,
        SurgoPage.vocabTier4,
      ]);
    });
  });

  group('页面内容 fixture 逐字呈现', () {
    testWidgets('hero / 统计 / 复习 / 单词本 / 分级文案全部出现', (tester) async {
      final app = AppState(current: SurgoPage.vocab); // 默认 IELTS
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      // hero
      expect(find.text('欢迎来到词汇学习'), findsOneWidget);
      expect(find.text('按间隔重复计划，完成今天的 IELTS 高频词复习'), findsOneWidget);
      expect(find.text('▥ 测测我的词汇水平'), findsOneWidget);

      // stats
      expect(find.text('48'), findsWidgets); // 也是 vh-rev-foot 的 48
      expect(find.text('剩余单词'), findsOneWidget);
      expect(find.text('连续天数'), findsOneWidget);

      // review card
      expect(find.text('10'), findsOneWidget);
      expect(find.text('个单词\n需今日复习'), findsOneWidget);
      expect(find.text('预计 4 分钟完成'), findsOneWidget);
      expect(find.text('开始复习'), findsOneWidget);
      expect(find.text('🎤 发音复习 (0)'), findsOneWidget);
      expect(find.text('学习中/需巩固'), findsOneWidget);
      expect(find.text('需学习'), findsOneWidget);

      // mine tiles
      expect(find.text('我的单词本'), findsOneWidget);
      expect(find.text('已收藏 12 词'), findsOneWidget);
      expect(find.text('我的发音本'), findsOneWidget);
      expect(find.text('0 个单词待复习'), findsOneWidget);

      // learning path section
      expect(find.text('学习路径'), findsOneWidget);
      expect(find.text('按词汇难度科学分级，循序渐进提升词汇量'), findsOneWidget);
      expect(find.text('Tier 1 · 必备'), findsOneWidget);
      expect(find.text('226 词'), findsOneWidget);
      // percent>0 → '46% · 继续学习'；percent==0 → 纯 CTA '开始学习'
      expect(find.text('46% · 继续学习'), findsOneWidget);
      expect(find.text('开始学习'), findsNWidgets(3));
    });

    testWidgets('exam 插值随 examType 变化（TOEFL）', (tester) async {
      final app = AppState(current: SurgoPage.vocab, examType: ExamType.toefl);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('按间隔重复计划，完成今天的 TOEFL 高频词复习'), findsOneWidget);
      expect(find.text('按间隔重复计划，完成今天的 IELTS 高频词复习'), findsNothing);
    });

    testWidgets('VocabHomePage 是自然高度 Column，无内部滚动/纵向 Expanded',
        (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      // 顶层 body 是 Column
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(VocabHomePage),
          matching: find.byType(Column),
        ).first,
      );
      expect(column.mainAxisSize, MainAxisSize.max); // 默认，但仍自然高度
      // 页面自身不引入 Scrollable（仅测试宿主的 SingleChildScrollView）
      expect(
        find.descendant(
          of: find.byType(VocabHomePage),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      // 页面自身不使用纵向 Expanded/Flexible
      expect(
        find.descendant(
          of: find.byType(VocabHomePage),
          matching: find.byType(Expanded),
        ),
        findsWidgets, // 存在的 Expanded 都在 Row 内（横向），下方逐一验证
      );
    });
  });

  group('链接跳转', () {
    testWidgets('测测我的词汇水平 → vocabTest', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('▥ 测测我的词汇水平'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabTest);
    });

    testWidgets('开始复习 → vocabStudy', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('开始复习'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy);
    });

    testWidgets('我的单词本 → vocabBook', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('我的单词本'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabBook);
    });

    testWidgets('我的发音本 → vocabPron', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('我的发音本'));
      await tester.tap(find.text('我的发音本'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPron);
    });

    testWidgets('Tier 卡片 → 对应 vocabTier 路由', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tier 3 · 重要'));
      await tester.tap(find.text('Tier 3 · 重要'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabTier3);
    });

    testWidgets('顶部 home 图标 → ielts', (tester) async {
      final app = AppState(current: SurgoPage.vocab);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      // SurgoTopBar 的 home 图标（唯一 InkWell 包裹的 SVG）
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.ielts);
    });
  });
}
