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
import 'toefl_words_logic.dart';

// ---------------------------------------------------------------------------
// 视觉常量 —— 从 index.html 对应 class 逐条抄，再套用 shrinkFonts（-2px，下限 10）。
// tr1-* / tf-clock / tffb-* / ra-* / mock-home 见 3.x 千行区 CSS。
// ---------------------------------------------------------------------------

const _tr1PageBg = Color(0xFFFDFAF5); // .tr1-page background:#fdfaf5
const _tr1BodyBg = Color(0xFFFAF7F0); // .tr1-body background:#faf7f0
const _tr1InLine = Color(0xFFCFC6B4); // .tr1-in border-bottom
const _tr1InFocus = SurgoColors.yellow; // 聚焦下划线
const _tr1FilledBg = Color(0xFFFDEAA0); // .tr1-in.filled background
const _tr1FilledLine = Color(0xFFE0A000); // .tr1-in.filled border-bottom
const _tr1Sub = Color(0xFF8A8378); // .tr1-sub color
const _tr1SubB = Color(0xFF3A352C); // .tr1-sub b
const _tr1N = Color(0xFFA89E8C); // .tr1-n
const _clockBg = Color(0xFF1C1A17); // .tf-clock background
const _clockWarn = Color(0xFFC0392B); // .tf-clock-warn background
const _yellowInk = Color(0xFF3A2E00); // 黄底深棕字
const _tr1Track = Color(0xFFEEE8DC); // .tr1-track background

/// tfDailyWords 页面。Body 自然高度 + 外层 shell 负责滚动，因此这里返回
/// 一个 Column（不自带 Scrollable），交给 shell 的 SingleChildScrollView。
class TfDailyWordsView extends StatefulWidget {
  const TfDailyWordsView({super.key, required this.content});
  final TfDwContent content;

  @override
  State<TfDailyWordsView> createState() => _TfDailyWordsViewState();
}

class _TfDailyWordsViewState extends State<TfDailyWordsView> {
  late final TfDwController _c;
  Timer? _timer;
  bool _timeupShown = false;
  // 时间到弹窗是否正开着（对应原型 tfDwTimeupOpen，用于 closeTfDwTimeup）。
  bool _timeupOpen = false;
  // 每个空格一个 controller；key 形如 '0_2'
  final Map<String, TextEditingController> _inputs = {};

  @override
  void initState() {
    super.initState();
    // 复用 session 里的 controller，保证跨页/重建不丢作答（原型 tfDwVals 全局）。
    final app = context.read<AppState>();
    _c = app.session['tfDwController'] as TfDwController? ??
        (app.session['tfDwController'] = TfDwController(widget.content)..start());
    _startFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  // 对应 tfDwStartFlow()：每秒 tick。到时首次弹「时间到」。
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

  TextEditingController _inputFor(int index) {
    final key = '${_c.para}_$index';
    final existing = _inputs[key];
    if (existing != null) return existing;
    final ctrl = TextEditingController(text: _c.valueAt(index));
    _inputs[key] = ctrl;
    return ctrl;
  }

  // 对应 tfDwSet：写值并即时刷新进度/填充态。
  void _onInput(int index, String v) {
    setState(() => _c.setBlank(index, v));
  }

  // 对应 tfDwPrev()：上一段，不重置计时。
  void _prev() {
    if (!_c.canPrev) return;
    setState(() => _c.prev());
  }

  // 对应 tfDwNext()：最后一段进入批改，否则下一段并重启计时。
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

  // 对应 openMarkSheet('tfDwFb', '正在批改日常训练 · 补全单词')：
  // 2 秒进度弹窗，满 100% 后 go('tfDwFb')。
  void _openMarkSheet(AppState app) {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: SurgoColors.mask,
      builder: (_) => _MarkSheet(
        label: '\u6b63\u5728\u6279\u6539\u65e5\u5e38\u8bad\u7ec3 \u00b7 \u8865\u5168\u5355\u8bcd',
        onDone: () {
          Navigator.of(context).pop();
          app.go(SurgoPage.tfDwFb);
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
    // 对应 closeTfDwTimeup()：仅当时间到弹窗还开着时，关闭它。
    if (_timeupOpen) {
      _timeupOpen = false;
      Navigator.of(context, rootNavigator: false).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _c.para < widget.content.paras.length
        ? widget.content.paras[_c.para]
        : const <TfDwToken>[];
    final total = _c.total();
    final done = _c.filled();

    return Container(
      // .tr1-page{background:#fdfaf5}
      color: _tr1PageBg,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // .tr1-top：左 home，中间时钟，右 kicker（空）
          _TopBar(clockText: _c.clockText(), warn: _c.over),
          const SizedBox(height: 10),
          // .tr1-card
          Container(
            decoration: const BoxDecoration(
              color: SurgoColors.card,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  para: _c.para,
                  total: widget.content.total,
                  done: done,
                  totalBlanks: total,
                  pct: _c.pct(),
                ),
                const SizedBox(height: 12),
                // .tr1-ttl（题目内容 → 用 Text，不过词典）
                const T(
                  '\u586b\u5165\u7f3a\u5931\u7684\u5b57\u6bcd\uff0c\u8865\u5168\u6bcf\u4e2a\u5355\u8bcd\u3002',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: SurgoColors.ink,
                  ),
                ),
                const SizedBox(height: 7),
                // .tr1-sub（含 <b>）
                const _Tr1Sub(),
                const SizedBox(height: 16),
                // .tr1-body：内联填空文本
                _Body(
                  tokens: tokens,
                  controllerFor: _inputFor,
                  valueAt: _c.valueAt,
                  onInput: _onInput,
                ),
                const SizedBox(height: 18),
                // .tr1-foot：上一题（可选）+ 下一段/下一部分
                _Foot(
                  showPrev: _c.canPrev,
                  // 词典里没有「下一部分」的英文（只有带箭头的那条），最后一段直接给 [英文, 中文]。
                  nextLabel: _c.isLast
                      ? const ['Next part', '\u4e0b\u4e00\u90e8\u5206']
                      : _c.nextLabel(),
                  onPrev: _prev,
                  onNext: _next,
                ),
              ],
            ),
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
        // TFD_HOME → .mock-home（tr1-page 覆盖为 26px 透明无边框，图标 20px）
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
          // 题目/计时内容 → Text（非 chrome）
          child: SourceText(
            clockText,
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        // 右侧 kicker 占位，保持时钟居中
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.para,
    required this.total,
    required this.done,
    required this.totalBlanks,
    required this.pct,
  });
  final int para;
  final int total;
  final int done;
  final int totalBlanks;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // .tr1-para —— 界面 chrome，过词典（大写由样式承担）
        T(
          'PARAGRAPH ${para + 1} OF $total',
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: SurgoColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        // .tr1-prog：计数 + 进度条（.tr1-hd 内强制 10px）
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: T(
                  // 词典只收了原型第一屏的「0 / 10 已填」，其它数字直接给 [英文, 中文]。
                  ['$done / $totalBlanks filled', '$done / $totalBlanks \u5df2\u586b'],
                  style: const TextStyle(fontSize: 10, color: SurgoColors.muted),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 7),
              // .tr1-track 66x4，圆角3；填充 .tr1-track i 黄色
              Container(
                width: 66,
                height: 4,
                decoration: BoxDecoration(
                  color: _tr1Track,
                  borderRadius: BorderRadius.circular(3),
                ),
                clipBehavior: Clip.hardEdge,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pct / 100.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: SurgoColors.yellow,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tr1Sub extends StatelessWidget {
  const _Tr1Sub();
  @override
  Widget build(BuildContext context) {
    // .tr1-sub{font-size:11.5px→(css)} 含加粗片段。题目说明属内容 → Text.rich。
    const base = TextStyle(fontSize: 11.5, height: 1.6, color: _tr1Sub);
    const bold = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
      fontSize: 11.5,
      height: 1.6,
      color: _tr1SubB,
      fontWeight: FontWeight.w700,
    );
    return const SourceText.rich(
      TextSpan(children: [
        TextSpan(text: '\u5c0f\u6570\u5b57\u8868\u793a', style: base),
        TextSpan(text: '\u7f3a\u5931\u4e86\u51e0\u4e2a\u5b57\u6bcd', style: bold),
        TextSpan(
          text: '\u3002\u70b9\u51fb\u4efb\u610f\u7a7a\u683c\u5373\u53ef\u8df3\u8f6c\u586b\u5199\u3002',
          style: base,
        ),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.tokens,
    required this.controllerFor,
    required this.valueAt,
    required this.onInput,
  });
  final List<TfDwToken> tokens;
  final TextEditingController Function(int index) controllerFor;
  final String Function(int index) valueAt;
  final void Function(int index, String v) onInput;

  @override
  Widget build(BuildContext context) {
    // .tr1-body：暖底圆角内边距，内联 wrap 的文本 + 填空。
    final children = <Widget>[];
    var bi = -1;
    for (final t in tokens) {
      if (!t.isBlank) {
        children.add(_TextChunk(t.text));
      } else {
        bi++;
        final idx = bi;
        children.add(_BlankWidget(
          token: t,
          controller: controllerFor(idx),
          filled: valueAt(idx).trim().isNotEmpty,
          onChanged: (v) => onInput(idx, v),
        ));
      }
    }
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _tr1BodyBg,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        children: children,
      ),
    );
  }
}

// 纯文本片段。题目内容 → Text（.tr1-body font-size:14 line-height:2.5）
class _TextChunk extends StatelessWidget {
  const _TextChunk(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return SourceText(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 2.5,
        color: SurgoColors.ink,
      ),
    );
  }
}

// 一个填空：前缀 + 输入框 + 缺失数小字（sub）+ 后缀。对应 .tr1-w 里的结构。
class _BlankWidget extends StatelessWidget {
  const _BlankWidget({
    required this.token,
    required this.controller,
    required this.filled,
    required this.onChanged,
  });
  final TfDwToken token;
  final TextEditingController controller;
  final bool filled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // size ≈ 字符数；用 ch≈8px 估宽，min-width 24（.tr1-in）
    final w = (token.inputSize * 8.0).clamp(24.0, 999.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        if (token.prefix.isNotEmpty)
          SourceText(token.prefix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SurgoColors.ink,
              )),
        // 输入框
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 24, maxWidth: w + 8),
          child: IntrinsicWidth(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              cursorColor: SurgoColors.yellow,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SurgoColors.ink,
                backgroundColor: filled ? _tr1FilledBg : Colors.transparent,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                filled: filled,
                fillColor: filled ? _tr1FilledBg : Colors.transparent,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: filled ? _tr1FilledLine : _tr1InLine,
                    width: 1.5,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _tr1InFocus, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        // .tr1-n 缺失字母数
        Padding(
          padding: const EdgeInsets.only(left: 1),
          child: SourceText(
            '${token.missing}',
            style: const TextStyle(fontSize: 10, color: _tr1N),
          ),
        ),
        if (token.suffix.isNotEmpty)
          SourceText(token.suffix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SurgoColors.ink,
              )),
      ],
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
  final Object nextLabel; // 字符串或 [英文, 中文]
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
  final Object label; // 字符串或 [英文, 中文]
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
        // 界面按钮文案 → 过词典
        child: T(
          label,
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: filled ? 15 : 13,
            fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
            color: filled ? _yellowInk : const Color(0xFF3A3630),
          ),
        ),
      ),
    );
  }
}

// 对应 openTfDwTimeup()：原 timeup.mp4 静音循环 + 标题 + 继续作答。
class _TimeupDialog extends StatelessWidget {
  const _TimeupDialog({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: SurgoColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SurgoShadow.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const LoopVideo(asset:'assets/video/timeup.mp4'),
            ),
            const SizedBox(height: 14),
            // 内容文案 → Text
            const SourceText(
              '\u65f6\u95f4\u5230\uff01',
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: SurgoColors.ink,
              ),
            ),
            const SizedBox(height: 16),
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
                  '\u7ee7\u7eed\u4f5c\u7b54',
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

class _MarkSheetState extends State<_MarkSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _tail;
  int _p = 0;

  @override
  void initState() {
    super.initState();
    _progress=AnimationController(vsync:this,duration:const Duration(milliseconds:2000))
      ..addListener(()=>setState(()=>_p=(_progress.value*100).round()))
      ..addStatusListener((status){if(status==AnimationStatus.completed){
        _tail=Timer(const Duration(milliseconds:200),(){if(mounted)widget.onDone();});
      }})
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
            // gs-ttl 用「作文」分支不适用；补全单词属阅读答卷范畴，但原型 openMarkSheet
            // 传入的 lbl 含「补全单词」→ 落到默认「作文」分支。此处照文案含 chrome，过词典。
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
              style: TextStyle(fontSize: 12, height: 1.5, color: SurgoColors.muted),
            ),
            const SizedBox(height: 14),
            // gs-bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _p / 100.0,
                minHeight: 8,
                backgroundColor: _tr1Track,
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
                    style: const TextStyle(fontSize: 11, color: SurgoColors.muted),
                    maxLines: 1,
                  ),
                ),
                SourceText('$_p%',
                    style: const TextStyle(fontSize: 11, color: SurgoColors.muted)),
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
