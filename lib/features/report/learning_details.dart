import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'learning_data.dart';

class LearningDetails extends StatelessWidget {
  const LearningDetails(
      {super.key,
      required this.data,
      required this.chinese,
      required this.selected,
      required this.expanded,
      required this.onSelect,
      required this.onExpand});
  final LearningReportData data;
  final bool chinese;
  final String? selected, expanded;
  final ValueChanged<String> onSelect, onExpand;
  String tr(String zh, String en) => chinese ? zh : en;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text(tr('四科现状', 'Skills at a glance'),
                  style: const TextStyle(
                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 17,
                      fontWeight: FontWeight.w800))),
          Text('${data.scores.length}/4 ${tr('科已出分', 'scored')}',
              style: const TextStyle(fontSize: 12.5, color: SurgoColors.muted))
        ]),
        const SizedBox(height: 12),
        for (final skill in learningSkills) ...[
          Material(
              type: MaterialType.transparency,
              child: InkWell(
                  key: ValueKey('learning-skill-$skill'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    onSelect(skill);
                    onExpand(skill);
                  },
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: selected == skill
                              ? const Color(0xfffff4d4)
                              : const Color(0xfff8f5ee),
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(skillName(skill, chinese),
                                  style: const TextStyle(
                                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  data.scores.containsKey(skill)
                                      ? tr('近30天评分练习',
                                          'Scored practices in the last30days')
                                      : tr('题型覆盖不足 · 待积累',
                                          'More task coverage needed'),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: SurgoColors.muted)),
                            ])),
                        Text(data.scores[skill]?.toStringAsFixed(1) ?? '—',
                            style: const TextStyle(
                                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Icon(
                            expanded == skill
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18)
                      ])))),
          if (expanded == skill)
            Container(
                key: ValueKey('learning-evidence-$skill'),
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(tr('评分依据 · 演示口径', 'Scoring basis · demo criteria'),
                          style: const TextStyle(
                              fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          tr('累计覆盖每个必需题型，才具备出分资格；分数只使用近30天样本。',
                              'Eligibility uses cumulative required-task coverage; displayed scores use only the latest30days.'),
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                      const SizedBox(height: 10),
                      Text(
                          tr('已评分练习：${data.requirements(skill, chinese).fold<int>(0, (n, r) => n + r.completed)}次（累计）',
                              'Scored practices: ${data.requirements(skill, chinese).fold<int>(0, (n, r) => n + r.completed)} cumulative'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      for (final req in data.requirements(skill, chinese))
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(req.name,
                                            style:
                                                const TextStyle(fontSize: 13))),
                                    Text('${req.completed}/${req.required}',
                                        style: const TextStyle(fontSize: 12.5))
                                  ]),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                          minHeight: 5,
                                          value: (req.completed / req.required)
                                              .clamp(0, 1),
                                          color: SurgoColors.yellow,
                                          backgroundColor:
                                              const Color(0xffe9e3d7))),
                                  if (req.remaining > 0)
                                    Text(
                                        tr('还需 ${req.remaining} 次',
                                            '${req.remaining} more needed'),
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: SurgoColors.muted)),
                                ])),
                    ])),
          const SizedBox(height: 8),
        ],
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                key: const ValueKey('learning-source'),
                onPressed: () => showLearningExplanation(context, data, chinese,
                    sourceOnly: true),
                child: Text(tr('数据来源与规则', 'Data sources & rules'),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xff8f6e16))))),
      ]);
}

Future<void> showLearningExplanation(
        BuildContext context, LearningReportData data, bool zh,
        {bool sourceOnly = false}) =>
    showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (ctx) => Dialog(
              backgroundColor: const Color(0xfffffcf4),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: 350,
                      maxHeight: MediaQuery.sizeOf(ctx).height - 80),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  sourceOnly
                                      ? (zh ? '数据来源与规则' : 'Sources & rules')
                                      : (zh
                                          ? '这次估分怎么来的'
                                          : 'How this estimate is calculated'),
                                  style: const TextStyle(
                                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800))),
                          IconButton(
                              key: const ValueKey('learning-dialog-close'),
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, size: 20))
                        ])),
                    Flexible(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      zh
                                          ? '以下为功能演示数据，并非真实学生记录。'
                                          : 'Demo data, not an actual student record.',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: SurgoColors.muted)),
                                  const SizedBox(height: 12),
                                  if (!sourceOnly) ...[
                                    Text(
                                        '${data.overallText} / ${data.maxScore}',
                                        style: const TextStyle(
                                            fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        zh
                                            ? (data.overall == null
                                                ? '四科都有成绩后才显示总分。缺分不算零分。'
                                                : '四科等权均值，保留当前报告的一位小数显示。')
                                            : (data.overall == null
                                                ? 'Overall appears only after all4skills are scored. Missing is not zero.'
                                                : 'Equal-weight mean of4skills, preserving this report’s one-decimal display.'),
                                        style: const TextStyle(fontSize: 13)),
                                    for (final s in learningSkills)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          child: Text(
                                              '${skillName(s, zh)}  ${data.scores[s]?.toStringAsFixed(1) ?? (zh ? '待积累' : 'Not scored')}',
                                              style: const TextStyle(
                                                  fontSize: 13))),
                                  ],
                                  for (final pair in [
                                    [
                                      zh
                                          ? '1. 需要练多少才出分？'
                                          : '1. When is a skill eligible?',
                                      zh
                                          ? '每个必需题型累计完成5次有效评分练习，或该科近90天完成有效模考。覆盖不足时显示“待积累”，不按零分处理。'
                                          : 'Complete5valid scored practices for every required task type, or a valid mock for the skill in the last90days. Missing scores are not zeros.'
                                    ],
                                    [
                                      zh
                                          ? '2. 分数用了哪些练习？'
                                          : '2. Which practices affect the score?',
                                      zh
                                          ? '出分资格看累计；当前分数展示近30天样本。重复练习与无效练习的生产去重规则需接入真实数据后明确。'
                                          : 'Eligibility uses all-time coverage; the estimate uses the last30days. Production deduplication and validity rules require a real data integration.'
                                    ],
                                    [
                                      zh
                                          ? '3. 总分如何计算？'
                                          : '3. How is the overall calculated?',
                                      zh
                                          ? '四科全部出分后才显示等权平均总分；部分科目已出分时，总分仍为待出分。缺分不画雷达顶点，不按零分参与计算。'
                                          : 'Show the equal-weight overall only after all4skills are scored. A partial report has no overall. Missing scores create no radar vertex and are never treated as zero.'
                                    ],
                                    [
                                      zh
                                          ? '4. 等于正式考试成绩吗？'
                                          : '4. Is this an official score?',
                                      zh
                                          ? '不等于。学情估分只用于训练参考，正式成绩以考试机构的成绩报告为准。'
                                          : 'No. This estimate is for learning guidance; official results are issued by the examination provider.'
                                    ],
                                  ]) ...[
                                    const SizedBox(height: 16),
                                    Text(pair[0],
                                        style: const TextStyle(
                                            fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Container(
                                        padding: pair[0].startsWith('4.')
                                            ? const EdgeInsets.all(12)
                                            : EdgeInsets.zero,
                                        decoration: pair[0].startsWith('4.')
                                            ? BoxDecoration(
                                                color: const Color(0xfffff0bc),
                                                borderRadius:
                                                    BorderRadius.circular(12))
                                            : null,
                                        child: Text(pair[1],
                                            style: const TextStyle(
                                                fontSize: 13, height: 1.65))),
                                  ],
                                  const SizedBox(height: 18),
                                ]))),
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                key: const ValueKey('learning-dialog-done'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: SurgoColors.yellow,
                                    foregroundColor: SurgoColors.ink),
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(zh ? '知道了' : 'Got it')))),
                  ])),
            ));
