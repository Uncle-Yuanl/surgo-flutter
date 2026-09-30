import 'package:flutter/foundation.dart';

import 'routes.dart';
import '../widgets/demo_audio.dart';

/// 全局会话状态 —— 对应原型 `app.js` 顶层的可变全局变量。
///
/// 原型里这些是散落的 `let` / `const`（共 315 个顶层声明），直接互相读写。
/// Flutter 端收进一个 ChangeNotifier，但**取值与切换语义一字不改**：
/// 例如 `examType` 切换后必须重渲染当前页，原型里是 `go(curPage)` 做的，
/// 这里由 [notifyListeners] 承担同样职责。
///
/// 已迁移的（有明确语义、驱动页面渲染）：
///   examType / uiLang / curPage
/// 其余仍留在各自页面控制器里（计时器、录音状态等），
/// 迁移时会逐页对照原型变量名，不合并、不重命名。
class AppState extends ChangeNotifier {
  AppState({
    ExamType examType = ExamType.ielts,
    UiLang lang = UiLang.zh,
    SurgoPage current = SurgoPage.ielts,
  })  : _examType = examType,
        _lang = lang,
        _current = current;

  /// Shared original-JS state keys for cross-route hand-off. Each module owns
  /// its own controllers; navigation inputs and full-mock state live here.
  final Map<String, dynamic> session = <String, dynamic>{};
  int _revision = 0;
  int get revision => _revision;

  void refresh() { _revision++; notifyListeners(); }
  void updateSession(Map<String, dynamic> values) {
    session.addAll(values);
    refresh();
  }

  // ---------------------------------------------------------------- examType
  // 原型：let examType='ielts'
  ExamType _examType;
  ExamType get examType => _examType;
  set examType(ExamType v) {
    if (_examType == v) return;
    _examType = v;
    notifyListeners();
  }

  // ---------------------------------------------------------------- uiLang
  // 原型：let uiLang='zh'（toggleLang 里 `go(curPage)` 重渲染）
  UiLang _lang;
  UiLang get lang => _lang;

  /// 对应 `toggleLang()`：切换语言后重渲染当前页。
  void toggleLang() {
    _lang = _lang == UiLang.zh ? UiLang.en : UiLang.zh;
    notifyListeners();
  }

  void setLang(UiLang v) {
    if (_lang == v) return;
    _lang = v;
    notifyListeners();
  }

  // ---------------------------------------------------------------- curPage
  // 原型：let curPage='ielts'
  SurgoPage _current;
  SurgoPage get current => _current;

  /// 对应原型 `go(id)`：
  /// ```js
  /// function go(id){
  ///   if(!V[id])return;
  ///   closeModal();
  ///   ...
  ///   render(id);
  /// }
  /// ```
  /// 关键差异（有意为之）：原型在进入 pronRepeat / pronSentence 时会先清掉
  /// 跟读计时与录音状态。那是"页面入场副作用"，在 Flutter 里由
  /// 各模块控制器承接；这里仅负责换页和触发重新构建。
  void go(SurgoPage page) {
    // 换页（包括 go 到同一页重建）先把演示音频停掉：页面切换有 300 毫秒的过渡，旧页面的 dispose 比新页面
    // 开始放音频还晚，让页面各自在 dispose 里停的话，会把新页面刚放起来的那一段掐掉。
    demoAudio.stop();
    _revision++;
    if (_current == page) {
      // 原型里 go() 到同一页也会重渲染（用于刷新数据），保持一致
      notifyListeners();
      return;
    }
    _current = page;
    notifyListeners();
  }

  /// 调试用：一一核对页面清单与原型是否等长。
  @visibleForTesting
  void debugAssertPages() {
    assert(SurgoPage.values.length == 141,
        '页面数应为 141，实际 ${SurgoPage.values.length}');
  }
}

/// 原型 `EXAM` 常量表（各模块模拟考的标题/时长/步骤/下一步）。
/// 迁移时按 `在 _extract/logic/` 里的原文逐条抄，不改文案。
class ExamConfig {
  const ExamConfig({
    required this.name,
    required this.time,
    required this.total,
    required this.parts,
    required this.next,
    required this.cta,
  });

  final String name;
  final String time;
  final String total;
  final List<String> parts;
  final SurgoPage next;
  final String cta;
}