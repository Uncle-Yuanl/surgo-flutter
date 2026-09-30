import 'package:flutter/material.dart';

/// 演示用真实数据（tool/demo_export）带的题图：后端存的原图 PNG，随 demo_data/ 一起盖进
/// assets/data/。原型数据没有 figure 这个键，各页面仍画自己原来的示意图。
///
/// 铺满宽度，按原图宽高比先留好位置（图解码完之前版面不跳），最高 320。
class ExamFigure extends StatelessWidget {
  const ExamFigure(this.figure, {super.key});

  /// `{asset, width, height, alt?}`，宽高是原图像素。
  final Map figure;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: AspectRatio(
          aspectRatio: (figure['width'] as num) / (figure['height'] as num),
          child: Image.asset(figure['asset'] as String,
              fit: BoxFit.contain,
              // 原图两千像素宽，缩到手机宽度时题号要看得清。
              filterQuality: FilterQuality.medium,
              semanticLabel: figure['alt'] as String?)));
}
