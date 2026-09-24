import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';

const reviewMuted = Color(0xff7b6f5c);
const reviewText =
    TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xff3a352c));
const reviewChinese =
    TextStyle(fontSize: 12.5, height: 1.65, color: Color(0xff6a645b));

class ReviewHeading extends StatelessWidget {
  const ReviewHeading(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final en = context.watch<AppState>().lang == UiLang.en;
    // Source headings contain a pictograph in the same DOM text node.
    // Exported dictionary keys omit it; keep explicit paired labels locally.
    const labels = {
      '分项评分': ['📊 分项评分', '📊 Criterion scores'],
      '提分建议': ['🔥 提分建议', '🔥 How to improve'],
      '你的作文（含批改）': ['📝 你的作文（含批改）', '📝 Your essay (marked)'],
      '母语负迁移分析': ['🌏 母语负迁移分析', '🌏 母语负迁移分析'],
    };
    final text = labels[label];
    return Padding(
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
                          color: SurgoColors.yellow.withAlpha(128),
                          borderRadius: BorderRadius.circular(3)))),
              if (text != null)
                Text(text[en ? 1 : 0],
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 27 / 17))
              else
                T(label,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 17, fontWeight: FontWeight.w800)),
            ])));
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, this.title, required this.children});
  final String? title;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (title != null) ReviewHeading(title!), ...children]));
}

class ReviewButton extends StatelessWidget {
  const ReviewButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4df5b301), blurRadius: 20, offset: Offset(0, 8))
          ]),
      child: Material(
          color: SurgoColors.yellow,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
              onTap: onTap,
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: label == '回到首页'
                      ? Text(
                          context.watch<AppState>().lang == UiLang.zh
                              ? '🏠 回到首页'
                              : '🏠 Back to home',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 23 / 14,
                              color: Color(0xff3a2e00)))
                      : T(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff3a2e00)))))));
}

class ReviewTab extends StatelessWidget {
  const ReviewTab(this.label,
      {super.key,
      required this.active,
      required this.onTap,
      this.task = false});
  final String label;
  final bool active, task;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
      textStyle: DefaultTextStyle.of(context).style,
      color:
          active ? (task ? SurgoColors.yellow : SurgoColors.ink) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(task ? 20 : 12),
          side: BorderSide(
              color: active
                  ? (task ? SurgoColors.yellow : SurgoColors.ink)
                  : SurgoColors.line,
              width: task ? 1 : 1.5)),
      child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(task ? 20 : 12),
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: task ? 21 : 17, vertical: task ? 9 : 10.75),
              child: T(label,
                  style: TextStyle(
                      fontFamily: task ? 'VioletSans' : 'Arimo',
                      fontSize: task ? 11 : 11.5,
                      fontWeight: task ? FontWeight.w800 : FontWeight.w700,
                      color: active
                          ? (task ? const Color(0xff3a2e00) : Colors.white)
                          : (task
                              ? const Color(0xff7b6f5c)
                              : const Color(0xff6a645b)))))));
}

class ReviewScore extends StatelessWidget {
  const ReviewScore({super.key, required this.score, this.overall = false});
  final String score;
  final bool overall;
  @override
  Widget build(BuildContext context) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(score,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 40,
                    height: overall ? 1.02 : 1.1,
                    fontWeight: overall ? FontWeight.w900 : FontWeight.w800,
                    color: SurgoColors.ink)),
            const SizedBox(width: 2),
            Text(' / 9.0',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: overall ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: overall
                        ? const Color(0xffa08b3a)
                        : const Color(0xff9a7a00))),
          ]);
}
