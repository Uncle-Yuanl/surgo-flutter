import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../oral_daily/controller.dart';

/// 写作/听力/口语/词汇日常训练向导的选择/生成逻辑 —— 逐条对应原型 app.js：
///
/// - `wizardView(key)` 头部：`wizKey=key; readMode='full'; selReadType=null;`
///   卡片版式还会 `selWizCard=c.cards[0].key;`
/// - `pickWizCard(el,k)`：`selWizCard=k;`（卡片版式选卡）
/// - `pickReadType(v)`：双卡「专注单一」的下拉（词汇用），`selReadType=v; readMode='single';`
/// - `pickPracticeMode(mode)`：双卡整篇/单一切换，切回整篇清空 selReadType
/// - `pickTfWrTask/pickTfLisTask/pickTfLisDiff/pickTfSpTask`：托福任务/难度
/// - `genSession(key)` → `openGenSheet(()=>doGenSession(key))`：先播动画再路由
/// - `doGenSession(key)`：写 session 变量、决定目标页（[resolveTarget]/[commitAndGo]）
///
/// 变量名一律沿用原型（wizKey/readMode/selReadType/selWizCard/tfWrTask/tfLisTask/
/// tfLisDiff/tfSpTask/sessionKey/sessionMode/readIdx/typeIdx/lisIdx…），写进共享
/// [AppState.session]，交给下游作答模块 / TaskBrief。
///
/// 阅读向导（reading）不在此实现，见 `reading_wizard`；本控制器只负责
/// writing / listening / speaking / vocab 四个 key。
class TrainingWizardController extends ChangeNotifier {
  TrainingWizardController(this._state, this.moduleKey, {String? initialCard}) {
    _enter(initialCard);
  }

  final AppState _state;

  /// 模块 key：'writing' / 'listening' / 'speaking' / 'vocab'。
  final String moduleKey;

  // ---- 原型全局变量 ----
  // let readMode='full'; 'full'=综合/整篇 / 'single'=专注单一（词汇双卡用）
  String readMode = 'full';
  // let selReadType=null; 双卡「专注单一」选中的方式 key（词汇用）
  String? selReadType;
  // let selWizCard=null; 卡片版式选中的任务/Part key（听力/写作/口语用）
  String? selWizCard;
  // let tfWrTask='sent';
  String tfWrTask = 'sent';
  // let tfLisTask='respond'; let tfLisDiff='std';
  String tfLisTask = 'respond';
  String tfLisDiff = 'std';
  // let tfSpTask='retell';
  String tfSpTask = 'retell';

  bool get isToefl => _state.examType == ExamType.toefl;

  /// 原型 `wizardView(key)` 头部 + 卡片版式初始化。
  void _enter(String? initialCard) {
    readMode = 'full';
    selReadType = null;
    _state.session['wizKey'] = moduleKey;
    // 卡片版式：selWizCard=c.cards[0].key（由页面在数据加载后传入 initialCard）
    selWizCard = initialCard;
    // 恢复上次的 TOEFL 选择（原型里这些是持久全局变量）
    tfWrTask = (_state.session['tfWrTask'] as String?) ?? 'sent';
    tfLisTask = (_state.session['tfLisTask'] as String?) ?? 'respond';
    tfLisDiff = (_state.session['tfLisDiff'] as String?) ?? 'std';
    tfSpTask = (_state.session['tfSpTask'] as String?) ?? 'retell';
  }

  /// 页面在数据加载后设置默认卡（原型 `selWizCard=c.cards[0].key`）。
  /// 只在尚未选择时生效，避免覆盖用户点选。
  void setDefaultCard(String key) {
    if (selWizCard == null) {
      selWizCard = key;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- IELTS 侧

  /// 原型 `pickWizCard(el,k)`：`selWizCard=k;`
  void pickWizCard(String k) {
    selWizCard = k;
    notifyListeners();
  }

  /// 原型 `pickPracticeMode(mode)`（词汇双卡）：切回 full 清空 selReadType。
  void pickPracticeMode(String mode) {
    readMode = mode;
    if (mode == 'full') selReadType = null;
    notifyListeners();
  }

  /// 原型 `pickReadType(v)`（词汇双卡「专注单一」下拉）：`selReadType=v; readMode='single';`
  void pickReadType(String v) {
    selReadType = v;
    readMode = 'single';
    notifyListeners();
  }

  // ---------------------------------------------------------------- TOEFL 侧

  void pickTfWrTask(String k) {
    tfWrTask = k;
    notifyListeners();
  }

  void pickTfLisTask(String k) {
    tfLisTask = k;
    notifyListeners();
  }

  void pickTfLisDiff(String k) {
    tfLisDiff = k;
    notifyListeners();
  }

  void pickTfSpTask(String k) {
    tfSpTask = k;
    notifyListeners();
  }

  // ---------------------------------------------------------------- 生成 → 路由

  /// 托福四个模块（reading/listening/writing/speaking）在此判定；vocab 无托福版式。
  bool get _tfBranch =>
      isToefl && (moduleKey == 'listening' || moduleKey == 'writing' || moduleKey == 'speaking');

  /// 原型 `doGenSession(key)` 的「任务 → 目标页」规则，纯计算版（不导航）。
  ///
  /// ```js
  /// if(examType==='toefl' && key in [reading,listening,writing,speaking]){ tfBriefMod=key; go('tfBrief'); return; }
  /// else if(key==='listening'){ setLisPart(...); go('listeningSession'); }
  /// else if(key==='writing'){ go('writingSession'); }
  /// else if(key==='speaking'){ if(selWizCard==='pron'){ go('pronCourse'); } else { startOralExam(); } }
  /// else if(key==='vocab'){ go('vocab'); }
  /// ```
  /// 其中 `startOralExam()`：`if(selWizCard==='p3'){ startDiscuss()→go('oralDiscuss'); } else go('oralExam');`
  SurgoPage resolveTarget() {
    if (_tfBranch) return SurgoPage.tfBrief;
    switch (moduleKey) {
      case 'listening':
        return SurgoPage.listeningSession;
      case 'writing':
        return SurgoPage.writingSession;
      case 'speaking':
        if (selWizCard == 'pron') return SurgoPage.pronCourse;
        if (selWizCard == 'p3') return SurgoPage.oralDiscuss;
        return SurgoPage.oralExam;
      case 'vocab':
        return SurgoPage.vocab;
      default:
        return SurgoPage.ielts;
    }
  }

  /// 原型 `setLisPart(LPARTS[selWizCard]?selWizCard:'s1')` —— 校验后再用，默认 's1'。
  String get _lisPart {
    const parts = {'s1', 's2', 's3', 's4'};
    return parts.contains(selWizCard) ? selWizCard! : 's1';
  }

  /// 把 session 变量写回共享状态（沿用原型变量名），供下游模块 / TaskBrief 读取。
  void _commitSession() {
    _state.session.addAll(<String, dynamic>{
      'sessionKey': moduleKey,
      'sessionMode': 'daily',
      'readIdx': 0,
      'typeIdx': 0,
      'lisIdx': 0,
      'readMode': readMode,
      'selReadType': selReadType,
      'selWizCard': selWizCard,
      if (moduleKey == 'listening') 'lisPart': _lisPart,
      if (_tfBranch) 'tfBriefMod': moduleKey,
      if (isToefl && moduleKey == 'writing') 'tfWrTask': tfWrTask,
      if (isToefl && moduleKey == 'listening') 'tfLisTask': tfLisTask,
      if (isToefl && moduleKey == 'listening') 'tfLisDiff': tfLisDiff,
      if (isToefl && moduleKey == 'speaking') 'tfSpTask': tfSpTask,
    });
  }

  /// 原型 `genSession(key)` 动画回调里的 `doGenSession(key)`：写 session、跳目标页。
  /// 调用方负责先播放生成动画（[ReadingGenOverlay]）。
  void commitAndGo() {
    _commitSession();
    if (!_tfBranch && moduleKey == 'speaking' && selWizCard != 'pron') {
      requestOralStart(_state);
    } else {
      _state.go(resolveTarget());
    }
  }
}
