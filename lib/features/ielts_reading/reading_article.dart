import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'reading_controller.dart';

class ReadingHeader extends StatelessWidget {
  const ReadingHeader({super.key, required this.controller});
  final ReadingController controller;
  // User revision 2026-09-23: clock and Home share a row. Keep caption below.
  static double contentTop(UiLang lang) => lang == UiLang.zh ? 72 : 67;
  @override
  Widget build(BuildContext context) {
    final x = controller, zh = x.state.lang == UiLang.zh;
    return Column(children: [
      SizedBox(
          height: 33,
          child: Stack(children: [
            Positioned(
                left: 20,
                top: 6,
                child: GestureDetector(
                    key: const ValueKey('reading-home'),
                    onTap: () => context.read<AppState>().go(SurgoPage.ielts),
                    child: SvgPicture.asset('assets/images/home_icon.svg',
                        width: 24, height: 24))),
            Positioned(
                left: 0,
                right: 0,
                top: 5,
                child: Center(
                    child: Text(x.clock,
                        key: const ValueKey('reading-clock'),
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                            height: 1,
                            // Preserve original ink color after expiry; only layout changed.
                            color: SurgoColors.ink)))),
          ])),
      const SizedBox(height: 4),
      if (x.left <= 0)
        const Text('已超时',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SurgoColors.muted))
      else
        T('本次练习时长',
            style: TextStyle(
                fontSize: 12,
                height: zh ? 17 / 12 : 1,
                fontWeight: FontWeight.w600,
                color: SurgoColors.muted)),
      const SizedBox(height: 10),
    ]);
  }
}

class ReadingArticle extends StatelessWidget {
  const ReadingArticle({super.key, required this.controller});
  final ReadingController controller;
  @override
  Widget build(BuildContext context) {
    final x = controller;
    final instruction =
        x.single ? x.type['instr'] as String : '题目 1-${x.total}';
    final renderedInstruction =
        Translator.instance.translate(instruction, x.state.lang) ?? instruction;
    final cjkInstruction =
        RegExp(r'[\u4e00-\u9fff]').hasMatch(renderedInstruction);
    return SingleChildScrollView(
        key: const ValueKey('reading-article-scroll'),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 6),
          // 用户 2026-09-24：左上角三段标题，改用公共 SessionTags。
          SessionTags(
              mock: x.state.session['sessionMode'] == 'mock',
              subject: x.single ? '单一题型' : '${x.state.examType.label} 阅读',
              part: x.single ? x.type['name'] as String : '篇章 1',
              padding: EdgeInsets.zero),
          const SizedBox(height: 10),
          T('${x.single ? 'IELTS' : x.state.examType.label} 阅读 · ${x.single ? x.type['name'] : x.article['title']}',
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -.3,
                  color: Colors.black)),
          const SizedBox(height: 4),
          T(instruction,
              style: TextStyle(
                  fontSize: 14,
                  height: cjkInstruction ? 20 / 14 : 1,
                  color: SurgoColors.muted,
                  fontWeight: FontWeight.w600)),
          // Source 16px subtitle bottom + 14px article top collapse to 16px.
          const SizedBox(height: 16),
          Container(
              key: const ValueKey('reading-article-card'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x143c321e),
                        blurRadius: 18,
                        offset: Offset(0, 4))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SourceText(x.article['title'],
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                            color: Colors.black)),
                    const SizedBox(height: 14),
                    for (final p in x.article['passage'])
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: SourceText.rich(
                              TextSpan(children: [
                                if (x.single || (p[0] as String).isNotEmpty)
                                  TextSpan(
                                      text: p[0],
                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: SurgoColors.yellow)),
                                if (x.single || (p[0] as String).isNotEmpty)
                                  const WidgetSpan(
                                      child: SizedBox(width: 5, height: 0)),
                                TextSpan(text: ' ${p[1]}'),
                              ]),
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.8,
                                  color: Color(0xff3a352c)))),
                  ])),
          const SizedBox(height: 18),
        ]));
  }
}
