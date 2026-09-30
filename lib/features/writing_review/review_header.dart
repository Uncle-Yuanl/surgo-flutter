import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'review_widgets.dart';

class WritingReviewHeader extends StatelessWidget {
  const WritingReviewHeader(
      {super.key, required this.task, required this.l1, this.data = const {}});
  final int task;
  final bool l1;

  /// writing_review.json。原型数据没有 overall / band / weak 这几个键，下面的
  /// 分数和薄弱项就用原来写死的值；演示用真实数据（tool/demo_export）会带上。
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    void selectTask(int n) {
      app.session['wfTask'] = n;
      app.go(SurgoPage.writingFeedback);
    }

    void selectTab(String tab) {
      app.session['wfTab'] = tab;
      app.go(SurgoPage.writingFeedback);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 20),
          child: Row(children: [
            Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x143c3214),
                          blurRadius: 12,
                          offset: Offset(0, 4))
                    ]),
                child: GestureDetector(
                    key: const ValueKey('review-home'),
                    onTap: () => app.go(SurgoPage.ielts),
                    child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                            child: SvgPicture.asset(
                                'assets/images/home_icon.svg',
                                width: 20,
                                height: 20))))),
            const SizedBox(width: 14),
            Flexible(
                child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: -4,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: SurgoColors.yellow,
                          borderRadius: BorderRadius.circular(3)))),
              Text(zh ? '练习回顾' : 'PRACTICE REVIEW',
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3)),
            ])),
          ])),
      Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: T(
              '${app.examType == ExamType.toefl ? 'TOEFL' : 'IELTS'} ${zh ? '写作' : 'Writing'}',
              key: const ValueKey('review-title'),
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 24,
                  height: (zh ? 33 : 24) / 24,
                  fontWeight: FontWeight.w900))),
      Container(
          key: const ValueKey('review-overall'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: const Color(0xfffbeec2),
              borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            T('总体 · 练习估分',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13.5,
                    height: (zh ? 14 : 10) / 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff6d5c24))),
            const SizedBox(height: 8),
            Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ReviewScore(
                      score: data['overall'] as String? ?? '6.5',
                      overall: true),
                  Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 1; i <= 2; i++) ...[
                          if (i > 1) const SizedBox(width: 7),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: const Color(0xfffdf6e0),
                                  border: Border.all(
                                      color: const Color(0x66e0a000)),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                  i == 1
                                      ? 'T1 ${data['task1']?['band'] ?? '6.0'}'
                                      : 'T2 ${data['WF_T2']?['band'] ?? '6.5'}',
                                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 13.5,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xff8a6a10)))),
                        ]
                      ])),
                ]),
            const SizedBox(height: 9),
            T('Task 2 权重是 Task 1 的两倍',
                style: TextStyle(
                    fontSize: 13.5,
                    height: (zh ? 14 : 10) / 10,
                    color: const Color(0xff6d5c24))),
          ])),
      ReviewCard(title: '薄弱项分析', children: [
        const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 14),
            child: T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',
                style: TextStyle(
                    fontSize: 13.5, height: 1.6, color: Color(0xff6a645b)))),
        // 用户 2026-09-24：淡黄背景里的反馈正文要随界面语言 —— 这两句原本硬编码
        // 英文，且两张词典都没有译文，中文模式一直露英文。
        for (final w in (data['weak'] as List?) ?? _prototypeWeak)
          _weak(w['label'], w['text']),
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ReviewButton('练习你最弱的题型 →',
                key: const ValueKey('review-practice'), onTap: () {
              app.examType = ExamType.ielts;
              app.go(SurgoPage.writingDaily);
            })),
      ]),
      Padding(
          // CSS margin-top:2 collapses into the previous card's 16px margin.
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
          child: Wrap(spacing: 9, runSpacing: 9, children: [
            for (var n = 1; n <= 2; n++)
              ReviewTab('Task $n',
                  key: ValueKey('review-task-$n'),
                  active: task == n,
                  task: true,
                  onTap: () => selectTask(n))
          ])),
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            ReviewTab('评分与作文',
                key: const ValueKey('review-tab-mark'),
                active: !l1,
                onTap: l1 ? () => selectTab('mark') : null),
            // 模考的那一块（hasL1 == false）没有母语负迁移检查，不出这个页签。
            if (data['hasL1'] != false)
              ReviewTab('母语负迁移分析',
                  key: const ValueKey('review-tab-l1'),
                  active: l1,
                  onTap: l1 ? null : () => selectTab('l1')),
          ])),
    ]);
  }

  static const _prototypeWeak = [
    {
      'label': 'Task 1 · 任务完成情况 6.0',
      'text': [
        'There is no overview sentence. Add one line summarising the overall trend (both rose, urban always higher) before the detail — this is required for Band 7 in Task Achievement.',
        '缺少总体概述句。请在细节之前加一句概括整体趋势（两者都上升，城市始终更高）—— 这是任务完成度上 7 分的硬性要求。',
      ],
    },
    {
      'label': 'Task 2 · 任务完成情况 6.5',
      'text': [
        'Arguments stay abstract. Support each side with a specific example (e.g. polio vaccine testing, EU cosmetics-testing ban) to fully develop the response.',
        '论证偏抽象。请为每一方补充具体例子（如小儿麻痹疫苗试验、欧盟化妆品试验禁令）以充分展开。',
      ],
    },
  ];

  // label / text：字符串或 [英文, 中文]，由 T 按界面语言取。
  Widget _weak(Object label, Object text) => Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
          color: const Color(0xfffdf8ec),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: SurgoColors.yellowTint,
                    borderRadius: BorderRadius.circular(10)),
                child: T(label,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff9a7a00))))),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xfff7f4ee),
                borderRadius: BorderRadius.circular(9)),
            child: T(text,
                // 用户 2026-09-24：字体颜色加深（原 #B7B0A3 在浅底上太淡）。
                style: const TextStyle(
                    fontSize: 13.5, height: 1.65, color: Color(0xff5f584d)))),
      ]));
}
