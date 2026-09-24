import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/tokens.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/t.dart';
import 'writing_plan_widgets.dart' show planShadow;

class ComposeNav extends StatelessWidget {
  const ComposeNav(
      {super.key, required this.essay, required this.home, required this.tab});
  final bool essay;
  final VoidCallback home;
  final ValueChanged<String> tab;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
          height: 40,
          child: Row(children: [
            DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ]),
                child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                        key: const ValueKey('compose-home'),
                        onTap: home,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                                child: Transform.translate(
                                    offset: const Offset(0, -2.5),
                                    child: SvgPicture.asset(
                                        'assets/images/home_icon.svg',
                                        width: 24,
                                        height: 24))))))),
            const SizedBox(width: 14),
            Flexible(
                child:
                    _Tab('TOPICS', active: !essay, onTap: () => tab('topics'))),
            const SizedBox(width: 14),
            Flexible(
                child: _Tab('WRITE ESSAY',
                    active: essay, onTap: () => tab('essay'))),
          ])));
}

class _Tab extends StatelessWidget {
  const _Tab(this.label, {required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      key: ValueKey('compose-tab-$label'),
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: active
              ? SizedBox(
                  height: 17 * 1.2,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 17 * 1.2 * 0.58,
                        bottom: 17 * 1.2 * (1 - 0.92),
                        child: Container(color: SurgoColors.yellow),
                      ),
                      T(label,
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.2,
                              color: SurgoColors.ink)),
                    ],
                  ),
                )
              : T(label,
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                      color: Color(0xffa8a29a)))));
}

class ComposeCta extends StatelessWidget {
  const ComposeCta(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
          color: SurgoColors.yellow,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
              key: const ValueKey('compose-cta'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Center(
                      child: T(label,
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: SurgoColors.ink)))))));
}

class ComposeDisclosure extends StatelessWidget {
  const ComposeDisclosure(
      {super.key,
      required this.label,
      required this.open,
      required this.onTap,
      this.main = false});
  final String label;
  final bool open, main;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: main && open ? const Color(0xfffef6dc) : Colors.white,
      textStyle: DefaultTextStyle.of(context).style,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: main
              ? BorderSide(
                  color: open ? SurgoColors.yellow : Colors.transparent,
                  width: 2)
              : BorderSide.none),
      child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: main ? 24 : 22, vertical: main ? 22 : 19),
              child: Row(children: [
                Expanded(
                    child: T(label,
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: main ? 17 : 16,
                            height: context.watch<AppState>().lang == UiLang.zh
                                ? (main ? 24 / 17 : 22 / 16)
                                : 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                            color: SurgoColors.ink))),
                const SizedBox(width: 12),
                CustomPaint(
                    size: Size(open ? 12 : 9, open ? 9 : 12),
                    painter: _Caret(
                        open,
                        main || open
                            ? SurgoColors.ink
                            : const Color(0xffd8cfae))),
              ]))));
}

class _Caret extends CustomPainter {
  const _Caret(this.open, this.color);
  final bool open;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Path();
    if (open) {
      p
        ..moveTo(0, 0)
        ..lineTo(s.width, 0)
        ..lineTo(s.width / 2, s.height);
    } else {
      p
        ..moveTo(0, 0)
        ..lineTo(s.width, s.height / 2)
        ..lineTo(0, s.height);
    }
    c.drawPath(p..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Caret old) =>
      old.open != open || old.color != color;
}

BoxDecoration composeCardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: planShadow);
