import 'package:flutter/material.dart';

/// 入场动效：淡入 + 从下往上升。
///
/// 用户 2026-09-25：开屏页与登录页要有动效，登录的面板从下往上升。
///
/// 页面首帧后自动播放一次，不循环、不随重建反复触发。
/// [delay] 用来让同一页里的多个元素依次入场（错峰更自然）。
/// [offsetY] 是起始下移距离：面板类用大值（整块升起），文字/按钮用小值。
class AuthRise extends StatefulWidget {
  const AuthRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offsetY = 28,
    this.curve = Curves.easeOutCubic,
    this.fade = true,
  });

  final Widget child;
  final Duration delay, duration;
  final double offsetY;
  final Curve curve;

  /// 面板类元素应设为 false：真实的面板升起是不透明的，
  /// 带淡入会在上升途中透见底图，显得像幽灵。
  final bool fade;

  @override
  State<AuthRise> createState() => _AuthRiseState();
}

class _AuthRiseState extends State<AuthRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> t =
      CurvedAnimation(parent: c, curve: widget.curve);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      // 首帧之后再起步，避免和页面切换动画抢同一帧。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c.forward();
      });
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: t,
      builder: (_, child) {
        final moved = Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - t.value)), child: child);
        if (!widget.fade) return moved;
        return Opacity(opacity: t.value.clamp(0.0, 1.0), child: moved);
      },
      child: widget.child);
}
