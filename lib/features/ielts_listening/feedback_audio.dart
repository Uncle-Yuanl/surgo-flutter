import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../ielts_reading/review_style.dart';
import '../../theme/tokens.dart';
import '../../widgets/demo_audio.dart';

/// Source feedback play button has no onclick. Speed is a label-only local menu.
/// 演示用真实数据带着这一 Part 的录音（[ListeningReviewAudio.clip]），网页上这一条是真的播放条：
/// 播放 / 暂停，竖条按进度变深，倍速作用在播放器上。原型数据、或不在网页上，仍是上面说的样子。
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
  const ListeningReviewAudio({super.key, required this.duration, this.clip});
  final String duration;

  /// 这一 Part 的录音：{ asset, sec }；原型数据没有。
  final Map? clip;
  @override
  State<ListeningReviewAudio> createState() => _ListeningReviewAudioState();
}

class _ListeningReviewAudioState extends State<ListeningReviewAudio> {
  String speed = '1X';
  Map? get clip => demoAudio.available ? widget.clip : null;
  void _changed() => setState(() {});
  static String _mmss(int s) =>
      '${'${s ~/ 60}'.padLeft(2, '0')}:${'${s % 60}'.padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    demoAudio.addListener(_changed);
  }

  // 停不在这里：换页由 AppState.go 统一停，换 Part 由回顾页（ListeningFeedback.select）停。
  @override
  void dispose() {
    demoAudio.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clip = this.clip;
    // 全站同一时间只放一段：播放器里是这一段，才算这一条在放、有进度。
    final mine = clip != null && demoAudio.asset == clip['asset'];
    final playing = mine && demoAudio.playing;
    // 40 根竖条里放到的那几根变深（一放就有第一根，放完是全部）。
    final played = mine ? 40 * demoAudio.position / demoAudio.duration : 0;
    // 有录音就写它的真实时长（不在网页上、放不了时也是）。
    final length = (widget.clip?['sec'] as num?)?.floor();
    final button = Container(
        key: ValueKey(clip == null ? 'lf-play-inert' : 'lf-play'),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: Color(0xff6b52d6), shape: BoxShape.circle),
        child: playing
            ? const Icon(Icons.pause, size: 18, color: Colors.white)
            : const CustomPaint(
                size: Size(9, 10), painter: _ReviewPlayTriangle()));
    return Container(
      key: const ValueKey('lf-audio'),
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: const Color(0xffefeafd),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        clip == null
            ? button
            : GestureDetector(
                onTap: () => demoAudio.toggle(clip['asset'],
                    seconds: (clip['sec'] as num).toDouble()),
                child: button),
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
                                    color: Color(
                                        i - 1 < played ? 0xff6b52d6 : 0xffb9a9ef),
                                    borderRadius: BorderRadius.circular(2))))
                      ]
                    ]))),
        const SizedBox(width: 10),
        RfText(length == null ? widget.duration : _mmss(length),
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
              demoAudio.rate = double.parse(value.replaceAll('X', ''));
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
}
