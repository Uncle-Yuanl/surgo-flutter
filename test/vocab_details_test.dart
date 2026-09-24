import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_details/vocab_details_module.dart';

Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabDetailsPage(page) ?? const SizedBox.shrink();
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

  group('buildVocabDetailsPage routing', () {
    test('returns widgets only for the four owned detail pages', () {
      expect(buildVocabDetailsPage(SurgoPage.vocabDetail), isA<VocabDetailPage>());
      expect(buildVocabDetailsPage(SurgoPage.vocabDetail2), isA<VocabDetailPage>());
      expect(buildVocabDetailsPage(SurgoPage.vocabDetail3), isA<VocabDetailPage>());
      expect(buildVocabDetailsPage(SurgoPage.vocabDetail4), isA<VocabDetailPage>());
      // Not owned by this module.
      expect(buildVocabDetailsPage(SurgoPage.vocab), isNull);
      expect(buildVocabDetailsPage(SurgoPage.vocabStudy), isNull);
      expect(buildVocabDetailsPage(SurgoPage.vocabWord), isNull);
      expect(buildVocabDetailsPage(SurgoPage.vocabDone), isNull);
    });
  });

  group('detail data verbatim from source', () {
    test('vocabDetail (Identify) keeps full card + real answers text', () {
      final d = kVocabDetailData[SurgoPage.vocabDetail]!;
      expect(d.progressLabel, '1/2 · 系统词汇复习');
      expect(d.progressFraction, 0.50);
      expect(d.word, 'Identify');
      expect(d.pos, 'VERB');
      expect(d.learn, '学习中');
      expect(d.book, '★ 已加入单词本');
      expect(d.ipa, '/aɪˈden.tɪ.faɪ/');
      expect(d.lvl, 'B1 / Tier 1');
      expect(d.defZh, 'v. 识别；确认；认出');
      expect(d.defEn, 'to recognise someone or something and be able to say who or what they are');
      expect(d.exampleEn, 'The study aimed to identify the main factors that discourage people from cycling to work.');
      expect(d.exampleZh, '该研究旨在找出使人们不愿骑车上班的主要因素。');
      expect(d.collocations, ['identify a problem', 'identify the cause', 'correctly identify', 'identify factors']);
      expect(d.pitfall, 'identify somebody / something = 识别出某人或某物');
      expect(d.synonyms, ['recognise', 'distinguish', 'pinpoint']);
      expect(d.antonyms, '反义词材料待提供');
      expect(d.family, ['identification (n.)', 'identity (n.)']);
      expect(d.pron, '发音提示材料待提供');
      expect(d.recallTarget, SurgoPage.vocabStudy3);
    });

    test('vocabDetail2 (Adapt) keeps 已掌握 tag + muted placeholders', () {
      final d = kVocabDetailData[SurgoPage.vocabDetail2]!;
      expect(d.progressLabel, '2/3 · 学习中');
      expect(d.word, 'Adapt');
      expect(d.learn, '已掌握'); // differs from the other three (学习中)
      expect(d.ipa, '/əˈdæpt/');
      expect(d.lvl, 'B2 / Tier 1');
      expect(d.defZh, 'v. 适应；改编');
      expect(d.defEn, 'to change to suit different conditions or uses');
      expect(d.exampleMuted, '例句材料待提供');
      expect(d.collocationsMuted, '搭配材料待提供');
      expect(d.pitfallMuted, '易错点材料待提供');
      expect(d.synonymsMuted, '材料待提供');
      expect(d.antonyms, '反义词材料待提供');
      expect(d.familyMuted, '材料待提供');
      expect(d.pron, '发音提示材料待提供');
      expect(d.recallTarget, SurgoPage.vocabStudy3);
    });

    test('vocabDetail3 (Analyse) and vocabDetail4 (Context) route to vocabDone', () {
      final d3 = kVocabDetailData[SurgoPage.vocabDetail3]!;
      expect(d3.word, 'Analyse');
      expect(d3.progressLabel, '2/2 · 系统词汇复习');
      expect(d3.progressFraction, 1.0);
      expect(d3.defEn, 'to examine something carefully');
      expect(d3.recallTarget, SurgoPage.vocabDone);

      final d4 = kVocabDetailData[SurgoPage.vocabDetail4]!;
      expect(d4.word, 'Context');
      expect(d4.pos, 'NOUN'); // only noun of the four
      expect(d4.progressLabel, '1/1 · 学习中');
      expect(d4.ipa, '/ˈkɒn.tekst/');
      expect(d4.defZh, 'n. 语境；背景');
      expect(d4.defEn, 'the situation in which something happens');
      expect(d4.recallTarget, SurgoPage.vocabDone);
    });

    test('recall targets match source verbatim across all four', () {
      expect(kVocabDetailData[SurgoPage.vocabDetail]!.recallTarget, SurgoPage.vocabStudy3);
      expect(kVocabDetailData[SurgoPage.vocabDetail2]!.recallTarget, SurgoPage.vocabStudy3);
      expect(kVocabDetailData[SurgoPage.vocabDetail3]!.recallTarget, SurgoPage.vocabDone);
      expect(kVocabDetailData[SurgoPage.vocabDetail4]!.recallTarget, SurgoPage.vocabDone);
    });
  });

  group('rendering + navigation', () {
    testWidgets('renders the recall prompt, three buttons and word card', (tester) async {
      final app = AppState(current: SurgoPage.vocabDetail);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('识别'), findsOneWidget);
      expect(find.text('你刚才回忆出来了吗？'), findsOneWidget);
      expect(find.text('你的选择会帮助我们安排下次复习时间'), findsOneWidget);
      expect(find.text('没想起'), findsOneWidget);
      expect(find.text('有点模糊'), findsOneWidget);
      expect(find.text('认识'), findsOneWidget);
      // real example text present (not the muted placeholder)
      expect(find.text('该研究旨在找出使人们不愿骑车上班的主要因素。'), findsOneWidget);
    });

    testWidgets('current detail route is recorded in session', (tester) async {
      final app = AppState(current: SurgoPage.vocabDetail4);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(app.session[kVocabDetailPageKey], SurgoPage.vocabDetail4);
      expect(find.text('语境'), findsOneWidget);
    });

    testWidgets('exit routes to vocab', (tester) async {
      final app = AppState(current: SurgoPage.vocabDetail);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('✕ 退出'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocab);
    });

    testWidgets('recall buttons on vocabDetail route to vocabStudy3', (tester) async {
      final app = AppState(current: SurgoPage.vocabDetail);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('有点模糊'));
      await tester.tap(find.text('有点模糊'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy3);
    });

    testWidgets('recall buttons on vocabDetail3 route to vocabDone', (tester) async {
      final app = AppState(current: SurgoPage.vocabDetail3);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('认识'));
      await tester.tap(find.text('认识'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabDone);
    });
  });
}
