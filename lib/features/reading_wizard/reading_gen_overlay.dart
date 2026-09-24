import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme/tokens.dart';
import '../../widgets/t.dart';

/// 生成题目动画 —— 对应原型 `openGenSheet(done)`：
/// 全屏纯白，`waiting.mp4` 循环播放，进度 0→100%（`DUR=2000` 毫秒），
/// 到 100% 后 `setTimeout(...,220)` 再执行 `done()`。
///
/// 用法：`await ReadingGenOverlay.run(context)`，返回后再执行 doGenSession。
/// 只负责呈现动画，题目、路由规则都不在这里。
class ReadingGenOverlay {
  /// 原型 `const DUR=2000`
  static const genDuration = Duration(milliseconds: 2000);

  /// 原型 100% 后 `setTimeout(...,220)`
  static const tailDelay = Duration(milliseconds: 220);

  /// 打开全屏遮罩，播放动画，动画走完自动关闭并 resolve。
  static Future<void> run(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.white,
      barrierLabel: 'gen',
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => const _GenSheet(),
    );
  }
}

class _GenSheet extends StatefulWidget {
  const _GenSheet();
  @override
  State<_GenSheet> createState() => _GenSheetState();
}

class _GenSheetState extends State<_GenSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: ReadingGenOverlay.genDuration)
      ..addStatusListener((s) async {
        if (s == AnimationStatus.completed) {
          await Future<void>.delayed(ReadingGenOverlay.tailDelay);
          if (mounted) Navigator.of(context).pop();
        }
      })
      ..forward();

    _video = VideoPlayerController.asset('assets/video/waiting.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        _video!
          ..seekTo(Duration.zero)
          ..play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _c.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // .gs-dlg{background:#fff;padding:52px 30px 138px;justify-content:center;align-items:center}
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 52, 30, 138),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // .gs-hero{gap:24px}
                _video != null && _video!.value.isInitialized
                    // .gs-vwrap{width:170px;height:170px;overflow:hidden}
                    ? ClipRect(
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: OverflowBox(
                            maxWidth: 194,
                            maxHeight: 194,
                            child: SizedBox(
                              width: 194,
                              height: 194,
                              child: VideoPlayer(_video!),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: 170, height: 170),
                const SizedBox(height: 24),
                // .gs-ttl{font-size:23px}
                const T('正在生成题目...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 21, fontWeight: FontWeight.w800, color: SurgoColors.ink)),
                // .gs-foot{margin-top:42px;max-width:330px}
                const SizedBox(height: 42),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: Column(
                    children: [
                      // .gs-sub{margin-bottom:20px}
                      const T('正在根据你的选择准备一套全新题目，请稍候片刻。',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.5, color: SurgoColors.muted)),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          // p=Math.min(100, Math.round((now-t0)/DUR*100))
                          final p = (_c.value * 100).round().clamp(0, 100);
                          return Column(
                            children: [
                              // .gs-bar + i#gs-fill
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: p / 100,
                                  minHeight: 8,
                                  backgroundColor: SurgoColors.track,
                                  valueColor: const AlwaysStoppedAnimation(SurgoColors.yellow),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // .gs-pct
                              SourceText('$p%',
                                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 12, fontWeight: FontWeight.w700, color: SurgoColors.muted)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // .gs-note
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SourceText('✓ ', style: TextStyle(color: SurgoColors.ok, fontSize: 12)),
                          const Flexible(
                            child: T(
                              '所有任务均已保存，不会丢失。你可以放心离开，稍后回来查看成绩。',
                              style: TextStyle(fontSize: 12, height: 1.5, color: SurgoColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
