import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// TOEFL 每日训练 · 生活阅读（tfDailyLife）与反馈（tfDlFb）的纯逻辑层。
//
// 逐条对应 surgo-mobile-new/app.js 9848-10135（只读源，未改动）：
//   TFDL_AD / TFDL_POST / TFDL_QS / TFDL_SEC / TFDL_TOTAL /
//   startTfDailyLife / tfDlSrc / tfDlTitle / tfDlAnswered / tfDlClearTimers /
//   tfDlPick / tfDlPrev / tfDlJump / tfDlNext / tfDlStartFlow /
//   openTfDlTimeup / closeTfDlTimeup / TFDLFB_WEAK / TFDLFB_SRC / TFDLFB_QS /
//   tfDlFbView。
//
// 这里只放数据结构与状态机；Widget 层（tfDailyLifeView / tfDlFbView）与计时器
// 驱动放在 toefl_life_page.dart / toefl_life_feedback.dart。规则一字不改：
//   * 每题独立 40 秒倒计时（TFDL_SEC=40）；归零转正计时并**仅弹一次**「时间到」；
//   * 「已作答」= tfDlVals 里的键数（tfDlAnswered），选项一经选择即计入；
//   * 「上一题」不重置计时（原型 tfDlPrev 只 render）；
//   * 「下一段」重置 left=40/over=false/up=0/alerted=false 并重启计时；
//   * 最后一题点「提交」→ 批改动画 → go('tfDlFb')；
//   * 原文/标题按 tfDlSrc / tfDlTitle 从当前题向前回溯继承；
//   * 反馈页为原型固定 fixture 文案，不发明任何真实评分。

/// 单题，对应 TFDL_QS 的元素 `{src?, title?, q, opts[]}`。
class TfDlQuestion {
  const TfDlQuestion({
    this.src,
    this.title,
    required this.q,
    required this.opts,
  });

  /// 原文来源标记：'ad' / 'post'，缺省表示沿用前一题的原文（原型 tfDlSrc 回溯）。
  final String? src;

  /// 题面标题，缺省表示沿用前一题的标题（原型 tfDlTitle 回溯）。
  final String? title;

  final String q;
  final List<String> opts;

  factory TfDlQuestion.fromJson(Map<String, dynamic> j) => TfDlQuestion(
        src: j['src'] as String?,
        title: j['title'] as String?,
        q: j['q'] as String,
        opts: (j['opts'] as List).map((e) => e as String).toList(),
      );
}

/// 反馈页薄弱项，对应 TFDLFB_WEAK 元素。
///
/// 三个字段在原型数据里是字符串；演示用真实数据（tool/demo_export）给的是
/// `[英文, 中文]` 一对，由页面按界面语言取。
class TfDlWeak {
  const TfDlWeak({required this.tags, required this.q, required this.a});
  final List<Object> tags; // 恰好 3 个：tags[0..2]
  final Object q;
  final Object a;

  factory TfDlWeak.fromJson(Map<String, dynamic> j) => TfDlWeak(
        tags: (j['tags'] as List).cast<Object>(),
        q: j['q'] as Object,
        a: j['a'] as Object,
      );
}

/// 反馈页 Passage 原文回看片段，对应 TFDLFB_SRC 元素
/// `[前文, 命中片段, 题号, 后文]`。命中片段为空表示纯文本片段（原型 !r[1]）。
class TfDlSrcRow {
  const TfDlSrcRow({
    required this.before,
    required this.hit,
    required this.qnum,
    required this.after,
  });
  final String before;
  final String hit; // 空串 => 纯文本片段
  final int qnum;
  final String after;

  bool get isPlain => hit.isEmpty;

  factory TfDlSrcRow.fromJson(List<dynamic> r) => TfDlSrcRow(
        before: r[0] as String,
        hit: (r.length > 1 && r[1] != null) ? r[1] as String : '',
        qnum: (r.length > 2 && r[2] != null) ? (r[2] as num).toInt() : 0,
        after: (r.length > 3 && r[3] != null) ? r[3] as String : '',
      );
}

/// 反馈页逐题卡，对应 TFDLFB_QS 元素。
class TfDlQ {
  const TfDlQ({
    required this.n,
    required this.ok,
    required this.q,
    required this.mine,
    this.ans,
    this.why,
    this.evi,
  });
  final int n;
  final bool ok;
  final String q;
  final String mine;
  final String? ans; // 缺省表示不显示「正确答案」行（原型 q.ans 假值）
  final Object? why; // 缺省表示不显示解析块（原型 q.why 假值）；字符串或 [英文, 中文]
  final String? evi; // 原文依据，与 why 同块

  factory TfDlQ.fromJson(Map<String, dynamic> j) => TfDlQ(
        n: (j['n'] as num).toInt(),
        ok: j['ok'] as bool,
        q: j['q'] as String,
        mine: j['mine'] as String,
        ans: j['ans'] as String?,
        why: j['why'],
        evi: j['evi'] as String?,
      );
}

/// 生活阅读页 + 反馈页共享的静态内容（从 assets/data/toefl_life.json 载入）。
///
/// JSON 由 tool/export_toefl_life.cjs 用 Node vm 直接 eval 原型 app.js 的常量
/// 源码切片导出，与原型对象字面量逐字节一致。
class TfDlContent {
  const TfDlContent({
    required this.ad,
    required this.post,
    required this.questions,
    required this.sec,
    required this.weak,
    required this.src,
    required this.qs,
    this.score,
  });

  /// 这一场的练习估分（TFDLFB_SCORE，如 "2.0"）。只有演示用真实数据带；
  /// 原型数据没有，反馈页照旧显示写死的分数和评语。
  final String? score;

  /// 原型 TFDL_AD —— 广告原文行（'' 表示段落间隔）。
  final List<String> ad;

  /// 原型 TFDL_POST —— 社媒帖子原文行。
  final List<String> post;

  /// 原型 TFDL_QS。
  final List<TfDlQuestion> questions;

  /// 原型 TFDL_SEC = 40（每题固定 40 秒）。
  final int sec;

  final List<TfDlWeak> weak;
  final List<TfDlSrcRow> src;
  final List<TfDlQ> qs;

  /// 原型 TFDL_TOTAL = TFDL_QS.length。
  int get total => questions.length;

  static TfDlContent? _cache;

  /// 从 assets/data/toefl_life.json 载入，缓存单例（同 [TfDwContent.load]）。
  static Future<TfDlContent> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/toefl_life.json');
    _cache = TfDlContent.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  factory TfDlContent.fromJson(Map<String, dynamic> j) {
    return TfDlContent(
      ad: (j['TFDL_AD'] as List).map((e) => e as String).toList(),
      post: (j['TFDL_POST'] as List).map((e) => e as String).toList(),
      questions: (j['TFDL_QS'] as List)
          .map((q) => TfDlQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      sec: (j['TFDL_SEC'] as num).toInt(),
      weak: (j['TFDLFB_WEAK'] as List)
          .map((w) => TfDlWeak.fromJson(w as Map<String, dynamic>))
          .toList(),
      src: (j['TFDLFB_SRC'] as List)
          .map((r) => TfDlSrcRow.fromJson(r as List))
          .toList(),
      qs: (j['TFDLFB_QS'] as List)
          .map((q) => TfDlQ.fromJson(q as Map<String, dynamic>))
          .toList(),
      score: j['TFDLFB_SCORE'] as String?,
    );
  }
}

/// 生活阅读页状态机 —— 对应 app.js 顶层的 tfDlIdx / tfDlVals / tfDlLeft /
/// tfDlOver / tfDlUp / tfDlAlerted 六个可变量与它们的读写函数。
///
/// 计时器本身（setInterval）不在这里，由 Widget 的 Timer 每秒调用 [tick]。
class TfDlController {
  TfDlController(this.content);

  final TfDlContent content;

  // 原型：let tfDlIdx=0, tfDlVals={}, tfDlLeft=TFDL_SEC;
  int idx = 0;

  /// 题号 → 所选选项下标（原型 tfDlVals）。
  final Map<int, int> vals = {};
  late int left = content.sec;
  // 原型：let tfDlOver=false, tfDlUp=0, tfDlAlerted=false;
  bool over = false;
  int up = 0;
  bool alerted = false;

  /// 对应 startTfDailyLife()：重置全部状态到起点。
  /// （原型还会 tfDlClearTimers() + go('tfDailyLife')，那由外层承担。）
  void start() {
    idx = 0;
    vals.clear();
    left = content.sec;
    over = false;
    up = 0;
    alerted = false;
  }

  /// 当前题（原型 `TFDL_QS[tfDlIdx]||TFDL_QS[0]`）。
  TfDlQuestion get current => idx < content.questions.length
      ? content.questions[idx]
      : content.questions[0];

  /// 对应 tfDlAnswered()：已作答数 = 记录键数。
  int answered() => vals.length;

  /// 当前题所选选项，未选返回 null（原型 `tfDlVals[tfDlIdx]`）。
  int? selected() => vals[idx];

  /// 对应 tfDlSrc()：从当前题向前回溯首个带 src 的题，返回其原文行；
  /// 'post' → TFDL_POST，其余 → TFDL_AD；找不到默认 TFDL_AD。
  List<String> srcLines() {
    for (var i = idx; i >= 0; i--) {
      final q = i < content.questions.length ? content.questions[i] : null;
      if (q != null && q.src != null) {
        return q.src == 'post' ? content.post : content.ad;
      }
    }
    return content.ad;
  }

  /// 对应 tfDlTitle()：从当前题向前回溯首个带 title 的题；
  /// 找不到默认 'Read an advertisement.'。
  String title() {
    for (var i = idx; i >= 0; i--) {
      final q = i < content.questions.length ? content.questions[i] : null;
      if (q != null && q.title != null) return q.title!;
    }
    return 'Read an advertisement.';
  }

  /// 对应 tfDlMMSS / tfDwMMSS(v)：秒 → mm:ss（两位补零）。
  static String mmss(int v) {
    final m = v ~/ 60;
    final x = v % 60;
    return '${m.toString().padLeft(2, '0')}:${x.toString().padLeft(2, '0')}';
  }

  /// 时钟文案，对应 view 里的 clockTxt：⏱ mm:ss / ⏱ +mm:ss。
  String clockText() => over ? '\u23f1 +${mmss(up)}' : '\u23f1 ${mmss(left)}';

  /// 超时提示文案，对应 .tfdl-overtip：`已用 (SEC+up) 秒，建议限制在 35-45 秒`。
  String overTip() =>
      '\u5df2\u7528 ${content.sec + up} \u79d2\uff0c\u5efa\u8bae\u9650\u5236\u5728 35-45 \u79d2';

  /// 下一步按钮文案：最后一题是「提交」，否则「下一段」。
  String nextLabel() => isLast
      ? '\u63d0\u4ea4'
      : '\u4e0b\u4e00\u6bb5';

  /// 是否显示「上一题」按钮（idx>0）。
  bool get canPrev => idx > 0;

  /// 是否为最后一题（点下一步进入批改）。
  bool get isLast => idx >= content.total - 1;

  /// 对应 tfDlPick(i)：记录当前题所选选项。
  void pick(int i) {
    vals[idx] = i;
  }

  /// 对应 tfDlPrev()：回上一题，不重置计时（原型只 render）。
  void prev() {
    if (idx <= 0) return;
    idx--;
  }

  /// 对应 tfDlJump(i)：跳到第 i 题，不重置计时（原型只 render）。
  void jump(int i) {
    if (i == idx) return;
    idx = i;
  }

  /// 对应 tfDlNext() 的「非最后一题」分支：进入下一题并重置本题计时。
  /// 返回值：true 表示已翻到下一题；false 表示当前已是最后一题
  /// （调用方应转入批改流程 → tfDlFb）。
  bool next() {
    if (isLast) return false;
    idx++;
    // 每题独立 40 秒：重置倒计时与正计时状态（原型注释同款）
    left = content.sec;
    over = false;
    up = 0;
    alerted = false;
    return true;
  }

  /// 计时器每秒回调，对应 tfDlStartFlow() 里的 setInterval body。
  /// 返回值：本次 tick 是否应触发「时间到」弹窗（首次归零，对应
  /// `if(!tfDlAlerted){ tfDlAlerted=true; openTfDlTimeup(); }`）。
  bool tick() {
    var shouldAlert = false;
    if (!over) {
      left--;
      if (left <= 0) {
        left = 0;
        over = true;
        if (!alerted) {
          alerted = true;
          shouldAlert = true;
        }
      }
    } else {
      up++;
    }
    return shouldAlert;
  }
}
