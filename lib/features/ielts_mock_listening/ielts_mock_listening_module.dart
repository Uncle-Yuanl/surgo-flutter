import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/marking_dialog.dart';
import '../../widgets/answer_sheet_dialog.dart';
import '../../widgets/session_tags.dart';
import '../ielts_listening/listening_layout.dart';
import '../../widgets/correction_dialog.dart';
import 'mock_listening_data.dart';

/// Exported entry — wired into shell.dart page dispatch.
/// Handles the 4 mock-listening question pages (mockListeningQ..Q4).
Widget? buildIeltsMockListeningPage(SurgoPage p) =>
    mockListeningPartOf.containsKey(p) ? MockListeningPage(page: p) : null;

class MockListeningPage extends StatefulWidget {
  const MockListeningPage({super.key, required this.page});
  final SurgoPage page;
  @override
  State<MockListeningPage> createState() => _MockListeningPageState();
}

class _MockListeningPageState extends State<MockListeningPage> {
  MockListeningController? c;
  Timer? timer; // shared 30:00 exam clock (startMockTimer)
  Timer? review; // Part 4 submit -> 118s review window (mq4Timer)
  int reviewLeft = 0;
  bool reviewing = false;
  /// 笔记输入框 —— 每秒计时 setState 会重建本页，需显式持有内容。
  final note = TextEditingController();

  /// 可拖拽题目面板的高度状态（与听力日常训练同一套）。
  double? sheetHeight;
  double dragStartY = 0, dragStartHeight = 0;

  int get partNo => mockListeningPartOf[widget.page]!;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    MockListeningData.load().then((d) {
      if (!mounted) return;
      setState(() => c = MockListeningController(app, d, partNo));
      // startMockTimer: Part 1 resets; Parts 2–4 retain the shared clock.
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final expired = c!.tick();
        setState(() {});
        if (expired) {
          timer?.cancel();
          review?.cancel();
          _mark();
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    review?.cancel();
    note.dispose();
    super.dispose();
  }

  String clock(int sec) {
    sec = sec < 0 ? 0 : sec;
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _mark() {
    if (!mounted) return;
    // H5 replaces modal.innerHTML. Do not stack a marking dialog above a
    // still-open exit/end dialog when either countdown expires.
    final pageRoute = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == pageRoute);
    showMarking(
        context, SurgoPage.listeningFeedback, c!.data.markLabel(partNo));
  }

  // openEndExamSheet(): confirm then openMarkSheet('listeningFeedback',mockMarkLbl()).
  void _endExam() {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => Dialog(
        shape:
            const RoundedRectangleBorder(borderRadius: SurgoRadius.dialogAll),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/otter_study.png',
                width: 110, height: 110),
            const SizedBox(height: 14),
            const T('结束考试', style: SurgoText.sheetTitle),
            const SizedBox(height: 10),
            const T('确定要现在结束考试吗？结束后将无法返回。',
                textAlign: TextAlign.center, style: SurgoText.cardDesc),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: SurgoButton('返回',
                      primary: false, onTap: () => Navigator.pop(ctx))),
              const SizedBox(width: 10),
              Expanded(
                  child: SurgoButton('结束考试', onTap: () {
                Navigator.pop(ctx);
                _mark();
              })),
            ]),
          ]),
        ),
      ),
    );
  }

  // submitMockPart4(): mark tip done, run 01:58 review countdown, then auto-mark.
  void _submitPart4() {
    review
        ?.cancel(); // Source repeat-submit replaces the interval and resets 118s.
    setState(() {
      reviewing = true;
      reviewLeft = c!.data.reviewSec;
    });
    review = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => reviewLeft--);
      if (reviewLeft < 0) {
        review?.cancel();
        _mark();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final x = c;
    if (x == null) return const Center(child: CircularProgressIndicator());
    final m = x.meta;
    final groups = m['groups'] as List;
    final zh = x.app.lang == UiLang.zh;
    // 用户 2026-09-24：模拟考版式改成与听力日常训练一致 ——
    // 顶部计时 + home，上半区标签/标题/说明/音频卡，题目放可拖拽面板。
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
                      clock: clock(x.left),
                      over: x.left <= 0,
                      homeKey: const ValueKey('mock-listening-home'),
                      clockKey: const ValueKey('mock-listening-clock'),
                      onHome: () => showExamExit(context),
                      label: '考试倒计时')),
              Positioned(
                  left: 0,
                  right: 0,
                  top: contentTop,
                  height: (box.maxHeight - height - contentTop)
                      .clamp(0.0, box.maxHeight),
                  child: SingleChildScrollView(
                      key: const ValueKey('mock-listening-brief-scroll'),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 6),
                            SessionTags(
                                mock: true,
                                subject:
                                    '${x.app.examType.label} ${zh ? '听力' : 'Listening'}',
                                part: '第 $partNo 部分',
                                padding: EdgeInsets.zero),
                            const SizedBox(height: 10),
                            T('${x.app.examType.label} ${zh ? '听力' : 'Listening'} · ${zh ? '模拟考' : 'Mock Exam'}',
                                style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontFamilyFallback:
                                        SurgoFontFamily.fallback,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    height: 1.45,
                                    letterSpacing: -.3,
                                    color: Colors.black)),
                            const SizedBox(height: 7),
                            T('四个部分共 40 题 · 录音仅播放一次',
                                style: TextStyle(
                                    fontSize: 14,
                                    height: zh ? 1.65 : 1.5,
                                    color: SurgoColors.muted,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            _audioCard(m),
                            const SizedBox(height: 16),
                            _noteCard(),
                            const SizedBox(height: 6),
                          ]))),
            ])),
            Positioned(
                left: 0,
                right: 0,
                top: (box.maxHeight - height).clamp(contentTop, box.maxHeight),
                height: height,
                child: Container(
                    key: const ValueKey('mock-listening-sheet'),
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
                              key: const ValueKey('mock-listening-sheet-handle'),
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
                                              child: x.done.isEmpty
                                                  ? T('Answered 0 / ${x.dots.length}',
                                                      maxLines: 1,
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
                                                  : Text(
                                                      zh
                                                          ? '已答 ${x.done.length} / ${x.dots.length}'
                                                          : 'Answered ${x.done.length} / ${x.dots.length}',
                                                      maxLines: 1,
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
                                          _navButton(zh),
                                        ])),
                                  ])))),
                      Positioned(
                          left: 0,
                          right: 0,
                          top: topHeight,
                          bottom: 74,
                          child: SingleChildScrollView(
                              key: const ValueKey('mock-listening-questions'),
                              padding:
                                  const EdgeInsets.fromLTRB(22, 8, 22, 28),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (partNo == 4 && reviewing)
                                      _tip(
                                          '第 4 部分结束。你现在有 2 分钟检查全部答案。 (${_mmss(reviewLeft)})',
                                          done: true),
                                    _group(groups[0]),
                                    // 演示用真实数据（tool/demo_export）：真实模考每个
                                    // Part 是一组混排的题（items：有 opts 的是选择题，
                                    // 其余填空），不是原型那种每个 Part 固定两种题型。
                                    if (m['items'] != null)
                                      for (final q in m['items'] as List)
                                        q['opts'] != null
                                            ? _mcQ(x, q)
                                            : _fillRow(x, q, simple: true)
                                    else ...[
                                    ..._bodyTop(x, m),
                                    const SizedBox(height: 24),
                                    _group(groups[1]),
                                    ..._bodyBottom(x, m),
                                    ],
                                  ]))),
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 74,
                          child: ColoredBox(
                              color: const Color(0xfffcf8f5),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 12, 22, 18),
                                  child: Row(children: [
                                    // 结束考试仍由音频卡上的按钮与顶部 home 负责，
                                    // 这里只放推进流程的主按钮（同日常训练底条）。
                                    Expanded(
                                        child: partNo < 4
                                            ? SurgoButton('进入下一部分 →',
                                                onTap: () =>
                                                    x.app.go(_nextPage()))
                                            : SurgoButton('提交 →',
                                                onTap: _submitPart4)),
                                  ])))),
                    ]))),
          ]);
        }));
  }

  SurgoPage _nextPage() => const {
        1: SurgoPage.mockListeningQ2,
        2: SurgoPage.mockListeningQ3,
        3: SurgoPage.mockListeningQ4,
      }[partNo]!;

  String _mmss(int s) {
    s = s < 0 ? 0 : s;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// 题号导航 —— 取代原底部常驻答题卡。
  /// 用户 2026-09-24：全站答题卡弹窗统一为阅读那版面板（图 2）。
  /// 只展示作答进度，不改任何作答状态；各部分之间的跳转仍走原有「进入下一部分」，
  /// 所以这里不提供跳题回调（本页只渲染当前部分的 10 道题）。
  void _openNav() {
    final x = c!;
    showAnswerSheet(context,
        first: x.dots.first,
        count: x.dots.length,
        answered: x.done.contains,
        onSubmit: _endExam,
        tileKey: (n) => ValueKey('mock-dot-$n'),
        closeKey: const ValueKey('mock-listening-nav-close'),
        submitKey: const ValueKey('mock-listening-nav-submit'));
  }

  // ---- audio state card (fixed pct / time from source per part) ----
  // 用户 2026-09-24：卡片样式对齐日常训练的白卡（白底 / 圆角22 / 软阴影）。
  // 下边距交给外层统一的 SizedBox(16)，本卡不再自带 margin。
  Widget _audioCard(Map m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x143c321e),
                  blurRadius: 18,
                  offset: Offset(0, 8))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SvgPicture.string(
                '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round"><path d="M6 8a6 6 0 0 1 12 0c0 3-2 4-2 7a4 4 0 0 1-8 0"/><path d="M9 20a3 3 0 0 0 6 0"/></svg>',
                width: 26,
                height: 26),
            const SizedBox(width: 12),
            Flexible(
                child: SourceText(m['audioTitle'] as String,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 15, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (m['audioBarPct'] as num) / 100,
                        color: SurgoColors.yellow,
                        backgroundColor: const Color(0xffefe9dd)))),
          ]),
          const SizedBox(height: 12),
          Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SourceText(m['audioTime'] as String,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xff8a8378))),
                OutlinedButton.icon(
                    onPressed: _endExam,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: SurgoColors.ink,
                        side: const BorderSide(
                            color: SurgoColors.yellow, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9)),
                    icon: SvgPicture.string(
                        '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round"><path d="M5 21V4h11l-1.5 4L16 12H5"/></svg>',
                        width: 15,
                        height: 15),
                    label: const SourceText('结束考试',
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
        ]),
      );

  /// 笔记卡 —— 用户 2026-09-24：位置移到音频卡下方、题目卡上方。
  /// 用显式 controller 保住已输入内容：本页计时每秒 setState 重建。
  Widget _noteCard() => SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('笔记', style: SurgoText.cardTitle),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('mock-listening-note'),
            controller: note,
            maxLines: 3,
            // 用户 2026-09-24：去掉描边，改成一层浅底色。
            decoration: const InputDecoration(
                hintText: '边听边记笔记',
                filled: true,
                fillColor: Color(0xfffaf7f0),
                hoverColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none)),
          ),
        ]),
      );

  Widget _tip(String text, {bool done = false}) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
            color: done ? const Color(0xffeaf6e6) : SurgoColors.yellowTint,
            border: Border.all(
                color:
                    done ? const Color(0xffbfe0b2) : const Color(0xfff0e2b4)),
            borderRadius: BorderRadius.circular(12)),
        child: SourceText(text,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color:
                    done ? const Color(0xff2f7a2a) : const Color(0xffb8860b))),
      );

  /// 题组标题 —— 用户 2026-09-24：版式对齐听力日常训练的 `_group`
  /// （15px 无下划线 + 13px 说明），不再用 17px 下划线。
  Widget _group(dynamic g) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SourceText(g['label'] as String,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.4)),
          SourceText(g['sub'] as String,
              style: const TextStyle(
                  fontSize: 13, height: 1.55, color: SurgoColors.muted)),
        ]),
      );

  /// 题号入口 —— 尺寸与听力日常训练的同款按钮逐值一致
  /// （vertical 6 + 中文行高 20/14）；改大会把固定高度的把手条撑溢出。
  Widget _navButton(bool zh) => GestureDetector(
      key: const ValueKey('mock-listening-nav-open'),
      onTap: _openNav,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0x80ffffff),
              borderRadius: BorderRadius.circular(10)),
          child: T('☰ 题号',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 14,
                  height: zh ? 20 / 14 : 16 / 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xffe0a000)))));

  // ---------- upper block per part ----------
  List<Widget> _bodyTop(MockListeningController x, Map m) {
    switch (partNo) {
      case 1:
        return [for (final q in m['mc'] as List) _mcQ(x, q)];
      case 2:
        return [_missingPersonTable(x, m)];
      case 3:
        return [
          if (m['matchBox'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in m['matchBox'] as List)
                      SourceText(l as String, style: SurgoText.cardDesc)
                  ]),
            ),
          for (final q in m['match'] as List)
            _matchQ(x, q, (m['matchLetters'] as List).cast<String>()),
        ];
      case 4:
        return [
          SourceText(m['notesTitle'] as String, style: SurgoText.cardTitle),
          for (final q in m['notes'] as List) _fillRow(x, q),
        ];
    }
    return const [];
  }

  // ---------- lower block per part ----------
  List<Widget> _bodyBottom(MockListeningController x, Map m) {
    switch (partNo) {
      case 1:
        return [
          for (final q in m['fills'] as List) _fillRow(x, q, simple: true)
        ];
      case 2:
        return [
          SvgPicture.string(x.data.mapSvg, height: 220),
          const SizedBox(height: 10),
          for (final q in m['mapQs'] as List) _mapRow(x, q),
        ];
      case 3:
        return [for (final q in m['mc'] as List) _mcQ(x, q)];
      case 4:
        return [for (final q in m['sents'] as List) _fillRow(x, q)];
    }
    return const [];
  }

  // single choice A/B/C
  Widget _mcQ(MockListeningController x, dynamic q) {
    final n = int.parse('${q['n']}');
    final opts = (q['opts'] as List).cast<String>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SourceText('$n  ${q['q']}',
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 15, fontWeight: FontWeight.w700, height: 1.6)),
        const SizedBox(height: 10),
        for (var i = 0; i < opts.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == opts.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => x.pickMc(n, i)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color:
                        x.ans[n] == i ? SurgoColors.yellowTint : Colors.white,
                    border: Border.all(
                        color: x.ans[n] == i
                            ? SurgoColors.yellow
                            : SurgoColors.line),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  // 用户 2026-09-24：考试页选项改成与日常训练同款的 32px 字母徐标。
                  Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: x.ans[n] == i
                              ? SurgoColors.yellow
                              : Colors.white,
                          border: Border.all(
                              color: x.ans[n] == i
                                  ? SurgoColors.yellow
                                  : SurgoColors.line),
                          borderRadius: BorderRadius.circular(9)),
                      child: SourceText(String.fromCharCode(65 + i),
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontFamilyFallback: SurgoFontFamily.fallback,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                              color: x.ans[n] == i
                                  ? Colors.white
                                  : SurgoColors.muted))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: SourceText(opts[i],
                          style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.4,
                              color: Color(0xff3a352c)))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  // matching A-F buttons
  Widget _matchQ(MockListeningController x, dynamic q, List<String> letters) {
    final n = int.parse('${q['n']}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SourceText('$n  ${q['q']}',
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 15, fontWeight: FontWeight.w700, height: 1.6)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final letter in letters)
            InkWell(
              onTap: () => setState(() => x.pickMatch(n, letter)),
              child: Container(
                width: 40,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: x.ans[n] == letter ? SurgoColors.yellow : Colors.white,
                  border: Border.all(color: SurgoColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SourceText(letter),
              ),
            ),
        ]),
      ]),
    );
  }

  // fill-in question (parts 1 fills / 4 notes+sents)
  Widget _fillRow(MockListeningController x, dynamic q, {bool simple = false}) {
    final n = int.parse('${q['n']}');
    final head = simple
        ? (q['q'] as String)
        : (q['head'] as String? ?? q['q'] as String);
    final tail = q['tail'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SourceText('$n  $head',
            style: const TextStyle(fontSize: 15, height: 1.6)),
        TextFormField(
          onChanged: (v) => setState(() => x.fill(n, v)),
          decoration: const InputDecoration(border: UnderlineInputBorder()),
        ),
        if (tail.isNotEmpty) SourceText(tail, style: SurgoText.cardDesc),
      ]),
    );
  }

  // Part 2 MISSING PERSON table: key -> value cell OR numbered gap.
  Widget _missingPersonTable(MockListeningController x, Map m) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SourceText(m['tableTitle'] as String, style: SurgoText.cardTitle),
      const SizedBox(height: 8),
      for (final r in m['table'] as List)
        SurgoCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
                width: 90,
                child:
                    SourceText(r['key'] as String, style: SurgoText.rowLabel)),
            const SizedBox(width: 10),
            Expanded(
              child: (r['n'] as int) != 0
                  ? Row(children: [
                      SourceText('${r['n']}  ',
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: TextFormField(
                          onChanged: (v) =>
                              setState(() => x.fill(r['n'] as int, v)),
                          decoration: const InputDecoration(
                              border: UnderlineInputBorder()),
                        ),
                      ),
                    ])
                  : SourceText(r['val'] as String, style: SurgoText.cardDesc),
            ),
          ]),
        ),
    ]);
  }

  // Part 2 map label rows: number + label + single-letter input.
  Widget _mapRow(MockListeningController x, dynamic q) {
    final n = q['n'] as int;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(
            width: 28,
            child: SourceText('$n',
                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.w700))),
        Expanded(child: SourceText(q['label'] as String)),
        SizedBox(
          width: 56,
          child: TextFormField(
            textAlign: TextAlign.center,
            inputFormatters: [LengthLimitingTextInputFormatter(1)],
            onChanged: (v) => setState(() => x.fill(n, v)),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ]),
    );
  }
}
