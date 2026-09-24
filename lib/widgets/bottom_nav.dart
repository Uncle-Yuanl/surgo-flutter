import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// 底部悬浮导航 —— 对应原型 `.fabnav` + [index.html 3775-3785] 的三个图标。
///
/// 原型的三个按钮是内联 SVG（不是图片文件），所以这里把 path 数据原样搬过来，
/// 保证图标形状与原型完全一致，而不是换一个"差不多"的 Material 图标。
///
/// 关键规则（来自 150-底部导航图标 与 app.js syncNav）：
///   - 三个图标本身是 26px，未选中灰色 #8a8a8a
///   - 中间的「考试」恒为品牌黄圆底 #FFC71B，尺寸 58px（比两侧大 3px），图标 28px
///   - 选中项（home / 学习报告）只把图标染成 #FFC71B，**不加圆底**
///     —— 原型早期版本用 .sel 加背景，后来改成 .home-yellow 只改颜色
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentPage,
    required this.onHome,
    required this.onExam,
    required this.onReport,
  });

  final String currentPage;
  final VoidCallback onHome;
  final VoidCallback onExam;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // .fabnav{left:20px;right:20px;bottom:24px;height:74px;border-radius:37px}
      left: SurgoDevice.navInset,
      right: SurgoDevice.navInset,
      bottom: SurgoDevice.navBottom,
      height: SurgoDevice.navHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        decoration: BoxDecoration(
          color: SurgoColors.navBar,
          borderRadius: BorderRadius.circular(37),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavIcon(
              svg: _homePath,
              viewBox: '0 0 24 24',
              selected: currentPage == 'ielts',
              onTap: onHome,
              semanticLabel: '首页',
            ),
            // 中间考试 FAB：恒黄、稍大
            _NavIcon(
              svg: _examPath,
              viewBox: '0 0 1024 1024',
              selected: true,
              big: true,
              onTap: onExam,
              semanticLabel: '考试',
            ),
            // 学习报告图标是描边+多条线（fill="none" stroke="currentColor"），
            // 不能用填充路径画，否则会变成一个实心方块。
            _NavIcon(
              selected: currentPage == 'report',
              onTap: onReport,
              semanticLabel: '学习报告',
              custom: (fill) => BottomNavReportIcon(hex: fill, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  /// index.html 3777 行的首页图标
  static const _homePath =
      'M12 3.1 2.8 11a1 1 0 0 0 .65 1.76H5V20a1 1 0 0 0 1 1h4v-5h4v5h4a1 1 0 0 0 1-1v-7.24h1.55A1 1 0 0 0 21.2 11L12 3.1z';

  /// index.html 3780 行的考试图标（1024 视框）
  static const _examPath =
      'M845.333 53.997H178.667c-46.021 0-83.333 37.313-83.333 83.333v749.35c0 46.021 37.313 83.333 83.333 83.333h666.667c46.021 0 83.333-37.313 83.333-83.333V137.331c-0.001-46.021-37.313-83.334-83.334-83.334zM324.5 314.027c0-22.99 18.636-41.626 41.647-41.626h291.707c23.01 0 41.646 18.636 41.646 41.626v0.061c0 22.99-18.637 41.646-41.646 41.646H366.146c-23.011 0-41.647-18.657-41.647-41.646v-0.061z m362.955 255.494l-187.5 189.514c-7.832 7.915-18.493 12.37-29.622 12.37s-21.789-4.455-29.622-12.37L336.544 653.749c-16.195-16.357-16.032-42.725 0.326-58.919 16.357-16.195 42.745-16.032 58.919 0.325l74.544 75.338 157.878-159.566c16.194-16.357 42.562-16.5 58.919-0.325 16.357 16.194 16.52 42.561 0.325 58.919z';

  /// index.html 3783 行的学习报告图标（描边样式，不是填充）
  static const _reportLines = [
    'M12 2.5V13',
    'M12 13l7.5-3.2',
    'M12 13l-7.2 4.2',
    'M12 13l6.6 5',
  ];
  static const _reportPath = 'M12 2.5 21 9l-3.44 10.5H6.44L3 9z';
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    this.svg,
    this.viewBox,
    this.custom,
    required this.onTap,
    this.selected = false,
    this.big = false,
    this.semanticLabel,
  });

  /// 填充式图标的 path 数据 + 对应 viewBox。
  final String? svg;
  final String? viewBox;

  /// 非填充图标（描边/多路径）用这个构造，参数是当前应使用的颜色串。
  final Widget Function(String hexColor)? custom;

  final VoidCallback onTap;
  final bool selected;
  final bool big;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // .fabnav .nav-ico{width:55px;height:55px;border-radius:50%}
    // .fabnav .nav-ico.exam-fab{width:58px;height:58px;background:#FFC71B}
    final box = big ? 58.0 : 55.0;
    // 图标 26px，exam-fab 28px
    final icon = big ? 28.0 : 26.0;
    // 图标颜色直接用原型里的十六进制字面量（#8a8a8a 未选中 / #FFC71B 选中），
    // 不经过 Color 往返转换，避免 SDK 版本间的取色 API 差异。
    final fill = selected ? '#FFC71B' : '#8A8A8A';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: big ? const Color(0xFFFFC71B) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: custom != null
                // 描边类图标：颜色由 custom 自己决定怎么用
                ? custom!(big ? '#141210' : fill)
                // 填充类图标：用 raw SVG 包一层，直接复用原型的内联 path
                : SvgPicture.string(
                    '<svg viewBox="$viewBox" xmlns="http://www.w3.org/2000/svg">'
                    '<path d="$svg" fill="${big ? '#141210' : fill}"/></svg>',
                    width: icon,
                    height: icon,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 学习报告图标需要描边 + 多条线，单独实现（`fill="none" stroke="currentColor"`）。
class BottomNavReportIcon extends StatelessWidget {
  const BottomNavReportIcon({super.key, required this.hex, this.size = 26});

  /// 描边颜色，直接给十六进制串（如 '#FFC71B' / '#8A8A8A'）。
  final String hex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final body = StringBuffer()
      ..write('<path d="${BottomNav._reportPath}" fill="none" stroke="$hex" '
          'stroke-width="1.8" stroke-linejoin="round"/>');
    for (final d in BottomNav._reportLines) {
      body.write('<path d="$d" fill="none" stroke="$hex" stroke-width="1.8"/>');
    }
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">$body</svg>',
      width: size,
      height: size,
    );
  }
}

/// 右上角全局按钮（设置 + 消息通知）。
///
/// 原型里这两个按钮**不随页面切换消失**（index.html 3767-3774），
/// 位置固定：`.gset{top:58px;right:10px}` / `.gnote{top:58px;right:58px}`，
/// 图标 34px、按钮盒 44px。窄屏媒体查询里缩到 40/28px。
///
/// 同时 `render()` 会按页面隐藏它们：
///   - `pf-on`（个人中心 prep）→ 设置让位给消息通知
///   - `exam-on`（雅思模考作答页）→ 右上角让给计时
class GlobalButtons extends StatelessWidget {
  const GlobalButtons({
    super.key,
    required this.onSettings,
    required this.onNotifications,
    this.showSettings = true,
    this.showNotifications = true,
  });

  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final bool showSettings;
  final bool showNotifications;

  /// 窄屏媒体查询下的尺寸（原型 index.html 3065-3071）
  static const _top = 58.0;
  static const _settingsRight = 10.0;
  static const _notifyRight = 58.0;
  static const _boxNarrow = 40.0;
  // User asked for a slight bump on both global icons (2026-09-24): 28 -> 31.
  static const _iconNarrow = 31.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top,
      left: 0,
      right: 0,
      child: SizedBox(
        height: _boxNarrow,
        child: Stack(
          children: [
            if (showNotifications)
              Positioned(
                right: showSettings ? _notifyRight : _settingsRight,
                top: 0,
                child: _GlobalIconButton(
                  asset: 'assets/images/msg_icon.svg',
                  onTap: onNotifications,
                  semanticLabel: '消息通知',
                ),
              ),
            if (showSettings)
              Positioned(
                right: _settingsRight,
                top: 0,
                child: _GlobalIconButton(
                  asset: 'assets/images/profile_icon.svg',
                  onTap: onSettings,
                  semanticLabel: '设置',
                  // .gset-btn{color:#3a2e00}
                  tint: const Color(0xFF3A2E00),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlobalIconButton extends StatelessWidget {
  const _GlobalIconButton({
    required this.asset,
    required this.onTap,
    this.semanticLabel,
    this.tint,
  });

  final String asset;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        key: ValueKey('global-$semanticLabel'),
        // .gset-btn:active{transform:scale(.92)}
        onTap: onTap,
        child: SizedBox(
          width: GlobalButtons._boxNarrow,
          height: GlobalButtons._boxNarrow,
          child: Center(
            child: _SvgOrDefault(
              asset: asset,
              size: GlobalButtons._iconNarrow,
              tint: tint,
            ),
          ),
        ),
      ),
    );
  }
}

/// 图标可能是 svg 也可能是 png（原型里混用），统一在这里兜住。
class _SvgOrDefault extends StatelessWidget {
  const _SvgOrDefault({required this.asset, required this.size, this.tint});

  final String asset;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      final pic = SvgPicture.asset(asset, width: size, height: size);
      if (tint == null) return pic;
      return ColorFiltered(
        colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
        child: pic,
      );
    }
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}