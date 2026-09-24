import 'package:flutter/material.dart';
import '../ielts_reading/review_style.dart';
import '../../theme/tokens.dart';

class ListeningReviewQuestion extends StatelessWidget {
  const ListeningReviewQuestion(
      {super.key, required this.part, required this.q});
  final int part;
  final Map q;
  @override
  Widget build(BuildContext context) {
    final bool ok = q['ok'];
    final type = part == 1
        ? 'Form completion'
        : part == 2
            ? 'Matching'
            : part == 3
                ? 'Multiple choice'
                : 'Note completion';
    final translated = rfTranslate(context, type);
    final typeWidth = RegExp(r'[\u3400-\u9fff]').hasMatch(translated)
        ? (part == 2 || part == 3 ? 30.90625 : 41.203125)
        : part == 2
            ? 46.1875
            : part == 3
                ? 74.5625
                : 80.0;
    return Container(
        key: ValueKey('lf-question-${q['n']}'),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffefe9dd)),
            borderRadius: BorderRadius.circular(16)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _number('${q['n']}', ok)),
            const SizedBox(width: 9),
            Expanded(
                child: RfText(q['q'],
                    size: 12, height: 1.4, weight: FontWeight.w700)),
            const SizedBox(width: 9),
            Padding(
                padding: const EdgeInsets.only(top: 3),
                child: SizedBox(
                    width: typeWidth,
                    child: RfText(type,
                        weight: FontWeight.w700,
                        color: const Color(0xffa89fd6),
                        spacing: .3,
                        align: TextAlign.right))),
          ]),
          const SizedBox(height: 12),
          if (part == 1 || part == 4) ...[
            Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const RfText('我的作答', color: rfMuted),
                  _answer(q['mine'], ok),
                  if (!ok) ...[
                    const RfText('正确答案', color: rfMuted),
                    _answer(q['ans'], true)
                  ],
                ]),
            const SizedBox(height: 10),
          ] else if (part == 2) ...[
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final option in q['opts']) _pill(option)]),
            const SizedBox(height: 12),
          ] else ...[
            for (var i = 0; i < (q['opts'] as List).length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _row(q['opts'][i]),
            ],
            const SizedBox(height: 12),
          ],
          RfEvidence('"${q['evi']}"'),
          const SizedBox(height: 8),
          RfText(q['why'],
              size: 10.5, height: 1.5, color: const Color(0xff6b6255)),
          const SizedBox(height: 2),
          RfText(q['whyZh'],
              size: 10.5, height: 1.5, color: const Color(0xffa49a8a)),
        ]));
  }

  Widget _answer(String text, bool ok) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Color(ok ? 0xffe8f5e0 : 0xfffbe9dc),
          borderRadius: BorderRadius.circular(8)),
      child: RfText(text,
          size: 10.5,
          weight: FontWeight.w700,
          color: Color(ok ? 0xff4f8a1f : 0xffb05a1f)));
  Widget _pill(String text) {
    final good = text == q['ans'], bad = text == q['mine'] && !good;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: Color(good
                ? 0xfff2fbee
                : bad
                    ? 0xfffdf1ef
                    : 0xffffffff),
            border: Border.all(
                width: 1.5,
                color: Color(good
                    ? 0xff8fce7f
                    : bad
                        ? 0xfff0a79b
                        : 0xffece4d6)),
            borderRadius: BorderRadius.circular(20)),
        child: RfText(
            '${good ? '✓ ' : bad ? '✕ ' : ''}$text',
            size: 11,
            weight: FontWeight.w600,
            color: Color(good
                ? 0xff2f7a2a
                : bad
                    ? 0xffc94436
                    : 0xff3a352c)));
  }

  Widget _row(String text) {
    final good = text == q['ans'], bad = text == q['mine'] && !good;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
            color: Color(good
                ? 0xfff2fbee
                : bad
                    ? 0xfffdf1ef
                    : 0xffffffff),
            border: Border.all(
                width: 1.5,
                color: Color(good
                    ? 0xff8fce7f
                    : bad
                        ? 0xfff0a79b
                        : 0xffece4d6)),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
              child: RfText(text, size: 12, color: const Color(0xff3a352c))),
          if (good || bad) ...[
            const SizedBox(width: 10),
            Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Color(good ? 0xff4f9e3a : 0xffd9503f),
                    shape: BoxShape.circle),
                child: Text(good ? '✓' : '✕',
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 12,
                        height: 1,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)))
          ]
        ]));
  }

  Widget _number(String n, bool ok) => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Color(ok ? 0xff7cb518 : 0xffe5484d), shape: BoxShape.circle),
      child: Text(n,
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 12,
              height: 1,
              color: Colors.white,
              fontWeight: FontWeight.w800)));
}
