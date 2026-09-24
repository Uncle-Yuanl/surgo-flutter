import '../../widgets/source_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/loop_video.dart';
import '../../widgets/t.dart';
import 'mock_intro_content.dart';

/// 全屏「准备好了吗？」弹窗 —— 端口自原型 `openMockReadySheet`（app.js 1990-2024）。
///
/// 原型行为：铺满状态栏以下的全屏卡片，循环播放 `assets/ready.mp4`，
/// 进度 0→100%（默认 DUR=2000ms，每 50ms 刷新一次），到 100% 后延时 220ms
/// `closeModal()` 再执行 `done()`。这里用一个不可点掉的 dialog + 2s 动画复刻，
/// 到点自动 pop；[showMockReadySheet] 的 Future 在弹窗关闭后完成，调用方再执行
/// 状态重置与跳页（即原型的 `o.done`）。
///
/// 视频用本地资源，走 [LoopVideo]（静音循环），与原型 muted/loop/autoplay 一致。
Future<void> showMockReadySheet(BuildContext context, MockReadyCopy copy) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: false,
    builder: (_) => _MockReadySheet(copy: copy),
  );
}

class _MockReadySheet extends StatefulWidget {
  const _MockReadySheet({required this.copy});
  final MockReadyCopy copy;
  @override
  State<_MockReadySheet> createState() => _MockReadySheetState();
}

class _MockReadySheetState extends State<_MockReadySheet>
    with SingleTickerProviderStateMixin {
  // 源默认 DUR=2000ms。
  late final AnimationController progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  Timer? _tail;

  @override
  void initState() {
    super.initState();
    progress.addStatusListener((status) {
      // 源：p>=100 后 setTimeout(...,220) 再 closeModal + done。
      if (status == AnimationStatus.completed) {
        _tail = Timer(const Duration(milliseconds: 220), () {
          if (mounted) Navigator.of(context, rootNavigator: false).pop();
        });
      }
    });
    progress.forward();
  }

  @override
  void dispose() {
    _tail?.cancel();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.copy;
    return Dialog(
      // User 2026-09-24: keep the card off the phone edges and show the whole
      // illustration, instead of the source's edge-to-edge sheet.
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: SurgoRadius.dialogAll),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // gs-hero：ready.mp4 + 标题
          const LoopVideo(
              asset: 'assets/video/ready.mp4',
              width: 168,
              height: 150,
              fit: BoxFit.contain),
          const SizedBox(height: 16),
          T(c.title, textAlign: TextAlign.center, style: SurgoText.sheetTitle),
          const SizedBox(height: 18),
          // gs-foot：说明 / 进度条 / 百分比 / 备注
          T(c.sub, textAlign: TextAlign.center, style: SurgoText.cardDesc),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: progress,
            builder: (_, __) => Column(children: [
              LinearProgressIndicator(
                value: progress.value,
                color: SurgoColors.yellow,
                backgroundColor: SurgoColors.track,
              ),
              const SizedBox(height: 8),
              SourceText('${(progress.value * 100).round()}%'),
            ]),
          ),
          const SizedBox(height: 14),
          T(c.note, textAlign: TextAlign.center, style: SurgoText.cardDesc),
        ]),
      ),
    );
  }
}
