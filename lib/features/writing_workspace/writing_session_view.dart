import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'writing_controller.dart';
import 'writing_source_chart.dart';

/// Only the confirmation page; controller, planner and compose timers untouched.
class WritingSessionView extends StatelessWidget {
  const WritingSessionView({super.key, required this.controller});
  final WritingController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, app = context.watch<AppState>();
    final t = c.task;
    final zh = app.lang == UiLang.zh,
        mock = app.session['sessionMode'] == 'mock';
    final label = c.key == 'email'
        ? 'Writing Email'
        : c.key == 'task2'
            ? 'Writing Task 2'
            : 'Writing Task 1';
    final nav = Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
        child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
                key: const ValueKey('writing-session-home'),
                onTap: () => app.go(SurgoPage.ielts),
                child: SvgPicture.asset('assets/images/home_icon.svg',
                    width: 24, height: 24))));
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
          padding: EdgeInsets.only(top: 2, bottom: 10),
          child: WritingSourceSteps(current: 1)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Tag(mock ? '模拟考' : '日常训练', purple: mock),
        _Tag(
            '${app.examType == ExamType.toefl ? 'TOEFL' : 'IELTS'} ${zh ? '写作' : 'Writing'}',
            purple: true),
      ]),
      const SizedBox(height: 10),
      Padding(
          // Inline source spans leave a baseline descent below their16/17px boxes.
          padding: EdgeInsets.only(bottom: 16 + (zh ? 2.5 : 3)),
          child: Wrap(
              spacing: 18,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Meta('doc', label),
                _Meta('check', '${t['minWords'] ?? 250} word'),
                _Meta('calendar', '${t['minutes'] ?? 40} min'),
              ])),
      Container(
          key: const ValueKey('writing-prompt-card'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SurgoColors.line),
              borderRadius: BorderRadius.circular(22),
              boxShadow: SurgoShadow.card),
          // Normal HTML whitespace collapses embedded blank lines. Raw task is unchanged.
          child: SourceText(
              (t['prompt'] as String? ?? '').replaceAll(RegExp(r'\s+'), ' '),
              key: const ValueKey('writing-prompt'),
              style: const TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 17,
                  height: 1.55,
                  color: Color(0xff3a352c)))),
      if (t['chartSeries'] != null) ...[
        const SizedBox(height: 16),
        WritingSourceChart(task: t)
      ] else if (t['chartDesc'] != null) ...[
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: SurgoColors.yellowTint,
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const T('图表说明',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w800)),
              SourceText(t['chartDesc'],
                  style: const TextStyle(fontSize: 12, height: 1.6))
            ]))
      ],
      // Source margins 16 (card bottom) and 14 (button row top) collapse to16.
      const SizedBox(height: 16),
      Material(
          color: SurgoColors.yellow,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
              key: const ValueKey('writing-confirm'),
              onTap: c.startPlan,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: T('确认题目',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 13,
                          height: (zh ? 18 : 15) / 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff3a2e00)))))),
      const SizedBox(height: 18),
    ]);
    return LayoutBuilder(builder: (context, bounds) {
      if (!bounds.hasBoundedHeight) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nav, content]);
      }
      return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            nav,
            Expanded(
                child: SingleChildScrollView(
                    key: const ValueKey('writing-session-scroll'),
                    child: content)),
          ]));
    });
  }
}

class WritingSourceSteps extends StatelessWidget {
  const WritingSourceSteps({super.key, required this.current});
  final int current;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      key: const ValueKey('writing-source-steps'),
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 4),
            Container(width: 12, height: 1.5, color: const Color(0xffe8e2d5)),
            const SizedBox(width: 4)
          ],
          Container(
              key: ValueKey('writing-step-${i + 1}'),
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current
                      ? SurgoColors.yellow
                      : const Color(0xffe8e2d5)),
              child: Text('${i + 1}',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: i < current
                          ? const Color(0xff3a2e00)
                          : const Color(0xffa99a82)))),
          const SizedBox(width: 5),
          T(['生成题目', '规划作文', '提交作文', '批改与复盘'][i],
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      i < current ? SurgoColors.ink : const Color(0xffa99a82))),
        ]
      ]));
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.purple});
  final String label;
  final bool purple;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: purple ? const Color(0xffe6e2fb) : const Color(0xffdcefe0),
          borderRadius: BorderRadius.circular(20)),
      child: T(label,
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 13,
              height:
                  (context.watch<AppState>().lang == UiLang.zh ? 18 : 13) / 13,
              fontWeight: FontWeight.w700,
              color:
                  purple ? const Color(0xff6b5fc7) : const Color(0xff3f9a5c))));
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);
  final String icon, label;
  @override
  Widget build(BuildContext context) {
    const paths = {
      'doc':
          '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
      'check':
          '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/>',
      'calendar':
          '<rect x="3.5" y="5" width="17" height="16" rx="3"/><path d="M3.5 10h17M8 3.5v3M16 3.5v3"/>'
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SvgPicture.string(
          '<svg viewBox="0 0 24 24" fill="none" stroke="#8a8378" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths[icon]}</svg>',
          width: 16,
          height: 16),
      const SizedBox(width: 6),
      T(label,
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff6a6357))),
    ]);
  }
}
