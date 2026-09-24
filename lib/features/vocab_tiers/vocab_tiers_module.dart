import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'tier_source_widgets.dart';

/// Vocab tiers feature — native Dart port of the H5 prototype views
/// `vocabTier1View` / `vocabTier2View` / `vocabTier3View` / `vocabTier4View`
/// (app.js 3547-3773) and `vocabNoNewView` (app.js 3655-3667), with styling
/// from `_extract/css/56-词汇学习-单词回忆页.css` (`.tr-*`) and
/// `_extract/css/57-词汇学习空状态页-Tier3-Tier4-无新单词.css` (`.vn-*`).
///
/// Owns: this module + test/vocab_tiers*.dart.
///
/// Every visible string, word count, percentage, stat number, chip word and
/// placeholder is copied verbatim from the source `*View.js`; nothing is
/// invented. State/routing semantics preserved from the prototype:
///
///   * The nav back (home glyph) routes `go('vocab')` on all four tier pages;
///     `vocabNoNewView` has no nav in the source, so none is rendered here.
///   * Tier 1 & 2 hero「继续学习 →」and「开始学习」both route `go('vocabStudy4')`
///     (source `onclick="go('vocabStudy4')"`).
///   * Tier 3 & 4 hero「继续学习 →」and「开始学习」both route `go('vocabNoNew')`
///     (source `onclick="go('vocabNoNew')"`).
///   * 查看全部词汇 → routes `go('vocabBook')` on every tier page.
///   * vocabNoNew「返回词汇首页」routes `go('vocab')`.
///
/// The body is a natural-height [Column] (no inner scroll view); the app shell
/// owns the vertical scroll, matching `.read-scroll` under the phone frame.
/// Interface chrome is wrapped in [T]; source data (word counts, chip words)
/// uses plain [Text].

// --------------------------------------------------------------- source colors
// Exact CSS hex values from the source stylesheets with no token equivalent.
const Color _cSubTaupe = Color(
    0xFFA99A82); // tr-hero-s / tr-prog-pct / tr-ps-l / tr-prev-s / tr-foot
const Color _cGoldIcon = Color(0xFFC99A1E); // ear / pen svg stroke
const Color _cGreenIcon = Color(0xFF4F8A1F); // chk svg stroke
const Color _cGrayIcon = Color(0xFF9A948A); // clk svg stroke
const Color _cGoldSub = Color(0xFFA08A4A); // tr-next-s
const Color _cStatGreenBg = Color(0xFFE8F5E0); // tr-g
const Color _cStatGrayBg = Color(0xFFEEEBE4); // tr-gray
const Color _cBarTrack = Color(0xFFEFE9DD); // tr-prog-bar
const Color _cChipInk = Color(0xFF4A453D); // tr-chip text
const Color _cChipPrevBg = Color(0xFFF1EFE9); // .tr-prev .tr-chip background
const Color _cVnTtl = Color(0xFF1C1A17); // vn-ttl

// Radii from the source CSS.
const BorderRadius _rHeroIc =
    BorderRadius.all(Radius.circular(999)); // tr-hero-ic circle
const BorderRadius _r18 = BorderRadius.all(
    Radius.circular(SurgoRadius.cardLg)); // tr-prog / tr-next / tr-prev
const BorderRadius _r22 =
    BorderRadius.all(Radius.circular(22)); // tr-hero-go / tr-next-go
const BorderRadius _r9 = BorderRadius.all(Radius.circular(9)); // tr-chip
const BorderRadius _r14 =
    BorderRadius.all(Radius.circular(14)); // tr-next-otter
const BorderRadius _rVnGo = BorderRadius.all(Radius.circular(26)); // vn-go

// -------------------------------------------------------------------- tier data

/// One learning-path tier — verbatim from the source `vocabTier{1..4}View`.
class VocabTierConfig {
  const VocabTierConfig({
    required this.route,
    required this.heroTitle,
    required this.heroSub,
    required this.target,
    required this.progTitle,
    required this.pct,
    required this.mastered,
    required this.reviewed,
    required this.pending,
    required this.previewTitle,
    required this.previewSub,
    required this.chips,
    required this.chipsMuted,
  });

  final SurgoPage route;

  /// tr-hero-t, e.g. 'Tier 1 · 必备'.
  final String heroTitle;

  /// tr-hero-s, e.g. '226 个词 · 必备词汇'.
  final String heroSub;

  /// Destination of both「继续学习 →」(tr-hero-go) and「开始学习」(tr-next-go).
  final SurgoPage target;

  /// tr-prog-t, e.g. 'Tier 1 学习进度'.
  final String progTitle;

  /// tr-prog-pct percentage and tr-prog-bar width (0-100).
  final int pct;

  /// tr-ps-n numbers: 已掌握 / 已复习 / 待巩固.
  final String mastered, reviewed, pending;

  /// tr-prev-t / tr-prev-s.
  final String previewTitle, previewSub;

  /// tr-chips words (shown in both tr-next and tr-prev).
  final List<String> chips;

  /// When true the chips are muted placeholders (tr-chip-muted).
  final bool chipsMuted;
}

/// Verbatim from the source view functions.
const Map<SurgoPage, VocabTierConfig> kVocabTierConfigs = {
  SurgoPage.vocabTier1: VocabTierConfig(
    route: SurgoPage.vocabTier1,
    heroTitle: 'Tier 1 · 必备',
    heroSub: '226 个词 · 必备词汇',
    target: SurgoPage.vocabStudy4,
    progTitle: 'Tier 1 学习进度',
    pct: 46,
    mastered: '86',
    reviewed: '18',
    pending: '122',
    previewTitle: 'Tier 1 词汇预览',
    previewSub: '共 226 个单词，展示部分高频词',
    chips: ['identify', 'adapt', 'analyse'],
    chipsMuted: false,
  ),
  SurgoPage.vocabTier2: VocabTierConfig(
    route: SurgoPage.vocabTier2,
    heroTitle: 'Tier 2 · 核心',
    heroSub: '1302 个词 · 核心词汇',
    target: SurgoPage.vocabStudy4,
    progTitle: 'Tier 2 学习进度',
    pct: 0,
    mastered: '0',
    reviewed: '0',
    pending: '1302',
    previewTitle: 'Tier 2 词汇预览',
    previewSub: '共 1302 个单词，展示部分高频词',
    chips: ['context'],
    chipsMuted: false,
  ),
  SurgoPage.vocabTier3: VocabTierConfig(
    route: SurgoPage.vocabTier3,
    heroTitle: 'Tier 3 · 重要',
    heroSub: '1180 个词 · 重要词汇',
    target: SurgoPage.vocabNoNew,
    progTitle: 'Tier 3 学习进度',
    pct: 0,
    mastered: '0',
    reviewed: '0',
    pending: '1180',
    previewTitle: 'Tier 3 词汇预览',
    previewSub: '共 1180 个单词，展示部分高频词',
    chips: ['词汇材料待提供'],
    chipsMuted: true,
  ),
  SurgoPage.vocabTier4: VocabTierConfig(
    route: SurgoPage.vocabTier4,
    heroTitle: 'Tier 4 · 拓展',
    heroSub: '3221 个词 · 拓展词汇',
    target: SurgoPage.vocabNoNew,
    progTitle: 'Tier 4 学习进度',
    pct: 0,
    mastered: '0',
    reviewed: '0',
    pending: '3221',
    previewTitle: 'Tier 4 词汇预览',
    previewSub: '共 3221 个单词，展示部分高频词',
    chips: ['词汇材料待提供'],
    chipsMuted: true,
  ),
};

// -------------------------------------------------------------------- entry

/// Router entry for the vocab-tiers native pages.
///
/// Returns the matching widget for `vocabTier{1..4}` / `vocabNoNew`, or `null`
/// for any page this module does not own (mirrors the prototype
/// `if(!V[id]) return;` — unknown ids are handled elsewhere).
Widget? buildVocabTiersPage(SurgoPage page) {
  switch (page) {
    case SurgoPage.vocabTier1:
    case SurgoPage.vocabTier2:
    case SurgoPage.vocabTier3:
    case SurgoPage.vocabTier4:
      return VocabTierPage(config: kVocabTierConfigs[page]!);
    case SurgoPage.vocabNoNew:
      return const VocabNoNewPage();
    default:
      return null;
  }
}

// -------------------------------------------------------------------- widgets

/// 词汇分级页 — port of `vocabTier{1..4}View`.
class VocabTierPage extends StatelessWidget {
  const VocabTierPage({super.key, required this.config});
  final VocabTierConfig config;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return TierFrame(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ------------------------------------------------------------ tr-hero
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 20),
          child: Row(
            children: [
              // tr-hero-ic (yellow-tint circle + ear glyph)
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SurgoColors.yellowTint,
                  borderRadius: _rHeroIc,
                ),
                child: tierIcon('ear', 26),
              ),
              const SizedBox(width: 14),
              // tr-hero-b (title + sub) — hero title/count are source data.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceText(config.heroTitle,
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: SurgoText.css(22),
                          fontWeight: FontWeight.w900,
                          color: SurgoColors.ink,
                        )),
                    const SizedBox(height: 3),
                    SourceText(config.heroSub,
                        style: TextStyle(
                            fontSize: SurgoText.css(13), color: _cSubTaupe)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // tr-hero-go → go(target)
              _PillButton(
                key: const ValueKey('tier-continue'),
                label: '继续学习 →',
                onTap: () => app.go(config.target),
                fontSize: SurgoText.css(15),
              ),
            ],
          ),
        ),

        // ------------------------------------------------------------ tr-prog
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: SurgoColors.card,
            borderRadius: _r18,
            boxShadow: tierShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tr-prog-l
              T(config.progTitle,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: SurgoText.css(17),
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink,
                  )),
              const SizedBox(height: 8),
              // tr-prog-pct: `<b>${pct}%</b> 已学习`
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SourceText('${config.pct}%',
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: SurgoColors.yellow)),
                    const SizedBox(width: 6),
                    const SourceText(' 已学习',
                        style: TextStyle(fontSize: 12, color: _cSubTaupe)),
                  ]),
              const SizedBox(height: 10),
              // tr-prog-bar
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: Container(
                  key: const ValueKey('tier-progress-track'),
                  width: double.infinity,
                  height: 8,
                  color: _cBarTrack,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: config.pct / 100,
                    child: Container(
                        key: const ValueKey('tier-progress-fill'),
                        decoration:const BoxDecoration(color:SurgoColors.yellow,borderRadius:BorderRadius.all(Radius.circular(6)))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // tr-prog-stats
              Row(
                key: const ValueKey('tier-stats'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Stat(
                    bg: _cStatGreenBg,
                    icon: 'check',
                    iconColor: _cGreenIcon,
                    n: config.mastered,
                    l: '已掌握',
                  ),
                  const _StatDivider(),
                  _Stat(
                    bg: SurgoColors.yellowTint,
                    icon: 'pen',
                    iconColor: _cGoldIcon,
                    n: config.reviewed,
                    l: '已复习',
                  ),
                  const _StatDivider(),
                  _Stat(
                    bg: _cStatGrayBg,
                    icon: 'clock',
                    iconColor: _cGrayIcon,
                    n: config.pending,
                    l: '待巩固',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------------------ tr-next
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: SurgoColors.yellowTint,
            borderRadius: _r18,
          ),
          child: LayoutBuilder(
              builder: (context, bounds) => Wrap(
                    key: const ValueKey('tier-next'),
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // tr-next-otter
                      ClipRRect(
                        borderRadius: _r14,
                        child: Image.asset('assets/images/otter_study.png',
                            width: 78, height: 78, fit: BoxFit.cover),
                      ),
                      // Source min-width180; at 390 the text gets220 and CTA wraps.
                      SizedBox(
                        width: bounds.maxWidth - 94 < 180
                            ? bounds.maxWidth
                            : bounds.maxWidth - 94,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            T('下一组推荐学习',
                                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: SurgoText.css(18),
                                  fontWeight: FontWeight.w800,
                                  color: SurgoColors.ink,
                                )),
                            const SizedBox(height: 4),
                            T('单词数量与预计时间将在开始学习后确认',
                                style: TextStyle(
                                    fontSize: SurgoText.css(13),
                                    color: _cGoldSub)),
                            const SizedBox(height: 10),
                            _Chips(
                                words: config.chips,
                                muted: config.chipsMuted,
                                prev: false),
                          ],
                        ),
                      ),
                      // tr-next-go → go(target), independent flex-wrap item.
                      _PillButton(
                        key: const ValueKey('tier-start'),
                        label: '开始学习',
                        onTap: () => app.go(config.target),
                        fontSize: SurgoText.css(15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 13),
                      ),
                    ],
                  )),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------------------ tr-prev
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SurgoColors.card,
            borderRadius: _r18,
            boxShadow: tierShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tr-prev-t / tr-prev-s — preview title/count are source data.
              SourceText(config.previewTitle,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: SurgoText.css(18),
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink,
                  )),
              const SizedBox(height: 4),
              SourceText(config.previewSub,
                  style: TextStyle(
                      fontSize: SurgoText.css(13), color: _cSubTaupe)),
              const SizedBox(height: 14),
              // tr-prev-row
              TierPreviewRow(
                  words: config.chips,
                  chips: _Chips(
                      words: config.chips,
                      muted: config.chipsMuted,
                      prev: true),
                  onTap: () => app.go(SurgoPage.vocabBook)),
            ],
          ),
        ),

        // ------------------------------------------------------------ tr-foot
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
          child: T('坚持每天学习一点点，词汇量会不断增长哦！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: SurgoText.css(13), color: _cSubTaupe)),
        ),
      ],
    ));
  }
}

/// tr-hero-go / tr-next-go: yellow pill, dark-brown label, intrinsic width so it
/// stays bounded inside a [Row] (never `double.infinity`).
class _PillButton extends StatelessWidget {
  const _PillButton(
      {super.key,
      required this.label,
      required this.onTap,
      required this.fontSize,
      this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12)});
  final EdgeInsets padding;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration:
          const BoxDecoration(borderRadius: _r22, boxShadow: tierButtonShadow),
      child: Material(
        color: SurgoColors.yellow,
        textStyle: DefaultTextStyle.of(context).style,
        borderRadius: _r22,
        child: InkWell(
          borderRadius: _r22,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: T(label,
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: fontSize,
                  height:
                      (context.watch<AppState>().lang == UiLang.zh ? 18 : 15) /
                          fontSize,
                  fontWeight: FontWeight.w700,
                  color: SurgoColors.onYellowStrong,
                )),
          ),
        ),
      ));
}

/// tr-ps: one progress stat (icon + number + label).
class _Stat extends StatelessWidget {
  const _Stat({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.n,
    required this.l,
  });
  final Color bg, iconColor;
  final String icon;
  final String n, l;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56),
        child: Column(
          children: [
            // tr-ps-ic
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: tierIcon(icon, 19),
            ),
            const SizedBox(height: 6),
            // tr-ps-n (source stat number)
            SourceText(n,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: SurgoText.css(22),
                  fontWeight: FontWeight.w900,
                  color: SurgoColors.ink,
                )),
            const SizedBox(height: 2),
            // tr-ps-l
            T(l,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: SurgoText.css(12), color: _cSubTaupe)),
          ],
        ),
      );
}

/// tr-ps-div: thin vertical rule between stats.
class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: SurgoColors.line,
      );
}

/// tr-chips: wrap of tr-chip pills. In tr-prev the pill background is #f1efe9;
/// in tr-next it is white. Muted chips use taupe text (tr-chip-muted).
class _Chips extends StatelessWidget {
  const _Chips({required this.words, required this.muted, required this.prev});
  final List<String> words;
  final bool muted, prev;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final w in words)
        Container(
          key: ValueKey('tier-chip-${prev ? 'preview' : 'next'}-$w'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: prev ? _cChipPrevBg : SurgoColors.card,
            borderRadius: _r9,
          ),
          // Chip words are source data → plain Text, not T.
          child: SourceText(w,
              style: TextStyle(
                fontSize: SurgoText.css(13),
                color: muted ? _cSubTaupe : _cChipInk,
              )),
        ),
    ];
    // A single long placeholder must wrap its own text at large/system fonts.
    if (items.length == 1) { return items.single; }
    if (prev) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          items[i]
        ],
      ]);
    }
    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }
}

/// 词汇学习空状态页 — port of `vocabNoNewView`.
class VocabNoNewPage extends StatelessWidget {
  const VocabNoNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // vn-wrap: centered column, padding:90px 20px 40px. No nav in source.
    return TierFrame(
        nav: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // vn-ic
              tierIcon('empty', 52),
              const SizedBox(height: 22),
              // vn-ttl
              T('当前没有新单词',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: SurgoText.css(22),
                    fontWeight: FontWeight.w800,
                    color: _cVnTtl,
                  )),
              const SizedBox(height: 26),
              // vn-go → go('vocab')
              DecoratedBox(
                  decoration: const BoxDecoration(
                      borderRadius: _rVnGo, boxShadow: tierButtonShadow),
                  child: Material(
                    color: SurgoColors.yellow,
                    textStyle: DefaultTextStyle.of(context).style,
                    borderRadius: _rVnGo,
                    child: InkWell(
                      key: const ValueKey('tier-empty-back'),
                      borderRadius: _rVnGo,
                      onTap: () => app.go(SurgoPage.vocab),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 38, vertical: 15),
                        child: T('返回词汇首页',
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: SurgoText.css(16),
                              fontWeight: FontWeight.w800,
                              color: SurgoColors.onYellowStrong,
                            )),
                      ),
                    ),
                  )),
            ],
          ),
        ));
  }
}
