import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// Figma 40:1415 "POP UP" —— OTP 验证码页，进入即弹条款确认。
class AuthOtpPage extends StatefulWidget {
  const AuthOtpPage({super.key});

  @override
  State<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends State<AuthOtpPage> {
  bool shown = false;

  @override
  void initState() {
    super.initState();
    // 设计稿里这一页是「底层 OTP 页 + 条款弹窗」的合成态，
    // 所以首帧后自动弹出，与稿面一致。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !shown) {
        shown = true;
        _terms(context);
      }
    });
  }

  Future<void> _terms(BuildContext context) => showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierColor: const Color(0x73141005),
      builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: AuthTokens.sheet,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
              child:
                  Column(mainAxisSize: MainAxisSize.min, children: [
                SourceText(
                    '"I accept the Terms of Service and Conditions, agree to electronic communications, and affirm the accuracy of my information."',
                    textAlign: TextAlign.center,
                    style: AuthTokens.text(
                        size: 16, weight: FontWeight.w700, height: 1.5)),
                const SizedBox(height: 26),
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                          key: const ValueKey('auth-terms-disagree'),
                          onTap: () => Navigator.pop(ctx),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                              child: SourceText('Disagree',
                                  style: AuthTokens.text(
                                      size: 16,
                                      weight: FontWeight.w700,
                                      color: AuthTokens.danger))))),
                  Expanded(
                      child: AuthButton('Agree',
                          key: const ValueKey('auth-terms-agree'),
                          radius: 25,
                          onTap: () => Navigator.pop(ctx))),
                ]),
              ]))));

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return SingleChildScrollView(
        key: const ValueKey('auth-otp-scroll'),
        padding: const EdgeInsets.fromLTRB(
            AuthTokens.pad, 44, AuthTokens.pad, 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBack(onTap: () => app.go(SurgoPage.authSignUp)),
              const SizedBox(height: 34),
              SourceText('Enter OTP Code',
                  style: AuthTokens.text(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              SourceText(
                  'We have just sent you 4 digit code via your email example@gmail.com',
                  style:
                      AuthTokens.text(color: AuthTokens.muted, height: 1.6)),
              const SizedBox(height: 28),
              // 设计稿呈现已输入 3 位（3、1、4）。
              const AuthOtpBoxes(digits: '314'),
              const SizedBox(height: 28),
              AuthButton('Continue',
                  key: const ValueKey('auth-otp-continue'),
                  onTap: () => app.go(SurgoPage.authCongrats)),
              const SizedBox(height: 18),
              AuthInlineLink(
                  key: const ValueKey('auth-otp-resend'),
                  prefix: 'Didn’t receive code? ',
                  link: 'Resend Code'),
            ]));
  }
}

/// Figma 40:1485 "Congratulations" —— 注册成功弹窗，选地区语言。
class AuthCongratsPage extends StatefulWidget {
  const AuthCongratsPage({super.key});

  @override
  State<AuthCongratsPage> createState() => _AuthCongratsPageState();
}

class _AuthCongratsPageState extends State<AuthCongratsPage> {
  bool shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !shown) {
        shown = true;
        _congrats(context);
      }
    });
  }

  /// 选完语言即切换全局 UI 语言，并进入首页 —— 不臆造后端注册流程。
  void _pick(BuildContext ctx, UiLang lang) {
    final app = context.read<AppState>();
    Navigator.pop(ctx);
    app.setLang(lang);
    app.go(SurgoPage.ielts);
  }

  Future<void> _congrats(BuildContext context) => showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierColor: const Color(0x73141005),
      builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: AuthTokens.sheet,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 30, 34, 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/auth/congrats.png',
                    width: 176, height: 152, fit: BoxFit.contain),
                const SizedBox(height: 14),
                SourceText('Congratulations!',
                    style:
                        AuthTokens.text(size: 20, weight: FontWeight.w700)),
                const SizedBox(height: 14),
                SourceText(
                    '"Account successfully created. Choose your region and language～',
                    textAlign: TextAlign.center,
                    style: AuthTokens.text(
                        color: AuthTokens.muted, height: 1.55)),
                const SizedBox(height: 24),
                AuthButton('English',
                    key: const ValueKey('auth-lang-en'),
                    onTap: () => _pick(ctx, UiLang.en)),
                const SizedBox(height: 14),
                AuthButton('Chinese',
                    key: const ValueKey('auth-lang-zh'),
                    onTap: () => _pick(ctx, UiLang.zh)),
              ]))));

  @override
  Widget build(BuildContext context) => Padding(
      key: const ValueKey('auth-congrats'),
      padding: const EdgeInsets.symmetric(horizontal: AuthTokens.pad),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/auth/congrats.png',
            width: 199, height: 172, fit: BoxFit.contain),
        const SizedBox(height: 18),
        SourceText('Congratulations!',
            style: AuthTokens.text(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        SourceText(
            '"Account successfully created. Choose your region and language～',
            textAlign: TextAlign.center,
            style: AuthTokens.text(color: AuthTokens.muted, height: 1.55)),
      ]));
}
