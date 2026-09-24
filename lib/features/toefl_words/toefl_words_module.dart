import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'toefl_words_feedback.dart';
import 'toefl_words_logic.dart';
import 'toefl_words_page.dart';

/// TOEFL 每日训练 · 补全单词特性的路由入口 —— 原生 Dart 端口，对应原型
/// `app.js` 9609-9842 的 `tfDailyWordsView` / `tfDwFbView` 两个页面。
///
/// 归属（own）：本模块 + `lib/features/toefl_words/**` +
/// `assets/data/toefl_words.json` + `test/toefl_words*.dart`。
///
/// 从原型无损保留的状态与文案规则（详见 [TfDwController] / [TfDwContent]）：
///   * 每段独立 90 秒倒计时；归零转正计时并**仅弹一次**「时间到」；
///   * 进度 = 已填空格数 / 空格总数，空格「已填」判定为 trim() 非空；
///   * 「上一题」不重置计时（原型 `tfDwPrev` 只 render）；
///   * 「下一段」重置 left=90/over=false/up=0/alerted=false 并重启计时；
///   * 最后一段点「下一部分」→ 批改动画 → `go('tfDwFb')`；
///   * 计时器在退出（dispose）时取消，进入下一段/批改时也取消，杜绝泄漏；
///   * 反馈页为原型固定文案 fixture，不发明任何真实评分。
///
/// 题面文本、缺失字母数、反馈解析等全部来自 `toefl_words.json`（由原型
/// 变量 TFDW_PARAS / TFDW_SEC / TFDWFB_WEAK / TFDWFB_SRC / TFDWFB_QS /
/// TFDWFB_SCORE 导出），一字不改。
///
/// Body 为自然高度（不自带 Scrollable）；外层 shell 的
/// [SingleChildScrollView] 负责整页纵向滚动，对应 `.read-scroll` 行为。
/// 因此这里绝不使用 Expanded 撑满纵向。

/// 路由入口：返回 `tfDailyWords` / `tfDwFb` 页面 widget；对本模块不拥有的
/// 页面返回 `null`（镜像原型 `if(!V[id]) return;`，未知页交由别处）。
Widget? buildToeflWordsPage(SurgoPage page) {
  switch (page) {
    case SurgoPage.tfDailyWords:
      return const _ToeflWordsLoader(page: SurgoPage.tfDailyWords);
    case SurgoPage.tfDwFb:
      return const _ToeflWordsLoader(page: SurgoPage.tfDwFb);
    default:
      return null;
  }
}

/// 异步加载 JSON 内容后再渲染对应视图（与 [ReadingWizardPage] 同款载入模式）。
///
/// [TfDwContent.load] 带单例缓存，重复进入不会重复读盘。加载完成前显示与其他
/// 模块一致的黄色 loading 指示。
class _ToeflWordsLoader extends StatefulWidget {
  const _ToeflWordsLoader({required this.page});
  final SurgoPage page;

  @override
  State<_ToeflWordsLoader> createState() => _ToeflWordsLoaderState();
}

class _ToeflWordsLoaderState extends State<_ToeflWordsLoader> {
  TfDwContent? _content;

  @override
  void initState() {
    super.initState();
    TfDwContent.load().then((c) {
      if (mounted) setState(() => _content = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    if (content == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: SurgoColors.yellow)),
      );
    }
    switch (widget.page) {
      case SurgoPage.tfDailyWords:
        return TfDailyWordsView(content: content);
      case SurgoPage.tfDwFb:
        return TfDwFbView(content: content);
      default:
        return const SizedBox.shrink();
    }
  }
}
