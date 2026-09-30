import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'source_gap_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/marking_dialog.dart';
import '../../widgets/answer_sheet_dialog.dart';
import '../../widgets/demo_audio.dart';
import '../ielts_reading/exam_figure.dart';
import '../ielts_reading/reading_measure.dart';
import 'listening_data.dart';
import 'listening_feedback.dart';
import 'listening_layout.dart';

Widget? buildIeltsListeningPage(SurgoPage p) =>
    p == SurgoPage.listeningSession || p == SurgoPage.listeningFeedback
        ? IeltsListeningPage(feedback: p == SurgoPage.listeningFeedback)
        : null;

class IeltsListeningPage extends StatefulWidget {
  const IeltsListeningPage({super.key, required this.feedback});
  final bool feedback;
  @override
  State<IeltsListeningPage> createState() => _IeltsListeningPageState();
}

class _IeltsListeningPageState extends State<IeltsListeningPage> {
  IeltsListeningController? c;
  Timer? timer, audio;
  final keys = <int, GlobalKey>{};
  final questionScroll = ScrollController();
  double? sheetHeight, questionHeight;
  double dragStartY = 0, dragStartHeight = 0;
  bool progressChanged = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    IeltsListeningData.load().then((d) {
      if (!mounted) return;
      setState(() => c = IeltsListeningController(app, d));
      if (widget.feedback) return;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final expired = c!.tick();
        setState(() {});
        if (expired) surgoPrototypeAlert(context, '时间已到');
      });
      audio = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && (c!.playing || c!.clip != null)) setState(c!.audioTick);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    audio?.cancel();
    demoAudio.stop();
    questionScroll.dispose();
    super.dispose();
  }

  String clock(num sec) =>
      '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec.floor() % 60).toString().padLeft(2, '0')}';

  /// 题号导航 —— 用户 2026-09-24：全站统一为阅读那版面板（图 2）。
  void nav() {
    final x = c!;
    showAnswerSheet(context,
        first: 1,
        count: x.total,
        answered: (n) => x.done.contains(n - 1),
        onJump: (n) {
          final target = keys[n - 1]?.currentContext;
          if (target != null) {
            Scrollable.ensureVisible(target,
                duration: const Duration(milliseconds: 250), alignment: .5);
          }
        },
        onSubmit: mark,
        tileKey: (n) => ValueKey('listening-nav-${n - 1}'),
        closeKey: const ValueKey('listening-nav-close'),
        submitKey: const ValueKey('listening-nav-submit'));
  }

  void mark() => showMarking(context, SurgoPage.listeningFeedback, '正在批改听力作答');

  /// 用户 2026-09-24：「下一题」滚到第一道未作答的题；都答过则滚到下一道。
  void _nextQuestion() {
    final x = c!;
    var target = -1;
    for (var i = 0; i < x.total; i++) {
      if (!x.done.contains(i)) {
        target = i;
        break;
      }
    }
    if (target < 0) return;
    final ctx = keys[target]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 250), alignment: .5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = c;
    if (x == null) return const Center(child: CircularProgressIndicator());
    if (widget.feedback) return ListeningFeedback(data: x.data);
    final zh = x.app.lang == UiLang.zh;
    // 同阅读：上下两个独立滚动区 + 可拖拽答题面板。
    return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: LayoutBuilder(builder: (context, box) {
          final maxSheet = box.maxHeight - 60,
              minSheet = (box.maxHeight * .2).roundToDouble();
          final topHeight = zh ? 51.0 : 47.0;
          final contentTop = ListeningHeader.contentTop(x.app.lang);
          final initial = (box.maxHeight - 8) * .58;
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
                  child: ListeningHeader(
                      clock: clock(x.left > 0 ? x.left : x.over),
                      over: x.left <= 0)),
              Positioned(
                  left: 0,
                  right: 0,
                  top: contentTop,
                  height: (box.maxHeight - height - contentTop)
                      .clamp(0.0, box.maxHeight),
                  child: ListeningBrief(
                      controller: x,
                      clock: clock,
                      onSeek: (v) => setState(() => x.seek(v)),
                      onToggle: () => setState(x.toggle),
                      onSpeed: (v) => setState(() => x.setSpeed(v)))),
            ])),
            Positioned(
                left: 0,
                right: 0,
                top: (box.maxHeight - height).clamp(contentTop, box.maxHeight),
                height: height,
                child: Container(
                    key: const ValueKey('listening-sheet'),
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
                              key: const ValueKey('listening-sheet-handle'),
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
                                                      style: const TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontFamilyFallback:
                                                              SurgoFontFamily
                                                                  .fallback,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: SurgoColors
                                                              .onYellowStrong))
                                                  : T('Answered 0 / ${x.total}',
                                                      style: const TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontFamilyFallback:
                                                              SurgoFontFamily
                                                                  .fallback,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: SurgoColors
                                                              .onYellowStrong))),
                                          GestureDetector(
                                              key: const ValueKey(
                                                  'listening-nav-open'),
                                              onTap: nav,
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
                                                      style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontFamilyFallback:
                                                              SurgoFontFamily
                                                                  .fallback,
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
                          bottom: 74,
                          child: SingleChildScrollView(
                              controller: questionScroll,
                              key: const ValueKey('listening-question-scroll'),
                              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                              child: ReadingMeasure(
                                  onSize: (s) {
                                    if (mounted && questionHeight != s.height) {
                                      setState(() => questionHeight = s.height);
                                    }
                                  },
                                  child: _questions(x)))),
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          // Two full-width buttons need more room than the
                          // reading page's single hint chip.
                          height: 74,
                          child: ColoredBox(
                              color: const Color(0xfffcf8f5),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 12, 22, 18),
                                  child: Row(children: [
                                    Expanded(
                                        child: SurgoButton('返回',
                                            primary: false,
                                            onTap: () =>
                                                x.app.go(SurgoPage.ielts))),
                                    const SizedBox(width: 10),
                                    // 用户 2026-09-24：未答完显示「下一题」，
                                    // 全部作答完成后才变成「提交并批改」。
                                    Expanded(
                                        child: x.done.length >= x.total
                                            ? SurgoButton('提交并批改',
                                                key: const ValueKey(
                                                    'listening-submit'),
                                                onTap: mark)
                                            : SurgoButton('下一题',
                                                key: const ValueKey(
                                                    'listening-next'),
                                                onTap: _nextQuestion)),
                                  ])))),
                    ]))),
          ]);
        }));
  }

  /// 面板内说明与表格单元格的小字 —— 用户 2026-09-24 要求放大（原 cardDesc 11px）。
  /// 只作用于听力题目区，不改全局 SurgoText.cardDesc。
  static const _small =
      TextStyle(fontSize: 13, height: 1.55, color: SurgoColors.muted);

  /// 面板内的题目区 —— 题型与源站完全一致，只是搬进可拖拽面板。
  Widget _questions(IeltsListeningController x) {
    final m = x.meta;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _group(m['groupLabel'] ?? '', m['groupInstr'] ?? ''),
      if (m['table'] != null) ...[
        if (m['tableTitle'] != null)
          SourceText(m['tableTitle'],
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        for (final row in m['table'])
          SurgoCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 80,
                child: SourceText(row['label'], style: SurgoText.rowLabel)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  for (final cell in row['rows'])
                    cell['n'] != null
                        ? _gap(
                            x.questions
                                .indexWhere((q) => q['num'] == cell['n']),
                            '${cell['n']}')
                        : SourceText(cell['val'], style: _small)
                ]))
          ])),
        if (m['mapQs'] != null) ...[
          _group(m['mapGroupLabel'], m['mapGroupInstr']),
          SvgPicture.string(x.data.raw['mapSvg'], height: 220),
          for (var i = 0; i < (m['mapQs'] as List).length; i++)
            _gap(x.questions.length + i,
                '${m['mapQs'][i]['n']}. ${m['mapQs'][i]['label']}',
                max: 1)
        ],
      ] else ...[
        if (m['matchBox'] != null)
          for (final line in m['matchBox'])
            SourceText(line, style: _small),
        for (var i = 0; i < x.questions.length; i++)
          _question(i, x.questions[i]),
        if (m['qs2'] != null) ...[
          _group(m['group2Label'] ?? '', m['group2Instr'] ?? ''),
          for (var i = 0; i < (m['qs2'] as List).length; i++)
            _gap(x.questions.length + i,
                '${m['qs2'][i]['n']}. ${m['qs2'][i]['q']}',
                second: true, tail: m['qs2'][i]['tail'])
        ],
      ],
    ]);
  }

  Widget _group(String title, String desc) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SourceText(title,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontFamilyFallback: SurgoFontFamily.fallback,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.4)),
        SourceText(desc, style: _small),
      ]));

  Widget _gap(int i, String label,
          {bool second = false, String? tail, int? max}) =>
      Padding(
          key: keys.putIfAbsent(i, () => GlobalKey()),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SourceText(label, style: const TextStyle(fontSize: 15, height: 1.6)),
            ListeningSourceGap(
                key: ValueKey('listening-gap-$i'),
                maxLength: max,
                inputEvent: second,
                onValue: (v) => setState(() {
                      c!.gap(i, v, second: second);
                      progressChanged = true;
                    })),
            if (tail != null) SourceText(tail, style: _small),
          ]));

  Widget _question(int i, Map q) {
    if (q['kind'] == 'gap') {
      return _gap(i, '${q['q'][0]} ______ ${q['q'][1]}');
    }
    return Padding(
        key: keys.putIfAbsent(i, () => GlobalKey()),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (q['groupStart'] != null)
            _group(q['groupStart'], q['groupInstr'] ?? ''),
          // 演示用真实数据：图示标注这组题的图，挂在这组的第一题上。
          if (q['figure'] != null) ...[
            ExamFigure(q['figure']),
            const SizedBox(height: 12),
          ],
          SourceText(q['q'],
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.6)),
          const SizedBox(height: 10),
          for (var j = 0; j < (q['opts'] as List).length; j++)
            _option(i, j, q['opts'][j] as String, q['kind'] == 'multi'),
        ]));
  }

  /// 选项卡片 —— 与阅读单选同款：左侧字母徽标 + 去掉文案里的 "A)" 前缀。
  Widget _option(int i, int j, String label, bool multi) {
    final selected = c!.picks[i]?.contains(j) == true;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
            key: ValueKey('listening-opt-$i-$j'),
            onTap: () => setState(() {
                  c!.pick(i, j, multi);
                  progressChanged = true;
                }),
            child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: selected ? SurgoColors.yellowTint : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            selected ? SurgoColors.yellow : SurgoColors.line)),
                child: Row(children: [
                  Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: selected ? SurgoColors.yellow : Colors.white,
                          border: Border.all(
                              color: selected
                                  ? SurgoColors.yellow
                                  : SurgoColors.line),
                          borderRadius: BorderRadius.circular(9)),
                      child: Text(String.fromCharCode(65 + j),
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontFamilyFallback: SurgoFontFamily.fallback,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : SurgoColors.muted))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: SourceText(
                          label.replaceFirst(RegExp(r'^[A-Z][).]\s*'), '').trim(),
                          style: const TextStyle(
                              fontSize: 14.5, height: 1.4))),
                ]))));
  }
}
