import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';

const wordMuted = TextStyle(fontSize: 11, color: Color(0xffa99a82));
const wordBody =
    TextStyle(fontSize: 12, height: 1.55, color: Color(0xff5a544b));
const wordSection = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xff2a2620));
Widget wordIcon(String name, {double size = 18}) {
  const paths = {
    'speaker':
        '<path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>',
    'info': '<circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v4h1"/>',
    'link':
        '<path d="M10 13a5 5 0 0 0 7 0l2-2a5 5 0 0 0-7-7l-1 1"/><path d="M14 11a5 5 0 0 0-7 0l-2 2a5 5 0 0 0 7 7l1-1"/>',
    'ban': '<circle cx="12" cy="12" r="9"/><path d="M5 5l14 14"/>',
    'family': '<path d="M4 20V8l8-4 8 4v12"/><path d="M9 20v-6h6v6"/>',
    'speak':
        '<path d="M8 10a4 4 0 1 1 8 0v3a4 4 0 0 1-8 0z"/><path d="M4 13a8 8 0 0 0 16 0"/>',
    'star':
        '<path d="M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9 6.8 19.2l1-5.8L3.5 9.2l5.9-.9z"/>',
  };
  final stroke = name == 'star'
      ? '#f2b705'
      : name == 'ban'
          ? '#9a948a'
          : '#c99a1e';
  return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="${name == 'star' ? stroke : 'none'}" stroke="$stroke" stroke-width="${name == 'star' ? 1 : name == 'speaker' ? 1.9 : 1.8}" stroke-linecap="round" stroke-linejoin="round">${paths[name]}</svg>',
      key: ValueKey('word-icon-$name'),
      width: size,
      height: size);
}

class WordChips extends StatelessWidget {
  const WordChips({super.key, required this.items, this.muted});
  final List<String> items;
  final String? muted;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 9, runSpacing: 9, children: [
        for (final item in muted == null ? items : [muted!])
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xfff1efe9),
                  borderRadius: BorderRadius.circular(9)),
              child: SourceText(item,
                  style: TextStyle(
                      fontSize: 11,
                      color: muted == null
                          ? const Color(0xff4a453d)
                          : const Color(0xffa99a82)))),
      ]);
}

class WordPanel extends StatelessWidget {
  const WordPanel(
      {super.key,
      required this.title,
      required this.icon,
      required this.child,
      this.highlight = false,
      this.chips = false});
  final String title, icon;
  final Widget child;
  final bool highlight, chips;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
          color: highlight ? const Color(0xfffdf6e3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: highlight ? const Color(0xfff0e2b4) : SurgoColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          wordIcon(icon),
          const SizedBox(width: 7),
          Flexible(child: T(title, style: wordSection))
        ]),
        SizedBox(height: chips ? 12 : 10),
        child,
      ]));
}

class WordHeader extends StatelessWidget {
  const WordHeader(
      {super.key,
      required this.word,
      required this.pos,
      required this.learn,
      required this.book});
  final String word, pos, learn, book;
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    final left = Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
          child: SourceText(word,
              key: const ValueKey('word-title'),
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 32,
                  height: (zh ? 45 : 32) / 32,
                  letterSpacing: .3,
                  fontWeight: FontWeight.w900))),
      const SizedBox(width: 10),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xfff1efe9),
              borderRadius: BorderRadius.circular(8)),
          child: SourceText(pos,
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff8a8378)))),
    ]);
    final right = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xfffdf3d4),
              borderRadius: BorderRadius.circular(9)),
          child: T(learn,
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xffb8860b)))),
      const SizedBox(width: 14),
      wordIcon('star', size: 17),
      const SizedBox(width: 5),
      Flexible(
          child: T(book,
              key: const ValueKey('word-remove-label'),
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff3a3630)))),
    ]);
    // At 390px source CJK fits; EN right group wraps then aligns to right.
    if (!zh || MediaQuery.textScalerOf(context).scale(1) > 1.05) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(alignment: Alignment.centerLeft, child: left),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: right)
      ]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: left),
      const SizedBox(width: 10),
      Flexible(child: right)
    ]);
  }
}
