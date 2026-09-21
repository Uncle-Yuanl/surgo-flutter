import 'package:flutter/material.dart';

import 'tokens.dart';

/// 全局 ThemeData —— 把 tokens 接进 Material 体系，让未显式设样式的文字/图标
/// 也落在同一套颜色上。
class SurgoTheme {
  const SurgoTheme._();

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: SurgoColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: SurgoColors.yellow,
        onPrimary: SurgoColors.onYellowStrong,
        secondary: SurgoColors.blue,
        surface: SurgoColors.card,
        onSurface: SurgoColors.ink,
        error: SurgoColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: SurgoColors.ink,
        displayColor: SurgoColors.ink,
        fontFamily: SurgoFontFamily.primary,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: SurgoColors.line,
      // 原型没有 Material 水波纹，点击反馈统一用 scale(0.97~0.98)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}