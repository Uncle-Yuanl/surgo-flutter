import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'writing_controller.dart';
import 'writing_plan_widgets.dart';

/// Original four cp-* panels, data and mutations delegated to the controller.
class WritingPlanPanel extends StatelessWidget {
  const WritingPlanPanel(
      {super.key,
      required this.controller,
      required this.step,
      required this.changed,
      this.embedded = false});
  final WritingController controller;
  final String step;
  final VoidCallback changed;
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final c = controller, p = c.plan, an = c.analysis;
    return PlanCard(
        key: ValueKey('plan-panel-$step'),
        embedded: embedded,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (step == 'analysis') ...[
            if (an != null) ...[
              Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 7),
                      decoration: BoxDecoration(
                          color: SurgoColors.yellowTint,
                          borderRadius: BorderRadius.circular(14)),
                      child: T(an['label'] ?? '',
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff9a7a00))))),
              const SizedBox(height: 14),
              T(an['requirement'] ?? '',
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      color: Color(0xffc98a06))),
              const SizedBox(height: 12),
            ],
            T(an?['detail'] ?? c.task['prompt'] ?? '',
                style: const TextStyle(
                    fontSize: 16, height: 1.75, color: Color(0xff3a352c))),
            if (an?['pitfall'] != null)
              Container(
                  key: const ValueKey('plan-pitfall'),
                  margin: const EdgeInsets.only(top: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                  decoration: BoxDecoration(
                      color: const Color(0xfffdecef),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                            width: 19,
                            child: Text('\u26a0\ufe0f',
                                style: TextStyle(fontSize: 15, height: 1.5))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: T(an!['pitfall'],
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xffc2455c)))),
                      ])),
          ],
          if (step == 'arg') ...[
            if (!embedded) const PlanHeading('论点选择'),
            // 用户 2026-09-24：论点选择字号放大一档。
            const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: T('选择一个论点来展开你的作文。',
                    style: TextStyle(fontSize: 13, height: 1.6, color: planMuted))),
            for (var i = 0; i < (p['args'] as List? ?? []).length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PlanSelectCard(
                      key: ValueKey('plan-arg-$i'),
                      selected: c.args.contains(i),
                      onTap: () {
                        c.pickArg(i);
                        changed();
                      },
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Container(
                                  key: ValueKey('plan-radio-$i'),
                                  width: 19,
                                  height: 19,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.args.contains(i)
                                          ? SurgoColors.yellow
                                          : Colors.white,
                                      border: Border.all(
                                          color: c.args.contains(i)
                                              ? SurgoColors.yellow
                                              : const Color(0xffcfc7b8),
                                          width: 1.6)),
                                  child: c.args.contains(i)
                                      ? planIcon('check',
                                          size: 12, color: Colors.white)
                                      : null),
                              const SizedBox(width: 11),
                              Expanded(
                                  child: T(p['args'][i]['text'],
                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                          fontSize: 14.5,
                                          height: 1.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xff1c1a17)))),
                            ]),
                            if (p['args'][i]['note'] != null) ...[
                              const SizedBox(height: 16),
                              const T('选择理由',
                                  style: TextStyle(
                                      fontSize: 12, color: planMuted)),
                              const SizedBox(height: 9),
                              T(p['args'][i]['note'],
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.6,
                                      color: Color(0xff6b6255))),
                            ],
                          ]))),
          ],
          if (step == 'para') ...[
            if (!embedded) const PlanHeading('段落规划'),
            if (p['parasByArg'] != null) ...[
              const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: T('已选论点',
                      style: TextStyle(fontSize: 11.5, color: planMuted))),
              Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                      color: SurgoColors.yellowTint,
                      borderRadius: BorderRadius.circular(12)),
                  child: T(p['args'][c.argIndex]['text'],
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff3a352c)))),
            ],
            for (var i = 0; i < c.paras.length; i++) ...[
              if (i > 0)
                Container(
                    height: 1,
                    color: SurgoColors.line,
                    margin: const EdgeInsets.symmetric(vertical: 18)),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 5),
                      decoration: BoxDecoration(
                          color: SurgoColors.yellow,
                          borderRadius: BorderRadius.circular(11)),
                      child: T(c.paras[i]['tag'],
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff3a2e00))))),
              const SizedBox(height: 11),
              T(c.paras[i]['text'],
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15.5,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1c1a17))),
              const SizedBox(height: 11),
              if (c.paras[i]['bullets'] != null || c.paras[i]['note'] != null)
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: SurgoColors.yellowTint,
                        borderRadius: BorderRadius.circular(14)),
                    child: _ParaNotes(para: c.paras[i])),
            ],
          ],
          if (step == 'vocab') ...[
            if (!embedded) const PlanHeading('主题词汇'),
            for (var i = 0; i < (p['vocab'] as List? ?? []).length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanSelectCard(
                      key: ValueKey('plan-vocab-$i'),
                      vocab: true,
                      selected: c.vocab.contains(i),
                      onTap: () {
                        c.toggleVocab(i);
                        changed();
                      },
                      child: Row(children: [
                        SizedBox(
                            width: 96,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SourceText(p['vocab'][i]['en'],
                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                          fontSize: 14.5,
                                          height: 1.3,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xff1c1a17))),
                                  const SizedBox(height: 3),
                                  SourceText(p['vocab'][i]['zh'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff6a6459))),
                                ])),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              SourceText(p['vocab'][i]['ex'],
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      color: Color(0xff5a5346))),
                              if (p['vocab'][i]['exZh'] != null) ...[
                                const SizedBox(height: 3),
                                SourceText(p['vocab'][i]['exZh'],
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: Color(0xff8d887f)))
                              ],
                            ])),
                        const SizedBox(width: 14),
                        Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.vocab.contains(i)
                                    ? SurgoColors.yellow
                                    : Colors.transparent,
                                border: Border.all(
                                    color: SurgoColors.yellow, width: 2)),
                            child: c.vocab.contains(i)
                                ? planIcon('check',
                                    size: 14, color: Colors.white)
                                : null),
                      ]))),
          ],
        ]));
  }
}

class _ParaNotes extends StatelessWidget {
  const _ParaNotes({required this.para});
  final Map para;
  @override
  Widget build(BuildContext context) {
    final lines = para['bullets'] as List?;
    if (lines == null) {
      return T(para['note'],
          style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: Color(0xffa99a72)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) const SizedBox(height: 4),
        T(lines[i],
            style: const TextStyle(
                fontSize: 11.5,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: Color(0xffa99a72))),
      ]
    ]);
  }
}
