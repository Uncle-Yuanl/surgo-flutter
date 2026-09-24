import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/t.dart';
import '../../theme/tokens.dart';

const tierShadow = [
  BoxShadow(color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
];
const tierButtonShadow = [
  BoxShadow(color: Color(0x4df5b301), blurRadius: 20, offset: Offset(0, 8))
];
const tierPaths = {
  'ear':
      '<path d="M6 8a6 6 0 0 1 12 0c0 3-2 4-2 7a4 4 0 0 1-8 0"/><path d="M9 20a3 3 0 0 0 6 0"/>',
  'check': '<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>',
  'pen':
      '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/>',
  'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  'empty': '<circle cx="12" cy="12" r="9"/><path d="M8 12.5l2.8 2.8L16.5 9"/>',
};
Widget tierIcon(String name, double size) {
  final color = switch (name) {
    'check' => '#4f8a1f',
    'clock' => '#9a948a',
    'empty' => '#2fb457',
    _ => '#c99a1e'
  };
  final stroke = name == 'empty'
      ? 2.2
      : name == 'check'
          ? 2
          : 1.8;
  return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">${tierPaths[name]}</svg>',
      key: ValueKey('tier-icon-$name'),
      width: size,
      height: size);
}

/// Source read-page has a fixed Home above read-scroll, not a scrolling Home.
class TierFrame extends StatelessWidget {
  const TierFrame({super.key, required this.child, this.nav = true});
  final Widget child;
  final bool nav;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final home = Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
            child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                    key: const ValueKey('tier-home'),
                    onTap: () => context.read<AppState>().go(SurgoPage.vocab),
                    child: SvgPicture.asset('assets/images/home_icon.svg',
                        width: 24, height: 24))));
        if (!bounds.hasBoundedHeight) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [if (nav) home, child]);
        }
        return Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (nav) home,
                  Expanded(
                      child: SingleChildScrollView(
                          key: const ValueKey('tier-scroll'), child: child)),
                ]));
      });
}

/// Reproduce flex-wrap + space-between using measured, translated chip widths.
class TierPreviewRow extends StatelessWidget {
  const TierPreviewRow(
      {super.key,
      required this.words,
      required this.chips,
      required this.onTap});
  final List<String> words;
  final Widget chips;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: Wrap(
          key: const ValueKey('tier-preview-row'),
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Atomic non-flex Row shrink-wraps the preview chips. The outer Wrap
            // may move the link, but must not squeeze the chip group to fit it.
            chips,
            GestureDetector(
                key: const ValueKey('tier-view-all'),
                onTap: onTap,
                child: const T('查看全部词汇 →',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff3a3630)))),
          ]));
}
