import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../vocab_words/book_list_view.dart';
import '../vocab_words/word_detail_view.dart';
import '../vocab_words/vocab_words_module.dart' show VocabWordData;

/// Vocab **pronunciation book** feature — native Dart port of the H5 prototype
/// views `vocabPronView` / `vocabPronWordView` / `vocabPronWord2View`
/// (app.js 2880-3048).
///
/// Owns: this module + test/vocab_pron_book*.dart.
///
/// These are the *pronunciation* word-book surfaces (`.wb-*` list + `.vw-*`
/// word detail), a sibling of the ordinary word book. Every visible string —
/// hero titles/counts, the four stat labels, toolbar text, each card's word /
/// IPA / definition / status tag / tier / score line, and on the two detail
/// pages the word, POS, tags, IPA, level, definitions, example, collocations,
/// pitfall, synonyms, antonyms, family, pronunciation hint and every "待提供"
/// placeholder — is copied verbatim from the source view functions. No data,
/// auth or AI is invented.
///
/// State / routing semantics preserved from the prototype:
///   * `vocabPron` back arrow "‹ 返回" → `go('vocab')`.
///   * Hero "开始发音复习" → `go('vocabPronStudy')`.
///   * Only the two cards whose word is in the source `ppage` map are
///     clickable: Identify → `vocabPronWord`, Adapt → `vocabPronWord2`
///     (the source only makes a card clickable when `ppage[w[0]]` exists).
///     Which card the learner last opened is remembered in AppState.session
///     under [kVocabPronSelectedKey] so the highlight survives a re-render,
///     mirroring the prototype's global `curPage`.
///   * Both detail pages' back arrow "‹ 返回发音本" → `go('vocabPron')`.
///   * The speaker buttons and the "★ 移出单词本" control are static fakes in
///     the prototype (no onclick / no TTS) and are preserved as inert glyphs.
///
/// The speaker glyphs render the original inline `<svg>` verbatim via
/// the shared source SVG helpers so the vector paths are preserved 1:1.
///
/// Bodies are natural-height (no inner scroll view); the app shell owns the
/// vertical scroll, matching `.read-scroll` behaviour under the phone frame.

/// Session key holding the currently-selected pron-book card (route id).
const String kVocabPronSelectedKey = 'vocabPronSelected';

// ------------------------------------------------------------------ data model

/// One `.wb-card` in the pron-book list — verbatim from `vocabPronView`'s
/// `words` rows: `[word, ipa, def, status, tagClass, score, cardClass]`.
class VocabPronCard {
  const VocabPronCard({
    required this.word,
    required this.ipa,
    required this.def,
    required this.status,
    required this.score,
    required this.mastered,
    required this.page,
  });

  final String word, ipa, def, status, score;

  /// True → 已掌握 (`.wb-c-tag-g` + `.wb-card-g` green styling).
  final bool mastered;

  /// Target route from the source `ppage` map, or `null` when the card is
  /// non-clickable (the prototype only wires `onclick` when `ppage[w]` exists).
  final SurgoPage? page;
}

/// The two pron-book cards — verbatim from `vocabPronView`.
///
/// Source rows:
///   ['Identify','/aɪˈden.tɪ.faɪ/','v. 识别；确认；认出','学习中','wb-c-tag','最近 76 · 最佳 84','']
///   ['Adapt','/əˈdæpt/','v. 适应；改编','已掌握','wb-c-tag wb-c-tag-g','最近 91 · 最佳 94','wb-card-g']
/// with ppage {Identify: vocabPronWord, Adapt: vocabPronWord2}.
const List<VocabPronCard> kVocabPronCards = [
  VocabPronCard(
    word: 'Identify',
    ipa: '/aɪˈden.tɪ.faɪ/',
    def: 'v. 识别；确认；认出',
    status: '学习中',
    score: '最近 76 · 最佳 84',
    mastered: false,
    page: SurgoPage.vocabPronWord,
  ),
  VocabPronCard(
    word: 'Adapt',
    ipa: '/əˈdæpt/',
    def: 'v. 适应；改编',
    status: '已掌握',
    score: '最近 91 · 最佳 94',
    mastered: true,
    page: SurgoPage.vocabPronWord2,
  ),
];

/// A pron-book word-detail page — verbatim from `vocabPronWord{,2}View`.
class VocabPronWordData {
  const VocabPronWordData({
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

  /// Example: real (en+zh) or a single muted placeholder.
  final String? exampleEn, exampleZh, exampleMuted;

  final List<String> collocations;
  final String? collocationsMuted;

  /// 中国学生易错点: real text vs muted placeholder.
  final String? pitfall, pitfallMuted;

  final List<String> synonyms;
  final String? synonymsMuted;

  /// 反义词 — always a muted placeholder in source.
  final String antonyms;

  final List<String> family;
  final String? familyMuted;

  /// 发音提示 — always a muted placeholder in source.
  final String pron;
}

/// The two pron-book detail views — verbatim from vocabPronWord{,2}View.
final Map<SurgoPage, VocabPronWordData> kVocabPronWordData = {
  // vocabPronWordView — app.js 2926-2989
  SurgoPage.vocabPronWord: const VocabPronWordData(
    route: SurgoPage.vocabPronWord,
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
  // vocabPronWord2View — app.js 2990-3048
  SurgoPage.vocabPronWord2: const VocabPronWordData(
    route: SurgoPage.vocabPronWord2,
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
};

// -------------------------------------------------------------- entry point

/// Router entry for the vocab pron-book native pages.
///
/// Returns the matching widget for `vocabPron` / `vocabPronWord{,2}`, or
/// `null` for any page this module does not own (mirrors the prototype
/// `if(!V[id]) return;`).
Widget? buildVocabPronBookPage(SurgoPage page) {
  switch (page) {
    case SurgoPage.vocabPron:
      return const VocabPronPage();
    case SurgoPage.vocabPronWord:
    case SurgoPage.vocabPronWord2:
      return VocabPronWordPage(data: kVocabPronWordData[page]!);
    default:
      return null;
  }
}

// ------------------------------------------------------------------- list page

/// Original two pronunciation-book entries; no selected-border override exists
/// in H5. Keep the legacy session marker but do not recolor mastered Adapt.
class VocabPronPage extends StatelessWidget {
  const VocabPronPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return BookListView(pronunciation: true, items: [
      for (final c in kVocabPronCards)
        BookListItem(
            word: c.word,
            ipa: c.ipa,
            definition: c.def,
            status: c.status,
            tier: '词汇训练',
            score: c.score,
            mastered: c.mastered,
            onTap: c.page == null
                ? null
                : () {
                    app.session[kVocabPronSelectedKey] = c.page;
                    app.go(c.page!);
                  }),
    ]);
  }
}

// ----------------------------------------------------------------- detail page

/// Original pron detail data adapted without changing fixed strings.
class VocabPronWordPage extends StatelessWidget {
  const VocabPronWordPage({super.key, required this.data});
  final VocabPronWordData data;
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().session[kVocabPronSelectedKey] = data.route;
    return WordDetailView(
        pronunciation: true,
        data: VocabWordData(
            route: data.route,
            word: data.word,
            pos: data.pos,
            learn: data.learn,
            book: data.book,
            ipa: data.ipa,
            lvl: data.lvl,
            defZh: data.defZh,
            defEn: data.defEn,
            exampleEn: data.exampleEn,
            exampleZh: data.exampleZh,
            exampleMuted: data.exampleMuted,
            collocations: data.collocations,
            collocationsMuted: data.collocationsMuted,
            pitfall: data.pitfall,
            pitfallMuted: data.pitfallMuted,
            synonyms: data.synonyms,
            synonymsMuted: data.synonymsMuted,
            antonyms: data.antonyms,
            family: data.family,
            familyMuted: data.familyMuted,
            pron: data.pron));
  }
}
