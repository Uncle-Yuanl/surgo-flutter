import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';

/// 阅读日常训练向导的选择/生成逻辑 —— 逐条对应原型 app.js 的这些函数与全局变量：
///
/// - `wizardView(key)` 入口：`wizKey=key; readMode='full'; selReadType=null;`
/// - `pickPracticeMode(mode)`：整篇/单一切换，切回整篇时清空 selReadType
/// - `pickReadType(key)`：选中单一题型，`readMode='single'`
/// - `pickTfReadTask(el,k)` / `pickTfReadDiff(el,k)`：TOEFL 任务与难度
/// - `genSession(key)` → `openGenSheet(()=>doGenSession(key))`：先播生成动画再路由
/// - `doGenSession(key)`：写入 session 变量并决定下一页
///
/// 变量名一律沿用原型（wizKey / readMode / selReadType / selWizCard /
/// tfReadTask / tfReadDiff / sessionKey / sessionMode / readIdx …），
/// 写进共享 [AppState.session]，交给下游作答模块。
class ReadingWizardController extends ChangeNotifier {
  ReadingWizardController(this._state) {
    _enter();
  }

  final AppState _state;

  // ---- 原型全局变量（本向导拥有的那几个）----
  // let readMode='full'; 'full'=练习整篇 / 'single'=专注单一
  String readMode = 'full';
  // let selReadType=null; 选中的单一题型 key（null=综合/整篇）
  String? selReadType;
  // let selWizCard=null; 卡片选择版式选中的 key（阅读不用，但 doGenSession 会读）
  String? selWizCard;
  // let tfReadTask='wordfill';
  String tfReadTask = 'wordfill';
  // let tfReadDiff='std';
  String tfReadDiff = 'std';

  bool get isToefl => _state.examType == ExamType.toefl;

  /// 对应 `wizardView('reading')` 头部：`wizKey='reading'; readMode='full'; selReadType=null;`
  void _enter() {
    readMode = 'full';
    selReadType = null;
    _state.session['wizKey'] = 'reading';
    // 恢复上次的 TOEFL 选择（原型里 tfReadTask/tfReadDiff 是持久全局变量）
    tfReadTask = (_state.session['tfReadTask'] as String?) ?? 'wordfill';
    tfReadDiff = (_state.session['tfReadDiff'] as String?) ?? 'std';
  }

  // ---------------------------------------------------------------- IELTS 侧

  /// 原型 `pickPracticeMode(mode)`：
  /// ```js
  /// readMode=mode;
  /// ...(切换 sel 高亮与 typePick 显隐)
  /// if(mode==='full'){ selReadType=null; }
  /// ```
  void pickPracticeMode(String mode) {
    readMode = mode;
    if (mode == 'full') selReadType = null;
    notifyListeners();
  }

  /// 原型 `pickReadType(key)`：`selReadType=key; readMode='single';`
  void pickReadType(String key) {
    selReadType = key;
    readMode = 'single';
    notifyListeners();
  }

  // ---------------------------------------------------------------- TOEFL 侧

  /// 原型 `pickTfReadTask(el,k)`：`tfReadTask=k;`（+ sel 高亮）
  void pickTfReadTask(String k) {
    tfReadTask = k;
    notifyListeners();
  }

  /// 原型 `pickTfReadDiff(el,k)`：`tfReadDiff=k;`（+ on 高亮）
  void pickTfReadDiff(String k) {
    tfReadDiff = k;
    notifyListeners();
  }

  // ---------------------------------------------------------------- 生成 → 路由

  /// 原型 `doGenSession(key)` 中与阅读相关的分支，纯计算版（不触发导航），
  /// 便于单测覆盖「任务 → 目标页」的所有规则。
  ///
  /// ```js
  /// function doGenSession(key){ sessionKey=key; sessionMode='daily';
  ///   readIdx=0; typeIdx=0; lisIdx=0; readDone.clear(); ...
  ///   if(examType==='toefl' && key in [reading,...]){ tfBriefMod=key; go('tfBrief'); return; }
  ///   if(key==='reading'){ go(selReadType ? 'typeSession' : 'readingSession'); }
  /// }
  /// ```
  SurgoPage resolveTarget() {
    if (isToefl) return SurgoPage.tfBrief;
    return selReadType != null ? SurgoPage.typeSession : SurgoPage.readingSession;
  }

  /// 把 session 变量写回共享状态（沿用原型变量名），供下游模块读取。
  void _commitSession() {
    _state.session.addAll(<String, dynamic>{
      'sessionKey': 'reading',
      'sessionMode': 'daily',
      'readIdx': 0,
      'typeIdx': 0,
      'lisIdx': 0,
      'readMode': readMode,
      'selReadType': selReadType,
      if (isToefl) 'tfBriefMod': 'reading',
      if (isToefl) 'tfReadTask': tfReadTask,
      if (isToefl) 'tfReadDiff': tfReadDiff,
    });
  }

  /// 原型 `genSession('reading')` 完成动画回调里的 `doGenSession('reading')`：
  /// 写 session、跳目标页。调用方负责先播放生成动画（[ReadingGenOverlay]）。
  void commitAndGo() {
    _commitSession();
    _state.go(resolveTarget());
  }
}
