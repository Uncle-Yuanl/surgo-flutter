import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/vocab_pron_book/vocab_pron_book_module.dart';

/// Hosts the module exactly as the app shell does: the page is picked from the
/// live [AppState.current] and the body lives inside a parent scroll view, so
/// taps that call `go(...)` re-render into the new page.
Widget _host(AppState app) => ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                final page = context.watch<AppState>().current;
                return buildVocabPronBookPage(page) ?? const SizedBox.shrink();
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

  group('buildVocabPronBookPage routing', () {
    test('returns widgets only for the 3 owned pages', () {
      expect(buildVocabPronBookPage(SurgoPage.vocabPron), isA<VocabPronPage>());
      expect(buildVocabPronBookPage(SurgoPage.vocabPronWord), isA<VocabPronWordPage>());
      expect(buildVocabPronBookPage(SurgoPage.vocabPronWord2), isA<VocabPronWordPage>());
    });

    test('returns null for pages this module does not own', () {
      expect(buildVocabPronBookPage(SurgoPage.vocab), isNull);
      expect(buildVocabPronBookPage(SurgoPage.vocabBook), isNull);
      expect(buildVocabPronBookPage(SurgoPage.vocabWord), isNull);
      // Pron study/done routes exist but belong to other modules.
      expect(buildVocabPronBookPage(SurgoPage.vocabPronStudy), isNull);
      expect(buildVocabPronBookPage(SurgoPage.vocabPronDone), isNull);
    });

    test('detail data is wired to the matching route', () {
      final w1 = buildVocabPronBookPage(SurgoPage.vocabPronWord) as VocabPronWordPage;
      final w2 = buildVocabPronBookPage(SurgoPage.vocabPronWord2) as VocabPronWordPage;
      expect(w1.data.route, SurgoPage.vocabPronWord);
      expect(w1.data.word, 'Identify');
      expect(w2.data.route, SurgoPage.vocabPronWord2);
      expect(w2.data.word, 'Adapt');
    });
  });

  group('pron-book card data (vocabPronView, verbatim)', () {
    test('exactly two cards with the source words / scores / status', () {
      expect(kVocabPronCards.length, 2);

      final identify = kVocabPronCards[0];
      expect(identify.word, 'Identify');
      expect(identify.ipa, '/aɪˈden.tɪ.faɪ/');
      expect(identify.def, 'v. 识别；确认；认出');
      expect(identify.status, '学习中');
      expect(identify.score, '最近 76 · 最佳 84');
      expect(identify.mastered, isFalse);
      expect(identify.page, SurgoPage.vocabPronWord);

      final adapt = kVocabPronCards[1];
      expect(adapt.word, 'Adapt');
      expect(adapt.ipa, '/əˈdæpt/');
      expect(adapt.def, 'v. 适应；改编');
      expect(adapt.status, '已掌握');
      expect(adapt.score, '最近 91 · 最佳 94');
      expect(adapt.mastered, isTrue);
      expect(adapt.page, SurgoPage.vocabPronWord2);
    });

    test('both source cards are clickable (ppage covers Identify + Adapt)', () {
      // In source every word here is in ppage, so both route somewhere.
      for (final c in kVocabPronCards) {
        expect(c.page, isNotNull);
      }
    });
  });

  group('detail data (vocabPronWord{,2}View, verbatim)', () {
    test('Identify — full real content, no placeholders', () {
      final d = kVocabPronWordData[SurgoPage.vocabPronWord]!;
      expect(d.pos, 'VERB');
      expect(d.learn, '学习中');
      expect(d.book, '移出单词本');
      expect(d.lvl, 'B1 / Tier 1');
      expect(d.defEn, 'to recognise someone or something and be able to say who or what they are');
      expect(d.exampleMuted, isNull);
      expect(d.exampleEn, contains('discourage people from cycling'));
      expect(d.collocations, [
        'identify a problem',
        'identify the cause',
        'correctly identify',
        'identify factors',
      ]);
      expect(d.pitfall, 'identify somebody / something = 识别出某人或某物');
      expect(d.synonyms, ['recognise', 'distinguish', 'pinpoint']);
      expect(d.family, ['identification (n.)', 'identity (n.)']);
      // These two are always muted placeholders in source.
      expect(d.antonyms, '反义词材料待提供');
      expect(d.pron, '发音提示材料待提供');
    });

    test('Adapt — mostly "待提供" placeholders', () {
      final d = kVocabPronWordData[SurgoPage.vocabPronWord2]!;
      expect(d.lvl, 'B2 / Tier 1');
      expect(d.defZh, 'v. 适应；改编');
      expect(d.exampleMuted, '例句材料待提供');
      expect(d.collocationsMuted, '搭配材料待提供');
      expect(d.pitfallMuted, '易错点材料待提供');
      expect(d.synonymsMuted, '材料待提供');
      expect(d.familyMuted, '材料待提供');
      expect(d.antonyms, '反义词材料待提供');
      expect(d.pron, '发音提示材料待提供');
    });
  });

  group('list page interactions', () {
    testWidgets('renders hero, stats, toolbar and both cards', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPron);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('我的发音本'), findsOneWidget);
      expect(find.text('已加入 2 个发音训练词'), findsOneWidget);
      expect(find.text('开始发音复习'), findsOneWidget);
      // stat labels
      expect(find.text('全部单词'), findsOneWidget);
      expect(find.text('已掌握'), findsWidgets); // stat + Adapt status tag
      expect(find.text('学习中'), findsWidgets);
      expect(find.text('未学习'), findsOneWidget);
      // toolbar
      expect(find.text('全部状态 ▾'), findsOneWidget);
      // cards (word + score)
      expect(find.text('识别'), findsOneWidget);
      expect(find.text('适应'), findsOneWidget);
      expect(find.text('最近 76 · 最佳 84'), findsOneWidget);
      expect(find.text('最近 91 · 最佳 94'), findsOneWidget);
    });

    testWidgets('back arrow returns to vocab', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPron);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('‹ 返回'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocab);
    });

    testWidgets('hero button starts pron review (vocabPronStudy)', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPron);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('开始发音复习'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPronStudy);
    });

    testWidgets('tapping Identify card opens vocabPronWord and records selection', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPron);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('识别'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPronWord);
      expect(app.session[kVocabPronSelectedKey], SurgoPage.vocabPronWord);
      // detail chrome
      expect(find.text('‹ 返回发音本'), findsOneWidget);
      expect(find.text('移出单词本'), findsOneWidget);
    });

    testWidgets('tapping Adapt card opens vocabPronWord2', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPron);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('适应'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPronWord2);
      expect(app.session[kVocabPronSelectedKey], SurgoPage.vocabPronWord2);
    });
  });

  group('detail page interactions', () {
    testWidgets('Identify detail shows real example, collocations and pitfall', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPronWord);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('识别'), findsOneWidget);
      expect(find.text('动词'), findsOneWidget);
      expect(find.text('B1 / Tier 1'), findsOneWidget);
      expect(find.text('例句'), findsOneWidget);
      expect(find.text('identify a problem'), findsOneWidget);
      expect(find.text('identify somebody / something = 识别出某人或某物'), findsOneWidget);
      expect(find.text('recognise'), findsOneWidget);
      expect(find.text('identification (n.)'), findsOneWidget);
      // muted placeholders that persist even on the "full" word
      expect(find.text('反义词材料待提供'), findsOneWidget);
      expect(find.text('发音提示材料待提供'), findsOneWidget);
    });

    testWidgets('Adapt detail shows the "待提供" placeholders', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPronWord2);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      expect(find.text('适应'), findsOneWidget);
      expect(find.text('例句材料待提供'), findsOneWidget);
      expect(find.text('搭配材料待提供'), findsOneWidget);
      expect(find.text('易错点材料待提供'), findsOneWidget);
      expect(find.text('反义词材料待提供'), findsOneWidget);
    });

    testWidgets('detail back arrow returns to the pron book', (tester) async {
      final app = AppState()..go(SurgoPage.vocabPronWord);
      await tester.pumpWidget(_host(app));
      await tester.pumpAndSettle();

      await tester.tap(find.text('‹ 返回发音本'));
      await tester.pumpAndSettle();
      expect(app.current, SurgoPage.vocabPron);
    });
  });
}
