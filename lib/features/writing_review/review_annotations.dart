import 'package:flutter/material.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'review_widgets.dart';
import '../../theme/tokens.dart';

/// Only known fixed annotation spans, not an HTML renderer. Keep superscripts
/// and purple L1 highlighting distinct from the normal yellow markup.
class ReviewEssay extends StatelessWidget {
  const ReviewEssay({super.key, required this.source});
  final String source;
  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var offset = 0;
    final re = RegExp(r'<span class="wf-hl(-p)?">(.*?)<sup>(\d+)</sup></span>');
    for (final m in re.allMatches(source)) {
      spans.add(TextSpan(text: source.substring(offset, m.start)));
      final purple = m[1] != null;
      final highlight =
          purple ? const Color(0xffe6e2fb) : const Color(0xfffde8b0);
      // CSS inline span has 2px horizontal padding. Keep text breakable rather
      // than making the whole L1 phrase one unbreakable WidgetSpan.
      spans.add(WidgetSpan(child: SizedBox(width: 2, height: 0)));
      spans.add(TextSpan(
          text: m[2],
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 12.5,
              height: 1.85,
              backgroundColor:
                  purple ? const Color(0xffe6e2fb) : const Color(0xfffde8b0),
              fontWeight: FontWeight.w700,
              fontVariations: const [
                FontVariation('wght', 700),
                FontVariation('opsz', 14)
              ],
              color: purple ? const Color(0xff5a4b9e) : null)));
      spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Transform.translate(
              offset: const Offset(0, -3),
              child: Text(m[3]!,
                  key: ValueKey('review-annotation-${m[3]}'),
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      fontVariations: const [
                        FontVariation('wght', 900),
                        FontVariation('opsz', 14)
                      ],
                      backgroundColor: highlight,
                      color: purple
                          ? const Color(0xff6b5fc7)
                          : const Color(0xffc96a1f))))));
      spans.add(WidgetSpan(child: SizedBox(width: 2, height: 0)));
      offset = m.end;
    }
    spans.add(TextSpan(text: source.substring(offset)));
    return Container(
        key: const ValueKey('review-essay'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xfff7f5f0),
            borderRadius: BorderRadius.circular(12)),
        child: SourceText.rich(TextSpan(children: spans),
            style: const TextStyle(
                fontFamily: 'Inter',
                // Optical-size 14 retained after comparing all four full essays.
                // 15/16 improve some lines but shorten Task 2 by another line.
                // A scoped OFL approximation, not bundled Apple font bytes.
                fontVariations: [FontVariation('opsz', 14)],
                fontSize: 13.5,
                height: 1.85,
                color: Color(0xff3a352c))));
  }
}

class ReviewNote extends StatelessWidget {
  const ReviewNote({super.key, required this.note, this.l1 = false});
  final Map note;
  final bool l1;
  Widget number() => Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: l1 ? const Color(0xff6b5fc7) : const Color(0xffc0392b)),
      child: Text('${note['n']}',
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)));
  Widget fix() => Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!l1) number(),
            SourceText(note['old'],
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: l1 ? 11 : 11.5,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.lineThrough,
                    color: const Color(0xffc0392b))),
            const Text('→', style: TextStyle(fontSize: 12.5, color: reviewMuted)),
            SourceText(note['neu'],
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: l1 ? 11 : 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff2f7a2a))),
          ]);
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(horizontal: l1 ? 16 : 16, vertical: 15),
      decoration: BoxDecoration(
          color: l1 ? const Color(0xfff6f4fd) : Colors.white,
          border: l1 ? null : Border.all(color: const Color(0xffefe9dd)),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (l1) ...[
          Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                number(),
                T(note['title'],
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
                T('· ${note['zh']}',
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xff6a645b)))
              ]),
          const SizedBox(height: 10)
        ],
        fix(),
        const SizedBox(height: 9),
        T(note['en'], style: reviewText),
        const SizedBox(height: 3),
        T(note[l1 ? 'cn' : 'zh'], style: reviewChinese),
        Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
                color: l1 ? const Color(0xffece8fa) : const Color(0xffeef7e8),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  T(l1 ? '母语负迁移成因' : '为什么这样更好',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: l1
                              ? const Color(0xff6b5fc7)
                              : const Color(0xff3f7a2e))),
                  const SizedBox(height: 5),
                  if (l1) ...[
                    T(note['whyZh'], style: reviewChinese),
                    Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8)),
                        child: T('💡 ${note['tip']}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.65,
                                color: Color(0xff5a4b9e))))
                  ] else ...[
                    T(note['whyEn'], style: reviewText),
                    const SizedBox(height: 3),
                    T(note['whyZh'], style: reviewChinese)
                  ],
                ])),
      ]));
}
