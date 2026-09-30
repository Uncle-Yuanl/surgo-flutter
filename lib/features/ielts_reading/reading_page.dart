import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/marking_dialog.dart';
import 'reading_controller.dart';
import 'reading_article.dart';
import 'reading_question.dart';
import 'reading_navigation.dart';
import 'reading_measure.dart';
import 'reading_overtime.dart';

/// Source bounded page, two independent scroll areas, adjustable question sheet.
class IeltsReadingPage extends StatefulWidget {
  const IeltsReadingPage({super.key, required this.single, this.auditSeconds});
  final bool single;
  final int? auditSeconds;
  @override
  State<IeltsReadingPage> createState() => _IeltsReadingPageState();
}

class _IeltsReadingPageState extends State<IeltsReadingPage> {
  ReadingController? c;
  Timer? timer;
  final input = TextEditingController();
  final questionScroll = ScrollController();
  final focus = FocusNode();
  final itemKey = GlobalKey();
  double? sheetHeight, questionHeight;
  double dragStartY = 0, dragStartHeight = 0;
  bool translated = true, progressChanged = false, inputDirty = false;
  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus && c != null && inputDirty) _commit(input.text);
    });
    final app = context.read<AppState>();
    ReadingData.load().then((data) {
      if (!mounted) return;
      setState(() => c = ReadingController(app, data,
          single: widget.single, auditSeconds: widget.auditSeconds));
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final over = c!.tick();
        setState(() {});
        if (over) _overtime();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    input.dispose();
    focus.dispose();
    questionScroll.dispose();
    super.dispose();
  }

  void _commit(String value) {
    setState(() {
      c!.commitInput(value);
      inputDirty = false;
      if (!widget.single ||
          c!.type['boxInput'] == true ||
          c!.type['diagramSvg'] != null) {
        progressChanged = true;
      }
    });
  }

  void jump(int n) {
    focus.unfocus();
    setState(() {
      c!.jump(n);
      input.clear();
      inputDirty = false;
      translated = false;
      progressChanged = true;
    });
    if (questionScroll.hasClients) questionScroll.jumpTo(0);
  }

  void mark() => showMarking(context, SurgoPage.readingFeedback, '正在批改阅读作答');
  void _overtime() => showReadingOvertime(context);
  void navigation() => showReadingNavigation(context, c!, (n) {
        if (!widget.single) {
          jump(n);
          return;
        }
        // Source jumpTypeQ does not assign typeIdx; it scrolls the only rq-item.
        if (itemKey.currentContext != null) {
          Scrollable.ensureVisible(itemKey.currentContext!,
              alignment: .5, duration: const Duration(milliseconds: 200));
        }
      }, mark);
  @override
  Widget build(BuildContext context) {
    final x = c;
    if (x == null) return const Center(child: CircularProgressIndicator());
    final zh = x.state.lang == UiLang.zh;
    return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: LayoutBuilder(builder: (context, box) {
          final maxSheet = box.maxHeight - 60,
              minSheet = (box.maxHeight * .2).roundToDouble();
          final topHeight = zh ? 51.0 : 47.0;
          final contentTop = ReadingHeader.contentTop(x.state.lang);
          final initialMax = (box.maxHeight - 8) * (widget.single ? .46 : .58);
          // Source auto sheet shrinks for short gap/diagram questions, then caps at46%.
          final natural = questionHeight == null
              ? initialMax
              : questionHeight! + 36 + topHeight + 50;
          final initial =
              widget.single ? natural.clamp(0.0, initialMax) : initialMax;
          final height = sheetHeight == null
              ? initial
              : sheetHeight!.clamp(minSheet, maxSheet);
          return Stack(children: [
            Positioned.fill(
                child: Stack(children: [
              Positioned(
                  left: 0,
                  right: 0,
                  top: 8,
                  child: ReadingHeader(controller: x)),
              Positioned(
                  left: 0,
                  right: 0,
                  top: contentTop,
                  height: (box.maxHeight - height - contentTop)
                      .clamp(0.0, box.maxHeight),
                  child: ReadingArticle(controller: x)),
            ])),
            Positioned(
                left: 0,
                right: 0,
                // Source flex keeps nav+clock above the sheet; large drag
                // heights extend below the phone rather than cover its clock.
                top: (box.maxHeight - height).clamp(contentTop, box.maxHeight),
                height: height,
                child: Container(
                    key: const ValueKey('reading-sheet'),
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                        color: Color(0xfffcf8f5),
                        borderRadius: SurgoRadius.sheetTopAll,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x213c3214),
                              blurRadius: 34,
                              offset: Offset(0, -10))
                        ]),
                    child: Stack(children: [
                      Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: topHeight,
                          child: GestureDetector(
                              key: const ValueKey('reading-sheet-handle'),
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: (d) {
                                dragStartY = d.globalPosition.dy;
                                dragStartHeight = height.roundToDouble();
                              },
                              onVerticalDragUpdate: (d) => setState(() =>
                                  sheetHeight = (dragStartHeight +
                                          dragStartY -
                                          d.globalPosition.dy)
                                      .clamp(minSheet, maxSheet)
                                      .roundToDouble()),
                              child: ColoredBox(
                                  color: const Color(0xfffdecb0),
                                  child: Column(children: [
                                    const SizedBox(height: 5),
                                    Container(
                                        width: 44,
                                        height: 4,
                                        decoration: BoxDecoration(
                                            color: const Color(0x403a2e00),
                                            borderRadius:
                                                BorderRadius.circular(4))),
                                    const SizedBox(height: 3),
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            22, 0, 22, 7),
                                        child: Row(children: [
                                          Expanded(
                                              child: progressChanged
                                                  ? Text(
                                                      'Answered ${x.done.length} / ${x.total}',
                                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: SurgoColors
                                                              .onYellowStrong))
                                                  // 原型雅思日常是 14 题；演示用真实数据的题数不同，
                                                  // 取实际题数（托福沿用原型写死的 14）。
                                                  : T('Answered 0 / ${widget.single || x.state.examType == ExamType.ielts ? x.total : 14}',
                                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: SurgoColors
                                                              .onYellowStrong))),
                                          GestureDetector(
                                              key: const ValueKey(
                                                  'reading-nav-open'),
                                              onTap: navigation,
                                              child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0x80ffffff),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  child: T('☰ 题号',
                                                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                                          fontSize: 14,
                                                          height: zh
                                                              ? 20 / 14
                                                              : 16 / 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: const Color(
                                                              0xffe0a000))))),
                                        ])),
                                  ])))),
                      Positioned(
                          left: 0,
                          right: 0,
                          top: topHeight,
                          bottom: 50,
                          child: SingleChildScrollView(
                              controller: questionScroll,
                              key: const ValueKey('reading-question-scroll'),
                              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                              child: ReadingMeasure(
                                  onSize: (s) {
                                    if (mounted && questionHeight != s.height) {
                                      setState(() => questionHeight = s.height);
                                    }
                                  },
                                  child: ReadingQuestion(
                                      itemKey: itemKey,
                                      x: x,
                                      input: input,
                                      focus: focus,
                                      changed: () => inputDirty = true,
                                      translated: translated,
                                      pick: (v) => setState(() {
                                            x.pick(v);
                                            progressChanged = true;
                                          }),
                                      jump: jump,
                                      commit: _commit,
                                      submit: mark)))),
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 60,
                          child: ColoredBox(
                              color: const Color(0xfffcf8f5),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 10, 22, 14),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 9),
                                          decoration: BoxDecoration(
                                              color: x.used > 90
                                                  ? const Color(0xfffdf1ef)
                                                  : const Color(0xfffdf6e3),
                                              border: Border.all(
                                                  color: x.used > 90
                                                      ? const Color(0xfff0a79b)
                                                      : const Color(
                                                          0xfff0e2b4)),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Text(
                                              '已用 ${x.used} 秒，建议每题不超过 90 秒',
                                              key:
                                                  const ValueKey('reading-hint'),
                                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w700, color: x.used > 90 ? const Color(0xffc94436) : const Color(0xffb8860b)))))))),
                    ]))),
          ]);
        }));
  }
}
