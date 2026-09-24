import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';

// Computed H5 sizes after shrinkFonts(), not declared CSS sizes.
const practiceBody =
    TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xff4a453d));
const practiceHint =
    TextStyle(fontSize: 11, height: kTextHeightNone, color: Color(0xffa99a82));
const practiceTitle = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: kTextHeightNone,
    color: SurgoColors.ink);

class PracticeNav extends StatelessWidget {
  const PracticeNav({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
      child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
              key: const ValueKey('practice-home'),
              onTap: onBack,
              child: SvgPicture.asset('assets/images/home_icon.svg',
                  width: 24, height: 24))));
}

class PracticeCard extends StatelessWidget {
  const PracticeCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
          ]),
      child: child);
}

class PracticeButton extends StatelessWidget {
  const PracticeButton(this.label,
      {super.key,
      required this.onTap,
      this.primary = true,
      this.mark = false,
      this.judgment});
  final String label;
  final VoidCallback onTap;
  final bool primary, mark;
  final bool? judgment;
  @override
  Widget build(BuildContext context) {
    final judge = judgment != null;
    final color = judge
        ? (judgment! ? const Color(0xff2f9e44) : const Color(0xffe5533c))
        : primary
            ? const Color(0xff3a2e00)
            : const Color(0xff3a352c);
    final border = judge
        ? (judgment! ? const Color(0xff8fce7f) : const Color(0xfff0a79b))
        : SurgoColors.yellow;
    return DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(mark ? 24 : 26),
            boxShadow: primary && !judge
                ? const [
                    BoxShadow(
                        color: Color(0x4df5b301),
                        blurRadius: 20,
                        offset: Offset(0, 8))
                  ]
                : null),
        child: Material(
            color: primary && !judge ? SurgoColors.yellow : Colors.white,
            textStyle: DefaultTextStyle.of(context).style,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(mark ? 24 : 26),
                side: !primary || judge
                    ? BorderSide(color: border, width: 1.5)
                    : BorderSide.none),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(mark ? 24 : 26),
                child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: judge
                            ? 11
                            : mark
                                ? 15
                                : 16,
                        horizontal: judge
                            ? 26
                            : mark
                                ? 40
                                : 16),
                    child: T(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: mark
                                ? 14
                                : judge
                                    ? 12
                                    : 13,
                            height: kTextHeightNone,
                            fontWeight: FontWeight.w800,
                            color: color))))));
  }
}

class PracticeRoundIcon extends StatelessWidget {
  const PracticeRoundIcon(
      {super.key,
      required this.mic,
      required this.onTap,
      this.active = false,
      this.recording = false});
  final bool mic, active, recording;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: recording
          ? const Color(0xfff0483e)
          : active
              ? SurgoColors.yellow
              : mic
                  ? const Color(0xfffdf0cf)
                  : SurgoColors.yellowTint,
      shape: const CircleBorder(),
      child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                  child: recording
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3)))
                      : SvgPicture.string(
                          practiceSvg(mic ? 'mic' : 'speaker',
                              active ? '#3a2e00' : '#E0A000'),
                          width: 20,
                          height: 20)))));
}

String practiceSvg(String icon, String color) {
  final path = switch (icon) {
    'speaker' =>
      '<path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>',
    'mic' =>
      '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M6 11a6 6 0 0 0 12 0M12 17v4"/>',
    'flag' => '<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>',
    _ => '<path d="M4 10v4M8 6v12M12 8v8M16 5v14M20 10v4"/>',
  };
  return '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">$path</svg>';
}
