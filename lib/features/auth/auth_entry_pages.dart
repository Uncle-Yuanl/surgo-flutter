import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// Figma 40:363 "80" —— 黄底启动页，居中品牌名。
class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
      key: const ValueKey('auth-splash'),
      onTap: () => context.read<AppState>().go(SurgoPage.authWelcome),
      child: ColoredBox(
          color: AuthTokens.accent,
          child: const Center(
              child: SourceText('Surgo',
                  style: TextStyle(
                      fontFamily: AuthTokens.family,
                      fontFamilyFallback: SurgoFontFamily.fallback,
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black)))));
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
      // 上半区是设计稿里的插画位。插画素材未随稿提供，这里留同色占位，
      // 不臆造图形；接入真图时替换这一块即可。
      Expanded(
          child: Container(
              width: double.infinity,
              color: AuthTokens.field,
              alignment: Alignment.center,
              child: SourceText('Surgo',
                  style: AuthTokens.text(
                      size: 32,
                      weight: FontWeight.w400,
                      color: AuthTokens.hint)))),
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
                GestureDetector(
                    key: const ValueKey('auth-welcome-register'),
                    onTap: () => app.go(SurgoPage.authSignUp),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SourceText('Don’t have an account? ',
                              style:
                                  AuthTokens.text(color: AuthTokens.muted)),
                          SourceText('Register',
                              style: AuthTokens.text(
                                  color: AuthTokens.accent,
                                  weight: FontWeight.w700)),
                        ])),
              ])),
    ]);
  }
}
