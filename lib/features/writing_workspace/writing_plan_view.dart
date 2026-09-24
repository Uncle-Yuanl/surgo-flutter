import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/primitives.dart';
import 'writing_controller.dart';
import 'writing_session_view.dart';
import 'writing_plan_panel.dart';
import 'writing_plan_widgets.dart';

class WritingPlanView extends StatefulWidget {
  const WritingPlanView({super.key, required this.controller});
  final WritingController controller;
  @override
  State<WritingPlanView> createState() => _WritingPlanViewState();
}

class _WritingPlanViewState extends State<WritingPlanView> {
  WritingController get c => widget.controller;
  static const labels = ['题目分析', '论点选择', '段落规划', '主题词汇'];
  void refresh() {
    // Source pickPlanArg re-renders the route; vocabulary only refreshes in place.
    if (c.step == 'arg') {
      c.state.go(SurgoPage.writingPlan);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = WritingController.steps.indexOf(c.step);
    final nav = Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
        child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
                key: const ValueKey('writing-plan-home'),
                onTap: () => c.state.go(SurgoPage.ielts),
                child: SvgPicture.asset('assets/images/home_icon.svg',
                    width: 24, height: 24))));
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
          padding: EdgeInsets.only(top: 2, bottom: 10),
          child: WritingSourceSteps(current: 2)),
      for (var i = 0; i < 4; i++) ...[
        if (i == current)
          WritingPlanPanel(controller: c, step: c.step, changed: refresh)
        else
          _row(i, current),
        // Adjacent block margins collapse in source; last cp-foot top20 wins.
        SizedBox(
            height: i == 3
                ? 20
                : i == current
                    ? 18
                    : 14),
      ],
      _footer(current),
      const SizedBox(height: 18),
    ]);
    return LayoutBuilder(builder: (context, bounds) {
      if (!bounds.hasBoundedHeight) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nav, content]);
      }
      return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            nav,
            Expanded(
                child: SingleChildScrollView(
                    key: const ValueKey('writing-plan-scroll'),
                    child: content)),
          ]));
    });
  }

  Widget _row(int i, int current) {
    final locked =
            i > current + 1 || (i == current + 1 && i == 2 && c.args.isEmpty),
        next = i == current + 1 && !locked;
    return DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22), boxShadow: planShadow),
        child: Material(
            color: locked
                ? const Color(0xffefeeec)
                : next
                    ? SurgoColors.yellowTint
                    : Colors.white,
            textStyle: DefaultTextStyle.of(context).style,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
                key: ValueKey('plan-row-${WritingController.steps[i]}'),
                hoverColor: Colors.transparent,
                onTap: i > current + 1
                    ? null
                    : () {
                        if (locked) {
                          surgoPrototypeAlert(context, '请先选择一个论点');
                        } else {
                          c.step = WritingController.steps[i];
                          c.state.go(SurgoPage.writingPlan);
                        }
                      },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 21),
                    child: Row(children: [
                      Expanded(
                          child: T(labels[i],
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 17,
                                  height:
                                      (c.state.lang == UiLang.zh ? 24 : 17) /
                                          17,
                                  letterSpacing: -.2,
                                  fontWeight:
                                      next ? FontWeight.w800 : FontWeight.w700,
                                  color: locked
                                      ? const Color(0xffa6a29a)
                                      : next
                                          ? SurgoColors.ink
                                          : const Color(0xff8d887f)))),
                      const SizedBox(width: 12),
                      planIcon(locked ? 'lock' : 'next',
                          size: locked ? 22 : 24,
                          color: locked
                              ? const Color(0xffb8b4ac)
                              : const Color(0xff4a453d)),
                    ])))));
  }

  Widget _footer(int current) {
    final add = c.step == 'vocab' && c.vocab.isNotEmpty;
    return LayoutBuilder(builder: (context, bounds) {
      final addWidth = c.state.lang == UiLang.zh ? 107.0 : 100.21875;
      final nextWidth = addWidth + 16;
      return Row(key: const ValueKey('plan-footer'), children: [
        Material(
            color: Colors.white,
            textStyle: DefaultTextStyle.of(context).style,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: SurgoColors.line, width: 1.5)),
            child: InkWell(
                key: const ValueKey('plan-prev'),
                onTap: c.prev,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 19, vertical: 15),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      planIcon('prev', size: 17),
                      const SizedBox(width: 6),
                      const T('上一步',
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff3a3630))),
                    ])))),
        const SizedBox(width: 12),
        if (add) ...[
          Expanded(
              flex: (addWidth * 100).round(),
              child: Material(
                  color: SurgoColors.yellowTint,
                  textStyle: DefaultTextStyle.of(context).style,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                      key: const ValueKey('plan-add-vocab'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => surgoPrototypeAlert(
                          context, '（原型）已加入生词本：${c.vocab.length} 个词'),
                      child: SizedBox(
                          height: 52,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(children: [
                                planIcon('book',
                                    color: const Color(0xff3a2e00)),
                                const SizedBox(width: 10),
                                const Flexible(
                                    child: TSpan(
                                        parts: [
                                      ('加入', false),
                                      ('\n', false),
                                      ('生词本', false)
                                    ],
                                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 10.5,
                                            height: 1.2,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xff3a2e00)))),
                              ])))))),
          const SizedBox(width: 12),
        ],
        Expanded(
            flex: add ? (nextWidth * 100).round() : 1,
            child: Material(
                color: SurgoColors.yellow,
                textStyle: DefaultTextStyle.of(context).style,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                    key: const ValueKey('plan-next'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (!c.next()) {
                        surgoPrototypeAlert(context, '请先选择一个论点');
                      }
                    },
                    child: SizedBox(
                        height: 52,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                      child: T(
                                          current == 3 && !add ? '开始写作' : '下一步',
                                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                              fontSize: 14,
                                              height: 1.2,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xff3a2e00)))),
                                  const SizedBox(width: 8),
                                  planIcon('next',
                                      size: 18, color: const Color(0xff3a2e00)),
                                ])))))),
      ]);
    });
  }
}
