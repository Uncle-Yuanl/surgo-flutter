import 'package:flutter/material.dart';
import '../ielts_reading/review_style.dart';
import 'feedback_audio.dart';
import 'feedback_questions.dart';
import '../../theme/tokens.dart';

const lfTitles = [
  'Transcript — Hall booking enquiry',
  'Transcript — Leisure centre tour',
  'Transcript — Tutorial on a research project',
  'Transcript — Lecture on coral reefs'
];
const lfTags = [
  '🏷 Form completion (fill in the gaps) · 表格填空（填写空缺）',
  '🏷 Matching (match the option to each item) · 匹配题（为每项选择对应选项）',
  '🏷 Multiple choice (choose the correct option) · 选择题（选出正确选项）',
  '🏷 Note completion (fill in the gaps) · 笔记填空（填写空缺）'
];

class ListeningReviewBody extends StatelessWidget {
  const ListeningReviewBody(
      {super.key, required this.part, required this.data});
  final int part;
  final Map data;
  @override
  Widget build(BuildContext context) {
    final qs = data['qs'] as List;
    // 演示用真实数据（tool/demo_export）自带题型标签和原文标题；原型数据没有这两个键，
    // 仍用上面按 Part 写死的。真实数据没有标题（title 为 null）就不画那一行。
    final Object tag = data['tag'] ?? lfTags[part - 1];
    final Object? title =
        data.containsKey('title') ? data['title'] : lfTitles[part - 1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RfCard(children: [
        if (part == 1) ...[rfTag(tag), const SizedBox(height: 10)],
        const RfHeading('原文'),
        if (title != null)
          RfText(title,
              key: const ValueKey('lf-transcript-title'),
              size: 12,
              weight: FontWeight.w700,
              color: rfMuted),
        if (part != 1) ...[
          const SizedBox(height: 8),
          rfTag(tag),
          const SizedBox(height: 6)
        ] else
          const SizedBox(height: 4),
        ListeningReviewAudio(
            key: ValueKey('lf-audio-$part'),
            duration: ['05:12', '05:48', '05:36', '05:00'][part - 1]),
        const RfText('高亮句对应每道题——带题号，绿色＝答对，红色＝答错。',
            color: Color(0xffb7b0a3), italic: true),
        const SizedBox(height: 10),
        ListeningReviewTranscript(part: part, data: data),
      ]),
      RfCard(children: [
        const RfHeading('我的作答'),
        for (final q in qs) ListeningReviewQuestion(part: part, q: q)
      ]),
    ]);
  }
}

class ListeningReviewTranscript extends StatelessWidget {
  const ListeningReviewTranscript(
      {super.key, required this.part, required this.data});
  final int part;
  final Map data;
  List<List<dynamic>> get rows {
    if (data['transcript'] is List) {
      return (data['transcript'] as List)
          .map((r) => List<dynamic>.from(r))
          .toList();
    }
    // Decode only source div/span markers, not a general HTML renderer.
    final html = data['tHtml'] as String;
    return RegExp(r'<div>(.*?)</div>', dotAll: true)
        .allMatches(html)
        .map((m) => <dynamic>[m[1]!])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <List<InlineSpan>>[];
    // 原型 Part 1-2 是 transcript 行，Part 3-4 是 tHtml；真实数据四个 Part 都给 tHtml
    // （一行里可以标多道题），所以按数据有哪一种来分，不按 Part 号。
    if (data['transcript'] is List) {
      for (final row in rows) {
        final children = <InlineSpan>[
          TextSpan(text: rfTranslate(context, row[0]))
        ];
        if (row[1] != null) {
          final q = (data['qs'] as List)
              .cast<Map>()
              .firstWhere((q) => q['n'] == row[2]);
          children.addAll(highlight(context, row[1], row[2], q['ok']));
          children.add(TextSpan(text: rfTranslate(context, row[3])));
        }
        if (part == 2 && blocks.isNotEmpty) {
          blocks.first.addAll(children);
        } else {
          blocks.add(children);
        }
      }
    } else {
      final pattern = RegExp(
          r'<span class="hit (ok|bad)">(.*?)</span><span class="qn (?:ok|bad)">(\d+)</span>',
          dotAll: true);
      for (final row in rows) {
        final s = row[0] as String;
        var pos = 0;
        final children = <InlineSpan>[];
        for (final m in pattern.allMatches(s)) {
          children.add(
              TextSpan(text: rfTranslate(context, s.substring(pos, m.start))));
          children.addAll(
              highlight(context, m[2]!, int.parse(m[3]!), m[1] == 'ok'));
          pos = m.end;
        }
        children.add(TextSpan(text: rfTranslate(context, s.substring(pos))));
        blocks.add(children);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final spans in blocks)
        Text.rich(TextSpan(children: spans),
            style: const TextStyle(fontSize: 12, height: 1.85, color: rfInk))
    ]);
  }

  List<InlineSpan> highlight(
          BuildContext context, String text, int number, bool ok) =>
      [
        const WidgetSpan(child: SizedBox(width: 2)),
        TextSpan(
            text: rfTranslate(context, text),
            style: TextStyle(
                backgroundColor: Color(ok ? 0xffdff2d8 : 0xfffbdcdc))),
        const WidgetSpan(child: SizedBox(width: 2)),
        WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Color(ok ? 0xff7cb518 : 0xffe5484d),
                        shape: BoxShape.circle),
                    child: Text('$number',
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 12,
                            height: 1,
                            color: Colors.white,
                            fontWeight: FontWeight.w800))))),
      ];
}
