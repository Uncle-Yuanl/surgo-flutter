import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';

/// Native rendering of writingBarChart's exact300×190 source coordinates.
class WritingSourceChart extends StatelessWidget {
  const WritingSourceChart({super.key, required this.task});
  final Map<String, dynamic> task;
  Widget legend() => Wrap(spacing: 16, runSpacing: 6, children: [
        for (final s in task['chartSeries'] as List)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                    color: _color(s['color']),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            SourceText(s['name'],
                style: const TextStyle(fontSize: 10, color: Color(0xff6b6255)))
          ])
      ]);
  Widget plot() => AspectRatio(
      aspectRatio: 300 / 190,
      child: CustomPaint(
          key: const ValueKey('writing-chart-plot'),
          painter: WritingChartPainter(task)));
  @override
  Widget build(BuildContext context) => GestureDetector(
      key: const ValueKey('writing-chart-open'),
      onTap: () => showDialog<void>(
          context: context,
          useRootNavigator: false,
          barrierColor: const Color(0x73140f05),
          builder: (ctx) => Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              child: DefaultTextStyle(
                  style: DefaultTextStyle.of(context).style,
                  child: Stack(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 22),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(right: 40),
                                  child: SourceText(task['chartTitle'] ?? '',
                                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          height: 1.4))),
                              const SizedBox(height: 14),
                              legend(),
                              const SizedBox(height: 14),
                              plot(),
                            ])),
                    Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                            key: const ValueKey('writing-chart-close'),
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: Color(0xfff1efe9),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,size:11,color:Color(0xff6a6357))))),
                  ])))),
      child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SurgoColors.line),
              borderRadius: BorderRadius.circular(14)),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (task['chartTitle'] != null) ...[
                SourceText(task['chartTitle'],
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff3a352c))),
                const SizedBox(height: 8)
              ],
              legend(),
              const SizedBox(height: 6),
              plot(),
              const SizedBox(height: 2), // Source inline SVG baseline descent.
            ]),
            Positioned(
                right: -4,
                bottom: 2,
                child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: const Color(0x0f1c1a17),
                        borderRadius: BorderRadius.circular(7)),
                    child: const Text('⤢',
                        style:
                            TextStyle(fontSize: 10, color: Color(0xff6a6357)))))
          ])));
}

Color _color(String s) =>
    Color(int.parse(s.replaceFirst('#', 'ff'), radix: 16));

class WritingChartPainter extends CustomPainter {
  WritingChartPainter(this.task);
  final Map<String, dynamic> task;
  static double oneDecimal(double x) => (x * 10).round() / 10;
  static List<Rect> barRects(Map<String, dynamic> task) {
    final years = task['chartYears'] as List,
        series = task['chartSeries'] as List;
    if (years.isEmpty || series.isEmpty) {
      return [];
    }
    final groupW = 266 / years.length,
        barW = math.max(
            8.0, (groupW * .62 - 6 * (series.length - 1)) / series.length);
    return [
      for (var gi = 0; gi < years.length; gi++)
        for (var si = 0; si < series.length; si++)
          Rect.fromLTWH(
              oneDecimal(26 +
                  groupW * gi +
                  (groupW - (barW * series.length + 6 * (series.length - 1))) /
                      2 +
                  si * (barW + 6)),
              oneDecimal(8 + 156 - 156 * (series[si]['data'][gi] as num) / 100),
              oneDecimal(barW),
              oneDecimal(156 * (series[si]['data'][gi] as num) / 100))
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 190);
    final paint = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xffeee7d8);
    void text(String s, double x, double y, Color color, {bool end = false}) {
      final p = TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(
                  fontFamily: 'VioletSans', fontSize: 10, color: color)),
          textDirection: TextDirection.ltr)
        ..layout();
      final baseline =
          p.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      p.paint(canvas, Offset(x - (end ? p.width : p.width / 2), y - baseline));
    }

    for (var v = 0; v <= 100; v += 20) {
      final y = oneDecimal(8 + 156 * (1 - v / 100));
      canvas.drawLine(Offset(26, y), Offset(292, y), paint);
      text('$v', 21, oneDecimal(y + 3), const Color(0xffb7b0a3), end: true);
    }
    final series = task['chartSeries'] as List,
        years = task['chartYears'] as List,
        rects = barRects(task);
    for (var i = 0; i < rects.length; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rects[i], const Radius.circular(2)),
          Paint()..color = _color(series[i % series.length]['color']));
    }
    for (var gi = 0; gi < years.length; gi++) {
      text('${years[gi]}', oneDecimal(26 + 266 / years.length * (gi + .5)), 181,
          const Color(0xff8a8474));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WritingChartPainter oldDelegate) =>
      oldDelegate.task != task;
}
