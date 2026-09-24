import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// 忘记密码流程共用的骨架：返回键 + 标题 + 说明 + 内容。
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.scrollKey,
    required this.title,
    required this.desc,
    required this.children,
    this.back,
  });

  final String scrollKey, title, desc;
  final List<Widget> children;
  final SurgoPage? back;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return SingleChildScrollView(
        key: ValueKey(scrollKey),
        padding: const EdgeInsets.fromLTRB(
            AuthTokens.pad, 44, AuthTokens.pad, 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBack(onTap: () => app.go(back ?? SurgoPage.authSignIn)),
              const SizedBox(height: 34),
              SourceText(title,
                  style: AuthTokens.text(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              SourceText(desc,
                  style:
                      AuthTokens.text(color: AuthTokens.muted, height: 1.6)),
              const SizedBox(height: 28),
              ...children,
            ]));
  }
}

/// Figma 40:1648 "Forget password 3" —— 填邮箱找回。
class AuthForgotPage extends StatelessWidget {
  const AuthForgotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return _AuthScaffold(
        scrollKey: 'auth-forgot-scroll',
        title: 'Forget Password',
        desc: '"Enter your email, and we’ll guide you to reset your password."',
        children: [
          const AuthField(
              title: 'Your Email',
              hint: 'Enter email',
              icon: Icons.mail_outline),
          const SizedBox(height: 28),
          AuthButton('Signup',
              key: const ValueKey('auth-forgot-submit'),
              onTap: () => app.go(SurgoPage.authCheckEmail)),
          const SizedBox(height: 18),
          GestureDetector(
              key: const ValueKey('auth-forgot-back'),
              onTap: () => app.go(SurgoPage.authSignIn),
              child: Center(
                  child: SourceText('Back to Sign In',
                      style: AuthTokens.text(color: AuthTokens.muted)))),
        ]);
  }
}

/// Figma 40:1689 "Check Email" —— 提示去邮箱查收。
class AuthCheckEmailPage extends StatelessWidget {
  const AuthCheckEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return _AuthScaffold(
        scrollKey: 'auth-check-email-scroll',
        title: 'Check Email',
        desc: 'We have sent a password recover instructions\u2028to your email.',
        back: SurgoPage.authForgot,
        children: [
          Center(
              child: Image.asset('assets/images/auth/check_email.png',
                  width: 220, height: 220, fit: BoxFit.contain)),
          const SizedBox(height: 24),
          AuthButton('Open Email App',
              key: const ValueKey('auth-check-open'),
              onTap: () => app.go(SurgoPage.authResetEmail)),
          const SizedBox(height: 18),
          GestureDetector(
              key: const ValueKey('auth-check-skip'),
              onTap: () => app.go(SurgoPage.authSignIn),
              child: Center(
                  child: SourceText('Skip, I’ll confirm later',
                      style: AuthTokens.text(color: AuthTokens.muted)))),
          const SizedBox(height: 30),
          SourceText(
              'Did not receive the email? Check your Spam\u2028folder or try. Try another email address',
              textAlign: TextAlign.center,
              style: AuthTokens.text(
                  size: 12, color: AuthTokens.muted, height: 1.6)),
        ]);
  }
}

/// Figma 40:1729 / 40:1855 —— 验证码页。[phone] 决定文案是邮箱还是手机号。
class AuthResetCodePage extends StatelessWidget {
  const AuthResetCodePage({super.key, this.phone = false});

  final bool phone;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return _AuthScaffold(
        scrollKey: phone ? 'auth-reset-phone-scroll' : 'auth-reset-email-scroll',
        title: 'Reset Password',
        desc: phone
            ? 'Please enter the verification code we sent\nto your Phone 1234444333'
            : 'Please enter the verification code we sent\nto your email arishairean@gmail.com',
        back: SurgoPage.authCheckEmail,
        children: [
          // 设计稿呈现的是已输入两位的状态（5、3）。
          const AuthOtpBoxes(digits: '53'),
          const SizedBox(height: 26),
          Center(
              child: SourceText('Resend code is 55s',
                  style: AuthTokens.text(color: AuthTokens.muted))),
          const SizedBox(height: 26),
          AuthButton('Verify',
              key: ValueKey('auth-verify-${phone ? 'phone' : 'email'}'),
              onTap: () => app.go(SurgoPage.authNewPassword)),
        ]);
  }
}

/// Figma 40:1981 "Create New Password 4" —— 设置新密码。
class AuthNewPasswordPage extends StatefulWidget {
  const AuthNewPasswordPage({super.key});

  @override
  State<AuthNewPasswordPage> createState() => _AuthNewPasswordPageState();
}

class _AuthNewPasswordPageState extends State<AuthNewPasswordPage> {
  bool remember = true;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return SingleChildScrollView(
        key: const ValueKey('auth-new-password-scroll'),
        padding: const EdgeInsets.fromLTRB(
            AuthTokens.pad, 44, AuthTokens.pad, 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBack(onTap: () => app.go(SurgoPage.authResetEmail)),
              const SizedBox(height: 20),
              Center(
                  child: Image.asset('assets/images/auth/new_password.png',
                      width: 200, height: 189, fit: BoxFit.contain)),
              const SizedBox(height: 18),
              SourceText('Create New Password',
                  style: AuthTokens.text(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 28),
              const AuthField(
                  title: 'Password',
                  hint: '',
                  icon: Icons.lock_outline,
                  obscure: true,
                  trailing: Icon(Icons.visibility_off_outlined,
                      size: 16, color: AuthTokens.muted)),
              const SizedBox(height: 8),
              SourceText('Must be at least 8 characters',
                  style:
                      AuthTokens.text(size: 12, color: AuthTokens.hint)),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'New Password',
                  hint: '',
                  icon: Icons.lock_outline,
                  obscure: true,
                  trailing: Icon(Icons.visibility_off_outlined,
                      size: 16, color: AuthTokens.muted)),
              const SizedBox(height: 8),
              SourceText('Both password must match',
                  style:
                      AuthTokens.text(size: 12, color: AuthTokens.hint)),
              const SizedBox(height: 22),
              GestureDetector(
                  key: const ValueKey('auth-newpass-remember'),
                  onTap: () => setState(() => remember = !remember),
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: remember
                                ? AuthTokens.accent
                                : AuthTokens.field,
                            borderRadius: BorderRadius.circular(3)),
                        child: remember
                            ? const Icon(Icons.check,
                                size: 11, color: Color(0xff1a1a1a))
                            : null),
                    const SizedBox(width: 10),
                    SourceText('Remember me',
                        style: AuthTokens.text(color: AuthTokens.hint)),
                  ])),
              const SizedBox(height: 26),
              AuthButton('Continue',
                  key: const ValueKey('auth-newpass-submit'),
                  onTap: () => app.go(SurgoPage.authCongrats)),
            ]));
  }
}
