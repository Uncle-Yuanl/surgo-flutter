import '../../widgets/source_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/t.dart';

/// Native port of the original `speakingReviewView()` from surgo-mobile-new/app.js.
///
/// This shows a FIXED demo review: the example answers, band scores and
/// per-criterion comments are the exact source fixtures (exported byte-for-byte
/// by tool/export_speaking_review.cjs). They are illustrative, not the product
/// of real grading, and must never be replaced by live scoring.
/// The Vercel demo build overlays one learner's stored results instead
/// (tool/demo_export/speaking.cjs) — still fixed JSON, nothing is scored live.
///
/// Layout mirrors the source markup as a single natural-height Column (no inner
/// scroll view — the shell owns scrolling): meta chips, overall hero, weak-point
/// analysis, the four criterion cards, then the per-question section with Part
/// tabs. Part 1 / Part 2 / Part 3 tabs appear together only in full-mock mode;
/// in daily training only the practised Part is shown. Part 3 renders all ten
/// discussion rounds followed by the examiner's overall comment card.
///
/// Font sizes follow the source `shrinkFonts()` pass (declared CSS px minus 2,
/// floored at 10) via [SurgoText.css]. Chrome labels go through [T] so they
/// translate with the UI language; question text, transcripts and the bilingual
/// feedback strings are raw [Text] (content, never translated).
class SpeakingReviewPage extends StatefulWidget {
  const SpeakingReviewPage({super.key});
  @override
  State<SpeakingReviewPage> createState() => _SpeakingReviewPageState();
}

class _SpeakingReviewPageState extends State<SpeakingReviewPage> {
  Map<String, dynamic>? d;
  // let spReviewPart='p1'; — the currently displayed Part tab.
  String spReviewPart = 'p1';

  @override
  void initState() {
    super.initState();
    // Daily training: land on the Part the user just practised (selWizCard).
    final s = context.read<AppState>().session;
    spReviewPart = s['spReviewPart'] as String? ?? 'p1';
    if (s['sessionMode'] != 'mock') {
      final card = s['selWizCard'];
      if (card == 'p1' || card == 'p2' || card == 'p3') spReviewPart = card as String;
    }
    rootBundle.loadString('assets/data/speaking_review.json').then((raw) {
      if (mounted) setState(() => d = jsonDecode(raw) as Map<String, dynamic>);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = d;
    if (data == null) return const Center(child: CircularProgressIndicator());
    final app = context.watch<AppState>();
    final en = app.lang == UiLang.en;
    final mock = app.session['sessionMode'] == 'mock';
    // 演示用真实数据（tool/demo_export/speaking.cjs）按 Part 各带一次作答：daily.p1/p2/p3，
    // 分数、分项、弱项、逐题都跟着当前 Part 走。原型数据没有 daily，整页用顶层这一份。
    final view = (data['daily'] as Map?)?[spReviewPart] as Map<String, dynamic>? ?? data;
    final score = view['score'] as String;
    final criteria = (view['criteria'] as List).cast<Map<String, dynamic>>();
    final weaks = (view['weaks'] as List).cast<Map<String, dynamic>>();
    final items = view['items'] as Map<String, dynamic>;
    // 真实数据没有「话题卡要点覆盖」和 Part 3 考官总评，这两块就不画。
    final cuePoints = (view['cuePoints'] as List? ?? const []).cast<List>();
    final overall = view['p3Overall'] as Map<String, dynamic>?;
    final curItems = (items[spReviewPart] as List? ?? const []).cast<Map<String, dynamic>>();

    final partInfo = spReviewPart == 'p1'
        ? const ['Part 1 · 介绍与问答', '关于熟悉话题的日常问答（4–5 分钟）。']
        : (spReviewPart == 'p3'
            ? const ['Part 3 · 双向讨论', '就抽象话题与考官深入讨论（4–5 分钟）。']
            : const ['Part 2 · 个人长陈述（话题卡）', '1 分钟准备，随后陈述 1–2 分钟。']);
    final tabParts = mock ? const ['p1', 'p2', 'p3'] : [spReviewPart];
    final pbNum = spReviewPart == 'p1' ? '1' : (spReviewPart == 'p3' ? '3' : '2');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // .ra-nav — home button + centred title.
      // 用户 2026-09-24：标题居中并改用标题字号（原 15px 靠左紧贴 home）。
      // 右上角有全局设置/消息按钮，给右侧留出同等空间，标题才真正视觉居中。
      Padding(padding: const EdgeInsets.fromLTRB(2, 6, 2, 20), child: Row(children: [
        InkWell(onTap: () => app.go(SurgoPage.ielts), child: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: SurgoShadow.card),
          alignment: Alignment.center, child: SvgPicture.asset('assets/images/home_icon.svg', width: 20, height: 20))),
        Expanded(child: T('练习回顾', textAlign: TextAlign.center, maxLines: 1, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(22), fontWeight: FontWeight.w800, letterSpacing: 0.3, color: SurgoColors.ink), uppercase: true)),
        const SizedBox(width: 86),
      ])),
      // .sv-meta chips.
      Padding(padding: const EdgeInsets.fromLTRB(2, 0, 2, 14), child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _chip('模拟考成绩', const Color(0xFF8A5AA8), const Color(0xFFF4E9F8)),
        _chip(app.examType == ExamType.toefl ? (en ? 'TOEFL Speaking' : 'TOEFL 口语') : (en ? 'IELTS Speaking' : 'IELTS 口语'), const Color(0xFF3F7AB8), const Color(0xFFE6F0FA)),
        T(view['meta'] ?? '今日完成, 14:32 · 24 min', style: TextStyle(fontSize: SurgoText.css(13.5), color: SurgoColors.muted)),
      ])),
      // .sv-hero — overall practice estimate (fixed demo score).
      Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(color: const Color(0xFFFBEEC2), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          T('总体 · 练习估分', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w700, color: const Color(0xFF8A7530))),
          const SizedBox(height: 6),
          SourceText.rich(TextSpan(children: [
            TextSpan(text: score, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(42), fontWeight: FontWeight.w900, height: 1.05, color: SurgoColors.ink)),
            TextSpan(text: ' / 9.0', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(17), fontWeight: FontWeight.w700, color: const Color(0xFFA08B3A))),
          ])),
          const SizedBox(height: 11),
          // 用户 2026-09-24：中英分开 —— 中文模式只出中文、英文模式只出英文，
          // 不再中英并列；字号同时放大一档。
          // 真实数据带 summary（第一条优先改进项，只有英文），两种界面都显示原文。
          SourceText(
              view['summary'] as String? ?? (en
                  ? 'A solid Band $score performance: you speak at length, stay relevant and use a decent range of vocabulary. To reach Band 7 you need fewer filled pauses before complex ideas, more varied verbs instead of repeating "I like", and a wider range of complex sentences. Pronunciation is not scored here because this practice run has no real audio analysis.'
                  : '总体 $score：你能持续表达、内容切题、词汇范围尚可。要冲 7 分，需要减少复杂观点前的填充停顿、用更多样的动词代替反复的 "I like"，并使用更丰富的复合句。发音在本次练习中不评分，因为没有真实音频分析。'),
              style: TextStyle(
                  fontSize: SurgoText.css(15),
                  height: 1.6,
                  color: const Color(0xFF5A4A20))),
        ]),
      ),
      // .sv-weak — weak-point analysis.
      _srCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        T('薄弱项分析', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(20), fontWeight: FontWeight.w800, color: SurgoColors.ink)),
        const SizedBox(height: 6),
        T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。', style: TextStyle(fontSize: SurgoText.css(14), height: 1.55, color: const Color(0xFFA99A82))),
        const SizedBox(height: 14),
        for (final w in weaks) Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(color: const Color(0xFFFDF6E3), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 16, height: 16, alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFC0392B), width: 1.5)),
                child: const SourceText('!', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFC0392B)))),
              const SizedBox(width: 8),
              Expanded(child: _text(w['en'], TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(16), fontWeight: FontWeight.w800, color: const Color(0xFFC0392B)))),
            ]),
            if (w['quote'] != null) ...[
              const SizedBox(height: 9),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEFECE4), borderRadius: BorderRadius.circular(9)),
                child: SourceText(_weakQuote(w, en), style: TextStyle(fontSize: SurgoText.css(14), fontStyle: FontStyle.italic, color: const Color(0xFF7A736A)))),
            ],
            const SizedBox(height: 10),
            SourceText.rich(TextSpan(children: [
              TextSpan(text: en ? 'Suggestion' : '改进建议', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(14.5), fontWeight: FontWeight.w800, color: const Color(0xFF3A3630))),
              TextSpan(text: ': ${_weakTip(w, en)}', style: TextStyle(fontSize: SurgoText.css(14.5), color: const Color(0xFF4A453D))),
            ], style: const TextStyle(height: 1.6))),
          ]),
        ),
        InkWell(onTap: () => app.go(SurgoPage.speakingDaily), borderRadius: SurgoRadius.btnAll, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: SurgoColors.yellow, borderRadius: SurgoRadius.btnAll),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child:T('练习你最弱的题型', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(15), fontWeight: FontWeight.w800, color: const Color(0xFF3A2E00)))),
            const SizedBox(width: 8), const SourceText('→', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.w800, color: Color(0xFF3A2E00))),
          ]))),
      ])),
      // Four criterion cards.
      for (final c in criteria) _srCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: T(c['zh'] as String, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(16), fontWeight: FontWeight.w800, color: SurgoColors.ink))),
          if (c['sc'] != null) SourceText.rich(TextSpan(children: [
            TextSpan(text: '${c['sc']} ', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(19), fontWeight: FontWeight.w800, color: SurgoColors.ink)),
            TextSpan(text: '/9', style: TextStyle(fontSize: SurgoText.css(13), fontWeight: FontWeight.w600, color: const Color(0xFFA99A82))),
          ]))
          else Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEEE9E0), borderRadius: BorderRadius.circular(9)),
            child: T('未评分', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w700, color: const Color(0xFF9A948A)))),
        ]),
        const SizedBox(height: 9),
        SourceText(c['en'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.55, color: const Color(0xFF4A453D))),
        // 真实数据的分项反馈只有英文，没有这段中文说明。
        if (c['zhNote'] != null) ...[
          const SizedBox(height: 5),
          SourceText(c['zhNote'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.55, color: const Color(0xFFA99A82))),
        ],
        for (final q in (c['quotes'] as List)) Padding(padding: const EdgeInsets.only(top: 8), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(color: const Color(0xFFF0EEFB), borderRadius: BorderRadius.circular(10)),
          child: SourceText(q as String, style: TextStyle(fontSize: SurgoText.css(13.5), fontStyle: FontStyle.italic, color: const Color(0xFF6B6FC7))))),
      ])),
      // .sr-sec — per-question section header.
      Padding(padding: const EdgeInsets.fromLTRB(2, 22, 2, 14),
        child: T('逐题分析', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(21), fontWeight: FontWeight.w800, color: SurgoColors.ink))),
      // .sr-parttabs.
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Wrap(spacing: 10, children: [
        for (final p in tabParts) _partTab(p, p == 'p1' ? 'Part 1' : (p == 'p3' ? 'Part 3' : 'Part 2'), on: spReviewPart == p),
      ])),
      // .sr-partband.
      Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(color: SurgoColors.yellowTint, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 26, height: 26, alignment: Alignment.center,
            decoration: const BoxDecoration(color: SurgoColors.yellow, shape: BoxShape.circle),
            child: SourceText(pbNum, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(14), fontWeight: FontWeight.w800, color: const Color(0xFF3A2E00)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            T(partInfo[0], style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(15), fontWeight: FontWeight.w800, color: SurgoColors.ink)),
            const SizedBox(height: 2),
            T(partInfo[1], style: TextStyle(fontSize: SurgoText.css(13.5), color: const Color(0xFFA08A4A))),
          ])),
        ])),
      // Per-question cards.
      for (var i = 0; i < curItems.length; i++) _questionCard(curItems[i], i, en, cuePoints),
      // Part 3 examiner overall comment, after the final round.
      if (spReviewPart == 'p3' && overall != null) Container(
        margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
        decoration: BoxDecoration(color: SurgoColors.yellowTint, borderRadius: BorderRadius.circular(18), border: Border.all(color: SurgoColors.yellowSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SourceText(en ? 'Examiner\u2019s overall comment' : '考官总评', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(15), fontWeight: FontWeight.w800, color: const Color(0xFF9A7A00))),
          const SizedBox(height: 10),
          SourceText(overall['en'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.6, color: const Color(0xFF4A453D))),
          const SizedBox(height: 8),
          SourceText(overall['zh'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.6, color: const Color(0xFF8A7C58))),
        ]),
      ),
      // .ra-next — return home.
      InkWell(onTap: () => app.go(SurgoPage.ielts), borderRadius: BorderRadius.circular(16), child: Container(
        alignment: Alignment.center, padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: SurgoColors.yellow, borderRadius: BorderRadius.circular(16), boxShadow: SurgoShadow.yellowCard),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SourceText('⌂', style: TextStyle(fontSize: SurgoText.css(15), color: const Color(0xFF3A2E00))),
          const SizedBox(width: 8),
          T('回到首页', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(16), fontWeight: FontWeight.w800, color: const Color(0xFF3A2E00))),
        ]))),
    ]);
  }

  // .sr-card container.
  Widget _srCard({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: const [BoxShadow(color: Color(0x0F3C3214), blurRadius: 22, offset: Offset(0, 8))]),
    child: child);

  Widget _chip(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
    child: T(text, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13), fontWeight: FontWeight.w700, color: fg)));

  Widget _partTab(String p, String label, {required bool on}) => InkWell(
    onTap: () { final app=context.read<AppState>();app.session['spReviewPart']=p;app.go(SurgoPage.speakingReview); }, borderRadius: BorderRadius.circular(20),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: on ? SurgoColors.yellow : Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? SurgoColors.yellow : SurgoColors.line)),
      // Fixed English Part label — question content, rendered as raw Text.
      child: SourceText(label, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(14), fontWeight: FontWeight.w700, color: on ? const Color(0xFF3A2E00) : const Color(0xFFB7B0A3)))));

  Widget _questionCard(Map<String, dynamic> it, int i, bool en, List<List> cuePoints) {
    // Part 3 cards are discussion Rounds; other Parts keep their Part label.
    final qLabel = spReviewPart == 'p3'
        ? (en ? 'Round ${i + 1}' : '第 ${i + 1} 轮对话')
        : (spReviewPart == 'p1' ? 'Part 1' : (spReviewPart == 'p2' ? 'Part 2' : 'Part 3'));
    return _srCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 24, height: 24, alignment: Alignment.center,
          decoration: const BoxDecoration(color: SurgoColors.yellow, shape: BoxShape.circle),
          child: SourceText(spReviewPart == 'p2' ? '2' : '${i + 1}', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13), fontWeight: FontWeight.w800, color: const Color(0xFF3A2E00)))),
        const SizedBox(width: 9),
        // Round / Part label is UI chrome (already localised above) — raw Text of the resolved string.
        Expanded(child: SourceText(qLabel, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(15), fontWeight: FontWeight.w700, color: SurgoColors.ink))),
        // 真实数据没有逐题分数和逐题点评（后端只给整场评分），这两处不画；逐题只留转写和挂在这题上的语法问题。
        if (it['band'] != null) Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E0), borderRadius: BorderRadius.circular(9)),
          child: SourceText(it['band'] as String, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w700, color: const Color(0xFF4F8A1F)))),
      ]),
      const SizedBox(height: 12),
      _examinerBlock(it),
      _answerBlock(it, cuePoints),
      if (it['en'] != null) ...[
        SourceText(it['en'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.55, color: const Color(0xFF4A453D))),
        const SizedBox(height: 4),
        SourceText(it['zh'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.55, color: const Color(0xFFA99A82))),
      ],
      const SizedBox(height: 12),
      for (final t in (it['tags'] as List)) _tagRow((t as List).cast()),
    ]));
  }

  // Examiner block: Part 3 writes the question text under "考官"; other Parts
  // show an avatar + audio waveform (plus the question text when the data has it).
  Widget _examinerBlock(Map<String, dynamic> it) {
    if (spReviewPart == 'p3') {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T('考官', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w800, color: const Color(0xFF3A352C))),
        const SizedBox(height: 5),
        // The raw English question text (题目内容), never translated.
        SourceText(it['q'] as String, style: TextStyle(fontSize: SurgoText.css(14), height: 1.6, color: const Color(0xFF4A453D))),
      ]));
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 38, height: 38, decoration: const BoxDecoration(color: SurgoColors.yellow, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T('考官', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w800, color: const Color(0xFF3A352C))),
        const SizedBox(height: 5),
        _audioBar(const Color(0xFFFDF6E3), SurgoColors.yellow, const Color(0xFF3A2E00), const Color(0xFFE6B93A), 26, 22, 30, playLabel: '▶'),
        // 真实数据每张卡都带考官问的原话（Part 2 是题卡加追问，一句一行），写在音频条下面，
        // 字体同 Part 3 那行；原型的 Part 1 / 2 没有 q，仍只有音频条。
        if (it['q'] != null) ...[
          const SizedBox(height: 7),
          SourceText(it['q'] as String, style: TextStyle(fontSize: SurgoText.css(14), height: 1.6, color: const Color(0xFF4A453D))),
        ],
      ])),
    ]));
  }

  // Answer block: Part 2 shows cue-card coverage + long-turn recording;
  // other Parts show the transcript text.
  Widget _answerBlock(Map<String, dynamic> it, List<List> cuePoints) {
    if (spReviewPart == 'p2') return _p2Body(it, cuePoints);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: const Color(0xFFEEF7E9), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // 字号放大后这一行在 390px 下放不开，标题可收缩避免溢出。
            Flexible(child: T(spReviewPart == 'p3' ? '你的作答' : '你的作答（转录）', maxLines: 1, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w700, color: const Color(0xFF4F8A1F)))),
            const SizedBox(width: 8),
            SourceText(it['dur'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w600, color: const Color(0xFF7B6F5C))),
          ]),
          const SizedBox(height: 6),
          SourceText(it['ans'] as String, style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.6, color: const Color(0xFF3A352C))),
        ])),
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 8, runSpacing: 8, children: [
        _op('▶ 播放考官'), _op('▶ 播放你的作答'), _op('↻ 连续回放对话'),
      ])),
    ]);
  }

  Widget _p2Body(Map<String, dynamic> it, List<List> cuePoints) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    // Cue-card coverage.
    if (cuePoints.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(color: const Color(0xFFF4F2FD), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T('▤ 话题卡要点覆盖', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w800, color: const Color(0xFF6B5FC7))),
        const SizedBox(height: 9),
        for (final p in cuePoints) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          SourceText('✓', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13), fontWeight: FontWeight.w900, color: const Color(0xFF4F9E3A))),
          const SizedBox(width: 7),
          Flexible(child: SourceText.rich(TextSpan(children: [
            TextSpan(text: p[0] as String, style: const TextStyle(color: Color(0xFF3A352C))),
            const TextSpan(text: '  ·  ', style: TextStyle(color: Color(0xFFB5AD9E))),
            TextSpan(text: p[1] as String, style: const TextStyle(color: SurgoColors.muted)),
          ], style: TextStyle(fontSize: SurgoText.css(13.5))))),
        ])),
      ])),
    // Long-turn recording.
    Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(color: const Color(0xFFEEF7EC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCFE6C8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          T('🎙 你的长陈述录音', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w800, color: const Color(0xFF2F7A2A))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDCEFD7), borderRadius: BorderRadius.circular(8)),
            child: T('长录音 · 独白', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(12.5), fontWeight: FontWeight.w700, color: const Color(0xFF4F9E3A)))),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          Container(width: 38, height: 38, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFF3F8F34), shape: BoxShape.circle),
            child: const SourceText('▶', style: TextStyle(fontSize: 13.5, color: Colors.white))),
          const SizedBox(width: 11),
          Expanded(child: _wave(40, 26, const Color(0xFF8FCE7F))),
        ]),
        const SizedBox(height: 7),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SourceText('00:00', style: TextStyle(fontSize: SurgoText.css(13), color: const Color(0xFF6A8A62))),
          SourceText(it['dur'] as String, style: TextStyle(fontSize: SurgoText.css(13), color: const Color(0xFF6A8A62))),
        ]),
      ])),
    // Transcript.
    Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(color: const Color(0xFFEEF7EC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCFE6C8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          T('🎙 你的作答（转录）', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13.5), fontWeight: FontWeight.w800, color: const Color(0xFF2F7A2A))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDCEFD7), borderRadius: BorderRadius.circular(8)),
            child: T('长录音 · 独白', style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(12.5), fontWeight: FontWeight.w700, color: const Color(0xFF4F9E3A)))),
          SourceText(it['dur'] as String, style: TextStyle(fontSize: SurgoText.css(13), color: const Color(0xFF6A8A62))),
        ]),
        const SizedBox(height: 9),
        SourceText(it['ans'] as String, style: TextStyle(fontSize: SurgoText.css(13), height: 1.75, color: const Color(0xFF3A352C))),
      ])),
    Padding(padding: const EdgeInsets.only(bottom: 12), child: Wrap(spacing: 8, runSpacing: 8, children: [
      _op('▶ 播放话题卡'), _op('🎙 播放你的长陈述'),
    ])),
  ]);

  Widget _tagRow(List t) {
    final warn = t[3] == 'warn';
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: warn ? const Color(0xFFFBEED6) : const Color(0xFFE8F5E0), borderRadius: BorderRadius.circular(8)),
        // Criterion chip label is a fixed criterion name (content) — raw Text.
        // 字号放大后胶囊会撑宽，限制最大宽度并允许缩放避免 390px 溢出。
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: SourceText(t[0] as String, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13), fontWeight: FontWeight.w700, color: warn ? const Color(0xFFC07A1F) : const Color(0xFF4F8A1F)))))),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SourceText('${warn ? '↗' : '✓'} ${t[1]}', style: TextStyle(fontSize: SurgoText.css(13.5), height: 1.55, color: const Color(0xFF3A352C))),
        const SizedBox(height: 3),
        SourceText(t[2] as String, style: TextStyle(fontSize: SurgoText.css(13), height: 1.55, color: const Color(0xFF7B6F5C))),
      ])),
    ]));
  }

  Widget _op(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SurgoColors.yellowTint)),
    child: T(label, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: SurgoText.css(13), fontWeight: FontWeight.w700, color: const Color(0xFFA08A4A))));

  Widget _audioBar(Color bg, Color playBg, Color playFg, Color waveColor, int bars, double height, double playSize, {required String playLabel}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: SurgoColors.yellowTint)),
    child: Row(children: [
      Container(width: playSize, height: playSize, alignment: Alignment.center,
        decoration: BoxDecoration(color: playBg, shape: BoxShape.circle),
        child: SourceText(playLabel, style: TextStyle(fontSize: 13, color: playFg))),
      const SizedBox(width: 11),
      Expanded(child: _wave(bars, height, waveColor)),
    ]));

  // Decorative waveform — heights vary per bar as in the source nth-child rules.
  Widget _wave(int bars, double height, Color color) => SizedBox(height: height, child: Row(children: [
    for (var i = 0; i < bars; i++) ...[
      Expanded(child: FractionallySizedBox(heightFactor: _waveFactor(i), child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))))),
      if (i < bars - 1) const SizedBox(width: 2),
    ],
  ]));

  double _waveFactor(int i) {
    // Approximates .sr-wave i:nth-child(odd){88%} / nth-child(3n){35%} else 55%.
    if ((i + 1) % 3 == 0) return 0.35;
    if ((i + 1) % 2 == 1) return 0.88;
    return 0.55;
  }

  /// 薄弱项的引文与建议：源 `SP_REVIEW.weaks` 只有英文，导出的 DOM 译表也只译了
  /// 三个标题，所以中文模式下正文会露英文。用户 2026-09-24 要求「中文模式都是
  /// 中文」，这里按标题补中文译文；英文模式仍用源串。
  static const _weakZh = <String, List<String>>{
    'Limited lexical variety': [
      '「我喜欢流行、我喜欢摇滚、我也喜欢爵士」',
      '换用更多样的动词和程度词，别反复说 "I like"：可以用 "I\'m really into..."、"I\'m a big fan of..."。',
    ],
    'Hesitation before complex ideas': [
      '「because... 呃... because it makes me relax」',
      '练熟衔接短语，让你能顺畅地引出理由，不必用填充停顿拖时间。',
    ],
    'Filler words reduce coherence': [
      '「you know，这是一种很好的放松」',
      '把 "you know"、"em" 这类填充语换成真正的连接词，例如 "on top of that"、"in other words"。',
    ],
  };

  /// 取某条薄弱项在当前语言下的引文。
  static String _weakQuote(Map<String, dynamic> w, bool en) =>
      en ? w['quote'] as String : (_weakZh[w['en']]?[0] ?? w['quote'] as String);

  /// 取某条薄弱项在当前语言下的建议。真实数据（能力分析的弱项）本身就是 [英文, 中文]。
  static String _weakTip(Map<String, dynamic> w, bool en) {
    final tip = w['tip'];
    if (tip is List) return '${tip[en ? 0 : 1]}';
    return en ? tip as String : (_weakZh[w['en']]?[1] ?? tip as String);
  }

  /// 原型的串照旧走 SourceText；真实数据的 [英文, 中文] 一对交给 T 按界面语言取。
  static Widget _text(Object v, TextStyle style) =>
      v is List ? T(v, style: style) : SourceText(v as String, style: style);
}
