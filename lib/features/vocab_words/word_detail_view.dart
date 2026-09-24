import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'vocab_words_module.dart' show VocabWordData;
import 'word_detail_widgets.dart';

class WordDetailView extends StatelessWidget {
  const WordDetailView(
      {super.key, required this.data, this.pronunciation = false});
  final VocabWordData data;
  final bool pronunciation;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    return LayoutBuilder(builder: (context, bounds) {
      final nav = Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
          child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                  key: const ValueKey('word-back'),
                  onTap: () => app.go(pronunciation
                      ? SurgoPage.vocabPron
                      : SurgoPage.vocabBook),
                  child: SizedBox(
                      height: 24,
                      child: Center(
                          widthFactor: 1,
                          child: T(pronunciation ? '‹ 返回发音本' : '‹ 返回单词本',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 13,
                                  height: (zh ? 18 : 13) / 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff3a3630))))))));
      final content =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            key: const ValueKey('word-main'),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: SurgoColors.line),
                borderRadius: BorderRadius.circular(18)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WordHeader(
                      word: data.word,
                      pos: data.pos,
                      learn: data.learn,
                      book: data.book),
                  const SizedBox(height: 14),
                  Row(children: [
                    Flexible(
                        child: SourceText(data.ipa,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xff5a544b)))),
                    const SizedBox(width: 8),
                    wordIcon('speaker', size: 22)
                  ]),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xfff1efe9),
                              borderRadius: BorderRadius.circular(9)),
                          child: SourceText(data.lvl,
                              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff7a736a))))),
                  const SizedBox(height: 16),
                  Container(
                      key: const ValueKey('word-definition'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 15),
                      decoration: BoxDecoration(
                          color: const Color(0xfffdf6e3),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                              left: BorderSide(
                                  color: SurgoColors.yellow, width: 4))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SourceText(data.defZh,
                                key: const ValueKey('word-definition-title'),
                                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: (zh ? 22 : 16) / 16)),
                            const SizedBox(height: 8),
                            SourceText(data.defEn, style: wordBody),
                          ])),
                  const SizedBox(height: 20),
                  const T('例句', style: wordSection),
                  const SizedBox(height: 10),
                  Container(
                      key: const ValueKey('word-example'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 15),
                      decoration: BoxDecoration(
                          color: const Color(0xfff6f4ef),
                          borderRadius: BorderRadius.circular(12)),
                      child: data.exampleMuted != null
                          ? T(data.exampleMuted!,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xffa99a82)))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  SourceText(data.exampleEn!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.55,
                                          color: Color(0xff2a2620))),
                                  const SizedBox(height: 8),
                                  SourceText(data.exampleZh!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xff8a8378))),
                                ])),
                  const SizedBox(height: 20),
                  const T('常见搭配', style: wordSection),
                  const SizedBox(height: 10),
                  WordChips(
                      items: data.collocations, muted: data.collocationsMuted),
                ])),
        const SizedBox(height: 18),
        WordPanel(
            title: '中国学生易错点',
            icon: 'info',
            highlight: true,
            child: data.pitfallMuted == null
                ? SourceText(data.pitfall!, style: wordBody)
                : T(data.pitfallMuted!, style: wordMuted)),
        const SizedBox(height: 14),
        WordPanel(
            title: '近义词',
            icon: 'link',
            chips: true,
            child: WordChips(items: data.synonyms, muted: data.synonymsMuted)),
        const SizedBox(height: 14),
        WordPanel(
            title: '反义词',
            icon: 'ban',
            child: T(data.antonyms, style: wordMuted)),
        const SizedBox(height: 14),
        WordPanel(
            title: '词族',
            icon: 'family',
            chips: true,
            child: WordChips(items: data.family, muted: data.familyMuted)),
        const SizedBox(height: 14),
        WordPanel(
            title: '发音提示',
            icon: 'speak',
            child: T(data.pron, style: wordMuted)),
      ]);
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
                child: ClipRect(
                    child: SingleChildScrollView(
                        key: const ValueKey('word-scroll'), child: content))),
          ]));
    });
  }
}
