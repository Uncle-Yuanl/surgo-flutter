import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// Figma 40:363 "80" —— 黄底启动页。
///
/// 用户 2026-09-25：品牌文字换成桌面 icon/logo.jpg（已抠白转透明 PNG）；
/// 黄色要连状态栏一起铺满（shell 对本页从 top:0 起画）。
class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
      key: const ValueKey('auth-splash'),
      onTap: () => context.read<AppState>().go(SurgoPage.authWelcome),
      child: ColoredBox(
          color: AuthTokens.accent,
          child: Center(
              child: Image.asset('assets/images/auth/logo.png',
                  width: 140, fit: BoxFit.contain))));
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
