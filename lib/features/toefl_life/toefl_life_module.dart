import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'toefl_life_feedback.dart';
import 'toefl_life_logic.dart';
import 'toefl_life_page.dart';

/// TOEFL 每日训练 · 生活阅读特性的路由入口 —— 原生 Dart 端口，对应原型
/// `app.js` 9911-10135 的 `tfDailyLifeView` / `tfDlFbView` 两个页面。
///
/// 归属（own）：本模块 + `lib/features/toefl_life/**` +
/// `assets/data/toefl_life.json` + `test/toefl_life*.dart` +
/// `tool/export_toefl_life.cjs`。
///
/// 从原型无损保留的状态与文案规则（详见 [TfDlController] / [TfDlContent]）：
///   * 每题独立**40 秒**倒计时（TFDL_SEC=40）；归零转正计时并**仅弹一次**「时间到」；
///   * 「已作答」= tfDlVals 键数（tfDlAnswered），选一项即计入；
///   * 「上一题」/答题卡「跳题」不重置计时（原型 tfDlPrev/tfDlJump 只 render）；
///   * 「下一段」重置 left=40/over=false/up=0/alerted=false 并重启计时；
///   * 最后一题点「提交」→ 批改动画 → `go('tfDlFb')`；
///   * 原文/标题按 tfDlSrc/tfDlTitle 从当前题向前回溯继承（ad/post）；
///   * 计时器在退出（dispose）时取消，进入下一题/批改时也取消，杜绝泄漏；
///   * 反馈页估分卡为原型内联固定文案 fixture，不发明任何真实评分。
///
/// 题面文本、选项、原文行、反馈解析等全部来自 `toefl_life.json`（由
/// `tool/export_toefl_life.cjs` 用 Node vm 直接 eval 原型常量源码切片
/// TFDL_AD / TFDL_POST / TFDL_QS / TFDL_SEC / TFDLFB_WEAK / TFDLFB_SRC /
/// TFDLFB_QS 导出），一字不改。
///
/// Body 为自然高度（不自带 Scrollable）；外层 shell 的
/// [SingleChildScrollView] 负责整页纵向滚动，对应 `.read-scroll` 行为。
/// 因此这里绝不使用 Expanded 撑满纵向。

/// 路由入口：返回 `tfDailyLife` / `tfDlFb` 页面 widget；对本模块不拥有的
/// 页面返回 `null`（镜像原型 `if(!V[id]) return;`，未知页交由别处）。
Widget? buildToeflLifePage(SurgoPage page) {
  switch (page) {
    case SurgoPage.tfDailyLife:
      return const _ToeflLifeLoader(page: SurgoPage.tfDailyLife);
    case SurgoPage.tfDlFb:
      return const _ToeflLifeLoader(page: SurgoPage.tfDlFb);
    default:
      return null;
  }
}

/// 异步加载 JSON 内容后再渲染对应视图（与 toefl_words 模块同款载入模式）。
///
/// [TfDlContent.load] 带单例缓存，重复进入不会重复读盘。加载完成前显示与其他
/// 模块一致的黄色 loading 指示。
class _ToeflLifeLoader extends StatefulWidget {
  const _ToeflLifeLoader({required this.page});
  final SurgoPage page;

  @override
  State<_ToeflLifeLoader> createState() => _ToeflLifeLoaderState();
}

class _ToeflLifeLoaderState extends State<_ToeflLifeLoader> {
  TfDlContent? _content;

  @override
  void initState() {
    super.initState();
    TfDlContent.load().then((c) {
      if (mounted) setState(() => _content = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    if (content == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
            child: CircularProgressIndicator(color: SurgoColors.yellow)),
      );
    }
    switch (widget.page) {
      case SurgoPage.tfDailyLife:
        return TfDailyLifeView(content: content);
      case SurgoPage.tfDlFb:
        return TfDlFbView(content: content);
      default:
        return const SizedBox.shrink();
    }
  }
}
