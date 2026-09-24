import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'practice_widgets.dart';

class PracticeCongrats extends StatelessWidget {
  const PracticeCongrats({super.key, required this.second});
  final bool second;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    String tr(String raw) =>
        Translator.instance.translate(raw, app.lang) ?? raw;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Center(
              child: Image.asset('assets/images/otter_welcome.png',
                  width: 180, fit: BoxFit.contain))),
      Text.rich(
          TextSpan(children: [
            TextSpan(text: tr('发音模块')),
            TextSpan(
                text: tr('完成啦！'),
                style: const TextStyle(color: SurgoColors.yellow))
          ]),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: SurgoColors.ink)),
      Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 26),
          child: T(
              second
                  ? '「个性化 /l/·/r/ 词汇练习」已收入你的发音进度，本阶段全部模块已完成～'
                  : '「/l/ 与 /r/ —— 发音要领」已收入你的发音进度，后续模块随之解锁～',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.6, color: Color(0xffa99a82)))),
      Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: LayoutBuilder(builder: (context, bounds) {
            // CSS flex:1 retains each item's min-content width. Flutter's
            // equal Expanded would split “assessment” into an extra line.
            final word = tr('自评')
                .split(RegExp(r'[\s-]+'))
                .reduce((a, b) => a.length > b.length ? a : b);
            final painter = TextPainter(
                text: TextSpan(
                    text: word,
                    style: const TextStyle(
                        fontFamily: 'VioletSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                textDirection: TextDirection.ltr)
              ..layout();
            final equal = (bounds.maxWidth - 26) / 3;
            final last = app.lang == UiLang.en && painter.width > equal
                ? painter.width.ceilToDouble()
                : equal;
            final first = (bounds.maxWidth - 26 - last) / 2;
            return IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  SizedBox(
                      width: first,
                      child:
                          _stat('flag', second ? '第 2 阶段' : '第 1 阶段', '所在阶段')),
                  _divider(),
                  SizedBox(
                      width: first,
                      child: _stat('mic', second ? '3' : '2', '练习词数')),
                  _divider(),
                  SizedBox(
                      width: last,
                      child: _stat('wave', '自评', '最佳准确度', badge: true)),
                ]));
          })),
      Row(key: const ValueKey('practice-congrats-actions'), children: [
        Expanded(
            child: PracticeButton('返回发音课程',
                onTap: () => app.go(SurgoPage.pronCourse))),
        const SizedBox(width: 12),
        Expanded(
            child: PracticeButton(
                app.examType == ExamType.toefl ? '返回托福首页' : '返回雅思首页',
                primary: false,
                onTap: () => app.go(SurgoPage.ielts))),
      ]),
    ]);
  }

  Widget _divider() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Container(width: 1, color: SurgoColors.line));
  Widget _stat(String icon, String value, String label, {bool badge = false}) =>
      Column(children: [
        Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: icon == 'mic'
                    ? const Color(0xffe3f2e6)
                    : SurgoColors.yellowTint),
            child: Center(
                child: SvgPicture.string(
                    practiceSvg(icon, icon == 'mic' ? '#5aa06a' : '#E0A000'),
                    width: 22,
                    height: 22))),
        T(value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SurgoColors.ink)),
        const SizedBox(height: 3),
        T(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xffa99a82))),
        if (badge)
          Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: BoxDecoration(
                  color: SurgoColors.yellowTint,
                  borderRadius: BorderRadius.circular(7)),
              child: const T('本次未获得自动评分',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xffc0902a)))),
      ]);
}
