import '../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import '../widgets/t.dart';

/// Source V.exam + selectExam. Selecting a card only changes its highlight;
/// only its arrow sets examType and navigates. IELTS starts selected on render.
class ExamSelectionPage extends StatefulWidget {
  const ExamSelectionPage({super.key});
  @override
  State<ExamSelectionPage> createState() => _ExamSelectionPageState();
}

class _ExamSelectionPageState extends State<ExamSelectionPage> {
  ExamType selected = ExamType.ielts;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(children: [
        Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Opacity(
                opacity: .5,
                child: Center(
                    child: Image.asset('assets/images/surgo_logo.png',
                        width: 150)))),
        Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 30),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                      padding: EdgeInsets.only(top: 40, bottom: 22),
                      child: Column(children: [
                        T('选择考试类型',
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5)),
                        SizedBox(height: 6),
                        T('Select one that applies to you',
                            style: TextStyle(
                                fontSize: 11, color: SurgoColors.muted))
                      ])),
                  const SizedBox(height: 10),
                  for (final exam in ExamType.values) ...[
                    _ExamCard(
                        exam: exam,
                        selected: selected == exam,
                        onSelect: () => setState(() => selected = exam),
                        onEnter: () {
                          final state = context.read<AppState>();
                          state.examType = exam;
                          state.go(SurgoPage.ielts);
                        }),
                    if (exam == ExamType.ielts) const SizedBox(height: 18),
                  ],
                ])),
      ]));
}

class _ExamCard extends StatelessWidget {
  const _ExamCard(
      {required this.exam,
      required this.selected,
      required this.onSelect,
      required this.onEnter});
  final ExamType exam;
  final bool selected;
  final VoidCallback onSelect, onEnter;
  @override
  Widget build(BuildContext context) {
    final ielts = exam == ExamType.ielts;
    return AnimatedScale(
        scale: selected ? 1 : .97,
        duration: const Duration(milliseconds: 280),
        child: GestureDetector(
            key: ValueKey('select-${exam.name}'),
            onTap: onSelect,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 242,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: selected
                        ? const Color(0xFFF6C238)
                        : const Color(0xFFE4DED2),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                                color: Color(0x24000000),
                                blurRadius: 34,
                                offset: Offset(0, 16))
                          ]
                        : null),
                child: Stack(children: [
                  Positioned(
                      right: ielts ? -18 : 6,
                      bottom: -8,
                      child: IgnorePointer(
                          child: Opacity(
                              opacity: selected ? 1 : .2,
                              child: Transform.scale(
                                  scale: selected ? (ielts ? 1.04 : 1.03) : 1,
                                  child: ColorFiltered(
                                      colorFilter: ColorFilter.matrix(selected
                                          ? const [
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0
                                            ]
                                          : const [
                                              .2126,
                                              .7152,
                                              .0722,
                                              0,
                                              0,
                                              .2126,
                                              .7152,
                                              .0722,
                                              0,
                                              0,
                                              .2126,
                                              .7152,
                                              .0722,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0
                                            ]),
                                      child: Image.asset(
                                          'assets/images/${ielts ? 'otter_study.png' : 'otter_start5.png'}',
                                          width: ielts ? 230 : 240,
                                          fit: BoxFit.contain)))))),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            T(ielts ? '雅思备考' : '托福备考',
                                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -.4,
                                    color: selected
                                        ? const Color(0xFF241D05)
                                        : const Color(0xFF3A352C))),
                            const SizedBox(height: 3),
                            SourceText(exam.label,
                                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: selected
                                        ? const Color(0x8C3C2E00)
                                        : const Color(0x803A352C))),
                            const SizedBox(height: 12),
                            FractionallySizedBox(
                                widthFactor: .58,
                                child: T(
                                    ielts
                                        ? '学术类雅思，涵盖听力、阅读、写作、口语四项完整训练。'
                                        : '托福 iBT 综合训练，模拟真实机考环境。',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        height: 1.5,
                                        color: selected
                                            ? const Color(0xB83C2E00)
                                            : const Color(0x993A352C)))),
                          ])),
                  if (selected)
                    Positioned(
                        left: 26,
                        bottom: 24,
                        child: Semantics(
                            button: true,
                            label: '进入 ${exam.label}',
                            child: GestureDetector(
                                key: ValueKey('enter-${exam.name}'),
                                onTap: onEnter,
                                child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF241D05),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 16,
                                              offset: Offset(0, 6))
                                        ]),
                                    alignment: Alignment.center,
                                    child: const SourceText('→',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white)))))),
                ]))));
  }
}
