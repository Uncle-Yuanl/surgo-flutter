import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';

/// Same source vs-top row as study, without changing that completed feature.
class VocabDetailTop extends StatelessWidget {
  const VocabDetailTop(
      {super.key,
      required this.progress,
      required this.fraction,
      this.exitTarget = SurgoPage.vocab});
  final SurgoPage exitTarget;
  final String progress;
  final double fraction;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    final exit = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
        height: (zh ? 17 : 12) / 12,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xff8a8474));
    final demo = TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
        height: (zh ? 14 : 10) / 10,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xffa08a4a));
    final count = TextStyle(
        height: (zh ? 14 : 10) / 10,
        fontSize: 10,
        color: const Color(0xffa99a82));
    return Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
        child: LayoutBuilder(builder: (context, bounds) {
          double widthOf(String raw, TextStyle style) {
            final text = Translator.instance.translate(raw, app.lang) ?? raw;
            return (TextPainter(
                    text: TextSpan(
                        text: text,
                        style: DefaultTextStyle.of(context).style.merge(style)),
                    textDirection: TextDirection.ltr,
                    textScaler: MediaQuery.textScalerOf(context))
                  ..layout())
                .width;
          }

          final min = widthOf('✕ 退出', exit) +
              widthOf('演示数据', demo) +
              16 +
              widthOf(progress, count) +
              30;
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                  width: min > bounds.maxWidth ? min : bounds.maxWidth,
                  child:
                      Row(key: const ValueKey('vocab-detail-top'), children: [
                    GestureDetector(
                        key: const ValueKey('vocab-detail-exit'),
                        onTap: () => app.go(exitTarget),
                        child: T('✕ 退出', style: exit)),
                    const SizedBox(width: 10),
                    Container(
                        key: const ValueKey('vocab-detail-demo'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: SurgoColors.yellowTint,
                            borderRadius: BorderRadius.circular(7)),
                        child: T('演示数据', style: demo)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                                key: const ValueKey('vocab-detail-progress'),
                                height: 6,
                                child: LinearProgressIndicator(
                                    value: fraction,
                                    color: SurgoColors.yellow,
                                    backgroundColor: SurgoColors.track)))),
                    const SizedBox(width: 10),
                    T(progress,
                        key: const ValueKey('vocab-detail-count'),
                        style: count),
                  ])));
        }));
  }
}
