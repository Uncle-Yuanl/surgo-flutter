import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';

/// TOEFL 口语「模考」批改反馈页（tfSpeakFb）。
///
/// 全部反馈都是源 app.js 里静态写死的固定文案（TFSF_TYPES / TFSF_SUB / TFSF_QS + 总分/薄弱项），
/// 不调用也不臆造任何 AI 评分。类型切换(r/i)本地进行；listen&repeat 题卡带完整度环(pct)，访谈没有。
class TfSpeakFbReview extends StatefulWidget {
  const TfSpeakFbReview({super.key, required this.fb});
  final Map<String, dynamic> fb;
  @override
  State<TfSpeakFbReview> createState() => _TfSpeakFbReviewState();
}

class _TfSpeakFbReviewState extends State<TfSpeakFbReview> {
  String type = 'r'; // 源 tfSfType 默认 'r'

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fb = widget.fb;
    final types = (fb['types'] as List).cast<Map<String, dynamic>>();
    final subs = (fb['subs'] as List).cast<Map<String, dynamic>>();
    final weak = (fb['weak'] as List).cast<Map<String, dynamic>>();
    final questions = ((fb['questions'] as Map)[type] as List).cast<Map<String, dynamic>>();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(title: '练习回顾'),
      // 总分卡（源 tffb-score）
      SurgoCard(color: SurgoColors.yellowSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('总体 · 练习估分', style: SurgoText.cardDesc), const SizedBox(height: 8),
        SourceText('${fb['score']} / 6.0', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 36, fontWeight: FontWeight.w900)),
        T(fb['description'] as String, style: SurgoText.cardDesc), const SizedBox(height: 7),
        T(fb['footnote'] as String, style: SurgoText.cardDesc),
      ])),
      // 各题型得分条（源 tffb-bar-row）
      SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('各题型得分', style: SurgoText.cardTitle), const SizedBox(height: 12),
        for (final t in types) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          SizedBox(width: 120, child: T(t['name'] as String, style: SurgoText.cardEn)),
          Expanded(child: LinearProgressIndicator(
            value: ((t['score'] as num) / 6).clamp(0, 1), color: SurgoColors.yellow, backgroundColor: SurgoColors.track)),
          const SizedBox(width: 10),
          SourceText('${(t['score'] as num).toStringAsFixed(1)}/6', style: SurgoText.rowLabel),
        ])),
      ])),
      // 薄弱项分析（源 tffb-weak，两段静态）
      SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('薄弱项分析', style: SurgoText.cardTitle), const SizedBox(height: 10),
        const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。', style: SurgoText.cardDesc), const SizedBox(height: 12),
        for (final w in weak) Padding(padding: const EdgeInsets.only(bottom: 12), child:
          SurgoCard(color: SurgoColors.bg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [for (final tag in w['tags'] as List) T(tag as String, style: SurgoText.cardEn)]),
            const SizedBox(height: 8), T(w['q'] as String, style: SurgoText.rowLabel),
            const SizedBox(height: 8), T(w['a'] as String, style: SurgoText.cardDesc),
          ]))),
        const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。', style: SurgoText.cardDesc),
        const SizedBox(height: 12),
        SurgoButton('练习你最弱的题型 →', onTap: () {
          state.examType = ExamType.toefl;
          state.go(SurgoPage.speakingDaily);
        }),
      ])),
      // 类型切换 chips（源 tffb-chips）
      SurgoCard(child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in types)
          ChoiceChip(label: SourceText(t['name'] as String), selected: type == t['key'],
            onSelected: (_) => setState(() => type = t['key'] as String)),
      ])),
      // Delivery / Language Use / Topic Development 子分（源 tsf-subs）
      SurgoCard(child: Wrap(spacing: 12, runSpacing: 8, children: [
        for (final sc in subs)
          Row(mainAxisSize: MainAxisSize.min, children: [
            T('${sc['n']}  ', style: SurgoText.cardDesc),
            SourceText(sc['v'] as String, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.w800,
                color: sc['c'] == 'ok' ? SurgoColors.ok : sc['c'] == 'bad' ? SurgoColors.overrun : SurgoColors.ink)),
          ]),
      ])),
      // 逐题分析（源 tffb-qcard，按当前 type 切换）
      SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('逐题分析', style: SurgoText.cardTitle), const SizedBox(height: 12),
        for (final q in questions) _qCard(q),
      ])),
      SurgoButton('⌂ 回到首页', onTap: () => state.go(SurgoPage.ielts)),
    ]);
  }

  Widget _qCard(Map<String, dynamic> q) {
    final ok = q['ok'] as bool;
    final pct = q['pct'] as int?; // 仅 Listen & Repeat 有
    return SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: T('第 ${q['n']}', style: SurgoText.rowLabel)),
        T(ok ? '表现良好' : '错误', style: TextStyle(color: ok ? SurgoColors.ok : SurgoColors.overrun, fontSize: 13.5)),
      ]),
      const SizedBox(height: 10),
      const T('考官提问', style: SurgoText.cardDesc),
      SourceText(q['ask'] as String, style: SurgoText.rowLabel),
      // 考官 / 你的作答 两条模拟音频波形（源 tsf-row，静态展示，无真实播放）
      const SizedBox(height: 10),
      _audio('考官', q['dur'] as String),
      const SizedBox(height: 6),
      _audio('你的作答', q['dur'] as String),
      if (pct != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(width: 48, height: 48, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: pct / 100, color: SurgoColors.yellow, backgroundColor: SurgoColors.track, strokeWidth: 5),
            SourceText('$pct%', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w800)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: T('复述完整度 · ${q['fb']}', style: SurgoText.cardDesc)),
        ]),
      ],
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: SurgoColors.bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('反馈', style: SurgoText.rowLabel), const SizedBox(height: 4),
          SourceText(q['fb'] as String, style: const TextStyle(fontSize: 13, height: 1.5)),
        ])),
    ]));
  }

  Widget _audio(String who, String dur) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: SurgoColors.bg, borderRadius: BorderRadius.circular(12)),
    child: Wrap(spacing:6,runSpacing:6,crossAxisAlignment:WrapCrossAlignment.center,children: [
      const Icon(Icons.play_arrow, size: 18),
      const SizedBox(width: 6),
      SourceText(who, style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      SourceText(dur, style: const TextStyle(fontSize: 12)),
      const SizedBox(width:4),
      const SourceText('↺15  ↻15  1.0x', style: TextStyle(fontSize: 12)),
    ]),
  );
}
