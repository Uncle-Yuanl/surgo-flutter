import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/source_text.dart';

class PronLessonHeader extends StatelessWidget {
  const PronLessonHeader({super.key, required this.listening});
  final bool listening;
  @override
  Widget build(BuildContext context) {
    const labels = ['讲解', '听辨', '单词跟读', '句子练习', '完成'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Wrap(spacing: 9, runSpacing: 9, children: [
            for (final t in const [
              ('认读与发音要领', 0xffa08a4a, 0xfffdf3d6),
              ('/l/ 与 /r/ 对比', 0xff4a7fd4, 0xffe8f0fc),
              ('英音示范', 0xff7a5fd6, 0xffeee9fb)
            ])
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                      color: Color(t.$3),
                      borderRadius: BorderRadius.circular(9)),
                  child: T(t.$1,
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(t.$2)))),
          ])),
      const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: T('/l/ 与 /r/ —— 发音要领',
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SurgoColors.ink))),
      const Padding(
          padding: EdgeInsets.fromLTRB(2, 4, 2, 16),
          child: SourceText('/l/ vs /r/ — articulation',
              style: TextStyle(fontSize: 12, color: Color(0xffa99a82)))),
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  GestureDetector(
                      onTap: listening
                          ? (i == 0
                              ? () => context
                                  .read<AppState>()
                                  .go(SurgoPage.pronLesson)
                              : i == 2
                                  ? () => context
                                      .read<AppState>()
                                      .go(SurgoPage.pronRepeat)
                                  : null)
                          : i == 1
                              ? () => context
                                  .read<AppState>()
                                  .go(SurgoPage.pronListen)
                              : null,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                              color: i == (listening ? 1 : 0)
                                  ? SurgoColors.yellow
                                  : const Color(0xfff4f0e9),
                              borderRadius: BorderRadius.circular(11)),
                          child: T('${i + 1} ${labels[i]}',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: i == (listening ? 1 : 0)
                                      ? const Color(0xff3a2e00)
                                      : const Color(0xffb7b0a3))))),
                ]
              ]))),
    ]);
  }
}
