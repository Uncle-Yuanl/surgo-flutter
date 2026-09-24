import '../../widgets/source_text.dart';
import '../../widgets/pill_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'data.dart';

/// TOEFL listening MOCK feedback / review page — a faithful Flutter port of the
/// source `tfListenFbView` (app.js 9117-9194) plus its `tfFbPickMod`,
/// `tfFbPickType` and `tfFbTranscript` helpers (9047-9115).
///
/// Everything shown here is FIXED native content exported to
/// `assets/data/tf_listening_mock.json` (feedback.typesM1 / typesM2 / qs /
/// transcript). The two module tabs (`m1` 定级 / `m2` Upper) swap the whole
/// type list; the type chips pick which question set + transcript is shown.
/// Nothing is graded at runtime — the hero score (4.5/6) and per-type scores
/// are the source's fixed demo values.
class TfListenFeedbackPage extends StatefulWidget {
  const TfListenFeedbackPage({super.key});
  @override
  State<TfListenFeedbackPage> createState() => _TfListenFeedbackPageState();
}

class _TfListenFeedbackPageState extends State<TfListenFeedbackPage> {
  Map<String, dynamic>? _fb;
  // Source module/state globals: `let tfFbMod='m1', tfFbType='r';`
  String _mod = 'm1';
  String _type = 'r';

  @override
  void initState() {
    super.initState();
    TfListeningMockData.load().then((raw) {
      if (!mounted) return;
      setState(() => _fb = raw['feedback'] as Map<String, dynamic>);
    });
  }

  /// Source `tfFbTypes()` — the per-module type list.
  List _types() =>
      (_mod == 'm2' ? _fb!['typesM2'] : _fb!['typesM1']) as List;

  /// Source `tfFbPickMod(m)` — swap module tab, keep type if still present
  /// otherwise fall back to the first key of the new list.
  void _pickMod(String m) {
    setState(() {
      _mod = m;
      final ks = _types().map((t) => t['key'] as String).toList();
      if (!ks.contains(_type)) _type = ks.first;
    });
  }

  /// Source `tfFbPickType(t)`.
  void _pickType(String t) => setState(() => _type = t);

  @override
  Widget build(BuildContext context) {
    final fb = _fb;
    if (fb == null) return const Center(child: CircularProgressIndicator());
    final state = context.read<AppState>();
    final isM1 = _mod == 'm1';
    final types = _types();
    final qs = ((fb['qs'] as Map)[_type] as List?) ?? const [];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ra-nav: home icon + 练习回顾 tab.
      SurgoTopBar(title: '练习回顾', onBack: () => state.go(SurgoPage.ielts)),

      // tffb-hero
      SurgoCard(
        color: SurgoColors.dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const T('最终成绩',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    color: SurgoColors.yellowSoft,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: SurgoColors.yellow,
                  borderRadius: SurgoRadius.pillAll),
              child: const SourceText('Upper',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      color: SurgoColors.onYellowStrong,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: const [
            SourceText('4.5',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900)),
            SourceText(' /6',
                style: TextStyle(color: SurgoColors.grip, fontSize: 16)),
            SizedBox(width: 8),
            SourceText('(4.0-5.0)',
                style: TextStyle(color: SurgoColors.arrow, fontSize: 13.5)),
          ]),
          const SizedBox(height: 8),
          const T('最终听力分基于你的 Upper 卷表现。对话是明显强项；学术讲座的推断需加强。',
              style: TextStyle(
                  color: Colors.white, fontSize: 13.5, height: 1.55)),
          const SizedBox(height: 6),
          const T('SURGO 练习估分。最终分基于你的正式模块（模块2）表现；模块1用于定级。',
              style: TextStyle(color: SurgoColors.grip, fontSize: 13, height: 1.5)),
        ]),
      ),

      // tffb-modtabs
      Row(children: [
        _ModTab(label: '模块1 · 定级', on: isM1, onTap: () => _pickMod('m1')),
        const SizedBox(width: 8),
        _ModTab(label: '模块2 · Upper', on: !isM1, onTap: () => _pickMod('m2')),
      ]),
      const SizedBox(height: 16),

      // tffb-score
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('总体 · 练习估分', style: SurgoText.cardDesc),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: const [
            SourceText('4.5',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 36, fontWeight: FontWeight.w900)),
            SourceText(' / 6.0', style: SurgoText.cardDesc),
          ]),
          const SizedBox(height: 6),
          T(
              isM1
                  ? '定级表现良好——你已进入 Upper（高阶）卷。'
                  : 'Upper 卷表现稳定，最终分基于本模块。',
              style: SurgoText.cardDesc),
          const SizedBox(height: 6),
          const T('练习估分仅供参考，不代表官方托福分数。', style: SurgoText.cardDesc),
        ]),
      ),

      // tffb-card 各题型得分 (typeBars)
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const T('各题型得分', style: SurgoText.cardTitle),
          const SizedBox(height: 12),
          for (final t in types) _BarRow(name: t['name'] as String, score: (t['score'] as num).toDouble()),
        ]),
      ),

      // tffb-card 薄弱项分析 (fixed weak analysis)
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const T('薄弱项分析', style: SurgoText.cardTitle),
          const SizedBox(height: 8),
          const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。', style: SurgoText.cardDesc),
          const SizedBox(height: 12),
          SurgoCard(
            color: SurgoColors.bg,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, children: const [
                T('听力', style: SurgoText.cardEn),
                T('目的意图', style: SurgoText.cardEn),
                T('对话开头', style: SurgoText.cardEn),
              ]),
              const SizedBox(height: 8),
              const T('听对话第 1 题：错把附带请求当成主要目的。', style: SurgoText.rowLabel),
              const SizedBox(height: 8),
              const T('对话目的的题重点听开头 2-3 句。建议练习“开头意图捕捉”。', style: SurgoText.cardDesc),
            ]),
          ),
          const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。',
              style: SurgoText.cardDesc),
          const SizedBox(height: 12),
          SurgoButton('练习你最弱的题型 →', onTap: () {
            state.examType = ExamType.toefl;
            state.go(SurgoPage.listeningDaily);
          }),
        ]),
      ),

      // tffb-chips (type chips)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in types)
            _Chip(
                label: t['name'] as String,
                on: _type == t['key'],
                onTap: () => _pickType(t['key'] as String)),
        ]),
      ),

      // Transcript card (only for non-'r' types) — source `tfFbTranscript()`.
      if (_type != 'r') _transcript(fb, qs),

      // tffb-card 逐题分析 (qcards)
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const T('逐题分析', style: SurgoText.cardTitle),
          const SizedBox(height: 12),
          for (final q in qs) _QCard(q: q as Map),
        ]),
      ),

      SurgoButton('⌂ 回到首页', onTap: () => state.go(SurgoPage.ielts)),
    ]);
  }

  /// Source `tfFbTranscript()` — highlights the transcript spans that the
  /// current type's questions hit, colouring by that question's ok flag.
  Widget _transcript(Map<String, dynamic> fb, List qs) {
    final rows = (fb['transcript'] as List);
    bool okOf(int n) {
      final i = n - 1;
      if (i < 0 || i >= qs.length) return true;
      return (qs[i] as Map)['ok'] == true;
    }

    return SurgoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SourceText('Transcript', style: SurgoText.cardTitle),
        const SizedBox(height: 12),
        SourceText.rich(
          TextSpan(children: [
            for (final r in rows) ...[
              TextSpan(text: r[0] as String),
              if ((r as List).length > 1 && r[1] != null && r[1] != '') ...[
                TextSpan(
                    text: r[1] as String,
                    style: TextStyle(
                        backgroundColor: okOf(r[2] as int)
                            ? const Color(0xFFE7F6EA)
                            : const Color(0xFFFDEAEA))),
                TextSpan(
                    text: ' ${r[2]} ',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontWeight: FontWeight.w800,
                        color: okOf(r[2] as int)
                            ? SurgoColors.ok
                            : SurgoColors.overrun)),
                TextSpan(text: r[3] as String),
              ],
            ],
          ]),
          style: const TextStyle(fontSize: 14, height: 1.8),
        ),
      ]),
    );
  }
}

// tffb-modtab
// 用户 2026-09-25：托福所有 tab 统一成雅思阅读模考篇章 tab 的胶囊样式
// （选中：淡黄底 + 黄色描边；未选中：无底灰字），取代原来的黑底/白底方案。
class _ModTab extends StatelessWidget {
  const _ModTab({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
      child: SurgoPillTab(
          label: label, selected: on, onTap: onTap, fontSize: 13, maxLines: 1));
}

// tffb-bar-row
class _BarRow extends StatelessWidget {
  const _BarRow({required this.name, required this.score});
  final String name;
  final double score;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          SizedBox(
              width: 150,
              child: SourceText(name, style: const TextStyle(fontSize: 13.5))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LinearProgressIndicator(
                  value: (score / 6).clamp(0, 1),
                  color: SurgoColors.yellow,
                  backgroundColor: SurgoColors.track),
            ),
          ),
          SourceText('${score.toStringAsFixed(1)}/6',
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

// tffb-chip
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: on ? SurgoColors.yellow : Colors.white,
        borderRadius: SurgoRadius.chipAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: SurgoRadius.chipAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                borderRadius: SurgoRadius.chipAll,
                border: on ? null : Border.all(color: SurgoColors.line)),
            child: SourceText(label,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: on ? SurgoColors.onYellowStrong : SurgoColors.ink)),
          ),
        ),
      );
}

// tffb-qcard
class _QCard extends StatelessWidget {
  const _QCard({required this.q});
  final Map q;
  @override
  Widget build(BuildContext context) {
    final ok = q['ok'] == true;
    return SurgoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: T('第 ${q['n']}', style: SurgoText.rowLabel)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: ok ? const Color(0xFFE7F6EA) : const Color(0xFFFDEAEA),
                borderRadius: SurgoRadius.chipAll),
            child: T(ok ? '表现良好' : '错误',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    color: ok ? SurgoColors.ok : SurgoColors.overrun,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        const T('题目', style: SurgoText.cardDesc),
        SourceText(q['q'] as String, style: SurgoText.rowLabel),
        // tffb-audio row (progress simulation — no real audio).
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: SurgoColors.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.play_arrow, size: 18),
              const SizedBox(width: 6),
              Expanded(
                  child: SourceText('00:00 / ${q['dur']}',
                      style: const TextStyle(fontSize: 12))),
              const SourceText('↺ 15   ↻ 15   1.0x', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            const LinearProgressIndicator(
                value: 0,
                color: SurgoColors.yellow,
                backgroundColor: SurgoColors.track),
          ]),
        ),
        const T('你的作答', style: SurgoText.cardDesc),
        SourceText(q['mine'] as String,
            style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ok ? SurgoColors.ok : SurgoColors.overrun)),
        if (q['ans'] != null) ...[
          const SizedBox(height: 6),
          const T('正确答案', style: SurgoText.cardDesc),
          SourceText(q['ans'] as String,
              style: const TextStyle(fontSize: 14, color: SurgoColors.ok)),
        ],
        if (q['why'] != null) ...[
          const SizedBox(height: 12),
          const T('解析', style: SurgoText.rowLabel),
          SourceText(q['why'] as String, style: const TextStyle(fontSize: 13, height: 1.5)),
          const SizedBox(height: 6),
          const T('原文依据：', style: SurgoText.cardDesc),
          SourceText(q['evi'] as String, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ]),
    );
  }
}
