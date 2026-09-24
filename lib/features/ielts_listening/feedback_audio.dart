import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../ielts_reading/review_style.dart';
import '../../theme/tokens.dart';

/// Source feedback play button has no onclick. Speed is a label-only local menu.
class _ReviewPlayTriangle extends CustomPainter {
  const _ReviewPlayTriangle();
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = Colors.white);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ListeningReviewAudio extends StatefulWidget {
  const ListeningReviewAudio({super.key, required this.duration});
  final String duration;
  @override
  State<ListeningReviewAudio> createState() => _ListeningReviewAudioState();
}

class _ListeningReviewAudioState extends State<ListeningReviewAudio> {
  String speed = '1X';
  @override
  Widget build(BuildContext context) => Container(
      key: const ValueKey('lf-audio'),
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: const Color(0xffefeafd),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
            key: const ValueKey('lf-play-inert'),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xff6b52d6), shape: BoxShape.circle),
            child: const CustomPaint(
                size: Size(9, 10), painter: _ReviewPlayTriangle())),
        const SizedBox(width: 10),
        Expanded(
            child: SizedBox(
                height: 24,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 40; i++) ...[
                        if (i > 1) const SizedBox(width: 2),
                        Expanded(
                            child: Container(
                                height: 24 *
                                    (i % 3 == 0
                                        ? 0.4
                                        : i.isOdd
                                            ? 0.9
                                            : 0.6),
                                decoration: BoxDecoration(
                                    color: const Color(0xffb9a9ef),
                                    borderRadius: BorderRadius.circular(2))))
                      ]
                    ]))),
        const SizedBox(width: 10),
        RfText(widget.duration,
            weight: FontWeight.w700, color: const Color(0xff6b52d6)),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
            key: const ValueKey('lf-speed'),
            tooltip: '',
            initialValue: speed,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(minWidth: 104),
            padding: EdgeInsets.zero,
            menuPadding: EdgeInsets.zero,
            onSelected: (value) {
              context.read<AppState>().session['lisSpeed'] = value;
              setState(() => speed = value);
            },
            itemBuilder: (_) => ['0.75X', '1X', '1.25X', '1.5X']
                .map((v) => PopupMenuItem<String>(
                    value: v,
                    height: 0,
                    padding: EdgeInsets.zero,
                    child: Container(
                        width: 104,
                        color: v == speed ? const Color(0xffeceae5) : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        child: Text(v,
                            style: const TextStyle(
                                fontFamily: 'VioletSans',
                                fontSize: 13.5,
                                height: 1,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff3a3630))))))
                .toList(),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffd8d0ee)),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(speed,
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 12,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff5a4b9e))),
                  const SizedBox(width: 6),
                  const Text('⌄',
                      style: TextStyle(
                          fontSize: 12, height: 1, color: Color(0xff8f82c9)))
                ]))),
      ]));
}
