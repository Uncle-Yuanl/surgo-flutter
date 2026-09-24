import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_tiers/vocab_tiers_module.dart';

Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabTiersPage(page) ?? const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
  });

  group('buildVocabTiersPage routing', () {
    test('returns widgets only for owned pages', () {
      expect(buildVocabTiersPage(SurgoPage.vocabTier1), isA<VocabTierPage>());
      expect(buildVocabTiersPage(SurgoPage.vocabTier2), isA<VocabTierPage>());
      expect(buildVocabTiersPage(SurgoPage.vocabTier3), isA<VocabTierPage>());
      expect(buildVocabTiersPage(SurgoPage.vocabTier4), isA<VocabTierPage>());
      expect(buildVocabTiersPage(SurgoPage.vocabNoNew), isA<VocabNoNewPage>());
      // Not owned by this module.
      expect(buildVocabTiersPage(SurgoPage.vocab), isNull);
      expect(buildVocabTiersPage(SurgoPage.vocabBook), isNull);
      expect(buildVocabTiersPage(SurgoPage.vocabStudy4), isNull);
    });
  });

  group('tier config verbatim from source', () {
    test('Tier 1 preserves hero/count/progress/stats/chips and target', () {
      final c = kVocabTierConfigs[SurgoPage.vocabTier1]!;
      expect(c.heroTitle, 'Tier 1 · 必备');
      expect(c.heroSub, '226 个词 · 必备词汇');
      expect(c.target, SurgoPage.vocabStudy4);
      expect(c.progTitle, 'Tier 1 学习进度');
      expect(c.pct, 46);
      expect(c.mastered, '86');
      expect(c.reviewed, '18');
      expect(c.pending, '122');
      expect(c.previewTitle, 'Tier 1 词汇预览');
      expect(c.previewSub, '共 226 个单词，展示部分高频词');
      expect(c.chips, ['identify', 'adapt', 'analyse']);
      expect(c.chipsMuted, isFalse);
    });

    test('Tier 2 preserves counts and single context chip → vocabStudy4', () {
      final c = kVocabTierConfigs[SurgoPage.vocabTier2]!;
      expect(c.heroTitle, 'Tier 2 · 核心');
      expect(c.heroSub, '1302 个词 · 核心词汇');
      expect(c.target, SurgoPage.vocabStudy4);
      expect(c.pct, 0);
      expect(c.mastered, '0');
      expect(c.reviewed, '0');
      expect(c.pending, '1302');
      expect(c.previewSub, '共 1302 个单词，展示部分高频词');
      expect(c.chips, ['context']);
      expect(c.chipsMuted, isFalse);
    });

    test('Tier 3 uses muted placeholder chip and routes vocabNoNew', () {
      final c = kVocabTierConfigs[SurgoPage.vocabTier3]!;
      expect(c.heroTitle, 'Tier 3 · 重要');
      expect(c.heroSub, '1180 个词 · 重要词汇');
      expect(c.target, SurgoPage.vocabNoNew);
      expect(c.pending, '1180');
      expect(c.previewSub, '共 1180 个单词，展示部分高频词');
      expect(c.chips, ['词汇材料待提供']);
      expect(c.chipsMuted, isTrue);
    });

    test('Tier 4 uses muted placeholder chip and routes vocabNoNew', () {
      final c = kVocabTierConfigs[SurgoPage.vocabTier4]!;
      expect(c.heroTitle, 'Tier 4 · 拓展');
      expect(c.heroSub, '3221 个词 · 拓展词汇');
      expect(c.target, SurgoPage.vocabNoNew);
      expect(c.pending, '3221');
      expect(c.previewSub, '共 3221 个单词，展示部分高频词');
      expect(c.chips, ['词汇材料待提供']);
      expect(c.chipsMuted, isTrue);
    });
  });

  group('tier page renders + navigation', () {
    testWidgets('Tier 1 shows verbatim text and stat numbers', (tester) async {
      final app = AppState(current: SurgoPage.vocabTier1);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('Tier 1 · 必备'), findsOneWidget);
      expect(find.text('226 个词 · 必备词汇'), findsOneWidget);
      expect(find.text('Tier 1 学习进度'), findsOneWidget);
      expect(find.text('86'), findsOneWidget); // 已掌握
      expect(find.text('18'), findsOneWidget); // 已复习
      expect(find.text('122'), findsOneWidget); // 待巩固
      expect(find.text('共 226 个单词，展示部分高频词'), findsOneWidget);
      // chip words appear in both tr-next and tr-prev
      expect(find.text('识别'), findsNWidgets(2));
    });

    testWidgets('Tier 1 继续学习 → routes to vocabStudy4', (tester) async {
      final app = AppState(current: SurgoPage.vocabTier1);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('继续学习 →'));
      await tester.tap(find.text('继续学习 →'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy4);
    });

    testWidgets('Tier 1 开始学习 routes to vocabStudy4', (tester) async {
      final app = AppState(current: SurgoPage.vocabTier1);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('开始学习'));
      await tester.tap(find.text('开始学习'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy4);
    });

    testWidgets('Tier 3 开始学习 routes to vocabNoNew', (tester) async {
      final app = AppState(current: SurgoPage.vocabTier3);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('词汇材料待提供'), findsNWidgets(2));
      await tester.ensureVisible(find.text('开始学习'));
      await tester.tap(find.text('开始学习'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabNoNew);
    });

    testWidgets('查看全部词汇 → routes to vocabBook', (tester) async {
      final app = AppState(current: SurgoPage.vocabTier2);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('查看全部词汇 →'));
      await tester.tap(find.text('查看全部词汇 →'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabBook);
    });
  });

  group('vocabNoNew page', () {
    testWidgets('shows empty-state text and returns to vocab', (tester) async {
      final app = AppState(current: SurgoPage.vocabNoNew);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('当前没有新单词'), findsOneWidget);
      await tester.ensureVisible(find.text('返回词汇首页'));
      await tester.tap(find.text('返回词汇首页'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocab);
    });
  });
}
