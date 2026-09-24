import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'pron_frame.dart';
import 'pron_header.dart';

/// 发音训练：`pronCourse`（课程页，app.js 5679-5725）与 `pronLesson`
/// （讲解页，app.js 5936-5986）两条路由的原生实现。
///
/// 只拥有这两页。其余 pron* 页（pronListen/pron2Lesson 等）不在本模块范围内，
/// 通过 [AppState.go] 命名跳转交给它们各自的模块/占位页。
///
/// Body 不含 Scaffold —— 外壳（shell.dart）已提供手机框与 `.read-scroll` 的
/// 滚动容器，这里返回自然高度的 [Column]。
Widget? buildPronCoursePage(SurgoPage page) {
  switch (page) {
    case SurgoPage.pronCourse:
      return const _PronCoursePage();
    case SurgoPage.pronLesson:
      return const _PronLessonPage();
    default:
      return null;
  }
}

// ============================================================ 源数据常量
//
// 逐条抄自 _extract/logic/fns/pronCourseView.js 与 pronLessonView.js，
// 文案不改（翻译交给 [T]）。

/// pronCourse 页：模块的解锁 / 进度取决于原型全局 `pronM1Done`。
/// 原型：`let pronM1Done=false;`（app.js 5676），
/// 在 pronDone 页点“标记完成”时置 true（`pronM1Done=true`）。
/// 迁移为 [AppState.session] 里的键，跨路由共享；默认 false。
const String kPronM1DoneKey = 'pronM1Done';

/// pronCourse 阶段模块的静态描述（源 pronCourseView.js 第 7-12 行）。
class PronCourseMod {
  const PronCourseMod({
    required this.stage,
    required this.consonant,
    required this.kind,
    required this.pair,
    required this.title,
    required this.en,
    required this.extra,
  });

  final String stage; // 第 N 阶段
  final String consonant; // 辅音对比副标题
  final String kind; // pc-k-warn 标签文案
  final String pair; // pc-k-blue 标签文案
  final String title; // 模块标题
  final String en; // 英文副标题
  final String? extra; // pc-k-purple 额外标签
}

/// pronLesson 页步骤（源 pronLessonView.js 第 7 行）。
const List<String> kPronLessonSteps = ['讲解', '听辨', '单词跟读', '句子练习', '完成'];

/// pronLesson 页对比词对（源 pronLessonView.js 第 8-12 行）：
/// [左词, 右词, 左音标, 右音标]。
const List<List<String>> kPronLessonPairs = [
  ['light', 'right', '/laɪt/', '/raɪt/'],
  ['load', 'road', '/ləʊd/', '/rəʊd/'],
  ['collect', 'correct', '/kəˈlekt/', '/kəˈrekt/'],
];

// ============================================================ pc/pl 令牌
//
// 116-发音训练课程页.css / 117-发音训练-讲解页.css 里的散落颜色，
// 全站字号经 shrinkFonts 减 2（下限 10）。这里用 SurgoText.css() 换算。

class _Pc {
  const _Pc._();
  static const heroTitle = Color(0xFF1C1A17);
  static const heroSub = Color(0xFFA99A82);
  static const heroBadgeBg = SurgoColors.yellowTint;
  static const heroBadgeNum = Color(0xFF1C1A17);
  static const heroBadgeLbl = Color(0xFFA08A4A);
  static const stageTitle = Color(0xFF1C1A17);
  static const stageMeta = Color(0xFFA99A82);
  static const modBg = Color(0xFFFFFFFF);
  static const kWarnFg = Color(0xFFA08A4A);
  static const kWarnBg = SurgoColors.yellowTint;
  static const kBlueFg = Color(0xFF4A7FD4);
  static const kBlueBg = Color(0xFFE8F0FC);
  static const kPurpleFg = Color(0xFF7A5FD6);
  static const kPurpleBg = Color(0xFFEEE9FB);
  static const modTtl = Color(0xFF1C1A17);
  static const modEn = Color(0xFFA99A82);
  static const statusFg = Color(0xFF9A948A);
  static const statusBg = Color(0xFFEEE9E0);
  static const statusDoneFg = Color(0xFF4F8A1F);
  static const statusDoneBg = Color(0xFFE8F5E0);
  static const modShadow = [
    BoxShadow(color: Color(0x0F3C3214), blurRadius: 22, offset: Offset(0, 8)),
  ];
}

class _Pl {
  const _Pl._();
  static const cardBg = Color(0xFFFFFFFF);
  static const cardTintBg = SurgoColors.yellowTint;
  static const h = Color(0xFF1C1A17);
  static const tx = Color(0xFF4A453D);
  static const w = Color(0xFF1C1A17);
  static const vsT = Color(0xFFB7B0A3);
  static const ipa = Color(0xFFB7B0A3);
  static const nextBg = SurgoColors.yellow;
  static const nextFg = Color(0xFF3A2E00);
  static const cardShadow = [
    BoxShadow(color: Color(0x0F3C3214), blurRadius: 22, offset: Offset(0, 8)),
  ];
}

/// 共用小标签（.pc-tag）：`font-size:12px;font-weight:700;padding:5px 11px;radius:9px`。
class _PcTag extends StatelessWidget {
  const _PcTag(this.text, {required this.fg, required this.bg});
  final String text;
  final Color fg, bg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: T(text,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: SurgoText.css(12),
              fontWeight: FontWeight.w700,
              color: fg,
            )),
      );
}

// ============================================================ pronCourse 页
//
// 源 pronCourseView.js（app.js 5679-5725）。两阶段模块卡：
//   阶段 1 —— /l/·/r/ 发音要领，永不锁；done 时状态“已完成”，跳 pronLesson。
//   阶段 2 —— 个性化词汇练习；done=false 时锁定不可点，done 时跳 pron2Lesson。
class _PronCoursePage extends StatelessWidget {
  const _PronCoursePage();

  @override
  Widget build(BuildContext context) =>
      PronPageFrame(back: SurgoPage.ielts, child: _content(context));
  Widget _content(BuildContext context) {
    // 原型 done=pronM1Done：驱动 hero 徽章、阶段 meta、模块状态与锁。
    final done = context
        .select<AppState, bool>((s) => s.session[kPronM1DoneKey] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .pc-hero
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    T('发音训练',
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: SurgoText.css(28),
                          fontWeight: FontWeight.w800,
                          color: _Pc.heroTitle,
                        )),
                    const SizedBox(height: 8),
                    T('9301 个考试词汇的系统发音课程——从单音对比到连读与考试语音',
                        style: TextStyle(
                          fontSize: SurgoText.css(14),
                          height: 1.6,
                          color: _Pc.heroSub,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // .pc-hero-badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _Pc.heroBadgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    T(done ? '1/2' : '0/2',
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: SurgoText.css(24),
                          fontWeight: FontWeight.w800,
                          color: _Pc.heroBadgeNum,
                        )),
                    const SizedBox(height: 2),
                    T('已完成模块',
                        style: TextStyle(
                          fontSize: SurgoText.css(11),
                          color: _Pc.heroBadgeLbl,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 阶段 1
        _PcStage(
          stage: '第 1 阶段',
          meta: '辅音对比 · Consonant contrasts · ${done ? '1' : '0'}/1 已完成',
          kind: '认读与发音要领',
          pair: '/l/ 与 /r/ 对比',
          title: '/l/ 与 /r/ —— 发音要领',
          en: '/l/ vs /r/ — articulation',
          status: done ? '已完成' : '未开始',
          statusDone: done,
          extra: null,
          locked: false,
          onTap: () => context.read<AppState>().go(SurgoPage.pronLesson),
        ),
        // 阶段 2
        _PcStage(
          stage: '第 2 阶段',
          meta: '辅音对比 · Consonant contrasts · 0/1 已完成',
          kind: '个性化词汇练习',
          pair: '/l/ 与 /r/ 对比',
          title: '个性化 /l/·/r/ 词汇练习',
          en: 'Personalised /l/·/r/ words',
          status: '未开始',
          statusDone: false,
          extra: '个性化选词',
          locked: !done,
          onTap: done
              ? () => context.read<AppState>().go(SurgoPage.pron2Lesson)
              : null,
        ),
      ],
    );
  }
}

/// 单个阶段块（.pc-stage + .pc-mod）。
class _PcStage extends StatelessWidget {
  const _PcStage({
    required this.stage,
    required this.meta,
    required this.kind,
    required this.pair,
    required this.title,
    required this.en,
    required this.status,
    required this.statusDone,
    required this.extra,
    required this.locked,
    required this.onTap,
  });

  final String stage, meta, kind, pair, title, en, status;
  final bool statusDone, locked;
  final String? extra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // .pc-lock svg：rect + path 的挂锁描边（源 pronCourseView.js 第 6 行）。
    final lockIcon = SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="#b7b0a3" stroke-width="1.8" '
      'stroke-linecap="round" stroke-linejoin="round">'
      '<rect x="4" y="10.5" width="16" height="11" rx="2.5"/>'
      '<path d="M8 10.5V7a4 4 0 0 1 8 0v3.5"/></svg>',
      width: 18,
      height: 18,
    );

    final mod = DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18), boxShadow: _Pc.modShadow),
        child: Material(
          textStyle: DefaultTextStyle.of(context).style,
          color: _Pc.modBg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              // Shadow belongs outside Material; painting it inside tinted white cards grey.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // .pc-mod-tags
                  Row(children: [
                    Expanded(
                        child: Row(children: [
                      Flexible(
                          child:
                              _PcTag(kind, fg: _Pc.kWarnFg, bg: _Pc.kWarnBg)),
                      const SizedBox(width: 9),
                      _PcTag(pair, fg: _Pc.kBlueFg, bg: _Pc.kBlueBg),
                    ])),
                    if (locked) ...[
                      const SizedBox(width: 9),
                      IgnorePointer(child: lockIcon)
                    ],
                  ]),
                  const SizedBox(height: 12),
                  T(title,
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: SurgoText.css(17),
                        fontWeight: FontWeight.w800,
                        color: _Pc.modTtl,
                      )),
                  const SizedBox(height: 4),
                  // 英文副标题是内容而非 chrome，用原生 Text 不过词典。
                  SourceText(en,
                      style: TextStyle(
                        fontSize: SurgoText.css(13),
                        color: _Pc.modEn,
                      )),
                  const SizedBox(height: 14),
                  // .pc-mod-foot
                  Wrap(
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusDone ? _Pc.statusDoneBg : _Pc.statusBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: T(status,
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: SurgoText.css(12),
                              fontWeight: FontWeight.w700,
                              color:
                                  statusDone ? _Pc.statusDoneFg : _Pc.statusFg,
                            )),
                      ),
                      if (extra != null) ...[
                        const SizedBox(width: 10),
                        _PcTag(extra!, fg: _Pc.kPurpleFg, bg: _Pc.kPurpleBg),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // .pc-stage-hd
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              runSpacing: 4,
              children: [
                T(stage,
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: SurgoText.css(20),
                      fontWeight: FontWeight.w800,
                      color: _Pc.stageTitle,
                    )),
                T(meta,
                    style: TextStyle(
                      fontSize: SurgoText.css(12.5),
                      color: _Pc.stageMeta,
                    )),
              ],
            ),
          ),
          mod,
        ],
      ),
    );
  }
}

// ============================================================ pronLesson 页
//
// 源 pronLessonView.js（app.js 5936-5986）。步骤条 5 步（当前=讲解），
// 第 2 步“听辨”与底部“下一步”按钮跳 pronListen。三张讲解卡 + 对比词对卡。
class _PronLessonPage extends StatelessWidget {
  const _PronLessonPage();

  @override
  Widget build(BuildContext context) =>
      PronPageFrame(back: SurgoPage.pronCourse, child: _content(context));
  Widget _content(BuildContext context) {
    void goListen() => context.read<AppState>().go(SurgoPage.pronListen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PronLessonHeader(listening: false),
        // 讲解卡片组
        const _PlCard(
          head: '本模块目标',
          body: 'Tell and produce /l/ vs /r/ in word-initial position.',
        ),
        const _PlCard(
          head: '讲解',
          body:
              'For /l/, the tongue tip touches the ridge behind the upper teeth. For /r/, it curls back without touching.',
        ),
        const _PlCard(
          head: '发音要领',
          body:
              '/l/: tongue tip on the alveolar ridge · /r/: tip pulled back, no contact',
          tint: true,
        ),
        // 对比词对卡
        _PlCard(
          head: '对比词对',
          child: Column(
            children: [
              for (var i = 0; i < kPronLessonPairs.length; i++)
                _PlPairRow(
                    pair: kPronLessonPairs[i],
                    last: i == kPronLessonPairs.length - 1),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // .ra-next
        Material(
          textStyle: DefaultTextStyle.of(context).style,
          color: _Pl.nextBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: goListen,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(17),
              child: T('下一步：听辨',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: SurgoText.css(16),
                    fontWeight: FontWeight.w800,
                    color: _Pl.nextFg,
                  )),
            ),
          ),
        ),
      ],
    );
  }
}

/// .pl-card：白底（或 .tint 黄底）圆角卡，标题 + 正文 / 自定义子组件。
class _PlCard extends StatelessWidget {
  const _PlCard({
    required this.head,
    this.body,
    this.child,
    this.tint = false,
  });

  final String head;
  final String? body;
  final Widget? child;
  final bool tint;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: tint ? _Pl.cardTintBg : _Pl.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: tint ? null : _Pl.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题：中文文案过词典；小节标题“讲解/发音要领/对比词对/本模块目标”。
            T(head,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: SurgoText.css(16),
                  fontWeight: FontWeight.w800,
                  color: _Pl.h,
                )),
            const SizedBox(height: 9),
            if (body != null)
              // 正文为英文讲解内容，用原生 Text 不过词典。
              SourceText(body!,
                  style: TextStyle(
                    fontSize: SurgoText.css(14.5),
                    height: 1.6,
                    color: _Pl.tx,
                  )),
            if (child != null) child!,
          ],
        ),
      );
}

/// .pl-pair：一行对比词对（左词 + 喇叭 · vs 右词 + 喇叭 · IPA 标注）。
class _PlPairRow extends StatelessWidget {
  const _PlPairRow({required this.pair, required this.last});
  final bool last;
  final List<String> pair; // [左词, 右词, 左音标, 右音标]

  @override
  Widget build(BuildContext context) {
    // .pl-spk 喇叭图标（源 pronLessonView.js 第 6 行）。
    Widget spk() => SvgPicture.string(
          '<svg viewBox="0 0 24 24" fill="none" stroke="#E0A000" stroke-width="1.8" '
          'stroke-linecap="round" stroke-linejoin="round">'
          '<path d="M11 5 6 9H3v6h3l5 4z"/>'
          '<path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>',
          width: 16,
          height: 16,
        );

    final wordStyle = TextStyle(
      fontSize: SurgoText.css(16),
      fontWeight: FontWeight.w600,
      color: _Pl.w,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: SurgoColors.line))),
      child: Row(
        children: [
          // .pl-w：左词 + 喇叭
          Expanded(
            child: Row(
              children: [
                Flexible(child: SourceText(pair[0], style: wordStyle)),
                const SizedBox(width: 6),
                spk(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // .pl-vs：vs + 右词 + 喇叭
          Expanded(
            child: Row(
              children: [
                SourceText('vs',
                    style:
                        TextStyle(fontSize: SurgoText.css(12), color: _Pl.vsT)),
                const SizedBox(width: 8),
                Flexible(child: SourceText(pair[1], style: wordStyle)),
                const SizedBox(width: 6),
                spk(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // .pl-ipa
          SourceText('/l/ vs /r/',
              style: TextStyle(fontSize: SurgoText.css(11.5), color: _Pl.ipa)),
        ],
      ),
    );
  }
}
