import 'package:flutter/material.dart';
import 'review_questions.dart';
import 'review_style.dart';
import '../../theme/tokens.dart';

const rfAnchors = [
  'no single butterfly completes the round trip',
  'They appear to use the position of the sun as a compass',
  'the location of the main colonies was only formally documented by researchers in 1975'
];

class RfPassage extends StatelessWidget {
  const RfPassage(
      {super.key,
      required this.paragraphs,
      required this.questions,
      required this.mock});
  final List paragraphs, questions;
  final bool mock;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final p in paragraphs)
          Text.rich(TextSpan(children: spans(context, p)),
              style: const TextStyle(fontSize: 12, height: 1.85, color: rfInk))
      ]);

  List<InlineSpan> spans(BuildContext context, List p) {
    final text = p[1] as String;
    final hits = <({int start, int i, String text})>[];
    for (var i = 0; i < questions.length; i++) {
      final anchor = mock
          ? questions[i]['ev'] as String?
          : i < rfAnchors.length
              ? rfAnchors[i]
              : null;
      if (anchor == null || anchor.isEmpty) continue;
      final start = text.indexOf(anchor);
      if (start >= 0) hits.add((start: start, i: i, text: anchor));
    }
    hits.sort((a, b) => a.start.compareTo(b.start));
    final children = <InlineSpan>[];
    var offset = 0;
    var prefix = mock ? p[0] as String : '';
    for (final hit in hits) {
      if (hit.start < offset) continue;
      children.add(TextSpan(
          text: rfTranslate(
              context, prefix + text.substring(offset, hit.start))));
      prefix = '';
      final q = questions[hit.i] as Map,
          ok = rfCorrect(questions[hit.i], mock: mock);
      children.add(const WidgetSpan(child: SizedBox(width: 2)));
      children.add(TextSpan(
          text: rfTranslate(context, hit.text),
          style:
              TextStyle(backgroundColor: Color(ok ? 0xffdff2d8 : 0xfffbdcdc))));
      children.add(const WidgetSpan(child: SizedBox(width: 2)));
      children.add(WidgetSpan(
          alignment: PlaceholderAlignment.aboveBaseline,
          baseline: TextBaseline.alphabetic,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(ok ? 0xff7cb518 : 0xffe5484d)),
                  alignment: Alignment.center,
                  child: Text('${mock ? q['no'] : hit.i + 1}',
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 12,
                          height: 1,
                          color: Colors.white,
                          fontWeight: FontWeight.w800))))));
      offset = hit.start + hit.text.length;
    }
    children.add(
        TextSpan(text: rfTranslate(context, prefix + text.substring(offset))));
    return children;
  }
}
