import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'source_text.dart';
import 't.dart';

/// 全站统一的 tab 胶囊（用户 2026-09-25：「托福的所有 tab 页都做成这个样式」）。
///
/// 基准 = 雅思阅读模考的篇章 tab：
///   * 选中：淡黄底 [SurgoColors.yellowTint] + 黄色描边 + 深色粗体文字；
///   * 未选中：无背景、无描边、灰色文字；
///   * 圆角 18 的胶囊，纵向 9、横向 6 内边距。
///
/// 文案有中英两种来源：题型名之类的固定英文标签走 [source]=true（不翻译），
/// 「题目 / 写作」这类界面文案走默认的 [T]。
class SurgoPillTab extends StatelessWidget {
  const SurgoPillTab({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.source = false,
    this.fontSize = 13,
    this.maxLines = 2,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// true 时用 [SourceText]（原文照出，不进翻译表）。
  final bool source;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontFamily: 'Outfit',
        fontFamilyFallback: SurgoFontFamily.fallback,
        fontSize: fontSize,
        height: 1.3,
        fontWeight: FontWeight.w800,
        color: selected ? SurgoColors.onYellowStrong : SurgoColors.muted);
    return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selected ? SurgoColors.yellowTint : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: selected ? SurgoColors.yellow : Colors.transparent)),
            child: source
                ? SourceText(label,
                    textAlign: TextAlign.center, maxLines: maxLines, style: style)
                : T(label,
                    textAlign: TextAlign.center,
                    maxLines: maxLines,
                    style: style)));
  }
}
