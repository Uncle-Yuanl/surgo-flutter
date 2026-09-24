import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'review_passage.dart';
import 'review_questions.dart';
import 'review_style.dart';
import 'review_summary.dart';

class ReadingFeedbackData {
  static Map<String, dynamic>? passages;
  static Future<void> load() async {
    if (passages != null) return;
    final raw = jsonDecode(
        await rootBundle.loadString('assets/data/reading_feedback_mock.json'));
    passages = Map<String, dynamic>.from(raw['passages']);
  }
}

/// Source demo scores only: never grade the reader's transient selections.
class ReadingFeedbackPage extends StatefulWidget {
  const ReadingFeedbackPage({super.key});
  @override
  State<ReadingFeedbackPage> createState() => _ReadingFeedbackPageState();
}

class _ReadingFeedbackPageState extends State<ReadingFeedbackPage> {
  @override
  void initState() {
    super.initState();
    if (context.read<AppState>().session['sessionMode'] == 'mock') {
      ReadingFeedbackData.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>(),
        mock = context.watch<AppState>().session['sessionMode'] == 'mock';
    if (mock && ReadingFeedbackData.passages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bank = QuestionBank.instance.skill('reading', app.examType);
    final daily = bank['passages']?['monarch'] ?? bank['daily'] ?? {};
    final passage = app.session['raPas'] as int? ?? 1;
    final d = mock
        ? ReadingFeedbackData.passages!['$passage'] ??
            ReadingFeedbackData.passages!['1']
        : daily;
    final List qs = d[mock ? 'qs' : 'questions'] ?? [];
    final List all = mock
        ? ReadingFeedbackData.passages!.values
            .expand((p) => p['qs'] as List)
            .toList()
        : qs;
    final total = mock
        ? all.length
        : qs.isEmpty
            ? 3
            : qs.length;
    final right = all.where((q) => rfCorrect(q, mock: mock)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const RfNav(),
      RfSummary(right: right, total: total, mock: mock),
      RfWeakness(mock: mock),
      if (mock)
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 14),
            child: Wrap(spacing: 9, runSpacing: 9, children: [
              for (final n in [1, 2, 3])
                GestureDetector(
                    key: ValueKey('rf-passage-$n'),
                    onTap: () {
                      app.session['raPas'] = n;
                      app.go(SurgoPage.readingFeedback);
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                            color: n == passage
                                ? SurgoColors.yellow
                                : Colors.white,
                            border: Border.all(
                                color: n == passage
                                    ? SurgoColors.yellow
                                    : SurgoColors.line),
                            borderRadius: BorderRadius.circular(20)),
                        child: RfText('Passage $n',
                            size: 11,
                            weight: FontWeight.w700,
                            color: n == passage
                                ? const Color(0xff3a2e00)
                                : rfMuted))),
            ])),
      RfCard(key: const ValueKey('rf-passage-card'), children: [
        if (!mock) ...[
          rfTag('🏷 TRUE / FALSE / NOT GIVEN · 判断（正确/错误/未提及）'),
          const SizedBox(height: 10)
        ],
        const RfHeading('原文'),
        RfText(d['title'] ?? 'The Migration of Monarch Butterflies',
            key: const ValueKey('rf-passage-title'),
            size: 12,
            weight: FontWeight.w700,
            color: rfMuted),
        const SizedBox(height: 8),
        if (mock) ...[rfTag('⚖ ${d['tag']}'), const SizedBox(height: 10)],
        const RfText('高亮句对应每道题——带题号，绿色＝答对，红色＝答错。',
            color: Color(0xffb7b0a3), italic: true),
        const SizedBox(height: 10),
        RfPassage(
            paragraphs: d[mock ? 'paras' : 'passage'] ?? [],
            questions: qs,
            mock: mock),
      ]),
      RfCard(children: [
        const RfHeading('我的作答'),
        for (var i = 0; i < qs.length; i++)
          RfQuestion(q: qs[i], index: i, mock: mock),
      ]),
      const SizedBox(height: 4),
      RfButton(mock ? '回到首页' : '完成，返回首页',
          home: mock,
          key: const ValueKey('rf-finish'),
          onTap: () => app.go(SurgoPage.ielts)),
    ]);
  }
}
