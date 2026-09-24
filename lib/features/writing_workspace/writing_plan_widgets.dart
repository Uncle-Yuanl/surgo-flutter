import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';

const planShadow = [
  BoxShadow(color: Color(0x143c321e), blurRadius: 18, offset: Offset(0, 4))
];
const planMuted = Color(0xffa99a82);
Widget planIcon(String name,
    {double size = 24, Color color = const Color(0xff4a453d)}) {
  const paths = {
    'next': '<path d="M4 12h15M13 6l6 6-6 6"/>',
    'prev': '<path d="M20 12H5M11 6l-6 6 6 6"/>',
    'lock':
        '<rect x="4" y="10.5" width="16" height="11" rx="2.5"/><path d="M8 10.5V7a4 4 0 0 1 8 0v3.5"/>',
    'book':
        '<path d="M12 6.5S9.5 4.5 4 5v13c5.5-.5 8 1.5 8 1.5s2.5-2 8-1.5V5c-5.5-.5-8 1.5-8 1.5z"/><path d="M12 6.5v13"/>',
    'check': '<path d="M20 6.5 9.5 17 4 11.5"/>',
  };
  return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="${name == 'check' ? 3.4 : name == 'book' ? 1.9 : 2.2}" stroke-linecap="round" stroke-linejoin="round">${paths[name]}</svg>',
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: size,
      height: size);
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.child, this.embedded = false});
  final Widget child;
  final bool embedded;
  @override
  Widget build(BuildContext context) => Container(
      padding: embedded
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 18)
          : const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
          color: embedded ? const Color(0xfffcfaf6) : Colors.white,
          borderRadius: BorderRadius.circular(embedded ? 18 : 26),
          boxShadow: embedded ? null : planShadow),
      child: child);
}

class PlanHeading extends StatelessWidget {
  const PlanHeading(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                  height: 20 * 1.2,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 20 * 1.2 * 0.62,
                        bottom: 20 * 1.2 * (1 - 0.88),
                        child: Container(color: SurgoColors.yellow),
                      ),
                      T(label,
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                              color: Colors.black)),
                    ],
                  )))));
}

class PlanSelectCard extends StatelessWidget {
  const PlanSelectCard(
      {super.key,
      required this.selected,
      required this.onTap,
      required this.child,
      this.vocab = false});
  final bool selected, vocab;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
      color: selected ? SurgoColors.yellowTint : const Color(0xfff4f2ef),
      textStyle: DefaultTextStyle.of(context).style,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(vocab ? 18 : 20),
          side: BorderSide(
              color: selected ? SurgoColors.yellow : Colors.transparent,
              width: 2)),
      child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(vocab ? 18 : 20),
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: vocab ? 20 : 23, vertical: vocab ? 18 : 21),
              child: child)));
}
