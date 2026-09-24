import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'vocab_home_page.dart' show VocabTier;

const vhShadow = [
  BoxShadow(color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
];
const vhMuted = Color(0xffa99a82);
Widget vhIcon(String kind, double size) {
  const paths = {
    'bookmark':
        '<path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1z"/>',
    'mic':
        '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M6 11a6 6 0 0 0 12 0M12 17v4"/>',
    'book':
        '<path d="M4 5a2 2 0 0 1 2-2h6v16H6a2 2 0 0 0-2 2zM20 5a2 2 0 0 0-2-2h-6v16h6a2 2 0 0 1 2 2z"/>',
  };
  return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths[kind]}</svg>',
      width: size,
      height: size);
}

class VhCard extends StatelessWidget {
  const VhCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      this.radius = 16});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius), boxShadow: vhShadow),
      child: Material(
          color: Colors.white,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
              onTap: onTap,
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child))));
}

class VhStats extends StatelessWidget {
  const VhStats({super.key, required this.review});
  final bool review;
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    final ns = review ? ['86', '18', '48'] : ['48', '86', '6'];
    final labels = review ? ['已掌握', '学习中/需巩固', '需学习'] : ['剩余单词', '已掌握', '连续天数'];
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0 && !review) const SizedBox(width: 8),
        Expanded(
            child: Column(children: [
          Text(ns[i],
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: review ? 18 : 22,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: review
                      ? [
                          const Color(0xff4f8a1f),
                          const Color(0xffc99a1e),
                          const Color(0xff9a948a)
                        ][i]
                      : SurgoColors.ink)),
          const SizedBox(height: 3),
          T(labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  height: (zh ? 14 : 10) / 10,
                  color: review ? vhMuted : const Color(0xffa08a4a))),
        ])),
      ]
    ]);
  }
}

class VhMine extends StatelessWidget {
  const VhMine({super.key, required this.pron});
  final bool pron;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    return VhCard(
        key: ValueKey(pron ? 'vh-pron' : 'vh-book'),
        onTap: () => app.go(pron ? SurgoPage.vocabPron : SurgoPage.vocabBook),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: SurgoColors.yellowTint,
                  borderRadius: BorderRadius.circular(12)),
              child: vhIcon(pron ? 'mic' : 'bookmark', 22)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                T(pron ? '我的发音本' : '我的单词本',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 14,
                        height: (zh ? 20 : 14) / 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                T(pron ? '0 个单词待复习' : '已收藏 12 词',
                    style: TextStyle(
                        fontSize: 10.5,
                        height: (zh ? 15 : 11) / 10.5,
                        color: vhMuted)),
              ])),
          const Text('›',
              style:
                  TextStyle(fontSize: 20, height: 1, color: Color(0xffc0b8a8))),
        ]));
  }
}

class VhTier extends StatelessWidget {
  const VhTier({super.key, required this.tier});
  final VocabTier tier;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    return VhCard(
        key: ValueKey('vh-${tier.route.name}'),
        onTap: () => app.go(tier.route),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: SurgoColors.yellowTint,
                      borderRadius: BorderRadius.circular(11)),
                  child: vhIcon('book', 20))),
          const SizedBox(height: 11),
          T(tier.title,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 14,
                  height: (zh ? 20 : 14) / 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          T(tier.count,
              style: TextStyle(
                  fontSize: 10.5,
                  height: (zh ? 15 : 11) / 10.5,
                  color: vhMuted)),
          const SizedBox(height: 10),
          Container(
              key: ValueKey('vh-track-${tier.route.name}'),
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xfff0ebe0),
                  borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: tier.percent / 100,
                  child: Container(
                      key: ValueKey('vh-fill-${tier.route.name}'),
                      decoration: BoxDecoration(
                          color: SurgoColors.yellow,
                          borderRadius: BorderRadius.circular(3))))),
          const SizedBox(height: 8),
          SourceText(
              tier.percent > 0 ? '${tier.percent}% · ${tier.cta}' : tier.cta,
              style: TextStyle(
                  fontSize: 10,
                  height: (zh ? 14 : 10) / 10,
                  color: const Color(0xffa08a4a))),
        ]));
  }
}
