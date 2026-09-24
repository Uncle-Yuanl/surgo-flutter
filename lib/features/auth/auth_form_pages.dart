import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/source_text.dart';
import 'auth_kit.dart';

/// Figma 40:388 "81" —— 注册表单（姓名 / 邮箱 / 密码 / 确认密码 + 条款勾选）。
class AuthSignUpPage extends StatefulWidget {
  const AuthSignUpPage({super.key});

  @override
  State<AuthSignUpPage> createState() => _AuthSignUpPageState();
}

class _AuthSignUpPageState extends State<AuthSignUpPage> {
  bool agree = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return SingleChildScrollView(
        key: const ValueKey('auth-signup-scroll'),
        padding: const EdgeInsets.fromLTRB(
            AuthTokens.pad, 44, AuthTokens.pad, 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                AuthBack(onTap: () => app.go(SurgoPage.authWelcome)),
                const SizedBox(width: 14),
                SourceText('Sign Up', style: AuthTokens.text()),
              ]),
              const SizedBox(height: 26),
              SourceText('Sign up your account', style: AuthTokens.text()),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'Full Name',
                  hint: 'Enter name',
                  icon: Icons.person_outline),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'Your Email',
                  hint: 'Enter email',
                  icon: Icons.mail_outline),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'Enter Password',
                  hint: '',
                  icon: Icons.lock_outline,
                  obscure: true,
                  trailing:
                      Icon(Icons.visibility_off_outlined, size: 16, color: AuthTokens.muted)),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'Confirm Password',
                  hint: '',
                  icon: Icons.lock_outline,
                  obscure: true,
                  trailing:
                      Icon(Icons.visibility_off_outlined, size: 16, color: AuthTokens.muted)),
              const SizedBox(height: 22),
              GestureDetector(
                  key: const ValueKey('auth-signup-agree'),
                  onTap: () => setState(() => agree = !agree),
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color:
                                agree ? AuthTokens.accent : AuthTokens.field,
                            borderRadius: BorderRadius.circular(3)),
                        child: agree
                            ? const Icon(Icons.check,
                                size: 11, color: Color(0xff1a1a1a))
                            : null),
                    const SizedBox(width: 10),
                    SourceText('I agree with Terms & Condition',
                        style: AuthTokens.text(color: AuthTokens.hint)),
                  ])),
              const SizedBox(height: 22),
              AuthButton('Signup',
                  key: const ValueKey('auth-signup-submit'),
                  onTap: () => app.go(SurgoPage.authOtp)),
              const SizedBox(height: 18),
              GestureDetector(
                  key: const ValueKey('auth-signup-signin'),
                  onTap: () => app.go(SurgoPage.authSignIn),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SourceText('have an account? ',
                            style: AuthTokens.text(color: AuthTokens.muted)),
                        SourceText('Sign In',
                            style: AuthTokens.text(
                                color: AuthTokens.accent,
                                weight: FontWeight.w700)),
                      ])),
            ]));
  }
}

/// Figma 40:2052 / 40:2192 —— 登录页。两版结构相同，[alt] 区分路由与标识。
class AuthSignInPage extends StatefulWidget {
  const AuthSignInPage({super.key, this.alt = false});

  final bool alt;

  @override
  State<AuthSignInPage> createState() => _AuthSignInPageState();
}

class _AuthSignInPageState extends State<AuthSignInPage> {
  bool remember = true;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final tag = widget.alt ? 'alt' : 'main';
    return SingleChildScrollView(
        key: ValueKey('auth-signin-scroll-$tag'),
        padding: const EdgeInsets.fromLTRB(
            AuthTokens.pad, 44, AuthTokens.pad, 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                AuthBack(onTap: () => app.go(SurgoPage.authWelcome)),
              ]),
              const SizedBox(height: 38),
              SourceText('Sign in your account', style: AuthTokens.text()),
              const SizedBox(height: 24),
              const AuthField(
                  title: 'Your Email',
                  hint: 'Enter email',
                  icon: Icons.mail_outline),
              const SizedBox(height: 20),
              const AuthField(
                  title: 'Enter Password',
                  hint: '',
                  icon: Icons.lock_outline,
                  obscure: true,
                  trailing: Icon(Icons.visibility_off_outlined,
                      size: 16, color: AuthTokens.muted)),
              const SizedBox(height: 22),
              Row(children: [
                GestureDetector(
                    key: ValueKey('auth-signin-remember-$tag'),
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
                const Spacer(),
                GestureDetector(
                    key: ValueKey('auth-signin-forgot-$tag'),
                    onTap: () => app.go(SurgoPage.authForgot),
                    child: SourceText('Forgot Password?',
                        style: AuthTokens.text(color: AuthTokens.accent))),
              ]),
              const SizedBox(height: 28),
              AuthButton('Signup',
                  key: ValueKey('auth-signin-submit-$tag'),
                  onTap: () => app.go(SurgoPage.authCongrats)),
            ]));
  }
}
