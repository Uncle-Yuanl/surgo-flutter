import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_words/vocab_words_module.dart';

Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabWordsPage(page) ?? const SizedBox.shrink();
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

  group('buildVocabWordsPage routing', () {
    test('returns widgets only for owned pages', () {
      expect(buildVocabWordsPage(SurgoPage.vocabBook), isA<VocabBookPage>());
      expect(buildVocabWordsPage(SurgoPage.vocabWord), isA<VocabWordPage>());
      expect(buildVocabWordsPage(SurgoPage.vocabWord2), isA<VocabWordPage>());
      expect(buildVocabWordsPage(SurgoPage.vocabWord3), isA<VocabWordPage>());
      expect(buildVocabWordsPage(SurgoPage.vocabWord4), isA<VocabWordPage>());
      // Not owned by this module.
      expect(buildVocabWordsPage(SurgoPage.vocab), isNull);
      expect(buildVocabWordsPage(SurgoPage.vocabStudy), isNull);
    });
  });

  group('word data verbatim from source', () {
    test('vocabWord (Identify) preserves detail + answers text', () {
      final d = kVocabWordData[SurgoPage.vocabWord]!;
      expect(d.word, 'Identify');
      expect(d.pos, 'VERB');
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
    });

    test('vocabWord2/3/4 keep muted placeholders exactly', () {
      for (final p in [SurgoPage.vocabWord2, SurgoPage.vocabWord3, SurgoPage.vocabWord4]) {
        final d = kVocabWordData[p]!;
        expect(d.exampleMuted, '例句材料待提供');
        expect(d.collocationsMuted, '搭配材料待提供');
        expect(d.pitfallMuted, '易错点材料待提供');
        expect(d.synonymsMuted, '材料待提供');
        expect(d.antonyms, '反义词材料待提供');
        expect(d.familyMuted, '材料待提供');
        expect(d.pron, '发音提示材料待提供');
      }
      expect(kVocabWordData[SurgoPage.vocabWord2]!.word, 'Adapt');
      expect(kVocabWordData[SurgoPage.vocabWord3]!.word, 'Analyse');
      expect(kVocabWordData[SurgoPage.vocabWord4]!.word, 'Context');
    });

    test('book cards map to the original wpage routes', () {
      expect(kVocabBookCards.map((c) => c.word).toList(), ['Identify', 'Adapt', 'Analyse', 'Context']);
      expect(kVocabBookCards.map((c) => c.page).toList(),
          [SurgoPage.vocabWord, SurgoPage.vocabWord2, SurgoPage.vocabWord3, SurgoPage.vocabWord4]);
      for (final c in kVocabBookCards) {
        expect(c.tag, '学习中');
      }
    });
  });

  group('selection state + route switching', () {
    testWidgets('tapping a card records selection and navigates', (tester) async {
      final app = AppState(current: SurgoPage.vocabBook);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('我的单词本'), findsOneWidget);
      expect(find.text('分析'), findsOneWidget);

      await tester.ensureVisible(find.text('分析'));
      await tester.tap(find.text('分析'));
      await tester.pumpAndSettle();

      // selection persisted under the original registry-id session key
      expect(app.session[kVocabSelectedWordKey], SurgoPage.vocabWord3);
      expect(app.current, SurgoPage.vocabWord3);
      // now on the detail page
      expect(find.text('仔细检查某事'), findsOneWidget);
      expect(find.text('例句材料待提供'), findsOneWidget);
    });

    testWidgets('word page back button returns to vocabBook', (tester) async {
      final app = AppState(current: SurgoPage.vocabWord);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('识别'), findsOneWidget);
      await tester.ensureVisible(find.text('‹ 返回单词本'));
      await tester.tap(find.text('‹ 返回单词本'));
      await tester.pumpAndSettle();

      expect(app.current, SurgoPage.vocabBook);
      expect(find.text('我的单词本'), findsOneWidget);
    });

    testWidgets('hero 开始复习 routes to vocabStudy', (tester) async {
      final app = AppState(current: SurgoPage.vocabBook);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('开始复习'));
      await tester.tap(find.text('开始复习'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabStudy);
    });
  });
}
