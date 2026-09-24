import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'vocab_quiz_module.dart' show kVocabQuizOptions, vocabQuizTarget;

const quizMuted = Color(0xffa99a82);
const quizShadow = [
  BoxShadow(color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
];

/// Computed source CSS sizes after shrinkFonts. No question data lives here.
class QuizPill extends StatelessWidget {
  const QuizPill(this.label,
      {super.key,
      required this.onTap,
      this.primary = true,
      this.fontSize = 13,
      this.padding = 14,
      this.radius = 24});
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final double fontSize, padding, radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: primary
              ? const [
                  BoxShadow(
                      color: Color(0x4df5b301),
                      blurRadius: 20,
                      offset: Offset(0, 8))
                ]
              : null),
      child: Material(
          color: primary ? SurgoColors.yellow : Colors.white,
          textStyle: DefaultTextStyle.of(context).style,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: primary
                  ? BorderSide.none
                  : const BorderSide(color: SurgoColors.yellow, width: 1.5)),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                  padding: EdgeInsets.all(padding + (primary ? 0 : 1)),
                  child: Center(
                      heightFactor: 1,
                      child: T(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: fontSize,
                              height:
                                  (context.watch<AppState>().lang == UiLang.zh
                                          ? (fontSize == 14 ? 20 : 18)
                                          : (fontSize == 14 ? 16 : 15)) /
                                      fontSize,
                              fontWeight: FontWeight.w700,
                              color: primary
                                  ? const Color(0xff3a2e00)
                                  : const Color(0xff3a352c))))))));
}

class QuizCard extends StatelessWidget {
  const QuizCard({super.key, required this.child, required this.vertical});
  final Widget child;
  final double vertical;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 24),
      padding: EdgeInsets.symmetric(horizontal: 26, vertical: vertical),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: quizShadow),
      child: child);
}

class VocabTestIntroView extends StatelessWidget {
  const VocabTestIntroView({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
          child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                  key: const ValueKey('vocab-test-home'),
                  onTap: () => app.go(SurgoPage.vocab),
                  child: SvgPicture.asset('assets/images/home_icon.svg',
                      width: 24, height: 24)))),
      QuizCard(
          key: const ValueKey('vocab-test-card'),
          vertical: 38,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
                child: Container(
                    key: const ValueKey('vocab-test-ruler'),
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: SurgoColors.yellowTint),
                    child: Center(
                        child: SvgPicture.string(
                            '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="18" height="10" rx="2"/><path d="M7 7v3M11 7v4M15 7v3M19 7v4"/></svg>',
                            width: 30,
                            height: 30)))),
            const SizedBox(height: 20),
            const T('词汇分级测试',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const T('几分钟的选择题，帮你找到合适的起始难度；答对的单词会直接标记为已掌握。',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11.5, height: 1.65, color: quizMuted)),
            const SizedBox(height: 26),
            Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: SizedBox(
                        width: double.infinity,
                        child: QuizPill('开始测试',
                            key: const ValueKey('vocab-test-start'),
                            fontSize: 14,
                            padding: 15,
                            radius: 26,
                            onTap: () => app.go(SurgoPage.vocabTestQ))))),
            const SizedBox(height: 18),
            GestureDetector(
                key: const ValueKey('vocab-test-skip'),
                onTap: () => app.go(SurgoPage.vocab),
                child: const T('暂不测试，返回词汇首页',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: quizMuted))),
          ])),
    ]);
  }
}

class VocabQuestionView extends StatelessWidget {
  const VocabQuestionView({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(
                key: const ValueKey('vocab-quiz-exit'),
                onTap: () => app.go(SurgoPage.vocab),
                child: T('✕ 退出',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        height: (app.lang == UiLang.zh ? 18 : 13) / 13,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff8a8474)))),
            const T('1/1 · Tier 1',
                style: TextStyle(fontSize: 11, color: quizMuted)),
          ])),
      Container(
          key: const ValueKey('vocab-quiz-progress'),
          height: 5,
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 32),
          decoration: BoxDecoration(
              color: SurgoColors.yellow,
              borderRadius: BorderRadius.circular(3))),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Original button has no onclick. Do not invent playback here.
        SvgPicture.string(
            '<svg viewBox="0 0 24 24" fill="none" stroke="#E0A000" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>',
            key: const ValueKey('vocab-quiz-speaker'),
            width: 26,
            height: 26),
        const SizedBox(width: 10),
        SourceText('Identify',
            key: const ValueKey('vocab-quiz-word'),
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 32, height: (app.lang == UiLang.zh ? 45 : 32) / 32, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 8),
      T('选出这个单词的正确释义',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, height: (app.lang == UiLang.zh ? 16 : 11) / 11.5, color: quizMuted)),
      const SizedBox(height: 24),
      for (final o in kVocabQuizOptions) ...[
        if (o.key != 'A') const SizedBox(height: 12),
        Material(
            color: Colors.white,
            textStyle: DefaultTextStyle.of(context).style,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: SurgoColors.line, width: 1.5)),
            child: InkWell(
                key: ValueKey('vocab-option-${o.key}'),
                onTap: () => app.go(vocabQuizTarget(correct: o.correct)),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 17, vertical: 16),
                    child: Row(children: [
                      Text('${o.key}.',
                          style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 7.6),
                      Flexible(
                          child: SourceText(o.def,
                              style: TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 13,
                                  height:
                                      (app.lang == UiLang.zh ? 18 : 15) / 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff3a352c)))),
                    ])))),
      ],
      const SizedBox(height: 20),
      GestureDetector(
          key: const ValueKey('vocab-quiz-skip'),
          onTap: () => app.go(SurgoPage.vocabTier1),
          child: const T('不确定，跳过这题',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff8a8474)))),
    ]);
  }
}

class VocabResultView extends StatelessWidget {
  const VocabResultView({super.key, required this.pass});
  final bool pass;
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return QuizCard(
        key: const ValueKey('vocab-result-card'),
        vertical: 40,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                      child: SvgPicture.string(
                          '<svg viewBox="0 0 24 24" fill="none" stroke="#e5484d" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/><circle cx="12" cy="12" r="2"/></svg>',
                          key: const ValueKey('vocab-result-target'),
                          width: 48,
                          height: 48)))),
          const SizedBox(height: 22),
          T('推荐从 Tier ${pass ? 2 : 1} 开始',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          T('答对 ${pass ? 1 : 0}/1 — 已认识的单词已标记为掌握。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: quizMuted)),
          const SizedBox(height: 28),
          IntrinsicHeight(
              child: Row(
                  key: const ValueKey('vocab-result-actions'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Expanded(
                    flex: 144,
                    child: QuizPill('开始学习',
                        key: const ValueKey('vocab-result-start'),
                        onTap: () => app.go(SurgoPage.vocabStudy4))),
                const SizedBox(width: 12),
                Expanded(
                    flex: 146,
                    child: QuizPill('返回词汇首页',
                        key: const ValueKey('vocab-result-back'),
                        primary: false,
                        onTap: () => app.go(SurgoPage.vocab))),
              ])),
        ]));
  }
}
