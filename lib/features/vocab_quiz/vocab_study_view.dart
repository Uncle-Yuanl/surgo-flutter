import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';

/// Presentation of the four original vs-* views. Data and transitions stay in
/// vocab_quiz_module.dart; source speaker has no handler and stays decorative.
class VocabStudyView extends StatelessWidget {
  const VocabStudyView(
      {super.key,
      required this.word,
      required this.ipa,
      required this.progress,
      required this.pct,
      required this.reveal,
      required this.showTipIcon});
  final String word, ipa, progress;
  final double pct;
  final SurgoPage reveal;
  final bool showTipIcon;
  static const _muted = Color(0xffa99a82);
  static const _shadow = [
    BoxShadow(color: Color(0x0f3c3214), blurRadius: 22, offset: Offset(0, 8))
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
          child: LayoutBuilder(builder: (context, bounds) {
            // Preserve source single row when it fits; support large accessibility
            // fonts without overflow by allowing a horizontal scroll fallback.
            double widthOf(String raw, TextStyle style) {
              final text = Translator.instance.translate(raw, app.lang) ?? raw;
              final p = TextPainter(
                  text: TextSpan(
                      text: text,
                      style: DefaultTextStyle.of(context).style.merge(style)),
                  textDirection: TextDirection.ltr,
                  textScaler: MediaQuery.textScalerOf(context))
                ..layout();
              return p.width;
            }

            final minWidth = widthOf(
                    '✕ 退出',
                    const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 12, fontWeight: FontWeight.w700)) +
                widthOf(
                    '演示数据',
                    const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 10, fontWeight: FontWeight.w700)) +
                16 +
                widthOf(progress, const TextStyle(fontSize: 10)) +
                30;
            final width =
                minWidth > bounds.maxWidth ? minWidth : bounds.maxWidth;
            return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                    width: width,
                    child:
                        Row(key: const ValueKey('vocab-study-top'), children: [
                      GestureDetector(
                          key: const ValueKey('vocab-study-exit'),
                          onTap: () => app.go(SurgoPage.vocab),
                          child: const T('✕ 退出',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff8a8474)))),
                      const SizedBox(width: 10),
                      Container(
                          key: const ValueKey('vocab-study-demo'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: SurgoColors.yellowTint,
                              borderRadius: BorderRadius.circular(7)),
                          child: const T('演示数据',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xffa08a4a)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ClipRRect(
                              key: const ValueKey('vocab-study-progress'),
                              borderRadius: BorderRadius.circular(3),
                              child: ColoredBox(
                                  color: const Color(0xfff0ebe0),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                          widthFactor: pct,
                                          child: const SizedBox(
                                              height: 6,
                                              child: ColoredBox(
                                                  color:
                                                      SurgoColors.yellow))))))),
                      const SizedBox(width: 10),
                      T(progress,
                          key: const ValueKey('vocab-study-count'),
                          style: const TextStyle(fontSize: 10, color: _muted)),
                    ])));
          })),
      Container(
          key: const ValueKey('vocab-study-card'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _shadow),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.string(
                  '<svg viewBox="0 0 24 24" fill="none" stroke="#1c1a17" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>',
                  key: const ValueKey('vocab-study-speaker'),
                  width: 30,
                  height: 30),
              const SizedBox(width: 14),
              Flexible(
                  child: SourceText(word,
                      key: const ValueKey('vocab-study-word'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                          color: SurgoColors.ink))),
            ]),
            const SizedBox(height: 6),
            SourceText(ipa,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: _muted)),
            const SizedBox(height: 36),
            const T('先在脑中回忆这个词的意思',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SurgoColors.ink)),
            const SizedBox(height: 6),
            const T('想一想它的中文含义、用法或例句',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _muted)),
            const SizedBox(height: 24),
            Center(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x4df5b301),
                              blurRadius: 20,
                              offset: Offset(0, 8))
                        ]),
                    child: Material(
                        color: SurgoColors.yellow,
                        borderRadius: BorderRadius.circular(24),
                        textStyle: DefaultTextStyle.of(context).style,
                        child: InkWell(
                            key: const ValueKey('vocab-study-reveal'),
                            onTap: () => app.go(reveal),
                            borderRadius: BorderRadius.circular(24),
                            child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 44, vertical: 14),
                                child: T('查看释义',
                                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xff3a2e00)))))))),
          ])),
      Container(
          key: const ValueKey('vocab-study-tip'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: SurgoColors.yellowTint,
              borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (showTipIcon) ...[
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/otter_study.png',
                      key: const ValueKey('vocab-study-tip-image'),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover)),
              const SizedBox(width: 13),
            ],
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const T('小贴士',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.ink)),
                  const SizedBox(height: 2),
                  const T('先回忆，再看释义，能帮你建立更牢固的记忆哦！',
                      style:
                          TextStyle(fontSize: 10.5, color: Color(0xffa08a4a))),
                ])),
          ])),
    ]);
  }
}
