import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'routes.dart';

/// 学员总览数据（assets/data/learner_profile.json）：首页、个人中心、消息通知、
/// 模考选科、学情分析共用。
///
/// 原型数据里这个文件是空的，各页面用自己原来写死的原型值；演示构建把
/// tool/demo_export/learner.cjs 导出的真实学员数据盖上来。约定：
/// **键不存在 = 用原型值；键存在而值是 null = 真实数据里没有，这一行 / 这一块不画**，
/// 所以可能缺的值要先看 containsKey。
class LearnerProfile {
  static Map<String, dynamic> data = const {};

  /// 跟词典一起在启动时载入（[Translator.load]），页面同步读，不用转圈等。
  static Future<void> load() async => data = jsonDecode(
          await rootBundle.loadString('assets/data/learner_profile.json'))
      as Map<String, dynamic>;

  /// 某门考试的那一块；没有就是空表。
  static Map<String, dynamic> exam(ExamType type) =>
      data[type.name] as Map<String, dynamic>? ?? const {};

  /// 离考试还有几天：原型 20；真实数据里没设考试日或已过就是 null。
  static int? get daysToExam =>
      data.containsKey('daysToExam') ? data['daysToExam'] as int? : 20;
}
