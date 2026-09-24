import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'vocab_detail_top.dart';

const _detailShadow = [
  BoxShadow(color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
];
const _detailMuted = TextStyle(fontSize: 11, color: Color(0xffb7b0a3));
const _detailBody =
    TextStyle(fontSize: 11, height: 1.6, color: Color(0xff6b6255));
const _detailSection = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 13, fontWeight: FontWeight.w800, color: SurgoColors.ink);

/// Vocab **details** feature — native Dart port of the H5 prototype views
/// `vocabDetailView` / `vocabDetail{2,3,4}View`
/// (app.js 5370-5435 / 5308-5368 / 3486-3546 / 3372-3432).
///
/// These are the *study-feedback* detail pages shown mid-review: a progress
/// bar + "演示数据" tag at the top, the full word card, five side panels and a
/// spaced-repetition recall prompt with three self-grading buttons. They are a
/// different surface from the `vocab_words` word-book detail (`vocabWordView`),
/// even though several words overlap — so the text, tags and, crucially, the
/// recall-button routing differ and are copied verbatim from source here.
///
/// Owns: this module + test/vocab_details*.dart.
///
/// State semantics preserved from the prototype:
///   * Top-left "✕ 退出" always routes to `vocab` (go('vocab')).
///   * The recall buttons ("没想起" / "有点模糊" / "认识") all route to the SAME
///     next page within a given detail view — exactly as in source:
///       vocabDetail  → vocabStudy3
///       vocabDetail2 → vocabStudy3
///       vocabDetail3 → vocabDone
///       vocabDetail4 → vocabDone
///   * Which detail page the learner is on is remembered in AppState.session
///     under the original registry-id key, mirroring the prototype's global
///     `curPage`, so the value survives a re-render.
///
/// Every visible string — word, POS, tags, IPA, level, definitions, example,
/// collocations, pitfall, synonyms, antonyms, family, pronunciation hint, the
/// progress labels and every "待提供" placeholder — is copied verbatim from the
/// source view functions. No data is invented.
///
/// Bodies are natural-height (no inner scroll view); the app shell owns the
/// vertical scroll, matching the source `.read-scroll` under the phone frame.

// ------------------------------------------------------------------ tokens

/// Speaker glyph — the exact inline `<svg>` used by `.vd-spk` in every source
/// view (`const spk = '<svg …>'`). Rendered natively via [SvgPicture.string]
/// so the original vector paths are preserved 1:1.
const String _spkSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.9" '
    'stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M11 5 6 9H3v6h3l5 4z"/>'
    '<path d="M15.5 8.5a5 5 0 0 1 0 7"/></svg>';

/// Recall-button border colours (CSS `.vd-rc-red/-yellow/-green`).
const Color _rcRed = Color(0xFFF0A9A9); // .vd-rc-red  border-color:#f0a9a9
const Color _rcGreen = Color(0xFFA7D98A); // .vd-rc-green border-color:#a7d98a
// yellow reuses SurgoColors.yellow (.vd-rc-yellow border-color:var(--yellow))

/// Learn-tag palette (CSS `.vd-learn{color:#4f8a1f;background:#e8f5e0}`).
const Color _learnInk = Color(0xFF4F8A1F);
const Color _learnBg = Color(0xFFE8F5E0);

/// Session key holding the current detail-page route id (original registry id).
const String kVocabDetailPageKey = 'vocabDetailPage';

// ------------------------------------------------------------------ data model

class VocabDetailData {
  const VocabDetailData({
    required this.route,
    required this.progressLabel,
    required this.progressFraction,
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
    required this.recallTarget,
  });

  final SurgoPage route;

  /// e.g. '1/2 · 系统词汇复习' (`.vs-prog`).
  final String progressLabel;

  /// Progress-bar fill fraction (`.vs-bar i style="width:50%"` → 0.50).
  final double progressFraction;

  final String word, pos, learn, book, ipa, lvl, defZh, defEn;

  /// Example: real (en+zh) or a single muted placeholder.
  final String? exampleEn, exampleZh, exampleMuted;

  final List<String> collocations;
  final String? collocationsMuted;

  /// 中国学生易错点: real text (`.vd-p-b`) vs muted placeholder.
  final String? pitfall, pitfallMuted;

  final List<String> synonyms;
  final String? synonymsMuted;

  /// 反义词 — always a muted placeholder in source.
  final String antonyms;

  final List<String> family;
  final String? familyMuted;

  /// 发音提示 — always a muted placeholder in source.
  final String pron;

  /// Where all three recall buttons route (verbatim from source onclick).
  final SurgoPage recallTarget;
}

/// The four detail views — verbatim from vocabDetail{,2,3,4}View.
final Map<SurgoPage, VocabDetailData> kVocabDetailData = {
  // vocabDetailView — app.js 5370-5435
  SurgoPage.vocabDetail: const VocabDetailData(
    route: SurgoPage.vocabDetail,
    progressLabel: '1/2 · 系统词汇复习',
    progressFraction: 0.50,
    word: 'Identify',
    pos: 'VERB',
    learn: '学习中',
    book: '★ 已加入单词本',
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
    recallTarget: SurgoPage.vocabStudy3,
  ),
  // vocabDetail2View — app.js 5308-5368
  SurgoPage.vocabDetail2: const VocabDetailData(
    route: SurgoPage.vocabDetail2,
    progressLabel: '2/3 · 学习中',
    progressFraction: 0.666,
    word: 'Adapt',
    pos: 'VERB',
    learn: '已掌握',
    book: '★ 已加入单词本',
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
    recallTarget: SurgoPage.vocabStudy3,
  ),
  // vocabDetail3View — app.js 3486-3546
  SurgoPage.vocabDetail3: const VocabDetailData(
    route: SurgoPage.vocabDetail3,
    progressLabel: '2/2 · 系统词汇复习',
    progressFraction: 1.0,
    word: 'Analyse',
    pos: 'VERB',
    learn: '学习中',
    book: '★ 已加入单词本',
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
    recallTarget: SurgoPage.vocabDone,
  ),
  // vocabDetail4View — app.js 3372-3432
  SurgoPage.vocabDetail4: const VocabDetailData(
    route: SurgoPage.vocabDetail4,
    progressLabel: '1/1 · 学习中',
    progressFraction: 1.0,
    word: 'Context',
    pos: 'NOUN',
    learn: '学习中',
    book: '★ 已加入单词本',
    ipa: '/ˈkɒn.tekst/',
    lvl: 'B2 / Tier 1',
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
    recallTarget: SurgoPage.vocabDone,
  ),
};

// -------------------------------------------------------------- entry point

/// Router entry for the vocab-details native pages.
///
/// Returns the matching widget for `vocabDetail{,2,3,4}`, or `null` for any
/// page this module does not own (mirrors the prototype `if(!V[id]) return;`).
Widget? buildVocabDetailsPage(SurgoPage page) {
  final data = kVocabDetailData[page];
  if (data == null) return null;
  return VocabDetailPage(data: data);
}

// ------------------------------------------------------------------- widgets

/// 词汇复习详情反馈页 — port of vocabDetail{,2,3,4}View.
class VocabDetailPage extends StatelessWidget {
  const VocabDetailPage({super.key, required this.data});
  final VocabDetailData data;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Remember which detail view we're on (survives re-render), like curPage.
    app.session[kVocabDetailPageKey] = data.route;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- .vs-top : exit / demo tag / progress bar / progress label ----
        VocabDetailTop(
            progress: data.progressLabel, fraction: data.progressFraction),

        // ---- .vd-card : word card ----
        Container(
          key: const ValueKey('vocab-detail-card'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SurgoColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _detailShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .vd-hd — word + tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SourceText(data.word,
                      key: const ValueKey('vocab-detail-word'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 28, fontWeight: FontWeight.w800)),
                  _Tag(
                      text: data.pos,
                      ink: SurgoColors.onYellowSoft,
                      bg: SurgoColors.yellowTint),
                  _Tag(text: data.learn, ink: _learnInk, bg: _learnBg),
                  _Tag(
                      text: data.book,
                      ink: SurgoColors.onYellowSoft,
                      bg: SurgoColors.yellowTint),
                ],
              ),
              const SizedBox(height: 8),
              // .vd-ipa — ipa + speaker
              Row(
                children: [
                  Flexible(
                      child: SourceText(data.ipa,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xffa99a82)))),
                  const SizedBox(width: 8),
                  SvgPicture.string(_spkSvg,
                      key: const ValueKey('vocab-detail-speaker'),
                      width: 18,
                      height: 18),
                ],
              ),
              const SizedBox(height: 8),
              // .vd-lvl
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EDE3),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: SourceText(data.lvl,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xff8a8474))),
              ),
              const SizedBox(height: 16),
              // .vd-def
              Container(
                width: double.infinity,
                key: const ValueKey('vocab-detail-definition'),
                padding: const EdgeInsets.fromLTRB(19, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: SurgoColors.yellowTint,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border(
                      left: BorderSide(color: SurgoColors.yellow, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceText(data.defZh,
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    SourceText(data.defEn,
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.6,
                            color: Color(0xff6b6255))),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // 例句
              const T('例句', style: _detailSection),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: data.exampleMuted != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: SourceText(data.exampleMuted!,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                color: Color(0xffb7b0a3))))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SourceText(data.exampleEn!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff3a352c))),
                          const SizedBox(height: 5),
                          SourceText(data.exampleZh!,
                              style: const TextStyle(
                                  fontSize: 10.5, color: Color(0xffa99a82))),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              // 常见搭配
              const T('常见搭配', style: _detailSection),
              const SizedBox(height: 9),
              _Chips(
                  items: data.collocations,
                  muted: data.collocationsMuted,
                  mutedChip: true),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---- side panels ----
        _Panel(
          title: '中国学生易错点',
          highlight: true,
          child: data.pitfallMuted != null
              ? T(data.pitfallMuted!, style: _detailMuted)
              : SourceText(data.pitfall!, style: _detailBody),
        ),
        _Panel(
          title: '近义词',
          child: _Chips(items: data.synonyms, muted: data.synonymsMuted),
        ),
        _Panel(
          title: '反义词',
          child: T(data.antonyms, style: _detailMuted),
        ),
        _Panel(
          title: '词族',
          child: _Chips(items: data.family, muted: data.familyMuted),
        ),
        _Panel(
          title: '发音提示',
          child: T(data.pron, style: _detailMuted),
        ),

        // ---- .vd-recall : spaced-repetition prompt ----
        // Source preceding 12px bottom margin collapses with this 4px top.
        Container(
          key: const ValueKey('vocab-detail-recall'),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: SurgoColors.yellowTint,
            borderRadius: BorderRadius.all(Radius.circular(SurgoRadius.cardMd)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const T('你刚才回忆出来了吗？',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const T('你的选择会帮助我们安排下次复习时间',
                  style: TextStyle(fontSize: 10, color: Color(0xffa08a4a))),
              const SizedBox(height: 14),
              // buttons constrained inside a Row via Expanded; IntrinsicHeight
              // gives the Row a bounded height so stretch yields equal heights.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _RecallButton(
                        title: '没想起',
                        subtitle: '完全没记起来',
                        borderColor: _rcRed,
                        onTap: () => app.go(data.recallTarget),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecallButton(
                        title: '有点模糊',
                        subtitle: '有印象但不确定',
                        borderColor: SurgoColors.yellow,
                        onTap: () => app.go(data.recallTarget),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecallButton(
                        title: '认识',
                        subtitle: '能准确想起来',
                        borderColor: _rcGreen,
                        onTap: () => app.go(data.recallTarget),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.vd-tag` pill.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.ink, required this.bg});
  final String text;
  final Color ink, bg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        // Tag text ('VERB', '学习中', '★ 已加入单词本') is source content → T so
        // the chrome-level ones translate consistently with the prototype.
        child: SourceText(text,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 10, color: ink, fontWeight: FontWeight.w700)),
      );
}

const _panelGlyphs = {
  '中国学生易错点': '\u24d8',
  '近义词': '\u{1f517}',
  '反义词': '\u{1f6ab}',
  '词族': '\u{1f201}',
  '发音提示': '\u{1f5e3}',
};
const _recallGlyphs = {
  '没想起': '\u{1f61f}',
  '有点模糊': '\u{1f610}',
  '认识': '\u{1f600}'
};

/// `.vd-panel` / `.vd-panel-y`.
class _Panel extends StatelessWidget {
  const _Panel(
      {required this.title, required this.child, this.highlight = false});
  final String title;
  final Widget child;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            color: highlight ? SurgoColors.yellowTint : SurgoColors.card,
            borderRadius:
                const BorderRadius.all(Radius.circular(SurgoRadius.cardMd)),
            boxShadow: highlight ? null : _detailShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                  constraints: BoxConstraints(minHeight: highlight ? 17 : 20),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(_panelGlyphs[title]!,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Flexible(
                            child: T(title,
                                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: SurgoColors.ink))),
                      ])),
              const SizedBox(height: 9),
              child,
            ],
          ),
        ),
      );
}

/// `.vd-chips` — either real chips or a single muted placeholder.
class _Chips extends StatelessWidget {
  const _Chips({required this.items, this.muted, this.mutedChip = false});
  final List<String> items;
  final String? muted;
  final bool mutedChip;
  @override
  Widget build(BuildContext context) {
    if (muted != null && !mutedChip) return T(muted!, style: _detailMuted);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: (muted == null ? items : [muted!])
          .map<Widget>((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EDE3),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                // Chip content is source data → plain Text, not T.
                child: SourceText(c,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: muted == null
                            ? const Color(0xff6b6255)
                            : const Color(0xffb7b0a3))),
              ))
          .toList(),
    );
  }
}

/// `.vd-rc` recall self-grade button.
class _RecallButton extends StatelessWidget {
  const _RecallButton({
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });
  final String title, subtitle;
  static const _sourceEn = {
    '没想起': "Didn't recall",
    '有点模糊': 'A bit fuzzy',
    '认识': 'Know it'
  };
  final Color borderColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: SurgoColors.card,
        textStyle: DefaultTextStyle.of(context).style,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: InkWell(
          key: ValueKey('vocab-detail-recall-$title'),
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: Container(
            constraints: BoxConstraints(
                minHeight:
                    context.watch<AppState>().lang == UiLang.zh ? 61 : 69),
            padding:
                const EdgeInsets.symmetric(horizontal: 7.5, vertical: 11.5),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 3,
                    children: [
                      Text(_recallGlyphs[title]!,
                          style: const TextStyle(fontSize: 11)),
                      Text(
                          context.watch<AppState>().lang == UiLang.en
                              ? _sourceEn[title]!
                              : title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: SurgoColors.ink)),
                    ]),
                const SizedBox(height: 3),
                T(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xffa99a82))),
              ],
            ),
          ),
        ),
      );
}
