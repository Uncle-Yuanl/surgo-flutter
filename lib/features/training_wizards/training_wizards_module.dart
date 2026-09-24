import 'package:flutter/widgets.dart';

import '../../app/routes.dart';
import 'training_wizards_page.dart';

/// 训练向导模块入口 —— 把 `writingDaily` / `listeningDaily` / `speakingDaily` /
/// `vocabDaily` 四个路由映射到 [TrainingWizardPage]（阅读向导独立，不在此处理）。
///
/// 对应原型 `V.writingDaily = () => wizardView('writing')` 等：每个入口页只是
/// 用不同 key 调用同一个 `wizardView(key)`，这里同样用 moduleKey 复用同一 Widget。
///
/// 命中返回对应页面 Widget，否则返回 null，交给 shell 的下一个 builder / switch。
Widget? buildTrainingWizardPage(SurgoPage page) {
  const keyOf = <SurgoPage, String>{
    SurgoPage.writingDaily: 'writing',
    SurgoPage.listeningDaily: 'listening',
    SurgoPage.speakingDaily: 'speaking',
    SurgoPage.vocabDaily: 'vocab',
  };
  final moduleKey = keyOf[page];
  if (moduleKey == null) return null;
  return TrainingWizardPage(moduleKey: moduleKey);
}
