import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// Figma 40:363 "80" —— 启动页。
///
/// 用户 2026-09-25：品牌文字换成桌面 icon/logo.jpg（已抠白转透明 PNG）；
/// 底色由黄色改为桌面素材 3333.png（与欢迎页同一张校园插画）；
/// 图片连状态栏一起铺满（shell 对本页从 top:0 起画）。
class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
      key: const ValueKey('auth-splash'),
      onTap: () => context.read<AppState>().go(SurgoPage.authWelcome),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/auth/welcome_hero.jpg',
            fit: BoxFit.cover, alignment: const Alignment(0, .05)),
        // 这张插画中部（石碑、水獬）本身是亮白的，白 logo 压上去读不出来，
        // 黑 logo 压在建筑群上同样发糊。所以在白 logo 下面垫一层模糊的黑色剪影：
        // 用 ColorFiltered 把同一张图染黑再模糊，得到贴合形状的阴影
        // （BoxShadow 只按矩形盒子投影，透明 PNG 会出现方形暗块，不能用）。
        // 用户 2026-09-25：logo 上移 200px（先 150，再追加 50）。
        // 实测原先居中（中心 y=422）时 SURGO 压在亮白石碑上，上移 50px（y=372）
        // 只是换成压玻璃幕墙，对比度改善有限；150px 才真正进到干净的天空里。
        Align(
            alignment: Alignment.center,
            child: Transform.translate(
                offset: const Offset(0, -200),
                child: SizedBox(
                width: 140,
                height: 140 * 607 / 595,
                child: Stack(fit: StackFit.expand, children: [
                  ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Color(0xcc000000), BlendMode.srcIn),
                          child: Image.asset(
                              'assets/images/auth/logo_white.png',
                              fit: BoxFit.contain))),
                  Image.asset('assets/images/auth/logo_white.png',
                      fit: BoxFit.contain),
                ])))),
      ]));
}

/// Figma 40:472 "错误页面" —— 加载失败 + RETRY。
class AuthErrorPage extends StatelessWidget {
  const AuthErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuthTokens.pad),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Image.asset('assets/images/auth/error.png',
                  width: 251, height: 274, fit: BoxFit.contain),
              const SizedBox(height: 24),
              SourceText('A mistake happened',
                  textAlign: TextAlign.center,
                  style: AuthTokens.text(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              SourceText(
                  'There was a minor error, so check the network and try refreshing',
                  textAlign: TextAlign.center,
                  style: AuthTokens.text(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AuthTokens.muted,
                      height: 1.55)),
              const SizedBox(height: 32),
              AuthButton('RETRY',
                  key: const ValueKey('auth-error-retry'),
                  onTap: () => app.go(SurgoPage.authWelcome)),
              const Spacer(),
            ]));
  }
}

/// Figma 40:500 "82" —— 欢迎页：邮箱主按钮 + 三个第三方入口。
class AuthWelcomePage extends StatelessWidget {
  const AuthWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(children: [
      // 用户 2026-09-25：上半区换成桌面素材 3333.png（SURGO 校园插画，941x1672 竖图）。
      Expanded(
          child: Container(
              width: double.infinity,
              color: AuthTokens.field,
              child: Image.asset('assets/images/auth/welcome_hero.jpg',
                  fit: BoxFit.cover,
                  // 竖构图（941x1672）。裁切位越小＝取景越靠上＝画面内容视觉下移，
                  // 且始终铺满不留白（平移会露底色，所以用 alignment 而非 translate）。
                  alignment: const Alignment(0, .05),
                  width: double.infinity,
                  height: double.infinity))),
      Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              color: Color(0xfffcf8f5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          padding: const EdgeInsets.fromLTRB(
              AuthTokens.pad, 26, AuthTokens.pad, 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SourceText('Welcome to Surgo',
                    style: AuthTokens.text(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                SourceText(
                    'If you are alrady have procery account, enter your email below.',
                    style: AuthTokens.text(
                        color: AuthTokens.muted, height: 1.55)),
                const SizedBox(height: 22),
                AuthButton('Continue with Email',
                    key: const ValueKey('auth-welcome-email'),
                    onTap: () => app.go(SurgoPage.authSignIn)),
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: Divider(color: SurgoColors.line)),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SourceText('Sign in with',
                          style: AuthTokens.text(color: AuthTokens.muted))),
                  const Expanded(child: Divider(color: SurgoColors.line)),
                ]),
                const SizedBox(height: 14),
                AuthAltButton('Continue with Google',
                    icon: Icons.g_mobiledata,
                    onTap: () => app.go(SurgoPage.authSignIn)),
                const SizedBox(height: 12),
                AuthAltButton('Continue with Phone number',
                    icon: Icons.phone_iphone,
                    onTap: () => app.go(SurgoPage.authResetPhone)),
                const SizedBox(height: 12),
                AuthAltButton('Continue with Apple',
                    icon: Icons.apple,
                    onTap: () => app.go(SurgoPage.authSignIn)),
                const SizedBox(height: 16),
                AuthInlineLink(
                    key: const ValueKey('auth-welcome-register'),
                    prefix: 'Don’t have an account? ',
                    link: 'Register',
                    onTap: () => app.go(SurgoPage.authSignUp)),
              ])),
    ]);
  }
}
