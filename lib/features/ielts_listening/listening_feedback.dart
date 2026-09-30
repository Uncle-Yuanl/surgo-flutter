import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../ielts_reading/review_style.dart';
import '../ielts_reading/review_summary.dart';
import 'feedback_body.dart';
import 'listening_data.dart';

class ListeningFeedback extends StatefulWidget {
  const ListeningFeedback({super.key, required this.data});
  final IeltsListeningData data;
  @override
  State<ListeningFeedback> createState() => _ListeningFeedbackState();
}

class _ListeningFeedbackState extends State<ListeningFeedback> {
  late int part, displayPart;
  bool refreshed = false,
      tabsRefreshed = false,
      outgoing = false,
      instantShift = false;
  double shift = 0;
  final transitions = <Timer>[];
  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    part = app.session['sessionMode'] == 'mock'
        ? (app.session['lfPart'] as int? ?? 1)
        : _dailyPart(app);
    displayPart = part;
    app.session['lfPart'] = part;
  }

  int _dailyPart(AppState app) => switch (app.session['lisPart']) {
        's2' => 2,
        's3' => 3,
        's4' => 4,
        _ => 1
      };
  void select(int next) {
    if (next == part) return;
    final dir = next > part ? 1 : -1;
    context.read<AppState>().session['lfPart'] = next;
    setState(() {
      part = next;
      tabsRefreshed = true;
      instantShift = false;
      outgoing = true;
      shift = -24.0 * dir;
    });
    transitions.add(Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        displayPart = next;
        refreshed = true;
        instantShift = true;
        shift = 24.0 * dir;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              outgoing = false;
              instantShift = false;
              shift = 0;
            });
          }
        });
        WidgetsBinding.instance.scheduleFrame();
      });
    }));
  }

  @override
  void dispose() {
    for (final timer in transitions) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mock = app.session['sessionMode'] == 'mock';
    final parts = mock ? [1, 2, 3, 4] : [_dailyPart(app)];
    // 演示用真实数据（tool/demo_export）：模考回顾是另一场作答（mockFeedback），日常每个
    // Part 是各自的一次练习；总评（review：估分、对题数、总评文字、薄弱项）模考一份、
    // 日常每个 Part 一份。原型数据没有这些键，下面各自用原来写死的值。
    final Map feedback = (mock ? widget.data.raw['mockFeedback'] : null) ??
        widget.data.raw['feedback'];
    final Map? review = (mock ? feedback : feedback['$part'])['review'];
    final List? weak = review?['weak'];
    return ReviewTextScope(
        route: 'listeningFeedback',
        child: Builder(
            builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RfNav(title: '练习回顾'),
                      RfSummary(
                          right: review?['right'] ?? 2,
                          total: review?['total'] ?? 4,
                          mock: false,
                          band: review == null
                              ? '6.5'
                              : review['band'] as String?,
                          text: review == null ? null : review['text'] ?? '',
                          english:
                              'You scored 2 of 4 across four sections. You are reliable on directly stated facts, but lose marks on distractors — where a speaker mentions a wrong option before confirming the right one (Q2, Q4). Train yourself to wait for the confirmed answer and to catch exact figures.',
                          chinese:
                              '四个部分共 4 题答对 2 题。你对直接陈述的事实可靠，但在干扰项上失分——说话人在确认正确答案前会先提到错误选项（第 2、4 题）。要训练自己等到被确认的答案，并抓住准确数字。'),
                      if (weak == null || weak.isNotEmpty)
                      RfCard(children: [
                        const RfHeading('薄弱项分析'),
                        const SizedBox(height: 8),
                        const RfText('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',
                            size: 10.5, color: rfMuted),
                        const SizedBox(height: 14),
                        if (weak != null)
                          for (final w in weak) ...[
                            rfTag(w['label'], weak: true),
                            const SizedBox(height: 20),
                            RfEvidence(w['text'], italic: false),
                            SizedBox(height: w == weak.last ? 14 : 20),
                          ]
                        else ...[
                        rfTag('Distractor traps', weak: true),
                        const SizedBox(height: 20),
                        const RfEvidence(
                            'Speakers often mention a wrong option first — wait for the confirmed one before you commit (cost you Q2 and Q4).',
                            italic: false),
                        const SizedBox(height: 20),
                        rfTag('Exact detail / number capture', weak: true),
                        const SizedBox(height: 20),
                        const RfEvidence(
                            'Practise dictation of numbers and key nouns; the exact figure or word is often tested (cost you Q4).',
                            italic: false),
                        const SizedBox(height: 14),
                        ],
                        RfButton('练习你最弱的题型 →',
                            key: const ValueKey('lf-practice'), onTap: () {
                          app.examType = ExamType.ielts;
                          app.go(SurgoPage.listeningDaily);
                        }),
                      ]),
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final n in parts)
                              GestureDetector(
                                  key: ValueKey('lf-part-$n'),
                                  onTap: () => select(n),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              width: 1.5,
                                              color: n == part
                                                  ? SurgoColors.yellow
                                                  : SurgoColors.line),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(
                                          tabsRefreshed
                                              ? 'Part $n'
                                              : rfTranslate(context, 'Part $n'),
                                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                              fontSize: tabsRefreshed ? 13 : 11,
                                              height: !tabsRefreshed &&
                                                      app.lang == UiLang.zh
                                                  ? 15 / 11
                                                  : 1,
                                              fontWeight: FontWeight.w700,
                                              color: Color(n == part
                                                  ? 0xff1c1a17
                                                  : 0xffa99a82))))),
                          ])),
                      AnimatedContainer(
                          key: const ValueKey('lf-body-transition'),
                          duration: instantShift
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.ease,
                          transform: Matrix4.translationValues(shift, 0, 0),
                          child: AnimatedOpacity(
                              opacity: outgoing ? 0 : 1,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.ease,
                              child: ReviewTextScope(
                                  route: 'listeningFeedback',
                                  raw: refreshed,
                                  child: ListeningReviewBody(
                                      key: ValueKey('lf-body-$displayPart'),
                                      part: displayPart,
                                      data: feedback['$displayPart'])))),
                      RfButton('回到首页',
                          key: const ValueKey('lf-finish'),
                          onTap: () => app.go(SurgoPage.ielts)),
                    ])));
  }
}
