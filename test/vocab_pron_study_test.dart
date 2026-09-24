import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_pron_study/vocab_pron_study_module.dart';

/// Hosts the module the way the shell does: watch `AppState.current`, build the
/// owned page, scroll externally (the shell owns vertical scroll — the module
/// never adds its own scroll view or vertical Expanded).
Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabPronStudyPage(page) ?? const SizedBox.shrink();
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

  group('buildVocabPronStudyPage routing', () {
    test('returns widgets only for the 7 owned pages', () {
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudy),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudy2),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudy3),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudyB),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudyB2),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronStudyB3),
          isA<VocabPronStudyPage>());
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronDone),
          isA<VocabPronDonePage>());
    });

    test('returns null for pages this module does not own', () {
      expect(buildVocabPronStudyPage(SurgoPage.vocabPron), isNull);
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronWord), isNull);
      expect(buildVocabPronStudyPage(SurgoPage.vocabPronWord2), isNull);
      expect(buildVocabPronStudyPage(SurgoPage.vocabStudy), isNull);
      expect(buildVocabPronStudyPage(SurgoPage.vocabDone), isNull);
      expect(buildVocabPronStudyPage(SurgoPage.vocab), isNull);
    });
  });

  group('study data — verbatim source constants (vocabPronStudy*View)', () {
    test('word 1 (Identify) carries example, 1/2 · 发音复习, 50% across 3 states',
        () {
      for (final p in [
        SurgoPage.vocabPronStudy,
        SurgoPage.vocabPronStudy2,
        SurgoPage.vocabPronStudy3,
      ]) {
        final d = kVocabPronStudyData[p]!;
        expect(d.word, 'Identify');
        expect(d.ipa, '/aɪˈden.tɪ.faɪ/');
        expect(
          d.example,
          'The study aimed to identify the main factors that discourage people from cycling to work.',
        );
        expect(d.barPct, 0.50);
        expect(d.progress, '1/2 · 发音复习');
      }
    });

    test('word 2 (Adapt) has no example, 2/2 · 发音复习, 100% across 3 states',
        () {
      for (final p in [
        SurgoPage.vocabPronStudyB,
        SurgoPage.vocabPronStudyB2,
        SurgoPage.vocabPronStudyB3,
      ]) {
        final d = kVocabPronStudyData[p]!;
        expect(d.word, 'Adapt');
        expect(d.ipa, '/əˈdæpt/');
        expect(d.example, isNull);
        expect(d.barPct, 1.0);
        expect(d.progress, '2/2 · 发音复习');
      }
    });

    test('phases and forward/retake transitions match the source chain', () {
      final s1 = kVocabPronStudyData[SurgoPage.vocabPronStudy]!;
      expect(s1.phase, VocabPronPhase.read);
      expect(s1.forward, SurgoPage.vocabPronStudy2);
      expect(s1.retake, isNull);

      final s2 = kVocabPronStudyData[SurgoPage.vocabPronStudy2]!;
      expect(s2.phase, VocabPronPhase.recording);
      expect(s2.forward, SurgoPage.vocabPronStudy3);

      final s3 = kVocabPronStudyData[SurgoPage.vocabPronStudy3]!;
      expect(s3.phase, VocabPronPhase.judge);
      expect(s3.forward, SurgoPage.vocabPronStudyB);
      expect(s3.retake, SurgoPage.vocabPronStudy);

      final b1 = kVocabPronStudyData[SurgoPage.vocabPronStudyB]!;
      expect(b1.phase, VocabPronPhase.read);
      expect(b1.forward, SurgoPage.vocabPronStudyB2);

      final b2 = kVocabPronStudyData[SurgoPage.vocabPronStudyB2]!;
      expect(b2.phase, VocabPronPhase.recording);
      expect(b2.forward, SurgoPage.vocabPronStudyB3);

      final b3 = kVocabPronStudyData[SurgoPage.vocabPronStudyB3]!;
      expect(b3.phase, VocabPronPhase.judge);
      expect(b3.forward, SurgoPage.vocabPronDone);
      expect(b3.retake, SurgoPage.vocabPronStudyB);
    });
  });

  group('read state (vocabPronStudy / vocabPronStudyB)', () {
    testWidgets('word 1 shows word, IPA, example, read prompt, demo badge',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy);
      await tester.pumpWidget(_host(app));
      expect(find.text('识别'), findsOneWidget);
      expect(find.text('/aɪˈden.tɪ.faɪ/'), findsOneWidget);
      expect(
        find.text(
            'The study aimed to identify the main factors that discourage people from cycling to work.'),
        findsOneWidget,
      );
      expect(find.text('大声朗读这个单词'), findsOneWidget);
      expect(find.text('无法录音？改用手动评价'), findsOneWidget);
      expect(find.text('演示数据'), findsOneWidget);
      expect(find.text('1/2 · 发音复习'), findsOneWidget);
    });

    testWidgets('tapping the mic advances read → recording', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.byKey(const ValueKey('vp-mic')));
      expect(app.current, SurgoPage.vocabPronStudy2);
    });

    testWidgets('word 2 (Adapt) omits the example sentence', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudyB);
      await tester.pumpWidget(_host(app));
      expect(find.text('适应'), findsOneWidget);
      expect(find.text('/əˈdæpt/'), findsOneWidget);
      expect(find.text('大声朗读这个单词'), findsOneWidget);
      expect(find.text('2/2 · 发音复习'), findsOneWidget);
      // No example markup for word 2.
      expect(find.textContaining('The study aimed'), findsNothing);
    });

    testWidgets('exit link returns to vocabPron', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('✕ 退出'));
      expect(app.current, SurgoPage.vocabPron);
    });
  });

  group('recording state (vocabPronStudy2 / vocabPronStudyB2)', () {
    testWidgets('shows recording prompt and stop button', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy2);
      await tester.pumpWidget(_host(app));
      expect(find.text('正在录音…点击停止'), findsOneWidget);
      expect(find.byKey(const ValueKey('vp-mic-rec')), findsOneWidget);
    });

    testWidgets('tapping stop advances recording → judge', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy2);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.byKey(const ValueKey('vp-mic-rec')));
      expect(app.current, SurgoPage.vocabPronStudy3);
    });

    testWidgets('word 2 stop advances to vocabPronStudyB3', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudyB2);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.byKey(const ValueKey('vp-mic-rec')));
      expect(app.current, SurgoPage.vocabPronStudyB3);
    });
  });

  group('judge state (vocabPronStudy3 / vocabPronStudyB3)', () {
    testWidgets('shows the honest self-assessment copy and buttons',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy3);
      await tester.pumpWidget(_host(app));
      expect(find.text('本次未获得自动评分，请诚实评价这次朗读'), findsOneWidget);
      expect(find.text('自动发音评分暂不可用；你的选择只影响复习计划。'), findsOneWidget);
      expect(find.text('没读好'), findsOneWidget);
      expect(find.text('读对了'), findsOneWidget);
      expect(find.text('重新录音'), findsOneWidget);
    });

    testWidgets('either judge button advances word 1 → word 2 (vocabPronStudyB)',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy3);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('没读好'));
      expect(app.current, SurgoPage.vocabPronStudyB);

      app.go(SurgoPage.vocabPronStudy3);
      await tester.pump();
      await tester.tap(find.text('读对了'));
      expect(app.current, SurgoPage.vocabPronStudyB);
    });

    testWidgets('重新录音 returns word 1 judge → its read page', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudy3);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('重新录音'));
      expect(app.current, SurgoPage.vocabPronStudy);
    });

    testWidgets('word 2 judge buttons advance to vocabPronDone', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudyB3);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('读对了'));
      expect(app.current, SurgoPage.vocabPronDone);

      app.go(SurgoPage.vocabPronStudyB3);
      await tester.pump();
      await tester.tap(find.text('没读好'));
      expect(app.current, SurgoPage.vocabPronDone);
    });

    testWidgets('word 2 重新录音 returns to vocabPronStudyB', (tester) async {
      final app = AppState(current: SurgoPage.vocabPronStudyB3);
      await tester.pumpWidget(_host(app));
      await tester.tap(find.text('重新录音'));
      expect(app.current, SurgoPage.vocabPronStudyB);
    });
  });

  group('vocabPronDone — fixed demo feedback (vocabPronDoneView)', () {
    testWidgets('shows 30 已复习 / 14 已掌握 / 32 待巩固 and both foot transitions',
        (tester) async {
      final app = AppState(current: SurgoPage.vocabPronDone);
      await tester.pumpWidget(_host(app));
      expect(find.text('你完成了 30 个单词，记忆提高了不止一点～'), findsOneWidget);
      expect(find.text('30'), findsOneWidget); // 已复习
      expect(find.text('14'), findsOneWidget); // 已掌握
      expect(find.text('32'), findsOneWidget); // 待巩固
      expect(find.text('已复习'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('待巩固'), findsOneWidget);
      expect(find.text('做得很好！'), findsOneWidget);
      expect(find.text('我们会帮助你巩固的！'), findsOneWidget);
      expect(
        find.text('下次复习时间已根据你的选择自动安排，有点模糊的单词，我们会稍后帮你再巩固哦～'),
        findsOneWidget,
      );

      await tester.tap(find.text('返回发音本'));
      expect(app.current, SurgoPage.vocabPron);

      app.go(SurgoPage.vocabPronDone);
      await tester.pump();
      await tester.tap(find.text('复习待巩固单词'));
      expect(app.current, SurgoPage.vocabPronStudy);
    });
  });
}
