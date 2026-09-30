import 'package:flutter/material.dart';
import 'review_style.dart';
import '../../theme/tokens.dart';

bool rfCorrect(Map q, {bool mock = false}) {
  // 演示用真实数据带后端判分结果（同义写法也算对），有就用它。
  if (q['ok'] is bool) return q['ok'] as bool;
  String value(dynamic x) => (x ?? '').toString().toUpperCase();
  return mock
      ? value(q['mine']).trim() == value(q['correct']).trim()
      : value(q['mine']) == value(q['a']);
}

class RfQuestion extends StatelessWidget {
  const RfQuestion(
      {super.key, required this.q, required this.index, required this.mock});
  final Map q;
  final int index;
  final bool mock;
  @override
  Widget build(BuildContext context) {
    final ok = rfCorrect(q, mock: mock);
    final number = mock ? q['no'] : index + 1;
    final type = q['typeLbl'] ??
        (mock
        ? ''
        : q['type'] == 'tfng'
            ? 'TRUE / FALSE / NOT GIVEN'
            : q['type'] == 'ynng'
                ? 'YES / NO / NOT GIVEN'
                : 'MULTIPLE CHOICE');
    final opts = mock
        ? q['opts'] ?? []
        : q['type'] == 'tfng'
            ? ['TRUE', 'FALSE', 'NOT GIVEN']
            : q['type'] == 'ynng'
                ? ['YES', 'NO', 'NOT GIVEN']
                : q['opts'] ?? [];
    String norm(dynamic x) =>
        mock ? '${x ?? ''}'.trim().toUpperCase() : '${x ?? ''}'.toUpperCase();
    final answer = norm(q[mock ? 'correct' : 'a']), mine = norm(q['mine']);
    final ev = q[mock ? 'ev' : 'evidence'],
        en = q[mock ? 'en' : 'why'],
        zh = q[mock ? 'zh' : 'whyZh'];
    // 原型只有模考题带 kind；真实数据的日常题也带（填空 / 简答走 input）。
    final input = q['kind'] == 'input', pills = q['kind'] == 'pills';
    return Container(
        key: ValueKey('rf-question-$number'),
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffefe9dd)),
            borderRadius: BorderRadius.circular(16)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _mark('$number', ok, 22)),
            const SizedBox(width: 9),
            Expanded(
                child: RfText(q['q'],
                    size: 12, weight: FontWeight.w700, height: 1.4)),
            const SizedBox(width: 9),
            Padding(
                padding: const EdgeInsets.only(top: 3),
                child: SizedBox(
                    width: 80,
                    child: RfText(type,
                        weight: FontWeight.w700,
                        color: const Color(0xffa89fd6),
                        spacing: .3,
                        align: TextAlign.right))),
          ]),
          const SizedBox(height: 12),
          if (input) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(context, '我的作答: ', q['mine'] ?? '', ok),
              if (!ok)
                _chip(context, '正确答案: ', q[mock ? 'correct' : 'a'], true),
            ]),
            const SizedBox(height: 10),
          ] else if (pills) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final option in opts)
                _pill('$option', norm(option) == answer, norm(option) == mine)
            ]),
            const SizedBox(height: 10),
          ] else ...[
            for (final option in opts)
              Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 1.5,
                          color: norm(option) == answer
                              ? const Color(0xffa7d98a)
                              : norm(option) == mine
                                  ? const Color(0xfff0a9a9)
                                  : const Color(0xffece4d6)),
                      color: norm(option) == answer
                          ? const Color(0xffe8f5e0)
                          : norm(option) == mine
                              ? const Color(0xfffbe4e4)
                              : null,
                      borderRadius: BorderRadius.circular(11)),
                  child: Row(children: [
                    Expanded(child: RfText('$option', weight: FontWeight.w600)),
                    if (norm(option) == answer)
                      _mark('✓', true, 20)
                    else if (norm(option) == mine)
                      _mark('✕', false, 20),
                  ])),
          ],
          if (ev != null && ev != '') ...[
            // Last option margin8 and evidence margin10 collapse to10.
            SizedBox(height: input || pills ? 0 : 2), RfEvidence('"$ev"'),
            const SizedBox(height: 8),
          ],
          if (en != null && en != '')
            RfText(en, size: 10.5, height: 1.5, color: const Color(0xff6b6255)),
          if (zh != null && zh != '') ...[
            const SizedBox(height: 2),
            RfText(zh, size: 10.5, height: 1.5, color: const Color(0xffa49a8a))
          ],
        ]));
  }

  Widget _chip(BuildContext context, String label, String value, bool ok) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
              color: Color(ok ? 0xffe8f5e0 : 0xfffbe4e4),
              borderRadius: BorderRadius.circular(9)),
          child: Text.rich(
              TextSpan(children: [
                TextSpan(text: rfTranslate(context, label)),
                TextSpan(
                    text: rfTranslate(context, value),
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontWeight: FontWeight.w800,
                        color: Color(ok ? 0xff3f6b1f : 0xff93383b)))
              ]),
              style: TextStyle(
                  fontSize: 12, color: Color(ok ? 0xff4a7a28 : 0xffa8484b))));

  Widget _pill(String text, bool correct, bool mine) => Container(
      // 390px capture: Q4/Q6 wrap2 rows; Q5 wraps3. The source's
      // fallback-font metrics differ slightly from its desktop DOM probe.
      width: switch (text) {
        'From hobby to food source' => 158.992 + (correct || mine ? 23 : 0),
        'Growing without soil' => 129 + (correct || mine ? 23 : 0),
        'The energy problem' => 126 + (correct || mine ? 23 : 0),
        _ => null,
      },
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
          color: Color(correct
              ? 0xffe8f5e0
              : mine
                  ? 0xfffbe4e4
                  : 0xffffffff),
          border: Border.all(
              width: 1.5,
              color: Color(correct
                  ? 0xffa7d98a
                  : mine
                      ? 0xfff0a9a9
                      : 0xffece4d6)),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (correct || mine) ...[
          _mark(correct ? '✓' : '✕', correct, 17),
          const SizedBox(width: 6)
        ],
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RfText(text, size: 10.5, weight: FontWeight.w600))),
      ]));
}

Widget _mark(String text, bool ok, double size) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Color(ok ? 0xff7cb518 : 0xffe5484d), shape: BoxShape.circle),
    child: Text(text,
        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: 12,
            height: 1,
            color: Colors.white,
            fontWeight: FontWeight.w800)));
