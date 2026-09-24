import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// TOEFL 每日训练 · 补全单词（tfDailyWords）与反馈（tfDwFb）的纯逻辑层。
//
// 逐条对应 surgo-mobile-new/app.js 9609-9842：
//   TFDW_PARAS / TFDW_SEC / tfDwBlanks / tfDwFilled / tfDwMMSS /
//   startTfDailyWords / tfDwSet / tfDwPrev / tfDwNext / tfDwStartFlow /
//   openTfDwTimeup / closeTfDwTimeup / TFDWFB_* / tfDwFbView。
//
// 这里只放数据结构与状态机；Widget 层（tfDailyWordsView / tfDwFbView）
// 与计时器驱动放在 toefl_words_page.dart。规则一字不改：
//   * 每段独立 90 秒倒计时；到 0 转正计时并弹「时间到」一次；
//   * 进度 = 已填空格数 / 空格总数；空格「已填」判定为 trim() 非空；
//   * 上一题不重置计时（原型 tfDwPrev 只 render，不动计时状态）；
//   * 下一段重置 left=90/over=false/up=0/alerted=false 并重启计时；
//   * 最后一段点「下一部分」进入批改 → tfDwFb。

/// 一个段落里的元素：要么是纯文本（[text] 非空、[isBlank]=false），
/// 要么是一个填空（[isBlank]=true，携带前缀/缺失字母数/后缀）。
///
/// 对应原型 TFDW_PARAS 里的元素：字符串 => 文本；`[前缀, 缺失数, 后缀]` => 填空。
class TfDwToken {
  const TfDwToken.text(this.text)
      : isBlank = false,
        prefix = '',
        missing = 0,
        suffix = '';

  const TfDwToken.blank({
    required this.prefix,
    required this.missing,
    required this.suffix,
  })  : isBlank = true,
        text = '';

  final bool isBlank;
  final String text;

  /// 填空前缀，原型 x[0]（如 "emb"）
  final String prefix;

  /// 缺失字母数，原型 x[1]（同时用于 <sub> 小数字与 input 的 size）
  final int missing;

  /// 填空后缀，原型 x[2]（如 "k"，可能为空串）
  final String suffix;

  /// 对应 `size="${Math.max(2,x[1])}"`
  int get inputSize => missing < 2 ? 2 : missing;
}

/// 反馈页薄弱项，对应 TFDWFB_WEAK 元素。
class TfDwWeak {
  const TfDwWeak({required this.tags, required this.q, required this.a});
  final List<String> tags; // 恰好 3 个：tags[0..2]
  final String q;
  final String a;
}

/// 反馈页「Completed paragraph」原文回看片段，对应 TFDWFB_SRC 元素
/// `[前文, 命中片段, 题号, 后文]`。命中片段为空表示纯文本片段。
class TfDwSrcRow {
  const TfDwSrcRow({
    required this.before,
    required this.hit,
    required this.qnum,
    required this.after,
  });
  final String before;
  final String hit; // 空串 => 纯文本片段（原型 !r[1] 分支）
  final int qnum;
  final String after;

  bool get isPlain => hit.isEmpty;
}

/// 反馈页逐题卡，对应 TFDWFB_QS 元素。
class TfDwQ {
  const TfDwQ({
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
  final String? why; // 缺省表示不显示解析块（原型 q.why 假值）
  final String? evi; // 原文依据，与 why 同块
}

/// 反馈页估分卡文案，对应 tfDwFbView 里的 .tffb-score 硬编码文案。
class TfDwScore {
  const TfDwScore({
    required this.k,
    required this.n,
    required this.den,
    required this.d,
    required this.f,
  });
  final String k;
  final String n;
  final String den;
  final String d;
  final String f;
}

/// 补全单词页 + 反馈页共享的静态内容（从 assets/data/toefl_words.json 载入）。
class TfDwContent {
  const TfDwContent({
    required this.paras,
    required this.sec,
    required this.weak,
    required this.src,
    required this.qs,
    required this.score,
  });

  /// 原型 TFDW_PARAS
  final List<List<TfDwToken>> paras;

  /// 原型 TFDW_SEC = 90
  final int sec;

  final List<TfDwWeak> weak;
  final List<TfDwSrcRow> src;
  final List<TfDwQ> qs;
  final TfDwScore score;

  /// 原型 TFDW_TOTAL = TFDW_PARAS.length
  int get total => paras.length;

  static TfDwContent? _cache;

  /// 从 assets/data/toefl_words.json 载入（原型 app.js 9609-9842 无损导出），
  /// 缓存单例，语义同 [ReadingWizardData.load]。
  static Future<TfDwContent> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/toefl_words.json');
    _cache = TfDwContent.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  factory TfDwContent.fromJson(Map<String, dynamic> j) {
    List<TfDwToken> parseTokens(List<dynamic> raw) {
      return raw.map<TfDwToken>((e) {
        if (e is List) {
          // [前缀, 缺失数, 后缀]
          return TfDwToken.blank(
            prefix: e[0] as String,
            missing: (e[1] as num).toInt(),
            suffix: e[2] as String,
          );
        }
        return TfDwToken.text(e as String);
      }).toList();
    }

    final paras = (j['TFDW_PARAS'] as List)
        .map((p) => parseTokens(p as List))
        .toList();

    final weak = (j['TFDWFB_WEAK'] as List).map((w) {
      final m = w as Map<String, dynamic>;
      return TfDwWeak(
        tags: (m['tags'] as List).map((e) => e as String).toList(),
        q: m['q'] as String,
        a: m['a'] as String,
      );
    }).toList();

    final src = (j['TFDWFB_SRC'] as List).map((r) {
      final l = r as List;
      return TfDwSrcRow(
        before: l[0] as String,
        hit: l[1] as String,
        qnum: (l[2] as num).toInt(),
        after: l[3] as String,
      );
    }).toList();

    final qs = (j['TFDWFB_QS'] as List).map((q) {
      final m = q as Map<String, dynamic>;
      return TfDwQ(
        n: (m['n'] as num).toInt(),
        ok: m['ok'] as bool,
        q: m['q'] as String,
        mine: m['mine'] as String,
        ans: m['ans'] as String?,
        why: m['why'] as String?,
        evi: m['evi'] as String?,
      );
    }).toList();

    final sc = j['TFDWFB_SCORE'] as Map<String, dynamic>;
    final score = TfDwScore(
      k: sc['k'] as String,
      n: sc['n'] as String,
      den: sc['den'] as String,
      d: sc['d'] as String,
      f: sc['f'] as String,
    );

    return TfDwContent(
      paras: paras,
      sec: (j['TFDW_SEC'] as num).toInt(),
      weak: weak,
      src: src,
      qs: qs,
      score: score,
    );
  }
}

/// 补全单词页状态机 —— 对应 app.js 顶层的 tfDwPara / tfDwVals / tfDwLeft /
/// tfDwOver / tfDwUp / tfDwAlerted 六个可变量与它们的读写函数。
///
/// 计时器本身（setInterval）不在这里，由 Widget 的 Ticker/Timer 每秒调用
/// [tick]。这样纯逻辑可被单测覆盖，无需真实时钟。
class TfDwController {
  TfDwController(this.content);

  final TfDwContent content;

  // 原型：let tfDwPara=0, tfDwVals={}, tfDwLeft=TFDW_SEC;
  int para = 0;
  final Map<String, String> vals = {};
  late int left = content.sec;
  // 原型：let tfDwOver=false, tfDwUp=0, tfDwAlerted=false;
  bool over = false;
  int up = 0;
  bool alerted = false;

  /// 对应 startTfDailyWords()：重置全部状态到起点。
  /// （原型里还会 tfDwClearTimers() + go('tfDailyWords')，那由外层承担。）
  void start() {
    para = 0;
    vals.clear();
    left = content.sec;
    over = false;
    up = 0;
    alerted = false;
  }

  /// 对应 tfDwBlanks()：当前段的填空列表。
  List<TfDwToken> blanks() =>
      (para < content.paras.length ? content.paras[para] : const <TfDwToken>[])
          .where((t) => t.isBlank)
          .toList();

  /// 对应 tfDwFilled()：当前段已填（trim 非空）的空格数。
  int filled() {
    final n = blanks().length;
    var c = 0;
    for (var i = 0; i < n; i++) {
      final v = vals['${para}_$i'] ?? '';
      if (v.trim().isNotEmpty) c++;
    }
    return c;
  }

  /// 当前段空格总数。
  int total() => blanks().length;

  /// 进度百分比，对应 `total?Math.round(done/total*100):0`。
  int pct() {
    final t = total();
    if (t == 0) return 0;
    return (filled() / t * 100).round();
  }

  /// 对应 tfDwSet(key, el)：写入某个空格的值。key 形如 '0_2'。
  void setVal(String key, String value) {
    vals[key] = value;
  }

  /// 便捷：按段内序号写值。
  void setBlank(int index, String value) => setVal('${para}_$index', value);

  /// 读取某段内空格当前值。
  String valueAt(int index) => vals['${para}_$index'] ?? '';

  /// 对应 tfDwMMSS(v)：秒 → mm:ss（两位补零）。
  static String mmss(int v) {
    final m = v ~/ 60;
    final x = v % 60;
    return '${m.toString().padLeft(2, '0')}:${x.toString().padLeft(2, '0')}';
  }

  /// 时钟文案，对应 view 里的 clockTxt：⏱ mm:ss / ⏱ +mm:ss。
  String clockText() =>
      over ? '\u23f1 +${mmss(up)}' : '\u23f1 ${mmss(left)}';

  /// 下一段/下一步按钮文案：最后一段是「下一部分」，否则「下一段」。
  String nextLabel() =>
      para >= content.total - 1 ? '\u4e0b\u4e00\u90e8\u5206' : '\u4e0b\u4e00\u6bb5';

  /// 是否显示「上一题」按钮（para>0）。
  bool get canPrev => para > 0;

  /// 是否为最后一段（点下一步进入批改）。
  bool get isLast => para >= content.total - 1;

  /// 对应 tfDwPrev()：回上一段，不重置计时（原型只 render）。
  void prev() {
    if (para <= 0) return;
    para--;
  }

  /// 对应 tfDwNext() 的「非最后一段」分支：进入下一段并重置本段计时。
  /// 返回值：true 表示已翻到下一段；false 表示当前已是最后一段
  /// （调用方应转入批改流程 → tfDwFb）。
  bool next() {
    if (isLast) return false;
    para++;
    // 每段独立 90 秒：重置倒计时与正计时状态（原型注释同款）
    left = content.sec;
    over = false;
    up = 0;
    alerted = false;
    return true;
  }

  /// 计时器每秒回调，对应 tfDwStartFlow() 里的 setInterval body。
  /// 返回值：本次 tick 是否应触发「时间到」弹窗（首次归零，对应
  /// `if(!tfDwAlerted){ tfDwAlerted=true; openTfDwTimeup(); }`）。
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
