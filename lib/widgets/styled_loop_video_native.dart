import 'package:flutter/material.dart';
import 'loop_video.dart';

/// Local muted media on native platforms, no embedded webpage.
class StyledLoopVideo extends StatelessWidget {
  const StyledLoopVideo(
      {super.key,
      required this.asset,
      required this.width,
      required this.height,
      this.brightness = 1,
      this.radius = 0});
  final String asset;
  final double width, height, brightness, radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColorFiltered(
          colorFilter: ColorFilter.matrix([
            brightness,
            0,
            0,
            0,
            0,
            0,
            brightness,
            0,
            0,
            0,
            0,
            0,
            brightness,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: LoopVideo(asset: asset, width: width, height: height)));
}
