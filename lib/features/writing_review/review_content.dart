import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import '../../theme/tokens.dart';
import 'review_widgets.dart';
import 'review_annotations.dart';

class WritingReviewContent extends StatelessWidget {
  const WritingReviewContent(
      {super.key,
      required this.data,
      required this.task,
      required this.l1,
      required this.app});
  final Map<String, dynamic> data;
  final int task;
  final bool l1;
  final AppState app;
  static const task1En =
      'You report the data accurately and cover both groups, which secures a solid Band 6. To move towards Band 7 you need a clear overview sentence, more precise data references, and a wider range of trend vocabulary rather than repeating "increased".';
  static const task1Zh =
      '你准确报告了数据并覆盖了两个群体，稳拿 6 分。要冲 7 分，需要一句清晰的总体概述、更精确地引用数据，以及更丰富的趋势词汇，而不是反复用 "increased"。';
  @override
  Widget build(BuildContext context) {
    final second = task == 2, block = second ? data['WF_T2'] : data['task1'];
    final zh = app.lang == UiLang.zh;
    final essay = l1
        ? (second ? data['WF_T2_L1_ESSAY'] : data['l1task1']['essay'])
        : (second ? data['WF_T2_ESSAY'] : data['task1']['essay']);
    final notes = second ? data['WF_T2_NOTES'] : data['task1']['notes'];
    // 模考那一块没有母语负迁移的数据（l1task1 为空，也进不了这一页），所以用 ?[。
    final items = second ? data['WF_T2_L1'] : data['l1task1']?['items'];
    // 演示用真实数据：这篇没查出母语负迁移时，用检查的总评代替空卡片。
    final l1Summary =
        second ? data['WF_T2_L1_SUMMARY'] : data['l1task1']?['summary'];
    final writing = QuestionBank.instance.skill('writing', app.examType);
    // 模考的评分页配模考的题目（演示用真实数据才有 mock.task1/2），否则是日常那两题。
    final key = second ? 'task2' : 'task1';
    final mock = app.session['sessionMode'] == 'mock' ? writing['mock'] : null;
    final prompt =
        (mock?[key] ?? writing['daily']?[key])?['prompt'] as String? ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (l1) ...[
        ReviewCard(title: '母语负迁移分析', children: [
          const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 14),
              child: T('因中文表达习惯而容易犯的错误——逐条给出纠正、成因和规避方法。',
                  style: TextStyle(fontSize: 13.5, color: reviewMuted))),
          ReviewEssay(source: essay)
        ]),
        ReviewCard(children: [
          if ((items as List).isEmpty && l1Summary != null)
            T(l1Summary,
                style: const TextStyle(fontSize: 13.5, height: 1.65, color: reviewMuted)),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            ReviewNote(note: items[i], l1: true)
          ]
        ]),
      ] else ...[
        Container(
            key: const ValueKey('review-prompt'),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
                color: const Color(0xfff2f0fb),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const T('题目',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff6b52d6))),
                  const SizedBox(height: 7),
                  SourceText(prompt.replaceAll(RegExp(r'\s+'), ' '),
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.7,
                          color: Color(0xff3a352c))),
                ])),
        Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
                color: SurgoColors.yellowSoft,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const T('总体 · 练习估分',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                          color: Color(0xff9a7a00))),
                  const SizedBox(height: 4),
                  ReviewScore(
                      score: block['band'] as String? ??
                          (second ? '6.5' : '6.0')),
                  const SizedBox(height: 8),
                  // 用户 2026-09-24：中英要对应 —— 中文模式只出中文，英文模式只出
                  // 英文，不再两段并列。数据源本就有 descEn / descZh 两份。
                  // 原型的 Task 1 块没有 descEn / descZh，用上面两句常量。
                  T(
                      zh
                          ? (block['descZh'] ?? task1Zh)
                          : (block['descEn'] ?? task1En),
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: Color(0xff574b22))),
                ])),
        ReviewCard(title: '分项评分', children: [
          for (var i = 0; i < (block['crit'] as List).length; i++) ...[
            if (i > 0)
              Container(
                  height: 1,
                  color: SurgoColors.line,
                  margin: const EdgeInsets.only(top: 16, bottom: 16)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: T(block['crit'][i]['name'],
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff3a352c)))),
              Text(block['crit'][i]['sc'],
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 18, fontWeight: FontWeight.w900))
            ]),
            const SizedBox(height: 10),
            for (final kind in ['ok', 'up'])
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind == 'ok' ? '✓' : '↑',
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 13.5,
                                height: 1.6,
                                fontWeight: FontWeight.w900,
                                color: kind == 'ok'
                                    ? const Color(0xff4f9e3a)
                                    : const Color(0xffe0a80f))),
                        const SizedBox(width: 8),
                        // 中英要对应：[0] 是英文、[1] 是中文，按界面语言只出一条。
                        Expanded(
                            child: T(
                                block['crit'][i][kind][zh ? 1 : 0],
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.65,
                                    color: Color(0xff3a352c)))),
                      ])),
          ]
        ]),
        ReviewCard(title: '提分建议', children: [
          for (var i = 0; i < (block['tips'] as List).length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xfffdf6e3),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      T(block['tips'][i]['name'],
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff3a352c))),
                      const SizedBox(height: 8),
                      for (final tip in block['tips'][i]['items'])
                        Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(top: 7),
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xffe0a80f))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: T(tip,
                                          style: const TextStyle(
                                              fontSize: 13.5,
                                              height: 1.6,
                                              color: Color(0xff6a5a2a))))
                                ])),
                    ])),
          ]
        ]),
        ReviewCard(title: '你的作文（含批改）', children: [ReviewEssay(source: essay)]),
        ReviewCard(title: '批注详情', children: [
          for (var i = 0; i < (notes as List).length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            ReviewNote(note: notes[i])
          ]
        ]),
      ],
    ]);
  }
}
