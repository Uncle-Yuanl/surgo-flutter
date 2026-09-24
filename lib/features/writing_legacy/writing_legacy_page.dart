import '../../widgets/source_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../writing_review/review_widgets.dart';
import '../../widgets/t.dart';

/// Native rewrite of the four fixed writing "legacy" review pages from the
/// prototype: writingImprove / writingBands / writingL1Error / writingL1Detail.
///
/// Every one is entirely static in the H5 source — no user draft flows in — so
/// the exact text, fixed sample data, numbered highlight spans, tab labels and
/// NEXT/back navigation targets are exported verbatim to
/// assets/data/writing_legacy.json by tool/export_writing_legacy.cjs and
/// rendered here with native Widgets (no HTML / WebView).
const _kPages = <SurgoPage>{
  SurgoPage.writingImprove,
  SurgoPage.writingBands,
  SurgoPage.writingL1Error,
  SurgoPage.writingL1Detail,
};

/// Parent hook. Returns null for pages this module does not own.
Widget? buildWritingLegacyPage(SurgoPage page) =>
    _kPages.contains(page) ? WritingLegacyPage(page: page) : null;

// ---- source colours (index.html), CSS hex → Color ----------------------
class _C {
  static const bodyInk = Color(0xFF3A352C); // .wi-body / .wb-para color
  static const tabOff = Color(0xFFC8C1B4); // .ra-tab color
  static const annoBg = Color(0xFFFAF7F0); // .wi-anno background
  static const annoOld = Color(0xFFB7B0A3); // .wi-anno-old (struck through)
  static const annoNote = Color(0xFFA99A82); // .wi-anno-note / .ld-note
  static const errBg = Color(0xFFFBE0E0); // .le-stat.le-err background
  static const catVocabFg = Color(0xFFE5844D);
  static const catVocabBg = Color(0xFFFBE4D6);
  static const catSyntaxFg = Color(0xFF3A7BD5);
  static const catSyntaxBg = Color(0xFFDCE9FB);
  static const catStyleFg = Color(0xFF3AA38A);
  static const catStyleBg = Color(0xFFD9F2EA);
  static const ldOld = Color(0xFFE5484D); // .ld-old
  static const ldNew = Color(0xFF3AA35A); // .ld-new
  static const ldTagLowFg = Color(0xFF3AA35A);
  static const ldTagLowBg = Color(0xFFE0F2D9);
  static const noteBlue = Color(0xFF3A7BD5); // .ld-note.blue
}

class WritingLegacyPage extends StatefulWidget {
  const WritingLegacyPage({super.key, required this.page});
  final SurgoPage page;
  @override
  State<WritingLegacyPage> createState() => _WritingLegacyPageState();
}

class _WritingLegacyPageState extends State<WritingLegacyPage> {
  Map<String, dynamic>? d;
  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/data/writing_legacy.json').then((raw) {
      if (mounted) setState(() => d = jsonDecode(raw) as Map<String, dynamic>);
    });
  }

  void _go(SurgoPage p) => context.read<AppState>().go(p);

  @override
  Widget build(BuildContext context) {
    final data = d;
    if (data == null) return const Center(child: CircularProgressIndicator());
    switch (widget.page) {
      case SurgoPage.writingImprove:
        return _improve(data['improve'] as Map<String, dynamic>);
      case SurgoPage.writingBands:
        return _bands(data);
      case SurgoPage.writingL1Error:
        return _l1error(data['l1error'] as Map<String, dynamic>);
      case SurgoPage.writingL1Detail:
        return _l1detail(data['l1detail'] as Map<String, dynamic>);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- shared chrome -----------------------------------------------------
  /// `.ra-nav` — round home button + IMPROVE/L1-ERROR tab strip.
  /// [tabs] is (label, target-or-null, isOn); a null target is a plain,
  /// non-interactive span exactly as in the source markup.
  Widget _nav(List<(String, SurgoPage?, bool)> tabs) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 20),
        child: Row(children: [
          InkWell(
            key: const ValueKey('writing-legacy-home'),
            onTap: () => _go(SurgoPage.ielts),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x14643214),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ]),
              alignment: Alignment.center,
              child: SvgPicture.asset('assets/images/home_icon.svg',
                  width: 20, height: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (label, target, on) in tabs) _tab(label, target, on)
              ],
            ),
          ),
        ]),
      );

  Widget _tab(String label, SurgoPage? target, bool on) {
    final text = T(label,
        uppercase: true,
        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
          fontSize: 11, // Parent 15→13, child source runtime 13→11.
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: on ? SurgoColors.ink : _C.tabOff,
        ));
    final child = on
        ? Stack(clipBehavior: Clip.none, children: [
            Positioned(
                left: 0,
                right: 0,
                bottom: -4,
                child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                        color: SurgoColors.yellow,
                        borderRadius: BorderRadius.circular(3)))),
            text,
          ])
        : text;
    return KeyedSubtree(
        key: ValueKey('writing-legacy-tab-$label'),
        child: target == null
            ? child
            : InkWell(onTap: () => _go(target), child: child));
  }

  /// `.ra-h` — bold heading with the translucent yellow underline swash.
  Widget _sectionHead(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
              child: Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 1,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                    color: SurgoColors.yellow.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            T(title,
                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink)),
          ]))
        ]),
      );

  /// `.wb-hd` — pill-shaped back header (whole row is the tap target).
  Widget _backPill(String title, SurgoPage target) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Material(
          color: Colors.white,
          textStyle: DefaultTextStyle.of(context).style,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            key: const ValueKey('writing-legacy-back'),
            onTap: () => _go(target),
            borderRadius: BorderRadius.circular(26),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: SurgoColors.yellow, width: 1.5),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SourceText('←',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.bodyInk)),
                const SizedBox(width: 14),
                // Source: back title is content text ("Original annotations",
                // "OVERALL EVALUATION"), rendered raw.
                Expanded(
                  child: SourceText(title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _C.bodyInk)),
                ),
              ]),
            ),
          ),
        ),
      );

  /// `.ra-next` — full-width yellow action button.
  Widget _next(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ReviewButton(label,
            key: const ValueKey('writing-legacy-next'), onTap: onTap),
      );

  Widget _card(Widget child,
          {Color color = Colors.white, EdgeInsets? margin}) =>
      Container(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F3C3214), blurRadius: 22, offset: Offset(0, 8))
          ],
        ),
        child: child,
      );

  // ---- IMPROVE (ORIGINAL ANNOTATIONS) ------------------------------------
  Widget _improve(Map<String, dynamic> m) {
    final bodies = (m['bodies'] as List).cast<List<dynamic>>();
    final annos = (m['annotations'] as List).cast<Map<String, dynamic>>();
    final children = <Widget>[];
    // Source interleaves .wi-body runs with .wi-anno blocks in DOM order:
    // body[0], anno[0], body[1], ... — reproduce that ordering.
    for (var i = 0; i < bodies.length; i++) {
      children.add(_bodyRun(bodies[i]));
      if (i < annos.length) children.add(_annoBlock(annos[i]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _nav([
        ('WRITING MARK', SurgoPage.writingFeedback, false),
        ('IMPROVE', null, true),
        ('L1 ERROR', null, false)
      ]),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _sectionHead(m['title'] as String),
            ...children,
            _next('NEXT', () => _go(SurgoPage.writingBands)),
          ])),
    ]);
  }

  /// `.wi-body` — source text with inline `.wi-qn` circles and `.wi-hl` spans.
  Widget _bodyRun(List<dynamic> segs) {
    final spans = <InlineSpan>[];
    for (final seg in segs.cast<Map<String, dynamic>>()) {
      final v = seg['v'] as String;
      switch (seg['k']) {
        case 'qn':
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: SurgoColors.yellow),
                alignment: Alignment.center,
                child: SourceText(v,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SurgoColors.onYellowStrong)),
              ),
            ),
          ));
          break;
        case 'hl':
          // Source inline highlight has 3px horizontal padding at each end.
          spans.add(const WidgetSpan(child: SizedBox(width: 3, height: 0)));
          spans.add(TextSpan(
              text: v,
              style: const TextStyle(
                  fontSize: 10,
                  backgroundColor: SurgoColors.yellowTint,
                  fontWeight: FontWeight.w600)));
          spans.add(const WidgetSpan(child: SizedBox(width: 3, height: 0)));
          break;
        default:
          spans.add(TextSpan(text: v));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      child: SourceText.rich(TextSpan(children: spans),
          style:
              const TextStyle(fontSize: 12, height: 1.75, color: _C.bodyInk)),
    );
  }

  Widget _corrected(String text, double size, double boldSize, Color color) {
    final body = text.startsWith('→ ') ? text.substring(2) : text;
    return SourceText.rich(
        TextSpan(children: [
          const TextSpan(text: '→ '),
          TextSpan(
              text: body,
              style:
                  TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: boldSize, fontWeight: FontWeight.w700)),
        ]),
        style: TextStyle(fontSize: size, height: 1.5, color: color));
  }

  /// `.wi-anno` — struck-through original / neutral rewrite / grey note.
  Widget _annoBlock(Map<String, dynamic> a) => Container(
        margin:
            EdgeInsets.zero, // Adjacent body margins collapse to 14px in CSS.
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _C.annoBg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: SurgoColors.yellow),
              alignment: Alignment.center,
              child: SourceText(a['n'] as String,
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: SurgoColors.onYellowStrong)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: SourceText(a['old'] as String,
                  style: const TextStyle(
                      fontSize: 10,
                      color: _C.annoOld,
                      decoration: TextDecoration.lineThrough)),
            ),
          ]),
          const SizedBox(height: 10),
          _corrected(a['neu'] as String, 12, 10, _C.bodyInk),
          const SizedBox(height: 10),
          SourceText(a['note'] as String,
              style: const TextStyle(
                  fontSize: 10, height: 1.6, color: _C.annoNote)),
        ]),
      );

  // ---- BANDS (opening paragraph per band) --------------------------------
  Widget _bands(Map<String, dynamic> data) {
    final bands = (data['bands'] as List).cast<Map<String, dynamic>>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _nav([
        ('WRITING MARK', SurgoPage.writingFeedback, false),
        ('IMPROVE', null, true),
        ('L1 ERROR', null, false)
      ]),
      _backPill(data['bandBackTitle'] as String, SurgoPage.writingImprove),
      for (final b in bands)
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHead(b['band'] as String),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: SurgoColors.yellowTint,
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < (b['stars'] as int); i++)
                Padding(
                  padding: EdgeInsets.only(
                      right: i + 1 < (b['stars'] as int) ? 5 : 0),
                  child: SvgPicture.string(
                      '<svg viewBox="0 0 24 24" fill="#f5b301"><path d="M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.8 5.9 21.4l1.4-6.8L2.2 9.9l6.9-.8z"/></svg>',
                      width: 19,
                      height: 19),
                ),
            ]),
          ),
          SourceText(b['para'] as String,
              style: const TextStyle(
                  fontSize: 12, height: 1.75, color: _C.bodyInk)),
        ])),
      _next('NEXT', () => _go(SurgoPage.writingL1Error)),
    ]);
  }

  // ---- L1 ERROR (stats + overall evaluation) -----------------------------
  Widget _l1error(Map<String, dynamic> m) {
    final stats = (m['stats'] as List).cast<Map<String, dynamic>>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _nav([
        ('WRITING MARK', SurgoPage.writingFeedback, false),
        ('IMPROVE', SurgoPage.writingImprove, false),
        ('L1 ERROR', null, true),
      ]),
      for (final s in stats) _statRow(s),
      _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHead(m['title'] as String),
          const SizedBox(height: 8),
          SourceText(m['para'] as String,
              style: const TextStyle(
                  fontSize: 12, height: 1.75, color: _C.bodyInk)),
        ]),
        margin: const EdgeInsets.only(bottom: 16), // Collapse previous 16px.
      ),
      _next('See details', () => _go(SurgoPage.writingL1Detail)),
    ]);
  }

  /// `.le-stat` row — label + big value; the Errors row is on a red fill.
  Widget _statRow(Map<String, dynamic> s) {
    final danger = s['danger'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: danger ? _C.errBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F3C3214), blurRadius: 22, offset: Offset(0, 8))
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // le-lbl is UI chrome ("Errors" etc.) → translatable.
        Expanded(
            child: T(s['label'] as String,
                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.bodyInk))),
        const SizedBox(width: 12),
        SourceText(s['value'] as String,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: danger ? SurgoColors.danger : _C.bodyInk)),
      ]),
    );
  }

  // ---- L1 DETAIL (category chips + repeated annotation card) -------------
  Widget _l1detail(Map<String, dynamic> m) {
    final cats = (m['cats'] as List).cast<Map<String, dynamic>>();
    final card = m['card'] as Map<String, dynamic>;
    final count = m['cardCount'] as int;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _nav([
        ('WRITING MARK', SurgoPage.writingFeedback, false),
        ('IMPROVE', SurgoPage.writingImprove, false),
        ('L1 ERROR', null, true),
      ]),
      _backPill(m['back'] as String, SurgoPage.writingL1Error),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final c in cats) _chip(c)]),
      ),
      for (var i = 0; i < count; i++) _detailCard(card),
      _next('The end', () => _go(SurgoPage.ielts)),
    ]);
  }

  (Color, Color) _catColors(String kind) => switch (kind) {
        'vocab' => (_C.catVocabFg, _C.catVocabBg),
        'syntax' => (_C.catSyntaxFg, _C.catSyntaxBg),
        'style' => (_C.catStyleFg, _C.catStyleBg),
        'low' => (_C.ldTagLowFg, _C.ldTagLowBg),
        _ => (SurgoColors.muted, SurgoColors.line),
      };

  /// `.ld-cat` chip.
  Widget _chip(Map<String, dynamic> c) {
    final (fg, bg) = _catColors(c['kind'] as String);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: SourceText(c['label'] as String,
          style:
              TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  /// `.ld-tag` chip (smaller radius than category chips).
  Widget _tag(Map<String, dynamic> t) {
    final (fg, bg) = _catColors(t['kind'] as String);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: SourceText(t['label'] as String,
          style:
              TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _detailCard(Map<String, dynamic> c) {
    final tags = (c['tags'] as List).cast<Map<String, dynamic>>();
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SourceText(c['old'] as String,
          style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _C.ldOld,
              decoration: TextDecoration.lineThrough)),
      const SizedBox(height: 12),
      _corrected(c['neu'] as String, 13, 11, _C.ldNew),
      const SizedBox(height: 14),
      SourceText(c['note'] as String,
          style:
              const TextStyle(fontSize: 11, height: 1.65, color: _C.annoNote)),
      const SizedBox(height: 12),
      SourceText(c['noteBlue'] as String,
          style:
              const TextStyle(fontSize: 11, height: 1.65, color: _C.noteBlue)),
      const SizedBox(height: 12),
      Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final t in tags) _tag(t)]),
    ]));
  }
}
