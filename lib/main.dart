import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_state.dart';
import 'app/i18n.dart';
import 'app/routes.dart';
import 'app/shell.dart';
import 'theme/app_theme.dart';
import 'widgets/demo_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 手机上音频和朗读都要由一次点击解锁，见 DemoAudio。
  demoAudio.unlockOnFirstTap();

  // 词典（949 条）与题库（62KB）都是原型原样导出的资产，启动时一次载入。
  // 原型里这两个是同步 <script> 引入的全局变量，这里是异步载入，
  // 因此页面首次构建发生在 load 之后 —— 避免首帧出现未翻译文案。
  await Future.wait([Translator.load(), QuestionBank.load()]);

  runApp(const SurgoApp());
}

class SurgoApp extends StatelessWidget {
  const SurgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        // 原型初始值：let examType='ielts' / let uiLang='zh' / let curPage='ielts'
        examType: ExamType.ielts,
        lang: UiLang.zh,
        // Source executes render('exam') after declarations.
        current: SurgoPage.exam,
      ),
      child: MaterialApp(
        title: 'SURGO · 移动端',
        debugShowCheckedModeBanner: false,
        theme: SurgoTheme.build(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return const SurgoShell();
  }
}

/// 把"是否铺满屏幕"这个决定传给 [PhoneFrame]，避免每层都量一次屏幕。
class PhoneFitScope extends InheritedWidget {
  const PhoneFitScope({
    super.key,
    required this.fitToScreen,
    required super.child,
  });

  final bool fitToScreen;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PhoneFitScope>()?.fitToScreen ??
      true;

  @override
  bool updateShouldNotify(PhoneFitScope oldWidget) =>
      oldWidget.fitToScreen != fitToScreen;
}