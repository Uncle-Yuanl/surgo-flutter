import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../vocab_tiers/tier_source_widgets.dart' show tierIcon;
import 'book_list_widgets.dart';

/// A display adapter, not a new source of vocabulary or score data.
class BookListItem {
  const BookListItem(
      {required this.word,
      required this.ipa,
      required this.definition,
      required this.status,
      required this.tier,
      required this.onTap,
      this.score,
      this.mastered = false});
  final String word, ipa, definition, status, tier;
  final String? score;
  final bool mastered;
  final VoidCallback? onTap;
}

class BookListView extends StatelessWidget {
  const BookListView(
      {super.key, required this.pronunciation, required this.items});
  final bool pronunciation;
  final List<BookListItem> items;
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
                  key: const ValueKey('book-home'),
                  onTap: () => app.go(SurgoPage.vocab),
                  child: pronunciation
                      ? SizedBox(
                          height: 24,
                          child: Center(
                              heightFactor: 1,
                              widthFactor: 1,
                              child: T('‹ 返回',
                                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: (zh ? 18 : 13) / 13,
                                      color: const Color(0xff3a3630)))))
                      : SvgPicture.asset('assets/images/home_icon.svg',
                          width: 24, height: 24))));
      final content =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: pronunciation && !zh ? 166 : 1,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        T(pronunciation ? '我的发音本' : '我的单词本',
                            key: const ValueKey('book-title'),
                            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 26,
                                height: (zh ? 37 : 26) / 26,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        T(pronunciation ? '已加入 2 个发音训练词' : '已收藏 4 个单词',
                            style: TextStyle(
                                fontSize: 11,
                                height: (zh ? 16 : 11) / 11,
                                color: const Color(0xffa99a82))),
                      ])),
              const SizedBox(width: 14),
              // Source English pronunciation CTA is non-shrinking and clipped
              // by read-scroll. Preserve it rather than inventing two-line CTA.
              Flexible(
                  flex: pronunciation && !zh ? 170 : 1,
                  child: pronunciation && !zh
                      ? SizedBox(
                          height:
                              24 + MediaQuery.textScalerOf(context).scale(15),
                          child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: 208,
                              maxWidth: 208,
                              child: BookAction('开始发音复习',
                                  onTap: () =>
                                      app.go(SurgoPage.vocabPronStudy))))
                      : Align(
                          alignment: Alignment.topRight,
                          child: BookAction(pronunciation ? '开始发音复习' : '开始复习',
                              onTap: () => app.go(pronunciation
                                  ? SurgoPage.vocabPronStudy
                                  : SurgoPage.vocabStudy)))),
            ])),
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  Expanded(
                      child: _Stat(
                          index: row * 2 + col,
                          count: (pronunciation
                              ? ['2', '1', '1', '0']
                              : ['4', '0', '4', '0'])[row * 2 + col])),
                ],
              ])),
        ],
        const SizedBox(height: 16),
        const BookToolbar(),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          BookListTile(item: items[i]),
        ],
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
                        key: const ValueKey('book-scroll'), child: content))),
          ]));
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.index, required this.count});
  final int index;
  final String count;
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    return Container(
        key: ValueKey('book-stat-$index'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: SurgoColors.yellowTint,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
              key: ValueKey('book-stat-icon-$index'),
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: index == 1
                      ? const Color(0xffe3f2e6)
                      : index == 3
                          ? const Color(0xffeeeae2)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: index == 0
                  ? SvgPicture.string(
                      '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5a2 2 0 0 1 2-2h6v16H6a2 2 0 0 0-2 2zM20 5a2 2 0 0 0-2-2h-6v16h6a2 2 0 0 1 2 2z"/></svg>',
                      width: 22,
                      height: 22)
                  : tierIcon(['', 'check', 'pen', 'clock'][index], 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(count,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 24, height: 1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                T(['全部单词', '已掌握', '学习中', '未学习'][index],
                    style: TextStyle(
                        fontSize: 10,
                        height: (zh ? 14 : 10) / 10,
                        color: const Color(0xffa08a4a))),
              ])),
        ]));
  }
}
