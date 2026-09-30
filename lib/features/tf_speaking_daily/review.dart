import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/demo_audio.dart';
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
    // 原型是一条薄弱项（Map）；演示用真实数据（tool/demo_export）是一个列表，
    // 这次没分析出薄弱项就是空列表，整块不画。文案可以是 [英文, 中文] 一对，T 按界面语言取。
    final weak = fb['weak'] is List ? fb['weak'] as List : [fb['weak']];
    final subs = fb['subs'] as List;
    final questions = fb['questions'] as List;
    final task = kind; // retell | interview
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(title: '练习回顾'),
      SurgoCard(color: const Color(0xFFFBE7A8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('总体 · 练习估分', style: SurgoText.cardDesc), const SizedBox(height: 8),
        SourceText('${fb['score']} / 6.0', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 36, fontWeight: FontWeight.w900)),
        // 后端没有整场的一句话总评，真实数据这一行不画。
        if (fb['description'] != null) T(fb['description'], style: SurgoText.cardDesc),
        const SizedBox(height: 7),
        const T('练习估分仅供参考，不代表官方托福分数。', style: SurgoText.cardDesc),
      ])),
      if (weak.isNotEmpty) SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const T('薄弱项分析', style: SurgoText.cardTitle), const SizedBox(height: 10),
        const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。', style: SurgoText.cardDesc), const SizedBox(height: 12),
        for (final w in weak) SurgoCard(color: SurgoColors.bg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, children: [for (final tag in w['tags'] as List) T(tag, style: SurgoText.cardEn)]),
          const SizedBox(height: 8), T(w['q'], style: SurgoText.rowLabel),
          const SizedBox(height: 8), T(w['a'], style: SurgoText.cardDesc),
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
            T(_gap((sc as List)[0]), style: SurgoText.cardDesc),
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

  /// 子分名称后面留两个空格；名称是 [英文, 中文] 一对时两项都留。
  static Object _gap(Object name) =>
      name is List ? [for (final s in name) '$s  '] : '$name  ';

  Widget _qCard(Map<String, dynamic> q) {
    final ok = q['ok'] == true;
    final pct = q['pct'] as int?; // 仅听后复述有
    // 演示用真实数据：口语没有对错，每题带的是这一题的分（score）和两段录音各自的时长；
    // 反馈是 [英文, 中文] 一对。原型数据没有这些键，走原来的写法。
    final score = q['score'] as String?;
    final dur = q['dur'] as String? ?? '00:03 / 00:10';
    final fb = q['fb'];
    return SurgoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: T('第 ${q['n']}', style: SurgoText.rowLabel)),
        if (score != null)
          SourceText('$score / 6', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13.5, fontWeight: FontWeight.w800))
        else
          T(ok ? '表现良好' : '错误', style: TextStyle(color: ok ? Colors.green : SurgoColors.overrun, fontSize: 13.5)),
      ]),
      const SizedBox(height: 10),
      const T('考官提问', style: SurgoText.cardDesc),
      SourceText(q['q'] as String, style: SurgoText.rowLabel),
      // 考官 / 你的作答 两条模拟音频波形（源 tfRtFbAudio，原型里是静态展示，无真实播放）
      const SizedBox(height: 10),
      _audio('考官', dur, q['audio'] as Map?),
      const SizedBox(height: 6),
      _audio('你的作答', q['myDur'] as String? ?? dur, q['myAudio'] as Map?),
      if (pct != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(width: 48, height: 48, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: pct / 100, color: SurgoColors.yellow, backgroundColor: SurgoColors.track, strokeWidth: 5),
            SourceText('$pct%', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w800)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: T(fb is List ? '复述完整度' : '复述完整度 · $fb', style: SurgoText.cardDesc)),
        ]),
      ],
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: SurgoColors.bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('反馈', style: SurgoText.rowLabel), const SizedBox(height: 4),
          if (fb is List)
            T(fb, style: const TextStyle(fontSize: 13, height: 1.5))
          else
            SourceText(fb as String, style: const TextStyle(fontSize: 13, height: 1.5)),
        ])),
    ]));
  }

  /// 演示用真实数据每题带着这两段音频（audio / myAudio：{ asset, sec }，tool/demo_export 导出）：考官那一行是
  /// 题目的原音频，你的作答那一行是学员这一题判分用的那段录音。在网页上点这一行真的放它，再点暂停；全站同一
  /// 时间只放一段，所以只有播放器里正是这一段时才显示暂停键和进度。原型数据没有这两项、或不在网页上，
  /// 就是原来的静态展示。
  Widget _audio(String who, String dur, Map? clip) {
    if (clip == null || !demoAudio.available) return _audioRow(who, dur, false);
    final asset = clip['asset'] as String;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => demoAudio.toggle(asset, seconds: (clip['sec'] as num).toDouble()),
      child: ListenableBuilder(listenable: demoAudio, builder: (_, __) {
        // 放完回到原样：时长那一栏本来就是「00:00 / 总长」。
        final on = demoAudio.asset == asset && !demoAudio.ended;
        final at = demoAudio.position.floor();
        return _audioRow(who, on ? '${(at ~/ 60).toString().padLeft(2, '0')}:${(at % 60).toString().padLeft(2, '0')} / ${dur.split(' / ').last}' : dur, on && demoAudio.playing);
      }),
    );
  }

  Widget _audioRow(String who, String dur, bool playing) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: SurgoColors.bg, borderRadius: BorderRadius.circular(12)),
    child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Icon(playing ? Icons.pause : Icons.play_arrow, size: 18),
      const SizedBox(width: 6),
      SourceText(who, style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      SourceText(dur, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      const SourceText('↻15  ↻15  1.0x', style: TextStyle(fontSize: 12)),
    ]),
  );
}
