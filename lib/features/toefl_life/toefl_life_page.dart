import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/loop_video.dart';
import 'toefl_life_logic.dart';

// ---------------------------------------------------------------------------
// 视觉常量 —— 从 index.html 对应 class 逐条抄。
// tr1-* / tr2-* / rq-* / tf-clock* / tfdl-* 见千行区 CSS。
// ---------------------------------------------------------------------------

const _tr1PageBg = Color(0xFFFDFAF5); // .tr1-page background:#fdfaf5
const _clockBg = Color(0xFF1C1A17); // .tf-clock background
const _clockWarn = Color(0xFFC0392B); // .tf-clock-warn background
const _yellowInk = Color(0xFF3A2E00); // 黄底深棕字

const _adInk = Color(0xFF3A352C); // .tr2-ad color
const _ttlInk = Color(0xFF1C1A17); // .tr2-ttl color
const _qInk = Color(0xFF1C1A17); // .tr2-q color
const _otxInk = Color(0xFF3A352C); // .tr2-otx color
const _optOnBg = Color(0xFFFFFAEA); // .tr2-opt.on background
const _badgeInk = Color(0xFF8A8378); // .mrq-badge color（未选）
const _sheetBg = Color(0xFFFCF8F5); // .rq-sheet background
const _sheetTopBg = Color(0xFFFDECB0); // .rq-top background
const _gripColor = Color(0x4D3A2E00); // .rq-grip rgba(58,46,0,.30)
const _noBg = Color(0xFF6A6357); // .tr2-no color
const _hintInk = Color(0xFFA08419); // .mq-sheet-hint color
const _grpInk = Color(0xFF1C1A17); // .tr2-grp color
const _grpNInk = Color(0xFF8A8378); // .tr2-grp-n color
const _cellDoneBg = Color(0xFFFDEAA0); // .tr2-cell.done background
const _cellDoneLine = Color(0xFFE8C766); // .tr2-cell.done border
const _cellDoneInk = Color(0xFF3A2E00); // .tr2-cell.done color
const _cellInk = Color(0xFF8A8378); // .tr2-cell 默认字色
const _overtipBg = Color(0xFFFDECEF); // .tfdl-overtip background
const _overtipInk = Color(0xFFD2547A); // .tfdl-overtip color
const _prevInk = Color(0xFF3A3630); // .tr1-prev color

/// tfDailyLife 页面。Body 自然高度 + 外层 shell 负责纵向滚动，因此这里返回
/// Column（不自带 Scrollable），对应 `.read-scroll` 行为。
class TfDailyLifeView extends StatefulWidget {
  const TfDailyLifeView({super.key, required this.content, this.academic=false});
  final TfDlContent content;
  final bool academic;

  @override
  State<TfDailyLifeView> createState() => _TfDailyLifeViewState();
}

class _TfDailyLifeViewState extends State<TfDailyLifeView> {
  late final TfDlController _c;
  Timer? _timer;
  bool _timeupShown = false;
  bool _timeupOpen = false;

  @override
  void initState() {
    super.initState();
    // 复用 session 里的 controller，保证跨页/重建不丢作答（原型 tfDlVals 全局）。
    final app = context.read<AppState>();
    final key=widget.academic?'tfDaController':'tfDlController';
    _c = app.session[key] as TfDlController? ??
        (app.session[key] = TfDlController(widget.content)..start());
    _startFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 对应 tfDlStartFlow()：每秒 tick。到时首次弹「时间到」。
  void _startFlow() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final alert = _c.tick();
      setState(() {});
      if (alert && !_timeupShown) {
        _timeupShown = true;
        _openTimeup();
      }
    });
  }

  // 对应 tfDlPick(i)：记录选项，即时刷新已作答计数与选中态。
  void _pick(int i) {
    setState(() => _c.pick(i));
  }

  // 对应 tfDlPrev()：上一题，不重置计时。
  void _prev() {
    if (!_c.canPrev) return;
    setState(() => _c.prev());
  }

  // 对应 tfDlJump(i)：跳到答题卡指定题，不重置计时。
  void _jump(int i) {
    setState(() => _c.jump(i));
  }

  // 对应 tfDlNext()：最后一题进入批改，否则下一题并重启计时。
  void _next() {
    final app = context.read<AppState>();
    if (_c.isLast) {
      _timer?.cancel();
      _closeTimeup();
      _openMarkSheet(app);
      return;
    }
    _closeTimeup();
    setState(() {
      _c.next();
      _timeupShown = false;
    });
    _startFlow();
  }

  // 对应 openMarkSheet('tfDlFb','正在批改日常训练 · 生活阅读')：
  // 2 秒进度弹窗，满 100% 后 go('tfDlFb')。
  void _openMarkSheet(AppState app) {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: SurgoColors.mask,
      builder: (_) => _MarkSheet(
        label:
            widget.academic?'正在批改日常训练 · 学术阅读':'正在批改日常训练 · 生活阅读',
        onDone: () {
          Navigator.of(context).pop();
          app.go(widget.academic?SurgoPage.tfDaFb:SurgoPage.tfDlFb);
        },
        onHome: () {
          Navigator.of(context).pop();
          app.go(SurgoPage.ielts);
        },
      ),
    );
  }

  void _openTimeup() {
    _timeupOpen = true;
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: SurgoColors.mask,
      builder: (_) => _TimeupDialog(onContinue: () {
        _timeupOpen = false;
        Navigator.of(context).pop();
      }),
    ).then((_) => _timeupOpen = false);
  }

  void _closeTimeup() {
    // 对应 closeTfDlTimeup()：仅当时间到弹窗还开着时关闭它。
    if (_timeupOpen) {
      _timeupOpen = false;
      Navigator.of(context, rootNavigator: false).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _c.current;
    final selected = _c.selected();
    return Container(
      // .tr1-page{background:#fdfaf5}；.read-page padding:8px 14px 0
      // 用户 2026-09-24：答题面板要两边贴边，所以外层不再给左右内边距，
      // 改由顶栏与正文卡各自加 11px（白框比原 14px 各宽 3px，共 6px）。
      color: _tr1PageBg,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // .tr1-top：左 home，中间时钟胶囊，右 kicker（空）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: _TopBar(clockText: _c.clockText(), warn: _c.over),
          ),
          const SizedBox(height: 10),
          // 用户 2026-09-24：做题页左上角三段标题。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: SessionTags(
                mock: false,
                subject: '托福阅读',
                part: widget.academic ? '学术阅读' : '日常阅读'),
          ),
          // .tr1-card.tr2-card：标题 + 原文
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 11),
           child: Container(
            decoration: const BoxDecoration(
              color: SurgoColors.card,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .tr2-ttl
                SourceText(
                  _c.title(),
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _ttlInk,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                // .tr2-ad：原文行，'' → 段间隔
                widget.academic?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  for(final para in _c.srcLines())Padding(padding:const EdgeInsets.only(bottom:14),child:SourceText(para,style:const TextStyle(fontSize:15,height:1.7)))
                ]):_AdBody(lines: _c.srcLines()),
              ],
            ),
          )),
          const SizedBox(height: 10),
          // .rq-sheet.rq-sheet-auto：答题面板（自然高度，非固定比例）
          _QuestionSheet(
            idx: _c.idx,
            total: widget.content.total,
            question: q,
            selected: selected,
            answered: _c.answered(),
            vals: _c.vals,
            showPrev: _c.canPrev,
            nextLabel: _c.nextLabel(),
            over: _c.over,
            overTip: _c.overTip(),
            onPick: _pick,
            onPrev: _prev,
            onNext: _next,
            onJump: _jump,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.clockText, required this.warn});
  final String clockText;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Row(
      children: [
        // TFD_HOME → .mock-home（go('ielts')）
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => app.go(SurgoPage.ielts),
              child: SizedBox(
                width: 26,
                height: 26,
                child: SvgPicture.asset('assets/images/home_icon.svg',
                    width: 20, height: 20),
              ),
            ),
          ),
        ),
        // .tf-clockrow：时钟胶囊居中
        Container(
          decoration: BoxDecoration(
            color: warn ? _clockWarn : _clockBg,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SourceText(
            clockText,
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        // 右侧 .tr1-kicker 占位（空），保持时钟居中
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

// .tr2-ad：原文行，'' 渲染为 .tr2-ad-gap 段落间隔。
class _AdBody extends StatelessWidget {
  const _AdBody({required this.lines});
  final List<String> lines;
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final l in lines) {
      if (l.isEmpty) {
        // .tr2-ad-gap{height:14px}
        children.add(const SizedBox(height: 14));
      } else {
        // .tr2-ad-l white-space:pre-wrap，行文本内容 → Text
        children.add(SourceText(
          l,
          style: const TextStyle(
            fontSize: 14,
            height: 1.85,
            color: _adInk,
          ),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// .rq-sheet.rq-sheet-auto：顶部黄条 grip + 进度，下方题目/选项/底部/答题卡。
class _QuestionSheet extends StatelessWidget {
  const _QuestionSheet({
    required this.idx,
    required this.total,
    required this.question,
    required this.selected,
    required this.answered,
    required this.vals,
    required this.showPrev,
    required this.nextLabel,
    required this.over,
    required this.overTip,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.onJump,
  });

  final int idx;
  final int total;
  final TfDlQuestion question;
  final int? selected;
  final int answered;
  final Map<int, int> vals;
  final bool showPrev;
  final String nextLabel;
  final bool over;
  final String overTip;
  final void Function(int) onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int) onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x21463214),
            blurRadius: 34,
            offset: Offset(0, -10),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // .rq-top：黄条 + grip + 进度行
          Container(
            decoration: const BoxDecoration(
              color: _sheetTopBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                // .rq-grip
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 5, 0, 3),
                  decoration: BoxDecoration(
                    color: _gripColor,
                    borderRadius: BorderRadius.circular(540),
                  ),
                ),
                // .rq-progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // .tr2-no：第 x / N（含数字，chrome → 过词典）
                      Expanded(child:T(
                        '\u7b2c ${idx + 1} / $total',
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _noBg,
                        ),
                      )),
                      // .mq-sheet-hint：上拉展开 / 下拉收起
                      const Flexible(child:T(
                        '\u4e0a\u62c9\u5c55\u5f00 / \u4e0b\u62c9\u6536\u8d77',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: _hintInk,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // .rq-scroll：题目 + 选项 + 底部 + 答题卡（自然高度，外层 shell 滚）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .tr2-q：题干内容 → Text
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                  child: SourceText(
                    question.q,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.55,
                      color: _qInk,
                    ),
                  ),
                ),
                // .tr2-opts
                for (var i = 0; i < question.opts.length; i++) ...[
                  _OptionButton(
                    letter: 'ABCDEFGH'[i],
                    text: question.opts[i],
                    on: selected == i,
                    onTap: () => onPick(i),
                  ),
                  if (i != question.opts.length - 1) const SizedBox(height: 9),
                ],
                const SizedBox(height: 18),
                // .tr1-foot：上一题（可选）+ 下一段/提交
                _Foot(
                  showPrev: showPrev,
                  nextLabel: nextLabel,
                  onPrev: onPrev,
                  onNext: onNext,
                ),
                const SizedBox(height: 18),
                // .tr2-sheet：答题卡
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: SurgoColors.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // .tr2-grp 答题卡 · 已作答 b / N
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: SourceText.rich(TextSpan(children: [
                          const TextSpan(
                            text: '\u7b54\u9898\u5361 ',
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _grpInk,
                            ),
                          ),
                          TextSpan(
                            text: '\u5df2\u4f5c\u7b54 ',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _grpNInk,
                            ),
                          ),
                          TextSpan(
                            text: '$answered',
                            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _grpNInk,
                            ),
                          ),
                          TextSpan(
                            text: ' / $total',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _grpNInk,
                            ),
                          ),
                        ])),
                      ),
                      // .tr2-cells：题号格子
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (var i = 0; i < total; i++)
                            _Cell(
                              n: i + 1,
                              done: vals.containsKey(i),
                              cur: i == idx,
                              onTap: () => onJump(i),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // .tfdl-overtip：超时后出现
                if (over) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _overtipBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: SourceText(
                      overTip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _overtipInk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// .tr2-opt：字母徽章 + 选项文本，选中态描黄。选项文本是内容 → Text。
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.text,
    required this.on,
    required this.onTap,
  });
  final String letter;
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: on ? _optOnBg : SurgoColors.card,
          border: Border.all(
            color: on ? SurgoColors.yellow : SurgoColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // .tr2-badge
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? SurgoColors.yellow : SurgoColors.card,
                border: Border.all(
                  color: on ? SurgoColors.yellow : SurgoColors.line,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SourceText(
                letter,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: on ? _yellowInk : _badgeInk,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // .tr2-otx：选项文案内容 → Text
            Expanded(
              child: SourceText(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? _ttlInk : _otxInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// .tr2-cell：答题卡格子；done 黄底，cur 描黄环。
class _Cell extends StatelessWidget {
  const _Cell({
    required this.n,
    required this.done,
    required this.cur,
    required this.onTap,
  });
  final int n;
  final bool done;
  final bool cur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? _cellDoneBg : SurgoColors.card,
          border: Border.all(
            color: cur
                ? SurgoColors.yellow
                : (done ? _cellDoneLine : SurgoColors.line),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: cur
              ? const [
                  BoxShadow(color: Color(0x47F5B301), blurRadius: 0, spreadRadius: 2),
                ]
              : null,
        ),
        child: SourceText(
          '$n',
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: done ? _cellDoneInk : _cellInk,
          ),
        ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({
    required this.showPrev,
    required this.nextLabel,
    required this.onPrev,
    required this.onNext,
  });
  final bool showPrev;
  final String nextLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showPrev)
          // .tr1-prev 白底描边
          _PillButton(
            label: '\u4e0a\u4e00\u9898',
            onTap: onPrev,
            filled: false,
          ),
        const Spacer(),
        // .tf-next 黄底
        _PillButton(label: nextLabel, onTap: onNext, filled: true),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: filled ? SurgoColors.yellow : SurgoColors.card,
          borderRadius: BorderRadius.circular(22),
          border: filled ? null : Border.all(color: SurgoColors.line),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: Color(0x4DF5B301),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  )
                ]
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: filled ? 26 : 20,
          vertical: filled ? 12 : 11,
        ),
        child: T(
          label,
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: filled ? 15 : 13,
            fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
            color: filled ? _yellowInk : _prevInk,
          ),
        ),
      ),
    );
  }
}

// 对应 openTfDlTimeup()：timeup.mp4 静音循环 + 标题 + 返回作答。
class _TimeupDialog extends StatelessWidget {
  const _TimeupDialog({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        // .tfdl-dlg{padding:30px 24px 24px}
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
        decoration: BoxDecoration(
          color: SurgoColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SurgoShadow.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // .tfdl-otter 214x214（web 覆盖），此处收敛到弹窗宽度
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 214,
                height: 214,
                child: LoopVideo(asset: 'assets/video/timeup.mp4'),
              ),
            ),
            const SizedBox(height: 12),
            // .tfdl-ttl：已经超时了，你需要加快一点速度（内容 → Text）
            const SourceText(
              '\u5df2\u7ecf\u8d85\u65f6\u4e86\uff0c\u4f60\u9700\u8981\u52a0\u5feb\u4e00\u70b9\u901f\u5ea6',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.5,
                color: SurgoColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            // .tfdw-btn：返回作答
            GestureDetector(
              onTap: onContinue,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SurgoColors.yellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const T(
                  '\u8fd4\u56de\u4f5c\u7b54',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _yellowInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 对应 openMarkSheet()：2 秒进度到 100% 后跳转。
class _MarkSheet extends StatefulWidget {
  const _MarkSheet({
    required this.label,
    required this.onDone,
    required this.onHome,
  });
  final String label;
  final VoidCallback onDone;
  final VoidCallback onHome;

  @override
  State<_MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<_MarkSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _tail;
  int _p = 0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..addListener(() => setState(() => _p = (_progress.value * 100).round()))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tail = Timer(const Duration(milliseconds: 200), () {
            if (mounted) widget.onDone();
          });
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _tail?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SurgoColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SurgoShadow.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset('assets/images/otter_study.png',
                  width: 90, height: 90),
            ),
            const SizedBox(height: 12),
            const T(
              '\u6b63\u5728\u6279\u6539\u4f60\u7684\u4f5c\u6587...',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SurgoColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const T(
              '\u8003\u5b98\u6b63\u6309\u5b98\u65b9\u8bc4\u5206\u6807\u51c6\u9010\u9898\u6253\u5206\uff0c\u8bf7\u7a0d\u5019\u7247\u523b\u3002',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, height: 1.5, color: SurgoColors.muted),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _p / 100.0,
                minHeight: 8,
                backgroundColor: SurgoColors.track,
                valueColor: const AlwaysStoppedAnimation(SurgoColors.yellow),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: T(
                    widget.label,
                    style:
                        const TextStyle(fontSize: 11, color: SurgoColors.muted),
                    maxLines: 1,
                  ),
                ),
                SourceText('$_p%',
                    style: const TextStyle(
                        fontSize: 11, color: SurgoColors.muted)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onHome,
              child: const T(
                '\u8fd4\u56de\u4e3b\u9875\uff0c\u5b8c\u6210\u540e\u901a\u77e5\u6211',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SurgoColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
