import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../pron_course/pron_frame.dart';
import '../pron_course/pron_header.dart';
import '../pron_practice/practice_widgets.dart';
import 'pron_listen_controller.dart';

const kPronListenSteps = ['讲解', '听辨', '单词跟读', '句子练习', '完成'];
Widget? buildPronListenPage(SurgoPage page) =>
    page == SurgoPage.pronListen ? const PronListenPage() : null;

class PronListenPage extends StatefulWidget {
  const PronListenPage({super.key, this.controller});
  final PronListenController? controller;
  @override
  State<PronListenPage> createState() => _PronListenPageState();
}

class _PronListenPageState extends State<PronListenPage> {
  late final PronListenController c;
  @override
  void initState() {
    super.initState();
    c = widget.controller ?? PronListenController();
    c.addListener(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(refresh);
    if (widget.controller == null) c.dispose();
    super.dispose();
  }

  void go(SurgoPage p) => context.read<AppState>().go(p);
  @override
  Widget build(BuildContext context) => PronPageFrame(
      back: SurgoPage.pronCourse,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PronLessonHeader(listening: true),
        PracticeCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const T('Listen: same word or different words?',
                  style: practiceTitle),
              const SizedBox(height: 9),
              T('第 ${c.idx + 1}/${c.total} 题',
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xffa99a82))),
              const SizedBox(height: 14),
              Wrap(
                  key: const ValueKey('listen-operations'),
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _operation('play', c.playing ? '播放中…' : '播放两个词', c.playPair,
                        play: true, selected: c.playing),
                    _operation('same', '相同', () => c.pick('same'),
                        selected: c.picked == 'same'),
                    _operation('diff', '不同', () => c.pick('diff'),
                        selected: c.picked == 'diff'),
                  ]),
              if (c.result != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: T(
                        c.result == 'ok'
                            ? '正确！'
                            : '再听一次，这组是${c.answerLabel()}的',
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.result == 'ok'
                                ? const Color(0xff2f9e44)
                                : const Color(0xffe0a000)))),
            ])),
        Row(children: [
          Expanded(
              child: PracticeButton('上一步',
                  primary: false, onTap: () => go(SurgoPage.pronLesson))),
          const SizedBox(width: 12),
          Expanded(
              child: PracticeButton('下一步：单词跟读',
                  onTap: () => go(SurgoPage.pronRepeat))),
        ]),
      ]));
  Widget _operation(String id, String text, VoidCallback action,
      {bool play = false, bool selected = false}) {
    final bg = play
        ? (selected ? SurgoColors.yellow : SurgoColors.yellowTint)
        : selected
            ? SurgoColors.yellowTint
            : Colors.white;
    final color = selected
        ? const Color(0xff3a2e00)
        : play
            ? const Color(0xffa08a4a)
            : const Color(0xff8a8474);
    return Material(
        key: ValueKey('listen-$id'),
        color: bg,
        textStyle: DefaultTextStyle.of(context).style,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
                color: play || selected ? SurgoColors.yellow : SurgoColors.line,
                width: 1.5)),
        child: InkWell(
            onTap: c.playing ? null : action,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 12.5, horizontal: play ? 19.5 : 25.5),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (play) ...[
                    SvgPicture.string(
                        practiceSvg(
                            'speaker', selected ? '#3a2e00' : '#E0A000'),
                        width: 16,
                        height: 16),
                    const SizedBox(width: 7)
                  ],
                  T(text,
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: play ? 10 : 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ]))));
  }
}
