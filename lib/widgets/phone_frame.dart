import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 手机外壳 —— 对应原型 index.html 里 `<div class="phone">` 这一层。
///
/// 原型的画布是**固定 390x844**（`.phone{width:390px;height:844px;border:12px solid #111}`），
/// 并且用 `transform:scale(.9)` 整体缩放。Flutter 端在窄屏上按比例适配，
/// 宽屏（桌面/平板）保持原始尺寸居中显示，配合外面那圈 `#e9e3d9` 画布底色。
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.backgroundImage,
    this.background,
    this.fitToScreen = false,
  });

  final Widget child;

  /// `.phone{background:#fff url('assets/app_bg.png') center top/cover no-repeat}`
  /// 作答类页面会整机换成纯色（`we-bg` → #FCF8F5），此时传 [background]。
  final String? backgroundImage;
  final Color? background;

  /// true = 单机占满窗口（真机运行）；false = 画布居中 + 缩放（桌面预览）
  final bool fitToScreen;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    var scale = 1.0;
    if (!fitToScreen) {
      final availW = media.size.width - 80;
      final availH = media.size.height - 80;
      scale = (availW / SurgoDevice.outerWidth)
          .clamp(0.0, availH / SurgoDevice.outerHeight)
          .clamp(0.35, 1.0);
    } else {
      scale = (media.size.width / SurgoDevice.outerWidth).clamp(0.0, 1.0);
    }

    final phone = SizedBox(
      width: SurgoDevice.outerWidth,
      height: SurgoDevice.outerHeight,
      child: DecoratedBox(
        // 边框与圆角：`.phone{border-radius:44px;border:12px solid #111}`
        decoration: BoxDecoration(
          color: SurgoColors.deviceBlack,
          borderRadius: BorderRadius.circular(
            SurgoDevice.screenWidth == 0 ? 44 : SurgoRadius.phone + SurgoDevice.frameBorder,
          ),
          boxShadow: SurgoShadow.device,
        ),
        child: Padding(
          padding: const EdgeInsets.all(SurgoDevice.frameBorder),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SurgoRadius.phone),
            child: SizedBox(
              width: SurgoDevice.screenWidth,
              height: SurgoDevice.screenHeight,
              child: Stack(
                children: [
                  // 机身底色：固定奶油背景图，或作答页的暖白纯色
                  Positioned.fill(
                    child: background != null
                        ? ColoredBox(color: background!)
                        : _MachineBackground(image: backgroundImage),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (fitToScreen) return phone;

    final scaled = Transform.scale(scale: scale, child: phone);
    return ColoredBox(
      // body{background:#e9e3d9}
      color: SurgoColors.canvas,
      child: Center(child: scaled),
    );
  }
}

/// 机框铺的固定背景图（`.phone` 的 background-image）。
class _MachineBackground extends StatelessWidget {
  const _MachineBackground({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const ColoredBox(color: SurgoColors.card);
    }
    return Image.asset(
      image!,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }
}

/// 刘海 —— `.notch{width:150px;height:30px;background:#111;border-radius:0 0 20px 20px;z-index:60}`
class PhoneNotch extends StatelessWidget {
  const PhoneNotch({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: SurgoDevice.notchWidth,
        height: SurgoDevice.notchHeight,
        decoration: const BoxDecoration(
          color: SurgoColors.deviceBlack,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
    );
  }
}

/// 状态栏 —— `.statusbar{top:0;height:52px}` + `assets/status_bar.png`。
///
/// 原型里这是一张 390x52 的整条图片（时间/信号/电量都画在图里），
/// 所以直接铺图即可，不用自己画。
class PhoneStatusBar extends StatelessWidget {
  const PhoneStatusBar({super.key, this.image = 'assets/images/status_bar.png'});

  final String image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SurgoDevice.statusBarHeight,
      width: double.infinity,
      child: Image.asset(image, fit: BoxFit.fill),
    );
  }
}