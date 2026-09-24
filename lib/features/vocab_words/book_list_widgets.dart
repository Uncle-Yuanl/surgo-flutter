import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../app/i18n.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import 'book_list_view.dart';

class BookAction extends StatelessWidget {
  const BookAction(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4df5b301), blurRadius: 20, offset: Offset(0, 8))
          ]),
      child: Material(
          color: SurgoColors.yellow,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
              key: const ValueKey('book-review'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: T(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: (context.watch<AppState>().lang == UiLang.zh
                                  ? 18
                                  : 15) /
                              13,
                          color: const Color(0xff3a2e00)))))));
}

class BookToolbar extends StatelessWidget {
  const BookToolbar({super.key});
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    return LayoutBuilder(builder: (context, bounds) {
      final select = _box(context, '全部状态 ▾', kind: 'filter');
      final sort = _box(context, '最近添加 ▾', kind: 'sort');
      final view = _box(context, '☰', kind: 'view');
      // Source flex-wrap uses a120px minimum search cell, causing English
      // view toggle to wrap. Controls are inert spans, not new filter actions.
      double labelWidth(String raw, double size) {
        final app = context.read<AppState>();
        final label = Translator.instance.translate(raw, app.lang) ?? raw;
        return (TextPainter(
                    text: TextSpan(
                        text: label,
                        style: DefaultTextStyle.of(context).style.merge(
                            TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: size, fontWeight: FontWeight.w700))),
                    textDirection: TextDirection.ltr,
                    textScaler: MediaQuery.textScalerOf(context))
                  ..layout())
                .width +
            26;
      }

      final fixed = labelWidth('全部状态 ▾', 11) +
          labelWidth('最近添加 ▾', 11) +
          16 +
          (zh ? labelWidth('☰', 12) + 8 : 0);
      if (bounds.maxWidth >= 340 && fixed + 120 <= bounds.maxWidth) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            select,
            const SizedBox(width: 8),
            Expanded(child: _box(context, '🔍 搜索单词或释义', kind: 'search')),
            const SizedBox(width: 8),
            sort,
            if (zh) ...[const SizedBox(width: 8), view],
          ]),
          if (!zh) ...[const SizedBox(height: 8), view],
        ]);
      }
      return Wrap(spacing: 8, runSpacing: 8, children: [
        select,
        _box(context, '🔍 搜索单词或释义', kind: 'search'),
        sort,
        view
      ]);
    });
  }

  Widget _box(BuildContext context, String text, {required String kind}) =>
      Container(
          key: ValueKey('book-toolbar-$kind'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SurgoColors.line),
              borderRadius: BorderRadius.circular(10)),
          child: T(text,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: kind == 'view' ? 12 : 11,
                  height: kind == 'view'
                      ? 14 / 12
                      : (context.watch<AppState>().lang == UiLang.zh
                              ? (kind == 'search' ? 18 : 16)
                              : 11) /
                          11,
                  fontWeight: kind == 'filter' || kind == 'sort'
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: kind == 'search'
                      ? const Color(0xffb7b0a3)
                      : const Color(0xff6b6255))));
}

class BookListTile extends StatelessWidget {
  const BookListTile({super.key, required this.item});
  final BookListItem item;
  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    final border = item.mastered ? const Color(0xffa7d98a) : SurgoColors.yellow;
    return DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0f3c3214),
                  blurRadius: 22,
                  offset: Offset(0, 8))
            ]),
        child: Material(
            color: Colors.white,
            textStyle: DefaultTextStyle.of(context).style,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: border, width: 1.5)),
            child: InkWell(
                key: ValueKey('book-card-${item.word}'),
                hoverColor: Colors.transparent,
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 17),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                    child: SourceText(item.word,
                                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 17,
                                            height: (zh ? 24 : 17) / 17,
                                            fontWeight: FontWeight.w800))),
                                Container(
                                    key: ValueKey('book-status-${item.word}'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: item.mastered
                                            ? const Color(0xffe5f4d9)
                                            : SurgoColors.yellowTint,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: T(item.status,
                                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 10,
                                            height: (zh ? 14 : 10) / 10,
                                            fontWeight: FontWeight.w700,
                                            color: item.mastered
                                                ? const Color(0xff4f8a1f)
                                                : const Color(0xffa08a4a)))),
                              ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Flexible(
                                child: SourceText(item.ipa,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        height: 16 / 11,
                                        color: Color(0xffa99a82)))),
                            const SizedBox(width: 6),
                            SvgPicture.string(
                                '<svg viewBox="0 0 24 24" fill="none" stroke="#c99a1e" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/></svg>',
                                key: ValueKey('book-speaker-${item.word}'),
                                width: 15,
                                height: 15),
                          ]),
                          const SizedBox(height: 8),
                          SourceText(item.definition,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  height: (zh ? 17 : 12) / 12.5,
                                  color: const Color(0xff3a352c))),
                          const SizedBox(height: 14),
                          Container(
                              padding: const EdgeInsets.only(top: 12),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      top:
                                          BorderSide(color: SurgoColors.line))),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 11, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: const Color(0xfff2ede3),
                                                borderRadius:
                                                    BorderRadius.circular(9)),
                                            child: T(item.tier,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    height:
                                                        (item.score != null &&
                                                                    zh
                                                                ? 14
                                                                : 10) /
                                                            10,
                                                    color: const Color(
                                                        0xff8a8474))))),
                                    if (item.score == null)
                                      const Text('★',
                                          style: TextStyle(
                                              fontSize: 16,
                                              height: 22 / 16,
                                              color: SurgoColors.yellow))
                                    else
                                      Flexible(
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                            SvgPicture.string(
                                                '<svg viewBox="0 0 24 24" fill="none" stroke="#9a948a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10v4M8 6v12M12 8v8M16 5v14M20 10v4"/></svg>',
                                                width: 14,
                                                height: 14),
                                            const SizedBox(width: 5),
                                            Flexible(
                                                child: SourceText(item.score!,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Color(
                                                            0xff8a8474)))),
                                          ])),
                                  ])),
                        ])))));
  }
}
