import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'vocab_test_views.dart' show quizMuted, QuizPill;

/// Original pg-* completion layout, with its fixed 2/1/32 example statistics.
class VocabDoneView extends StatelessWidget {
  const VocabDoneView({super.key, this.pronunciation = false});
  final bool pronunciation;
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Center(
              child: Image.asset('assets/images/otter_welcome.png',
                  key: const ValueKey('vocab-done-image'),
                  width: 180,
                  fit: BoxFit.contain))),
      SourceText.rich(
          TextSpan(children: [
            TextSpan(text: pronunciation ? '今天的发音复习' : '今天的词汇复习'),
            const TextSpan(
                text: '完成啦！',
                style: TextStyle(fontSize: 26, color: SurgoColors.yellow)),
          ]),
          key: const ValueKey('vocab-done-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 28, fontWeight: FontWeight.w800)),
      Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 26),
          child: T(
              pronunciation
                  ? '你完成了 30 个单词，记忆提高了不止一点～'
                  : '你完成了 2 个单词，记忆提高了不止一点～',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.6, color: quizMuted))),
      Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Stack(children: [
            Positioned.fill(
                child: Row(children: [
              const Expanded(child: SizedBox()),
              _divider(),
              const Expanded(child: SizedBox()),
              _divider(),
              const Expanded(child: SizedBox()),
            ])),
            Row(
                key: const ValueKey('vocab-done-stats'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _Stat(
                          icon: '\u{1f4d8}',
                          value: pronunciation ? '30' : '2',
                          label: '已复习')),
                  const SizedBox(width: 13),
                  Expanded(
                      child: _Stat(
                          icon: '✓',
                          value: pronunciation ? '14' : '1',
                          label: '已掌握',
                          badge: '做得很好！',
                          green: true)),
                  const SizedBox(width: 13),
                  const Expanded(
                      child: _Stat(
                          icon: '★',
                          value: '32',
                          label: '待巩固',
                          badge: '我们会帮助你巩固的！')),
                ]),
          ])),
      Container(
          key: const ValueKey('vocab-done-note'),
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 24),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
              color: SurgoColors.yellowTint,
              borderRadius: BorderRadius.circular(14)),
          child: const T('下次复习时间已根据你的选择自动安排，有点模糊的单词，我们会稍后帮你再巩固哦～',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.5, height: 1.6, color: Color(0xffa08a4a)))),
      // Adjacent source margins (note 24 / footer 8) collapse to 24.
      IntrinsicHeight(
          child: Row(
              key: const ValueKey('vocab-done-actions'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Expanded(
                child: QuizPill(pronunciation ? '返回发音本' : '返回词汇首页',
                    padding: 16,
                    radius: 26,
                    key: const ValueKey('vocab-done-back'),
                    onTap: () => app.go(pronunciation
                        ? SurgoPage.vocabPron
                        : SurgoPage.vocab))),
            const SizedBox(width: 12),
            Expanded(
                child: QuizPill('复习待巩固单词',
                    padding: 16,
                    radius: 26,
                    key: const ValueKey('vocab-done-review'),
                    primary: false,
                    onTap: () => app.go(pronunciation
                        ? SurgoPage.vocabPronStudy
                        : SurgoPage.vocabStudy))),
          ])),
    ]);
  }

  Widget _divider() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Container(width: 1, color: SurgoColors.line));
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      this.badge,
      this.green = false});
  final String icon, value, label;
  final String? badge;
  final bool green;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            key: ValueKey('vocab-done-stat-$value'),
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    green ? const Color(0xffe3f2e6) : SurgoColors.yellowTint),
            child: Text(icon, style: const TextStyle(fontSize: 20))),
        Text(value,
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        T(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: quizMuted)),
        if (badge != null)
          Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color:
                      green ? const Color(0xffe8f5e0) : SurgoColors.yellowTint),
              child: T(badge!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: green
                          ? const Color(0xff4f8a1f)
                          : const Color(0xffc0902a)))),
      ]);
}
