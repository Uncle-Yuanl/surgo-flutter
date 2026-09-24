import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import 'book_list_view.dart';
import 'word_detail_view.dart';

/// Vocab words feature — native Dart port of the H5 prototype views
/// `vocabBookView` / `vocabWord{,2,3,4}View` (app.js 2592-2879).
///
/// Owns: this module + assets/data/vocab_words*.json + test/vocab_words*.dart.
/// Every visible string, word datum, definition, example, collocation,
/// synonym, family member and "待提供" placeholder is copied verbatim from
/// the source `_extract/logic/fns/*.js` so text/state semantics are exact.
///
/// State semantics preserved from the prototype:
///   * The word-book cards are clickable and route via `go(...)` to the
///     matching detail page (Identify→vocabWord, Adapt→vocabWord2,
///     Analyse→vocabWord3, Context→vocabWord4). Exactly the `wpage` map.
///   * The hero "开始复习" button routes to `vocabStudy` (go('vocabStudy')).
///   * The back arrow on the book returns to `vocab`; each word page's
///     "‹ 返回单词本" returns to `vocabBook`.
///   * Which word the user last opened is remembered in AppState.session
///     under the original registry key so the selection survives re-render,
///     mirroring the prototype's global `curPage` driven highlight.
///
/// Bodies are natural-height (no inner scroll view); the app shell owns the
/// vertical scroll, matching `.read-scroll` behaviour under the phone frame.

// ------------------------------------------------------------------ data model

/// Session key holding the currently-selected word-book entry (route id).
/// Uses the original page-registry id string, e.g. 'vocabWord'.
const String kVocabSelectedWordKey = 'vocabSelectedWord';

class VocabBookCard {
  const VocabBookCard({
    required this.word,
    required this.ipa,
    required this.def,
    required this.tier,
    required this.tag,
    required this.page,
  });
  final String word, ipa, def, tier, tag;

  /// Target registry id (matches prototype `wpage` map).
  final SurgoPage page;
}

class VocabWordData {
  const VocabWordData({
    required this.route,
    required this.word,
    required this.pos,
    required this.learn,
    required this.book,
    required this.ipa,
    required this.lvl,
    required this.defZh,
    required this.defEn,
    required this.exampleEn,
    required this.exampleZh,
    required this.exampleMuted,
    required this.collocations,
    required this.collocationsMuted,
    required this.pitfall,
    required this.pitfallMuted,
    required this.synonyms,
    required this.synonymsMuted,
    required this.antonyms,
    required this.family,
    required this.familyMuted,
    required this.pron,
  });

  final SurgoPage route;
  final String word, pos, learn, book, ipa, lvl, defZh, defEn;

  /// Example: either (en+zh) real, or a single muted placeholder.
  final String? exampleEn, exampleZh, exampleMuted;

  final List<String> collocations;
  final String? collocationsMuted;

  /// 中国学生易错点: real text vs muted placeholder.
  final String? pitfall, pitfallMuted;

  final List<String> synonyms;
  final String? synonymsMuted;

  /// 反义词 always muted placeholder in source.
  final String antonyms;

  final List<String> family;
  final String? familyMuted;

  /// 发音提示 always muted placeholder in source.
  final String pron;
}

/// The four word-book entries — verbatim from `vocabBookView` `words`/`wpage`.
const List<VocabBookCard> kVocabBookCards = [
  VocabBookCard(
      word: 'Identify',
      ipa: '/aɪˈden.tɪ.faɪ/',
      def: 'v. 识别；确认；认出',
      tier: 'Tier 1',
      tag: '学习中',
      page: SurgoPage.vocabWord),
  VocabBookCard(
      word: 'Adapt',
      ipa: '/əˈdæpt/',
      def: 'v. 适应；改编',
      tier: 'Tier 1',
      tag: '学习中',
      page: SurgoPage.vocabWord2),
  VocabBookCard(
      word: 'Analyse',
      ipa: '/ˈæn.əl.aɪz/',
      def: 'v. 分析',
      tier: 'Tier 1',
      tag: '学习中',
      page: SurgoPage.vocabWord3),
  VocabBookCard(
      word: 'Context',
      ipa: '/ˈkɒn.tekst/',
      def: 'n. 语境；背景',
      tier: 'Tier 2',
      tag: '学习中',
      page: SurgoPage.vocabWord4),
];

/// Word detail data — verbatim from vocabWord{,2,3,4}View.
final Map<SurgoPage, VocabWordData> kVocabWordData = {
  SurgoPage.vocabWord: const VocabWordData(
    route: SurgoPage.vocabWord,
    word: 'Identify',
    pos: 'VERB',
    learn: '学习中',
    book: '移出单词本',
    ipa: '/aɪˈden.tɪ.faɪ/',
    lvl: 'B1 / Tier 1',
    defZh: 'v. 识别；确认；认出',
    defEn:
        'to recognise someone or something and be able to say who or what they are',
    exampleEn:
        'The study aimed to identify the main factors that discourage people from cycling to work.',
    exampleZh: '该研究旨在找出使人们不愿骑车上班的主要因素。',
    exampleMuted: null,
    collocations: [
      'identify a problem',
      'identify the cause',
      'correctly identify',
      'identify factors'
    ],
    collocationsMuted: null,
    pitfall: 'identify somebody / something = 识别出某人或某物',
    pitfallMuted: null,
    synonyms: ['recognise', 'distinguish', 'pinpoint'],
    synonymsMuted: null,
    antonyms: '反义词材料待提供',
    family: ['identification (n.)', 'identity (n.)'],
    familyMuted: null,
    pron: '发音提示材料待提供',
  ),
  SurgoPage.vocabWord2: const VocabWordData(
    route: SurgoPage.vocabWord2,
    word: 'Adapt',
    pos: 'VERB',
    learn: '学习中',
    book: '移出单词本',
    ipa: '/əˈdæpt/',
    lvl: 'B2 / Tier 1',
    defZh: 'v. 适应；改编',
    defEn: 'to change to suit different conditions or uses',
    exampleEn: null,
    exampleZh: null,
    exampleMuted: '例句材料待提供',
    collocations: [],
    collocationsMuted: '搭配材料待提供',
    pitfall: null,
    pitfallMuted: '易错点材料待提供',
    synonyms: [],
    synonymsMuted: '材料待提供',
    antonyms: '反义词材料待提供',
    family: [],
    familyMuted: '材料待提供',
    pron: '发音提示材料待提供',
  ),
  SurgoPage.vocabWord3: const VocabWordData(
    route: SurgoPage.vocabWord3,
    word: 'Analyse',
    pos: 'VERB',
    learn: '学习中',
    book: '移出单词本',
    ipa: '/ˈæn.əl.aɪz/',
    lvl: 'B2 / Tier 1',
    defZh: 'v. 分析',
    defEn: 'to examine something carefully',
    exampleEn: null,
    exampleZh: null,
    exampleMuted: '例句材料待提供',
    collocations: [],
    collocationsMuted: '搭配材料待提供',
    pitfall: null,
    pitfallMuted: '易错点材料待提供',
    synonyms: [],
    synonymsMuted: '材料待提供',
    antonyms: '反义词材料待提供',
    family: [],
    familyMuted: '材料待提供',
    pron: '发音提示材料待提供',
  ),
  SurgoPage.vocabWord4: const VocabWordData(
    route: SurgoPage.vocabWord4,
    word: 'Context',
    pos: 'NOUN',
    learn: '学习中',
    book: '移出单词本',
    ipa: '/ˈkɒn.tekst/',
    lvl: 'B2 / Tier 2',
    defZh: 'n. 语境；背景',
    defEn: 'the situation in which something happens',
    exampleEn: null,
    exampleZh: null,
    exampleMuted: '例句材料待提供',
    collocations: [],
    collocationsMuted: '搭配材料待提供',
    pitfall: null,
    pitfallMuted: '易错点材料待提供',
    synonyms: [],
    synonymsMuted: '材料待提供',
    antonyms: '反义词材料待提供',
    family: [],
    familyMuted: '材料待提供',
    pron: '发音提示材料待提供',
  ),
};

// -------------------------------------------------------------- entry point

/// Router entry for the vocab-words native pages.
///
/// Returns the matching widget for `vocabBook` / `vocabWord{,2,3,4}`,
/// or `null` for any page this module does not own (mirrors the prototype
/// `if(!V[id]) return;` — unknown ids are handled elsewhere).
Widget? buildVocabWordsPage(SurgoPage page) {
  switch (page) {
    case SurgoPage.vocabBook:
      return const VocabBookPage();
    case SurgoPage.vocabWord:
    case SurgoPage.vocabWord2:
    case SurgoPage.vocabWord3:
    case SurgoPage.vocabWord4:
      return VocabWordPage(data: kVocabWordData[page]!);
    default:
      return null;
  }
}

// ------------------------------------------------------------------- widgets

/// 我的单词本 — original fixed rows and click targets, source wb-* display.
class VocabBookPage extends StatelessWidget {
  const VocabBookPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return BookListView(pronunciation: false, items: [
      for (final c in kVocabBookCards)
        BookListItem(
            word: c.word,
            ipa: c.ipa,
            definition: c.def,
            status: c.tag,
            tier: c.tier,
            onTap: () {
              app.session[kVocabSelectedWordKey] = c.page;
              app.go(c.page);
            }),
    ]);
  }
}

/// Native shared source vw-* detail; data remains above verbatim.
class VocabWordPage extends StatelessWidget {
  const VocabWordPage({super.key, required this.data});
  final VocabWordData data;
  @override
  Widget build(BuildContext context) => WordDetailView(data: data);
}
