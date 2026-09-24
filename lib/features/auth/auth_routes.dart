import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'auth_entry_pages.dart';
import 'auth_form_pages.dart';
import 'auth_recovery_pages.dart';
import 'auth_result_pages.dart';

/// 登录注册 13 页的路由分发（Figma gW9DKhEd6UuQQAnv32BlXH · Page 5）。
///
/// 与工程既有做法一致：由 shell 的 builder 列表调用，命中返回页面，否则返回 null。
Widget? buildAuthPage(SurgoPage page) => switch (page) {
      SurgoPage.authSplash => const AuthSplashPage(),
      SurgoPage.authSignUp => const AuthSignUpPage(),
      SurgoPage.authError => const AuthErrorPage(),
      SurgoPage.authWelcome => const AuthWelcomePage(),
      SurgoPage.authOtp => const AuthOtpPage(),
      SurgoPage.authCongrats => const AuthCongratsPage(),
      SurgoPage.authForgot => const AuthForgotPage(),
      SurgoPage.authCheckEmail => const AuthCheckEmailPage(),
      SurgoPage.authResetEmail => const AuthResetCodePage(),
      SurgoPage.authResetPhone => const AuthResetCodePage(phone: true),
      SurgoPage.authNewPassword => const AuthNewPasswordPage(),
      SurgoPage.authSignIn => const AuthSignInPage(),
      SurgoPage.authSignInAlt => const AuthSignInPage(alt: true),
      _ => null,
    };
