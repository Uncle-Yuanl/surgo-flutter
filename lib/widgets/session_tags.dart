import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import 't.dart';

/// 做题页左上角的三段标题（用户 2026-09-24）。
///
/// 格式：`日常训练 / 模拟考试` + `雅思阅读` + `Part 1`，三块胶囊横排。
/// 样式沿用雅思听力作答页既有的标签：绿色=训练类型，紫色=科目，第三块用中性灰
/// 区分，避免与前两块抢视觉。第三段可缺省（没有 part 概念的页面只显示两段）。
class SessionTags extends StatelessWidget {
  const SessionTags({
    super.key,
    required this.mock,
    required this.subject,
    this.part,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  /// true 显示「模拟考试」，false 显示「日常训练」。
  final bool mock;

  /// 科目，例如「雅思阅读」「托福听力」。
  final String subject;

  /// 第三段，例如「Part 1」「篇章 2」「Task 1」；为空时不渲染。
  final String? part;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    return Padding(
        padding: padding,
        child: SingleChildScrollView(
            key: const ValueKey('session-tags'),
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tag(mock ? '模拟考试' : '日常训练', _Tone.green, zh),
              const SizedBox(width: 8),
              _tag(subject, _Tone.purple, zh),
              if (part != null && part!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _tag(part!, _Tone.neutral, zh),
              ],
            ])));
  }

  /// 与雅思听力作答页 `_tag` 同款胶囊。
  Widget _tag(String label, _Tone tone, bool zh) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: switch (tone) {
            _Tone.green => const Color(0xffdcefe0),
            _Tone.purple => const Color(0xffe6e2fb),
            _Tone.neutral => const Color(0xffeeeae1),
          },
          borderRadius: BorderRadius.circular(20)),
      child: T(label,
          style: TextStyle(
              fontFamily: 'Outfit',
              fontFamilyFallback: SurgoFontFamily.fallback,
              fontSize: 13,
              height: zh ? 18 / 13 : 1,
              fontWeight: FontWeight.w700,
              color: switch (tone) {
                _Tone.green => const Color(0xff3f9a5c),
                _Tone.purple => const Color(0xff6b5fc7),
                _Tone.neutral => const Color(0xff7a7267),
              })));
}

enum _Tone { green, purple, neutral }
