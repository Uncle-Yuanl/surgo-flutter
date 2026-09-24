import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'source_text.dart';
import 't.dart';

/// 全局统一的答题卡弹窗（用户 2026-09-24：「答题卡弹窗全局统一为图2」）。
///
/// 图 2 = 雅思阅读日常训练的「题号导航」面板，构成要素：
///   * 顶部 56×5 拖拽条；
///   * 左对齐标题「题号导航」(18 Outfit w800) + 右上圆形关闭按钮；
///   * 图例行：黄色实心圆＝已作答，描边空心圆＝未作答；
///   * 题号区间小标题 `Questions a-b`（中文模式经 SURGO_ZH 正则变成「第 a-b 题」）；
///   * 圆形题号格：已作答黄底白字，当前题黄环，未作答白底描边；
///   * 底部整宽黄色「交卷」按钮。
///
/// 各页只提供数据与回调，样式一处改全站生效；页面原有的 key 通过
/// [tileKey]/[closeKey]/[submitKey] 传入，保证既有测试与审计脚本不受影响。
Future<void> showAnswerSheet(
  BuildContext context, {
  /// 第一题的题号（1 基）。听力模考各部分从 11 / 21 / 31 开始。
  required int first,
  required int count,

  /// 某题号是否已作答（入参为 1 基题号）。
  required bool Function(int number) answered,

  /// 当前题号（1 基）；null 表示该页没有「当前题」概念，不画黄环。
  int? current,

  /// 点某个题号（1 基）。null 表示只展示进度、不可跳题。
  void Function(int number)? onJump,

  /// 「交卷」回调；null 则不显示该按钮。
  VoidCallback? onSubmit,
  Key Function(int number)? tileKey,
  Key? closeKey,
  Key? submitKey,
}) =>
    showModalBottomSheet<void>(
        context: context,
        useRootNavigator: false,
        isScrollControlled: true,
        // 用户 2026-09-24：答题弹窗两边贴边，不留安全区白边。
        useSafeArea: false,
        backgroundColor: Colors.white,
        barrierColor: const Color(0x73140f05),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (ctx) => DefaultTextStyle(
            style: DefaultTextStyle.of(context).style,
            child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .8),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                              child: Container(
                                  width: 56,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                      color: const Color(0xffe3e7ec),
                                      borderRadius: BorderRadius.circular(4)))),
                          Row(children: [
                            const Expanded(
                                child: T('题号导航',
                                    style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontFamilyFallback:
                                            SurgoFontFamily.fallback,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800))),
                            GestureDetector(
                                key: closeKey,
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xfff0ebe2)),
                                    child: const Icon(Icons.close,
                                        size: 16, color: SurgoColors.muted)))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _legend('已作答', true),
                            const SizedBox(width: 22),
                            _legend('未作答', false)
                          ]),
                          const SizedBox(height: 20),
                          T('Questions $first-${first + count - 1}',
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontFamilyFallback: SurgoFontFamily.fallback,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            for (var n = first; n < first + count; n++)
                              GestureDetector(
                                  onTap: onJump == null
                                      ? null
                                      : () {
                                          Navigator.pop(ctx);
                                          onJump(n);
                                        },
                                  child: _tile(n, answered(n), current == n,
                                      tileKey?.call(n))),
                          ]),
                          if (onSubmit != null) ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                                key: submitKey,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onSubmit();
                                },
                                child: Container(
                                    padding: const EdgeInsets.all(16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: SurgoColors.yellow,
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: const T('交卷',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Arimo',
                                            height: 18.5 / 13,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                SurgoColors.onYellowStrong)))),
                          ],
                        ])))));

/// 圆形题号格。已作答黄底白字；当前题黄环；未作答白底描边。
///
/// key 落在这个 Container 上（而非外层 GestureDetector），这样既有测试里
/// `t.widget<Container>(find.byKey(...))` 读装饰色仍然成立，点击也照样命中。
Widget _tile(int number, bool answered, bool current, Key? key) => Container(
    key: key,
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: answered ? SurgoColors.yellow : Colors.white,
        border: Border.all(
            color: answered || current ? SurgoColors.yellow : SurgoColors.line,
            width: 1),
        boxShadow: current
            ? const [
                BoxShadow(color: SurgoColors.yellowTint, spreadRadius: 4)
              ]
            : null),
    child: SourceText('$number',
        style: TextStyle(
            fontFamily: 'Outfit',
            fontFamilyFallback: SurgoFontFamily.fallback,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: answered
                ? Colors.white
                : (current ? SurgoColors.yellow : SurgoColors.muted))));

Widget _legend(String text, bool answered) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: answered ? SurgoColors.yellow : Colors.white,
              border: answered
                  ? null
                  : Border.all(color: SurgoColors.line, width: 1.5))),
      const SizedBox(width: 8),
      T(text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
