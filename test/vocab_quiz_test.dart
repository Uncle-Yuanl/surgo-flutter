import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_quiz/vocab_quiz_module.dart';

Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabQuizPage(page) ?? const SizedBox.shrink();
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

  group('buildVocabQuizPage routing', () {
    test('returns widgets only for the 9 owned pages', () {
      expect(buildVocabQuizPage(SurgoPage.vocabTest), isA<VocabTestPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabTestQ), isA<VocabTestQPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabTestPass), isA<VocabTestResultPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabTestFail), isA<VocabTestResultPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabStudy), isA<VocabStudyPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabStudy2), isA<VocabStudyPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabStudy3), isA<VocabStudyPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabStudy4), isA<VocabStudyPage>());
      expect(buildVocabQuizPage(SurgoPage.vocabDone), isA<VocabDonePage>());
    });

    test('pass vs fail flag is wired through', () {
      final pass = buildVocabQuizPage(SurgoPage.vocabTestPass) as VocabTestResultPage;
      final fail = buildVocabQuizPage(SurgoPage.vocabTestFail) as VocabTestResultPage;
      expect(pass.pass, isTrue);
      expect(fail.pass, isFalse);
    });

    test('returns null for pages this module does not own', () {
      expect(buildVocabQuizPage(SurgoPage.vocab), isNull);
      expect(buildVocabQuizPage(SurgoPage.vocabBook), isNull);
      expect(buildVocabQuizPage(SurgoPage.vocabWord), isNull);
      expect(buildVocabQuizPage(SurgoPage.vocabDetail), isNull);
      expect(buildVocabQuizPage(SurgoPage.vocabTier1), isNull);
      expect(buildVocabQuizPage(SurgoPage.vocabTier2), isNull);
    });
  });

  group('quiz grading — known / fuzzy / unknown paths (vocabTestQView)', () {
    test('the four fixed options are verbatim, A is correct', () {
      expect(kVocabQuizOptions.length, 4);
      expect(kVocabQuizOptions[0].key, 'A');
      expect(kVocabQuizOptions[0].def, '识别；确认；认出');
      expect(kVocabQuizOptions[0].correct, isTrue);
      expect(kVocabQuizOptions[1].key, 'B');
      expect(kVocabQuizOptions[1].def, '适应；改编');
      expect(kVocabQuizOptions[2].key, 'C');
      expect(kVocabQuizOptions[2].def, '分析');
      expect(kVocabQuizOptions[3].key, 'D');
      expect(kVocabQuizOptions[3].def, '语境；背景');
      // Only A is correct.
      expect(kVocabQuizOptions.where((o) => o.correct).map((o) => o.key), ['A']);
    });

    test('known path (correct A) → Tier 2; fuzzy/unknown → Tier 1', () {
      // Known: the correct answer recommends the harder tier.
      expect(vocabQuizTarget(correct: true), SurgoPage.vocabTier2);
      // Fuzzy (a wrong option) and unknown (skip) both fall back to Tier 1.
      expect(vocabQuizTarget(correct: false), SurgoPage.vocabTier1);
    });

    testWidgets('tapping A routes to Tier 2, tapping B routes to Tier 1',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabTestQ);
      await tester.pumpWidget(_host(app));

      // Known path: correct option A.
      await tester.tap(find.byKey(const ValueKey('vocab-option-A')));
      expect(app.current, SurgoPage.vocabTier2);

      // Reset and take the fuzzy path: wrong option B.
      app.go(SurgoPage.vocabTestQ);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('vocab-option-B')));
      expect(app.current, SurgoPage.vocabTier1);
    });

    testWidgets('unknown path: "不确定，跳过这题" routes to Tier 1', (tester) async {
      final app = AppState(current: SurgoPage.vocabTestQ);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('不确定，跳过这题'));
      expect(app.current, SurgoPage.vocabTier1);
    });
  });

  group('test intro + result — source constants (vocabTest/Result)', () {
    testWidgets('vocabTest intro text + start/skip transitions', (tester) async {
      final app = AppState(current: SurgoPage.vocabTest);
      await tester.pumpWidget(_host(app));
      expect(find.text('词汇分级测试'), findsOneWidget);
      expect(
        find.text('几分钟的选择题，帮你找到合适的起始难度；答对的单词会直接标记为已掌握。'),
        findsOneWidget,
      );
      await tester.tap(find.text('开始测试'));
      expect(app.current, SurgoPage.vocabTestQ);
    });

    testWidgets('pass result: 推荐从 Tier 2 开始 / 答对 1/1', (tester) async {
      final app = AppState(current: SurgoPage.vocabTestPass);
      await tester.pumpWidget(_host(app));
      expect(find.text('推荐从 Tier 2 开始'), findsOneWidget);
      expect(find.text('答对 1/1 — 已认识的单词已标记为掌握。'), findsOneWidget);
      await tester.tap(find.text('开始学习'));
      expect(app.current, SurgoPage.vocabStudy4);
    });

    testWidgets('fail result: 推荐从 Tier 1 开始 / 答对 0/1', (tester) async {
      final app = AppState(current: SurgoPage.vocabTestFail);
      await tester.pumpWidget(_host(app));
      expect(find.text('推荐从 Tier 1 开始'), findsOneWidget);
      expect(find.text('答对 0/1 — 已认识的单词已标记为掌握。'), findsOneWidget);
    });
  });

  group('study cards — source constants (vocabStudy{,2,3,4}View)', () {
    test('four cards keep verbatim words / IPA / progress / reveal target', () {
      final s1 = kVocabStudyData[SurgoPage.vocabStudy]!;
      expect(s1.word, 'Identify');
      expect(s1.ipa, '/aɪˈden.tɪ.faɪ/');
      expect(s1.barPct, 0.50);
      expect(s1.progress, '1/2 · 系统词汇复习');
      expect(s1.reveal, SurgoPage.vocabDetail);
      expect(s1.showTipIcon, isTrue);

      final s2 = kVocabStudyData[SurgoPage.vocabStudy2]!;
      expect(s2.word, 'Adapt');
      expect(s2.ipa, '/əˈdæpt/');
      expect(s2.barPct, 0.666);
      expect(s2.progress, '2/3 · 学习中');
      expect(s2.reveal, SurgoPage.vocabDetail2);
      // vocabStudy2View omits the otter tip image.
      expect(s2.showTipIcon, isFalse);

      final s3 = kVocabStudyData[SurgoPage.vocabStudy3]!;
      expect(s3.word, 'Analyse');
      expect(s3.ipa, '/ˈæn.əl.aɪz/');
      expect(s3.barPct, 1.0);
      expect(s3.progress, '2/2 · 系统词汇复习');
      expect(s3.reveal, SurgoPage.vocabDetail3);

      final s4 = kVocabStudyData[SurgoPage.vocabStudy4]!;
      expect(s4.word, 'Context');
      expect(s4.ipa, '/ˈkɒn.tekst/');
      expect(s4.barPct, 1.0);
      expect(s4.progress, '1/1 · 学习中');
      expect(s4.reveal, SurgoPage.vocabDetail4);
    });

    testWidgets('study renders fixed word + recall prompt, reveal navigates',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabStudy);
      await tester.pumpWidget(_host(app));
      expect(find.text('识别'), findsOneWidget);
      expect(find.text('/aɪˈden.tɪ.faɪ/'), findsOneWidget);
      expect(find.text('先在脑中回忆这个词的意思'), findsOneWidget);
      expect(find.text('1/2 · 系统词汇复习'), findsOneWidget);
      expect(find.text('演示数据'), findsOneWidget);
      await tester.tap(find.text('查看释义'));
      expect(app.current, SurgoPage.vocabDetail);
    });
  });

  group('vocabDone — fixed demo scores (vocabDoneView)', () {
    testWidgets('shows 2/1/32 demo stats and both foot transitions',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabDone);
      await tester.pumpWidget(_host(app));
      expect(find.text('你完成了 2 个单词，记忆提高了不止一点～'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 已复习
      expect(find.text('32'), findsOneWidget); // 待巩固
      expect(find.text('已复习'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('待巩固'), findsOneWidget);
      expect(find.text('做得很好！'), findsOneWidget);
      expect(find.text('我们会帮助你巩固的！'), findsOneWidget);

      await tester.tap(find.text('返回词汇首页'));
      expect(app.current, SurgoPage.vocab);

      app.go(SurgoPage.vocabDone);
      await tester.pump();
      await tester.tap(find.text('复习待巩固单词'));
      expect(app.current, SurgoPage.vocabStudy);
    });
  });
}
