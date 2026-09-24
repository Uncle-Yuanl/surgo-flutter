import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';

/// 登录注册流程的设计令牌（Figma gW9DKhEd6UuQQAnv32BlXH · Page 5）。
///
/// 设计稿画布 375×812，左右边距 25，控件宽 325。
/// 字体是 DM Sans 600 —— 工程未内嵌该字族，按既定做法回落到 Outfit
/// （同为几何无衬线，字重与观感最接近），中文继续走 fallback 链。
class AuthTokens {
  const AuthTokens._();

  /// 页面左右边距。
  static const pad = 25.0;

  /// 输入框 / 主按钮的统一高度与圆角。
  static const fieldHeight = 50.0;
  static const radius = 11.0;

  /// 输入框、次级按钮、返回键圆底的填充色。
  static const field = Color(0xfff1ece6);

  /// 主按钮黄。设计稿 #ffc71b 与 tokens 的 SurgoColors.yellow 同值，
  /// 这里直接复用 tokens，避免出现第二个"黄"。
  static const accent = SurgoColors.yellow;

  /// 正文灰（副标题、占位符）。
  static const muted = Color(0xff6d6d6d);

  /// 更浅的灰（"Remember me"、图标）。
  static const hint = Color(0xffaaaaaa);

  /// 危险色（"Disagree"）。
  static const danger = Color(0xffef2d56);

  /// 弹窗底色。
  static const sheet = Color(0xfff1ece6);

  static const family = 'Outfit';

  static TextStyle text(
          {double size = 14,
          FontWeight weight = FontWeight.w600,
          Color color = Colors.black,
          double? height}) =>
      TextStyle(
          fontFamily: family,
          fontFamilyFallback: SurgoFontFamily.fallback,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color);
}

/// 带标题的输入框（Figma: title + 50 高圆角填充框 + 左侧图标）。
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.title,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.trailing,
    this.controller,
    this.fieldKey,
  });

  final String title, hint;
  final IconData? icon;

  /// true 时按设计稿画成一排圆点（原型不接真实鉴权，这里只呈现视觉）。
  final bool obscure;
  final Widget? trailing;
  final TextEditingController? controller;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SourceText(title, style: AuthTokens.text(height: 18.2 / 14)),
        const SizedBox(height: 10),
        Container(
            key: fieldKey,
            height: AuthTokens.fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: AuthTokens.field,
                borderRadius: BorderRadius.circular(AuthTokens.radius)),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AuthTokens.hint),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: obscure
                      ? Row(
                          children: List.generate(
                              8,
                              (_) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AuthTokens.muted))))
                      : TextField(
                          controller: controller,
                          decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: hint,
                              hintStyle:
                                  AuthTokens.text(color: AuthTokens.muted)),
                          style: AuthTokens.text())),
              if (trailing != null) trailing!,
            ])),
      ]);
}

/// 主按钮（黄底 325×50，圆角 11）。
class AuthButton extends StatelessWidget {
  const AuthButton(this.label,
      {super.key,
      this.onTap,
      this.color = AuthTokens.accent,
      this.textColor = const Color(0xff0a0a0a),
      this.radius = AuthTokens.radius});

  final String label;
  final VoidCallback? onTap;
  final Color color, textColor;
  final double radius;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
          height: AuthTokens.fieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(radius)),
          child: SourceText(label,
              style: AuthTokens.text(color: textColor, height: 18.2 / 14))));
}

/// 次级按钮：浅底 + 左侧图标（Continue with Google / Phone / Apple）。
class AuthAltButton extends StatelessWidget {
  const AuthAltButton(this.label, {super.key, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
          height: AuthTokens.fieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AuthTokens.field,
              borderRadius: BorderRadius.circular(AuthTokens.radius)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 12),
            ],
            SourceText(label, style: AuthTokens.text(height: 18.2 / 14)),
          ])));
}

/// 左上角圆形返回键（48×48 浅底 + 左箭头）。
class AuthBack extends StatelessWidget {
  const AuthBack({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AuthTokens.field),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black)));
}

/// 验证码格子：一格一位，已填黄底，当前位显示竖线光标。
class AuthOtpBoxes extends StatelessWidget {
  const AuthOtpBoxes({super.key, required this.digits, this.length = 4});

  /// 已输入的数字串，按设计稿静态呈现。
  final String digits;
  final int length;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < length; i++)
          Container(
              key: ValueKey('auth-otp-$i'),
              width: 70,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: i < digits.length
                      ? AuthTokens.accent
                      : AuthTokens.field,
                  borderRadius: BorderRadius.circular(AuthTokens.radius)),
              child: SourceText(i < digits.length ? digits[i] : (i == digits.length ? '|' : ''),
                  style: AuthTokens.text(
                      size: 20,
                      weight: FontWeight.w700,
                      color: i < digits.length
                          ? Colors.black
                          : AuthTokens.muted))),
      ]);
}
