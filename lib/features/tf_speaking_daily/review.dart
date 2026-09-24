import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';

/// TOEFL 口语日常训练 批改反馈页（tfRetellFb / tfInterviewFb）。
///
/// 全部反馈都是源 app.js 里写死的固定文案（TFRTFB_QS / TFIVFB_QS + 总分/薄弱项），
/// 不调用也不臆造任何 AI 评分。听后复述题卡带完整度环(pct)，接受访谈没有。
class TfSpeakingReview extends StatelessWidget {
  const TfSpeakingReview({super.key, required this.kind, required this.data});
  final String kind; // retell | interview
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fb = (data['feedback'] as Map).cast<String, dynamic>();
    final weak = (fb['weak'] as Map).cast<String, dynamic>();
    final subs = fb['subs'] as List;
    final questions = fb['questions'] as List;
    final task = kind; // retell | interview
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(title: '练习回顾'),
      SurgoCard(color: const Color(0xFFFBE7A8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('总体 · 练习估分', style: SurgoText.cardDesc), const SizedBox(height: 8),
        SourceText('${fb['score']} / 6.0', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 36, fontWeight: FontWeight.w900)),
        T(fb['description'] as String, style: SurgoText.cardDesc), const SizedBox(height: 7),
        const T('练习估分仅供参考，不代表官方托福分数。', style: SurgoText.cardDesc),
      ])),
      SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('薄弱项分析', style: SurgoText.cardTitle), const SizedBox(height: 10),
        const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。', style: SurgoText.cardDesc), const SizedBox(height: 12),
        SurgoCard(color: SurgoColors.bg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, children: [for (final tag in weak['tags'] as List) T(tag as String, style: SurgoText.cardEn)]),
          const SizedBox(height: 8), T(weak['q'] as String, style: SurgoText.rowLabel),
          const SizedBox(height: 8), T(weak['a'] as String, style: SurgoText.cardDesc),
        ])),
        const SizedBox(height: 12),
        const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。', style: SurgoText.cardDesc),
        const SizedBox(height: 12),
        SurgoButton('练习你最弱的题型 →', onTap: () {
          state.examType = ExamType.toefl;
          state.session['tfSpTask'] = task;
          state.go(SurgoPage.speakingDaily);
        }),
      ])),
      // Delivery / Language Use / Topic Development 子分（源 twfb-subs）
      SurgoCard(child: Wrap(spacing: 10, runSpacing: 8, children: [
        for (final sc in subs)
          Row(mainAxisSize: MainAxisSize.min, children: [
            T('${(sc as List)[0]}  ', style: SurgoText.cardDesc),
            SourceText(sc[1] as String, style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.w800,
                color: sc[2] == 'ok' ? Colors.green : sc[2] == 'bad' ? SurgoColors.overrun : SurgoColors.ink)),
          ]),
      ])),
      SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('逐题分析', style: SurgoText.cardTitle), const SizedBox(height: 12),
        for (final q in questions) _qCard((q as Map).cast<String, dynamic>()),
      ])),
      SurgoButton('⌂ 回到首页', onTap: () => state.go(SurgoPage.ielts)),
    ]);
  }

  Widget _qCard(Map<String, dynamic> q) {
    final ok = q['ok'] as bool;
    final pct = q['pct'] as int?; // 仅听后复述有
    return SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: T('第 ${q['n']}', style: SurgoText.rowLabel)),
        T(ok ? '表现良好' : '错误', style: TextStyle(color: ok ? Colors.green : SurgoColors.overrun, fontSize: 13.5)),
      ]),
      const SizedBox(height: 10),
      const T('考官提问', style: SurgoText.cardDesc),
      SourceText(q['q'] as String, style: SurgoText.rowLabel),
      // 考官 / 你的作答 两条模拟音频波形（源 tfRtFbAudio，静态展示，无真实播放）
      const SizedBox(height: 10),
      _audio('考官'),
      const SizedBox(height: 6),
      _audio('你的作答'),
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

  Widget _audio(String who) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: SurgoColors.bg, borderRadius: BorderRadius.circular(12)),
    child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      const Icon(Icons.play_arrow, size: 18),
      const SizedBox(width: 6),
      SourceText(who, style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      const SourceText('00:03 / 00:10', style: TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      const SourceText('↻15  ↻15  1.0x', style: TextStyle(fontSize: 12)),
    ]),
  );
}
