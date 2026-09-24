import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'source_text.dart';
import 't.dart';

/// 音频卡 —— 以雅思听力日常训练的卡片为唯一样式标准
/// （用户 2026-09-24：托福听力/口语日常训练的音频卡都做成与它一致）。
///
/// 白底圆角 22 + 软阴影；上排标题与倍速胶囊，中排进度条配两端时间，
/// 下排四个控制键，末行耳机提示。各页只传数据与回调，不再各写一套。
class AudioCard extends StatelessWidget {
  const AudioCard({
    super.key,
    this.cardKey,
    required this.title,
    required this.subtitle,
    required this.elapsed,
    required this.total,
    required this.progress,
    required this.playing,
    required this.speedLabel,
    required this.speeds,
    required this.onSpeed,
    required this.onToggle,
    required this.onSeek,
    required this.onRestart,
    this.hint = '🎧 支持逐句回放，日常训练可反复播放同一题。',
    this.controlsEnabled = true,
  });

  /// 卡片本体的 key，供既有测试按原有标识定位。
  final Key? cardKey;

  /// 卡片标题，例如 Section 3 / 听后选择回应。
  final String title;

  /// 标题下的一行说明。
  final String subtitle;

  /// 已播放与总时长，形如 00:00 / 07:00。
  final String elapsed, total;

  /// 进度 0..1。
  final double progress;
  final bool playing;

  /// 倍速当前值与可选值，例如 1X。
  final String speedLabel;
  final List<String> speeds;
  final ValueChanged<String> onSpeed;
  final VoidCallback onToggle, onRestart;

  /// 前后跳转，单位秒（负数为回退）。
  final ValueChanged<int> onSeek;
  final String hint;

  /// 播放中禁用作答类页面会把控制键置灰。
  final bool controlsEnabled;

  @override
  Widget build(BuildContext context) => Container(
      key: cardKey ?? const ValueKey('audio-card'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x143c321e), blurRadius: 18, offset: Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SourceText(title,
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontFamilyFallback: SurgoFontFamily.fallback,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              SourceText(subtitle,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: SurgoColors.muted)),
            ],
          ])),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
              key: const ValueKey('audio-speed'),
              initialValue: speedLabel,
              tooltip: '',
              position: PopupMenuPosition.under,
              color: Colors.white,
              onSelected: onSpeed,
              itemBuilder: (_) => speeds
                  .map((v) => PopupMenuItem(
                      value: v,
                      child:
                          SourceText(v, style: const TextStyle(fontSize: 13))))
                  .toList(),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xfffdf6e3),
                      border: Border.all(color: const Color(0xfff0e2b4)),
                      borderRadius: BorderRadius.circular(10)),
                  child: SourceText('$speedLabel ⌄',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xffb8860b))))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          SourceText(elapsed,
              style: const TextStyle(fontSize: 13, color: SurgoColors.muted)),
          const SizedBox(width: 8),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 6,
                      color: SurgoColors.yellow,
                      backgroundColor: SurgoColors.line))),
          const SizedBox(width: 8),
          SourceText(total,
              style: const TextStyle(fontSize: 13, color: SurgoColors.muted)),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              onPressed: controlsEnabled ? () => onSeek(-15) : null,
              icon: const Icon(Icons.replay_10)),
          IconButton(
              key: const ValueKey('audio-play'),
              onPressed: controlsEnabled ? onToggle : null,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 30)),
          IconButton(
              onPressed: controlsEnabled ? () => onSeek(15) : null,
              icon: const Icon(Icons.forward_10)),
          IconButton(
              onPressed: controlsEnabled ? onRestart : null,
              icon: const Icon(Icons.replay)),
        ]),
        const SizedBox(height: 2),
        T(hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12.5, height: 1.5, color: SurgoColors.muted)),
      ]));
}
