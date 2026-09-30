import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/i18n.dart';
import '../app/routes.dart';

/// 界面文案 —— 对应原型 `applyLang()` 在 DOM 上逐文本节点做的翻译。
///
/// 原型的做法很"网页"：渲染完中文文案后，用 TreeWalker 遍历文本节点，
/// 把能命中词典的整串替换掉。Flutter 没有这一层，所以改用显式包装：
/// 页面里凡是**界面文案（chrome）**都用 [T] 包起来，
/// 而题干、原文、选项、transcript 这类**题目内容**用原始 Text，
/// 与原型「翻译只作用于 chrome」的边界完全一致。
///
/// 判定规则原样照搬 [Translator.translate]（整串精确匹配 / 正则兜底 /
/// zh 模式只翻不含中文的串 / en 模式只翻含中文的串）。
class T extends StatelessWidget {
  const T(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.uppercase = false,
  });

  /// 中文模式下的原文（也是词典的 key）；也可以是 `[英文, 中文]` 一对
  /// （演示用真实数据，tool/demo_export 导出），按界面语言取一项再过词典。
  final Object text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  /// 对应 CSS 的 `text-transform:uppercase`。
  ///
  /// ⚠️ 顺序很重要：原型是「文本节点存原文 → CSS 视觉转大写」，
  /// 而词典的 key 是**原文**（"Today's train"），不是大写形式。
  /// 所以必须**先翻译、后大写**。反过来（先大写再查词典）会命中失败，
  /// 中文模式下就会漏翻成 "TODAY'S TRAIN"。
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, UiLang>((s) => s.lang);
    final raw = langText(text, lang);
    var out = Translator.instance.translate(raw, lang) ?? raw;
    if (uppercase) out = out.toUpperCase();
    return Text(out, style: style, textAlign: textAlign, maxLines: maxLines);
  }
}

/// 带内联高亮的文案（首页「距离你的考试还剩 20天」那种）。
/// 每个片段单独过词典，行为与原型逐文本节点翻译一致。
class TSpan extends StatelessWidget {
  const TSpan({
    super.key,
    required this.parts,
    this.style,
    this.highlightStyle,
  });

  /// (文案, 是否高亮)；文案同 [T]，也可以是 `[英文, 中文]` 一对。
  final List<(Object, bool)> parts;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, UiLang>((s) => s.lang);
    final spans = <TextSpan>[];
    for (final (part, hl) in parts) {
      final raw = langText(part, lang);
      final out = Translator.instance.translate(raw, lang) ?? raw;
      spans.add(TextSpan(text: out, style: hl ? highlightStyle : null));
    }
    return Text.rich(TextSpan(children: spans), style: style);
  }
}

/// `[英文, 中文]` 一对里按界面语言取一项；普通字符串原样返回。
/// 给不走 [T] 的地方用（`Text`、拼进句子里的片段）。
String langText(Object text, UiLang lang) => text is List
    ? '${text[lang == UiLang.zh && text.length > 1 ? 1 : 0]}'
    : '$text';