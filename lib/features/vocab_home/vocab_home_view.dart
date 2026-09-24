import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'vocab_home_page.dart' show kVocabTiers;
import 'vocab_home_widgets.dart';

class VocabHomeView extends StatelessWidget {
  const VocabHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    final exam = app.examType == ExamType.toefl ? 'TOEFL' : 'IELTS';
    return LayoutBuilder(builder: (context, bounds) {
      final nav = Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
          child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                  key: const ValueKey('vh-home'),
                  onTap: () => app.go(SurgoPage.ielts),
                  child: SvgPicture.asset('assets/images/home_icon.svg',
                      width: 24, height: 24))));
      final content =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const T('欢迎来到词汇学习',
                      key: ValueKey('vh-title'),
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 26,
                          height: 1.25,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  T('按间隔重复计划，完成今天的 $exam 高频词复习',
                      style: const TextStyle(
                          fontSize: 11.5, height: 1.6, color: vhMuted)),
                  const SizedBox(height: 14),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                          color: Colors.white,
                          textStyle: DefaultTextStyle.of(context).style,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                  color: SurgoColors.yellow, width: 1.5)),
                          child: InkWell(
                              key: const ValueKey('vh-test'),
                              onTap: () => app.go(SurgoPage.vocabTest),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 17, vertical: 10),
                                  child: T('▥ 测测我的词汇水平',
                                      style: TextStyle(
                                          fontFamily: 'Arimo',
                                          fontSize: 11,
                                          height: (zh ? 16 : 13) / 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xffa08a4a))))))),
                ])),
        ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              Container(
                  key: const ValueKey('vh-stats'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  color: SurgoColors.yellowTint,
                  child: const VhStats(review: false)),
              Positioned(
                  right: 8,
                  bottom: 0,
                  child: Opacity(
                      opacity: .9,
                      child: Image.asset('assets/images/otter_welcome.png',
                          width: 56, fit: BoxFit.contain))),
            ])),
        const SizedBox(height: 16),
        VhCard(
            key: const ValueKey('vh-review-card'),
            padding: const EdgeInsets.all(18),
            radius: 18,
            child: Column(children: [
              LayoutBuilder(builder: (context, b) {
                final buttonWidth = (zh ? 100.78125 : 161.921875) *
                    MediaQuery.textScalerOf(context).scale(1);
                final row = Row(children: [
                  Container(
                      key: const ValueKey('vh-ring'),
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: SurgoColors.yellow, shape: BoxShape.circle),
                      child: const Text('10',
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff3a2e00)))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const SourceText.rich(
                            TextSpan(children: [
                              TextSpan(text: '个单词'),
                              TextSpan(text: '\n'),
                              TextSpan(text: '需今日复习')
                            ]),
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const T('预计 4 分钟完成',
                            style: TextStyle(fontSize: 10, color: vhMuted)),
                      ])),
                  const SizedBox(width: 14),
                  SizedBox(
                      width: buttonWidth,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Material(
                                color: SurgoColors.yellow,
                                textStyle: DefaultTextStyle.of(context).style,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                    key: const ValueKey('vh-review-start'),
                                    onTap: () => app.go(SurgoPage.vocabStudy),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: T('开始复习',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontFamily: 'Arimo',
                                                fontSize: 12,
                                                height: (zh ? 17 : 14) / 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(
                                                    0xff3a2e00)))))),
                            const SizedBox(height: 8),
                            Container(
                                key: const ValueKey('vh-review-inert'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: SurgoColors.line),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                    zh
                                        ? '\u{1f3a4} 发音复习 (0)'
                                        : '\u{1f3a4} Pronunciation review (0)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 10,
                                        height: 17 / 10,
                                        fontWeight: FontWeight.w600,
                                        color: vhMuted))),
                          ])),
                ]);
                // Preserve source middle-column squeeze at normal size; allow width
                // expansion under accessibility fonts rather than overflowing a Row.
                final min = buttonWidth + 156;
                if (min > b.maxWidth) {
                  return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: min, child: row));
                }
                return row;
              }),
              Container(
                  height: 1,
                  color: SurgoColors.line,
                  margin: const EdgeInsets.symmetric(vertical: 16)),
              const VhStats(review: true),
            ])),
        const SizedBox(height: 14),
        const VhMine(pron: false),
        const SizedBox(height: 12),
        const VhMine(pron: true),
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 22, 2, 5),
            child: T('学习路径',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 19,
                    height: (zh ? 26 : 19) / 19,
                    fontWeight: FontWeight.w800))),
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
            child: T('按词汇难度科学分级，循序渐进提升词汇量',
                style: TextStyle(
                    fontSize: 10.5,
                    height: (zh ? 15 : 11) / 10.5,
                    color: vhMuted))),
        for (var i = 0; i < kVocabTiers.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          VhTier(tier: kVocabTiers[i])
        ],
      ]);
      if (!bounds.hasBoundedHeight) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nav, content]);
      }
      return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            nav,
            Expanded(
                child: SingleChildScrollView(
                    key: const ValueKey('vh-scroll'), child: content)),
          ]));
    });
  }
}
