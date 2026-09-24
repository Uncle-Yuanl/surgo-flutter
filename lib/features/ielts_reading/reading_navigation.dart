import 'package:flutter/material.dart';
import '../../widgets/answer_sheet_dialog.dart';
import 'reading_controller.dart';

/// 阅读日常训练的题号导航。
///
/// 用户 2026-09-24：这一版面板就是全站答题卡弹窗的基准（图 2），
/// 实现已抽到 [showAnswerSheet]，本文件只做 0 基下标与 1 基题号的换算。
Future<void> showReadingNavigation(BuildContext context, ReadingController x,
        void Function(int) jump, VoidCallback submit) =>
    showAnswerSheet(context,
        first: 1,
        count: x.total,
        answered: (n) => x.done.contains(n - 1),
        current: x.single ? null : x.index + 1,
        onJump: (n) => jump(n - 1),
        onSubmit: submit,
        tileKey: (n) => ValueKey('reading-nav-${n - 1}'),
        closeKey: const ValueKey('reading-nav-close'),
        submitKey: const ValueKey('reading-nav-submit'));
