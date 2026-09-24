import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/source_text.dart';
import 'practice_controller.dart';
import 'practice_widgets.dart';
import 'practice_congrats.dart';

class PracticeContent extends StatelessWidget {
  const PracticeContent(
      {super.key,
      required this.page,
      required this.controller,
      required this.speak,
      required this.mic,
      required this.judge});
  final SurgoPage page;
  final PracticeController controller;
  final void Function(int, String) speak;
  final void Function(int) mic;
  final void Function(int, bool) judge;
  bool get second => [
        SurgoPage.pron2Lesson,
        SurgoPage.pron2Repeat,
        SurgoPage.pron2Done,
        SurgoPage.pronCongrats2
      ].contains(page);
  bool get sentence => page == SurgoPage.pronSentence;
  void go(BuildContext c, SurgoPage p) => c.read<AppState>().go(p);
  @override
  Widget build(BuildContext context) {
    final done = page == SurgoPage.pronDone || page == SurgoPage.pron2Done;
    final congrats =
        page == SurgoPage.pronCongrats || page == SurgoPage.pronCongrats2;
    return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!congrats)
            PracticeNav(onBack: () => go(context, SurgoPage.pronCourse)),
          Expanded(
              child: SingleChildScrollView(
                  key: const ValueKey('practice-scroll'),
                  child: congrats
                      ? PracticeCongrats(second: second)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              _header(context),
                              if (page == SurgoPage.pron2Lesson) ...[
                                _textCard('本模块目标',
                                    'Practise your weak /l/·/r/ words.'),
                                _textCard('讲解',
                                    'A personalised batch drawn from your weak, saved and unseen words for this sound.'),
                                _footer([
                                  PracticeButton('下一步：单词跟读',
                                      onTap: () =>
                                          go(context, SurgoPage.pron2Repeat))
                                ]),
                              ] else if (done) ...[
                                PracticeCard(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      const T('完成本模块', style: practiceTitle),
                                      const SizedBox(height: 9),
                                      T(
                                          second
                                              ? '完成需要至少一次跟读练习记录（Azure 评分或诚实自评均可）。服务端会核对练习证据后标记本阶段完成。'
                                              : '完成需要至少一次跟读练习记录（Azure 评分或诚实自评均可）。服务端会核对练习证据后解锁后续模块。',
                                          style: practiceBody),
                                      const SizedBox(height: 16),
                                      PracticeButton('标记完成', mark: true,
                                          onTap: () {
                                        context.read<AppState>().session[second
                                            ? 'pronM2Done'
                                            : 'pronM1Done'] = true;
                                        go(
                                            context,
                                            second
                                                ? SurgoPage.pronCongrats2
                                                : SurgoPage.pronCongrats);
                                      }),
                                    ])),
                                _footer([
                                  PracticeButton('上一步',
                                      primary: false,
                                      onTap: () => go(
                                          context,
                                          second
                                              ? SurgoPage.pron2Repeat
                                              : SurgoPage.pronSentence))
                                ]),
                              ] else ...[
                                if (!sentence)
                                  Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          2, 0, 2, 14),
                                      child: T(
                                          second
                                              ? '本批单词根据你的薄弱发音自动挑选，每次进入都会更新。'
                                              : '逐个跟读本模块的练习词，点 🔊 听示范。',
                                          style: practiceHint)),
                                if (sentence)
                                  _recordCard(0, practiceSentence, null, null)
                                else
                                  for (var i = 0; i < practiceWords.length; i++)
                                    _recordCard(
                                        i,
                                        practiceWords[i][0],
                                        practiceWords[i][1],
                                        practiceWords[i][2]),
                                _footer([
                                  PracticeButton('上一步',
                                      primary: false,
                                      onTap: () => go(
                                          context,
                                          second
                                              ? SurgoPage.pron2Lesson
                                              : sentence
                                                  ? SurgoPage.pronRepeat
                                                  : SurgoPage.pronListen)),
                                  PracticeButton(
                                      sentence || second
                                          ? '下一步：完成'
                                          : '下一步：句子练习',
                                      onTap: () => go(
                                          context,
                                          second
                                              ? SurgoPage.pron2Done
                                              : sentence
                                                  ? SurgoPage.pronDone
                                                  : SurgoPage.pronSentence)),
                                ]),
                              ],
                            ]))),
        ]));
  }

  Widget _textCard(String title, String text) => PracticeCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T(title, style: practiceTitle),
        const SizedBox(height: 9),
        T(text, style: practiceBody)
      ]));
  Widget _footer(List<Widget> buttons) => Padding(
      // H5 adjacent bottom 14 / top 8 margins collapse to 14, not 22.
      padding: EdgeInsets.zero,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: buttons[i])
        ],
      ]));
  Widget _header(BuildContext context) {
    final tags = [
      second ? '个性化词汇练习' : '认读与发音要领',
      '/l/ 与 /r/ 对比',
      '英音示范',
      if (second) '本次为你个性化选词'
    ];
    final colors = [
      (SurgoColors.yellowTint, const Color(0xffa08a4a)),
      (const Color(0xffe8f0fc), const Color(0xff4a7fd4)),
      (const Color(0xffeee9fb), const Color(0xff7a5fd6))
    ];
    final pages = second
        ? [SurgoPage.pron2Lesson, SurgoPage.pron2Repeat, SurgoPage.pron2Done]
        : [
            SurgoPage.pronLesson,
            SurgoPage.pronListen,
            SurgoPage.pronRepeat,
            SurgoPage.pronSentence,
            SurgoPage.pronDone
          ];
    final labels =
        second ? ['讲解', '单词跟读', '完成'] : ['讲解', '听辨', '单词跟读', '句子练习', '完成'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Wrap(spacing: 9, runSpacing: 9, children: [
            for (var i = 0; i < tags.length; i++)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                      color: colors[i > 2 ? 2 : i].$1,
                      borderRadius: BorderRadius.circular(9)),
                  child: T(tags[i],
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors[i > 2 ? 2 : i].$2))),
          ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: T(second ? '个性化 /l/·/r/ 词汇练习' : '/l/ 与 /r/ —— 发音要领',
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SurgoColors.ink))),
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 16),
          child: T(
              second
                  ? 'Personalised /l/·/r/ words'
                  : '/l/ vs /r/ — articulation',
              style: const TextStyle(fontSize: 12, color: Color(0xffa99a82)))),
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                for (var i = 0; i < pages.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  GestureDetector(
                      onTap: pages[i] == page ||
                              (!second &&
                                  page == SurgoPage.pronRepeat &&
                                  i == 4)
                          ? null
                          : () => go(context, pages[i]),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                              color: pages[i] == page
                                  ? SurgoColors.yellow
                                  : const Color(0xfff4f0e9),
                              borderRadius: BorderRadius.circular(11)),
                          child: T('${i + 1} ${labels[i]}',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: pages[i] == page
                                      ? const Color(0xff3a2e00)
                                      : const Color(0xffb7b0a3)))))
                ],
              ]))),
    ]);
  }

  Widget _recordCard(int i, String word, String? ipa, String? pos) {
    final st = controller.at(i);
    return PracticeCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (sentence)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SourceText(word,
                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: SurgoColors.ink)))
      else ...[
        Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SourceText(word,
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.ink)),
                  const SizedBox(width: 10),
                  if (ipa != null)
                    SourceText(ipa,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xffa99a82))),
                ])),
        if (pos != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SourceText(pos, style: practiceHint)),
      ],
      Row(children: [
        PracticeRoundIcon(
            key: ValueKey('speak-$i'),
            mic: false,
            active: controller.speaking == i,
            onTap: () => speak(i, word)),
        const SizedBox(width: 10),
        PracticeRoundIcon(
            key: ValueKey('mic-$i'),
            mic: true,
            recording: st.recording,
            onTap: () => mic(i)),
        const SizedBox(width: 10),
        Expanded(
            child: T(
                st.recording
                    ? '正在录音…点击停止'
                    : st.judged
                        ? '已记录你的自评'
                        : st.done
                            ? '本次未获得自动评分，请诚实评价这次朗读'
                            : second
                                ? '点击喇叭听示范 · 点击麦克风朗读：$word'
                                : '点击麦克风朗读：$word',
                style: practiceHint)),
      ]),
      if (st.done && !st.judged)
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              PracticeButton('没读好',
                  judgment: false, onTap: () => judge(i, false)),
              PracticeButton('读对了',
                  judgment: true, onTap: () => judge(i, true)),
            ])),
    ]));
  }
}
