import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import 'review_style.dart';
import '../../theme/tokens.dart';

class RfSummary extends StatelessWidget {
  const RfSummary(
      {super.key,
      required this.right,
      required this.total,
      required this.mock,
      this.english,
      this.chinese,
      this.band = '6.5',
      this.text});
  final int right, total;
  final bool mock;
  final String? english, chinese;

  /// 演示用真实数据（tool/demo_export）：估分没有就不画；[text] 是字符串或
  /// `[英文, 中文]`，给了就代替下面两句原型文案，空串表示这次作答没有总评。
  final String? band;
  final Object? text;
  @override
  Widget build(BuildContext context) => Container(
      key: const ValueKey('rf-summary'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
          color: const Color(0xfffbe6ad),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const RfText('总体 · 练习估分',
            weight: FontWeight.w800, color: Color(0xff9a7a00), spacing: .4),
        const SizedBox(height: 4),
        LayoutBuilder(
            builder: (_, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (band != null) ...[
                                Text(band!,
                                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                        fontSize: 40,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 2),
                                const RfText('/ 9.0',
                                    size: 14,
                                    height: 1.1,
                                    weight: FontWeight.w700,
                                    color: Color(0xff9a7a00)),
                              ],
                              const Spacer(),
                              RfText('$right/$total',
                                  size: 14,
                                  height: 1.1,
                                  weight: FontWeight.w700,
                                  color: const Color(0xff9a7a00)),
                              const SizedBox(width: 10),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: const Color(0xfffbe7a2),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: RfText(
                                      '${total == 0 ? 0 : (right / total * 100).round()}% 正确率',
                                      size: 14,
                                      height: 1.1,
                                      weight: FontWeight.w700,
                                      color: const Color(0xff9a7a00))),
                            ]))))),
        if (text != null) ...[
          if (text != '') ...[
            const SizedBox(height: 8),
            RfText(text!,
                size: 10.5, height: 1.55, color: const Color(0xff6b5d2e)),
          ]
        ] else ...[
        const SizedBox(height: 8),
        RfText(
            english ??
                (mock
                    ? 'You scored $right of $total across three passages. Your factual location of answers is good, but you confuse FALSE with NOT GIVEN (Q3) and rely on surface word-matching rather than meaning (Q5, Q8). Focus on the exact meaning the passage supports, not just matching keywords.'
                    : 'Practice set: $right of $total correct. You confuse FALSE with NOT GIVEN — when the passage gives a fact that contradicts the statement, the answer is FALSE, not NOT GIVEN.'),
            size: 10.5,
            height: 1.55,
            color: const Color(0xff6b5d2e)),
        const SizedBox(height: 4),
        RfText(
            chinese ??
                (mock
                    ? '三篇文章共 $total 题答对 $right 题。你定位事实的能力不错，但会混淆 FALSE 与 NOT GIVEN（第 3 题），并依赖表面词匹配而非真正含义（第 5、8 题）。要关注原文支持的确切含义，而不只是匹配关键词。'
                    : '练习集：$total 题对 $right 题。你混淆了 FALSE 与 NOT GIVEN——当原文给出与陈述矛盾的事实时，答案是 FALSE，不是 NOT GIVEN。'),
            size: 10.5,
            height: 1.55,
            color: const Color(0xff8a7a45)),
        ],
      ]));
}

class RfWeakness extends StatelessWidget {
  const RfWeakness({super.key, required this.mock, this.items});
  final bool mock;

  /// 演示用真实数据：`[{label, text}]`（各为字符串或 `[英文, 中文]`）。给了就代替
  /// 下面写死的原型薄弱项；这次作答没有分析（空列表）就整块不画。
  final List? items;
  @override
  Widget build(BuildContext context) => items != null && items!.isEmpty
      ? const SizedBox.shrink()
      : RfCard(children: [
        // Source ra-h-wrap is29px (17+12), then subtitle margin-top8.
        const RfHeading('薄弱项分析'),
        const SizedBox(height: 8),
        const RfText('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',
            size: 10.5, color: rfMuted),
        const SizedBox(height: 14),
        if (items != null) ...[
          for (final w in items!) _weak(w['label'], w['text']),
          const SizedBox(height: 6),
        ] else if (mock) ...[
          _weak('FALSE vs NOT GIVEN confusion',
              'FALSE = the text contradicts the statement; NOT GIVEN = the text is silent. Q3 was contradicted, so FALSE.'),
          _weak('Surface word-matching',
              'Match the meaning, not just keywords — “printed” looked right in Q8 but the passage says “copied”.'),
          // Button inline-block keeps its top6 after weak block bottom11.
          const SizedBox(height: 6),
        ] else ...[
          rfTag('FALSE vs NOT GIVEN confusion', weak: true),
          const SizedBox(height: 20),
          const RfEvidence(
              'FALSE = the text contradicts the statement; NOT GIVEN = the text is silent.',
              italic: false),
          const SizedBox(height: 14),
        ],
        RfButton('练习你最弱的题型 →', key: const ValueKey('rf-practice'), onTap: () {
          final app = context.read<AppState>();
          app.examType = ExamType.ielts;
          app.session['selReadType'] = null;
          app.go(SurgoPage.readingDaily);
        }),
      ]);
  Widget _weak(Object title, Object evidence) => Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
          color: const Color(0xfffdf8ec),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        rfTag(title, weak: true),
        const SizedBox(height: 8),
        RfEvidence(evidence, italic: false),
      ]));
}
