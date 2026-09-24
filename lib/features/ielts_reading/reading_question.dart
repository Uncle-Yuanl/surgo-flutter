import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'reading_controller.dart';

class ReadingQuestion extends StatelessWidget {
  const ReadingQuestion(
      {super.key,
      required this.x,
      required this.itemKey,
      required this.input,
      required this.focus,
      required this.pick,
      required this.jump,
      required this.commit,
      required this.submit,
      required this.changed,
      required this.translated});
  final ReadingController x;
  final GlobalKey itemKey;
  final TextEditingController input;
  final FocusNode focus;
  final ValueChanged<String> pick, commit;
  final ValueChanged<int> jump;
  final VoidCallback submit, changed;
  // Source refreshReadBody/refreshTypeBody calls shrinkFonts, not applyLang.
  final bool translated;
  Widget text(String s, TextStyle style) =>
      translated ? T(s, style: style) : Text(s, style: style);
  static const questionStyle = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
      fontSize: 15,
      height: 1.55,
      fontWeight: FontWeight.w700,
      color: SurgoColors.ink);
  @override
  Widget build(BuildContext context) {
    final gap = x.options.isEmpty;
    final inline = gap &&
        (!x.single ||
            (x.type['boxInput'] != true && x.type['diagramSvg'] == null));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (x.single && x.type['groupLabel'] != null) ...[
        text(x.type['groupLabel'],
            const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        text(
            x.type['instr'],
            const TextStyle(
                fontSize: 11, height: 1.5, color: SurgoColors.muted)),
        const SizedBox(height: 16),
      ],
      Column(
          key: itemKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (x.single && x.type['summaryText'] != null)
              Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: const Color(0xfff5f1e9),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (x.type['summaryTitle'] != null) ...[
                          text(
                              x.type['summaryTitle'],
                              const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 11,
                                  letterSpacing: .5,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                        ],
                        _summaryText(),
                      ])),
            if (x.single && x.type['diagramSvg'] != null)
              Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xfff5f1e9),
                      borderRadius: BorderRadius.circular(12)),
                  child: SvgPicture.string(x.type['diagramSvg'],
                      height: 140, fit: BoxFit.contain)),
            if (inline)
              Text.rich(
                  TextSpan(children: [
                    TextSpan(text: x.single ? x.item[0] : ('${x.question} ')),
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _input(true)),
                    if (x.single) TextSpan(text: x.item[1]),
                  ]),
                  style: questionStyle.copyWith(height: x.single ? 1.9 : 1.8))
            else
              text(
                  x.question, questionStyle.copyWith(height: gap ? 1.9 : 1.55)),
            if (!inline) const SizedBox(height: 22),
            if (x.single && x.type['optionLabels'] != null)
              Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xfff5f1e9),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in x.type['optionLabels'])
                          text(s, const TextStyle(fontSize: 10, height: 1.7))
                      ])),
            if (x.kind == 'match')
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (var i = 0; i < x.options.length; i++) _option(i)
              ])
            else if (x.options.isNotEmpty)
              for (var i = 0; i < x.options.length; i++) ...[
                _option(i),
                if (i < x.options.length - 1) const SizedBox(height: 14),
              ],
            if (gap && !inline)
              Align(alignment: Alignment.centerLeft, child: _input(false)),
          ]),
      const SizedBox(height: 26), // Adjacent rq-item26/rq-btns16 collapse.
      LayoutBuilder(builder: (_, box) {
        // Both CSS flex bases include 28px padding; BACK adds 2px border.
        final left = (box.maxWidth - 12 - 58) / 2.6 + 30;
        return IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              width: left,
              child: _nav('BACK', false,
                  x.index == 0 ? null : () => jump(x.index - 1))),
          const SizedBox(width: 12),
          Expanded(
              child: _nav(x.last ? 'SUBMIT' : 'NEXT', true,
                  x.last ? submit : () => jump(x.index + 1))),
        ]));
      }),
    ]);
  }

  Widget _summaryText() {
    final s = x.type['summaryText'] as String;
    final spans = <InlineSpan>[];
    int start = 0;
    for (final m in RegExp(r'\(\d+\)\s*_+').allMatches(s)) {
      spans.add(TextSpan(text: s.substring(start, m.start)));
      spans.add(TextSpan(
          text: m[0],
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: SurgoColors.goldInk)));
      start = m.end;
    }
    spans.add(TextSpan(text: s.substring(start)));
    return Text.rich(TextSpan(children: spans),
        style: const TextStyle(fontSize: 12, height: 1.75));
  }

  Widget _option(int i) {
    final s = x.options[i],
        selected = x.selected == s,
        mc = x.kind == 'mc',
        match = x.kind == 'match';
    final bg = selected
        ? (mc
            ? const Color(0xfffffdf4)
            : match
                ? SurgoColors.yellow
                : SurgoColors.yellowTint)
        : Colors.white;
    return GestureDetector(
        key: ValueKey('reading-option-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => pick(s),
        child: Container(
            constraints: match ? const BoxConstraints(minWidth: 64) : null,
            height: match ? 56 : null,
            padding: EdgeInsets.symmetric(
                horizontal: match ? 20 : 16,
                vertical: match
                    ? 0
                    : mc
                        ? 10
                        : 16),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(match ? 16 : 14),
                border: Border.all(
                    color: selected ? SurgoColors.yellow : SurgoColors.line)),
            child: match
                ? Center(
                    widthFactor: 1,
                    child: text(
                        s,
                        TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : SurgoColors.ink)))
                : Row(children: [
                    if (mc) ...[
                      Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color:
                                  selected ? SurgoColors.yellow : Colors.white,
                              border: Border.all(
                                  color: selected
                                      ? SurgoColors.yellow
                                      : SurgoColors.line),
                              borderRadius: BorderRadius.circular(9)),
                          child: Text(String.fromCharCode(65 + i),
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : SurgoColors.muted))),
                      const SizedBox(width: 14)
                    ],
                    Expanded(
                        child: text(
                            s.replaceFirst(RegExp(r'^[A-Z]\)\s*'), '').trim(),
                            TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 14.5,
                                height: mc ? 1.4 : null,
                                fontWeight:
                                    mc ? FontWeight.w600 : FontWeight.w700,
                                color: !mc && selected
                                    ? SurgoColors.goldInk
                                    : SurgoColors.ink))),
                  ])));
  }

  Widget _input(bool inline) => AnimatedBuilder(
      animation: focus,
      builder: (_, __) => Container(
          key: const ValueKey('reading-input'),
          width: inline ? 90 : 200,
          height: inline ? 20 : 37,
          padding: EdgeInsets.symmetric(
              horizontal: inline ? 6 : 13, vertical: inline ? 2 : 10),
          decoration: BoxDecoration(
              color: inline ? Colors.transparent : Colors.white,
              border: inline
                  ? const Border(bottom: BorderSide(color: SurgoColors.yellow))
                  : Border.all(
                      color: focus.hasFocus
                          ? SurgoColors.yellow
                          : SurgoColors.line),
              borderRadius: inline ? null : BorderRadius.circular(12),
              boxShadow: inline
                  ? null
                  : const [
                      BoxShadow(
                          color: Color(0x0d3c3214),
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ]),
          child: TextField(
              controller: input,
              focusNode: focus,
              onChanged: (_) => changed(),
              onSubmitted: commit,
              style: TextStyle(
                  fontFamily: 'VioletSans',
                  fontSize: inline ? 15 : 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: SurgoColors.goldInk),
              decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: inline ? '______' : '',
                  hintStyle: const TextStyle(color: Color(0xffc2bbae)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none))));
  Widget _nav(String label, bool primary, VoidCallback? tap) => Opacity(
      opacity: tap == null ? .4 : 1,
      child: GestureDetector(
          key: ValueKey('reading-${primary ? 'next' : 'previous'}'),
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: primary ? SurgoColors.yellow : Colors.white,
                  border: primary ? null : Border.all(color: SurgoColors.line),
                  borderRadius: BorderRadius.circular(14)),
              child: translated
                  ? T(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 16,
                          height: x.state.lang == UiLang.zh ? 22 / 16 : 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                          color: primary
                              ? SurgoColors.onYellowStrong
                              : SurgoColors.muted))
                  : Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                          color: primary
                              ? SurgoColors.onYellowStrong
                              : SurgoColors.muted)))));
}
