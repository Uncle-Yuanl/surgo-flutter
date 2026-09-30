import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';

const rfInk = Color(0xff1c1a17);
const rfMuted = Color(0xff8c8579);

class ReviewTextScope extends InheritedWidget {
  const ReviewTextScope(
      {super.key,
      required super.child,
      this.route = 'readingFeedback',
      this.raw = false});
  final String route;
  final bool raw;
  @override
  bool updateShouldNotify(ReviewTextScope oldWidget) =>
      route != oldWidget.route || raw != oldWidget.raw;
}

String rfTranslate(BuildContext context, String text) {
  final scope = context.dependOnInheritedWidgetOfExactType<ReviewTextScope>();
  if (scope?.raw == true) return text;
  final app = context.read<AppState>();
  final mapped = SourceNodeTranslations.lookup(
      text, scope?.route ?? 'readingFeedback', app.lang.name);
  return mapped != text
      ? mapped
      : (Translator.instance.translate(text, app.lang) ?? text);
}

class RfText extends StatelessWidget {
  const RfText(this.text,
      {super.key,
      this.size = 10,
      this.weight = FontWeight.w400,
      this.color = rfInk,
      this.height,
      this.italic = false,
      this.spacing = 0,
      this.align,
      this.family});
  /// 字符串，或 `[英文, 中文]` 一对（演示用真实数据，tool/demo_export 导出），
  /// 按界面语言取一项。
  final Object text;
  final double size, spacing;
  final FontWeight weight;
  final Color color;
  final double? height;
  final bool italic;
  final TextAlign? align;
  final String? family;
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    final t = text;
    final value = rfTranslate(
        context, t is List ? '${t[zh && t.length > 1 ? 1 : 0]}' : '$t');
    return Text(value,
        textAlign: align,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
            height: height ??
                (RegExp(r'[\u3400-\u9fff]').hasMatch(value) ? 1.4 : 1),
            letterSpacing: spacing,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontFamily: family));
  }
}

class RfHeading extends StatelessWidget {
  const RfHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Stack(children: [
            Positioned(
                left: 0,
                right: 0,
                bottom: 1,
                child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: SurgoColors.yellow.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(3)))),
            RfText(text, size: 17, weight: FontWeight.w800),
          ])));
}

class RfCard extends StatelessWidget {
  const RfCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
}

class RfButton extends StatelessWidget {
  const RfButton(this.text,
      {super.key, required this.onTap, this.home = false});
  final String text;
  final VoidCallback onTap;
  final bool home;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
              color: SurgoColors.yellow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4df5b301),
                    blurRadius: 20,
                    offset: Offset(0, 8))
              ]),
          child: home
              ? Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '⌂', style: TextStyle(fontSize: 13)),
                    TextSpan(text: ' ${rfTranslate(context, text)}'),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff3a2e00),
                      height: context.watch<AppState>().lang == UiLang.zh
                          ? 20 / 14
                          : 16 / 14))
              : RfText(text,
                  family: 'Arimo',
                  size: 14,
                  weight: FontWeight.w800,
                  color: const Color(0xff3a2e00),
                  height: context.watch<AppState>().lang == UiLang.zh
                      ? 20 / 14
                      : 16 / 14,
                  align: TextAlign.center)));
}

class RfNav extends StatelessWidget {
  const RfNav({super.key, this.title = 'READING MARK'});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 20),
      child: Row(children: [
        GestureDetector(
            key: const ValueKey('rf-home'),
            onTap: () => context.read<AppState>().go(SurgoPage.ielts),
            child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x143c3214),
                          blurRadius: 12,
                          offset: Offset(0, 4))
                    ]),
                child: Center(
                    child: SvgPicture.asset('assets/images/home_icon.svg',
                        width: 20, height: 20)))),
        const SizedBox(width: 14),
        Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: 0,
              right: 0,
              bottom: -4,
              child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                      color: SurgoColors.yellow,
                      borderRadius: BorderRadius.circular(3)))),
          RfText(
              context.watch<AppState>().lang == UiLang.en
                  ? rfTranslate(context, title).toUpperCase()
                  : title,
              size: 11,
              weight: FontWeight.w800,
              spacing: .3),
        ]),
      ]));
}

class RfEvidence extends StatelessWidget {
  const RfEvidence(this.text, {super.key, this.italic = true});
  final Object text;
  final bool italic;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
          color: const Color(0xfff7f4ee),
          borderRadius: BorderRadius.circular(9)),
      child: RfText(text, color: const Color(0xffb7b0a3), italic: italic));
}

Widget rfTag(Object text, {bool weak = false}) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: weak ? 12 : 10, vertical: weak ? 7 : 4),
        decoration: BoxDecoration(
            color: Color(weak ? 0xfffdf3d6 : 0xffefeafd),
            borderRadius: BorderRadius.circular(weak ? 10 : 9)),
        child: RfText(text,
            weight: FontWeight.w800,
            color: Color(weak ? 0xff9a7a00 : 0xff6b52d6))));
