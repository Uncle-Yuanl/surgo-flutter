import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'routes.dart';
import 'js_replacement.dart';
import 'learner_profile.dart';
import 'supplementary_en.dart';
import 'supplementary_zh.dart';
import '../widgets/source_text.dart' show SourceNodeTranslations;

/// 一位正在翻译的字符串。原型 `applyLang()` 的逻辑逐条照搬：
///
/// ```js
/// const pick=(s)=>{
///   const key=s.trim(); if(!key) return s;
///   if(EXACT[key]!==undefined) return EXACT[key];
///   if(TABLE[key]!==undefined) return TABLE[key];
///   for(let i=0;i<RES.length;i++){ if(RES[i][0].test(key)) return key.replace(RES[i][0],RES[i][1]); }
///   return s;
/// };
/// ```
///
/// 注意这里有个必须保留的设计：**整串精确匹配优先，正则兜底**。
/// 原型的前身用「平铺数组 + 子串替换」，导致
/// 「主题词汇 → 主题Vocabulary」「回到首页 → 回到Home」这类混排，
/// 所以现在只认整节点精确命中。翻译时必须保持这个顺序，否则会退化回老 bug。
class Translator {
  Translator._(this._en, this._enRe, this._zh, this._zhRe);

  final Map<String, String> _en;
  final List<_ReRule> _enRe;
  final Map<String, String> _zh;
  final List<_ReRule> _zhRe;

  /// 原型：`const LANG_EXACT={'分':' band','天':' days','词':' words','分钟':' min'};`
  static const _langExact = <String, String>{
    '分': ' band',
    '天': ' days',
    '词': ' words',
    '分钟': ' min',
  };

  /// 原型：`const ZH_EXACT={'EN':'EN','OK':'确定'};`
  static const _zhExact = <String, String>{
    'EN': 'EN',
    'OK': '确定',
  };

  /// 原型：`const CJK_RE=/[\u3400-\u9fff\uf900-\ufaff\u3000-\u303f\uff01-\uff5e]/;`
  /// 用于判断一个字符串是"中文界面文案"还是"英文原文/题干"。
  static final cjkRe = RegExp(
    r'[\u3400-\u9fff\uf900-\ufaff\u3000-\u303f\uff01-\uff5e]',
  );

  static Translator? _cached;

  static bool get isLoaded => _cached != null;
  static Translator get instance {
    final t = _cached;
    if (t == null) {
      throw StateError('词典未加载，请先 await Translator.load()');
    }
    return t;
  }

  /// 从 assets/data/i18n.json 载入。该文件由 i18n.js 原样导出生成
  /// （949 条精确词条 + 62 条正则规则），不经过手工转写，保证与原型一致。
  static Future<Translator> load() async {
    if (_cached != null) return _cached!;
    await SourceNodeTranslations.load();
    // 学员总览数据也在这里一起载入：页面（首页、个人中心、学情分析…）同步读它，
    // 而每个入口和测试启动时都会先载词典。
    await LearnerProfile.load();
    final raw = await rootBundle.loadString('assets/data/i18n.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final t = Translator._(
      _strMap(map['SURGO_EN']),
      _rules(map['SURGO_EN_RE']),
      _strMap(map['SURGO_ZH']),
      _rules(map['SURGO_ZH_RE']),
    );
    _cached = t;
    return t;
  }

  static Map<String, String> _strMap(dynamic v) {
    if (v is! Map) return const {};
    return v.map((k, val) => MapEntry(k.toString(), val.toString()));
  }

  /// 正则在 JSON 里是 `["pattern","replacement","flags"]` 三元组。
  static List<_ReRule> _rules(dynamic v) {
    if (v is! List) return const [];
    final out = <_ReRule>[];
    for (final row in v) {
      if (row is! List || row.length < 2) continue;
      final flags = row.length > 2 ? row[2].toString() : '';
      final pattern = row[0].toString();
      out.add(_ReRule(jsRegExp(pattern, flags),
          row[1].toString(), flags.contains('g')));
    }
    return out;
  }

  /// 对应原型 `trStr(s)`：精确表 → 正则表 → 原样。
  String trStr(String s) {
    final key = s.trim();
    if (key.isEmpty) return s;
    final exact = _langExact[key];
    if (exact != null) return exact;
    final hit = _en[key];
    if (hit != null) return hit;
    for (final r in _enRe) {
      if (r.pattern.hasMatch(key)) {
        return jsReplace(key, r.pattern, r.replacement, global: r.global);
      }
    }
    return s;
  }

  /// 对应原型 `pick()`，按当前界面语言选表。
  String _pick(String s, UiLang lang) {
    final key = s.trim();
    if (key.isEmpty) return s;
    if (lang == UiLang.en) {
      final e = _langExact[key];
      if (e != null) return e;
      final t = _en[key];
      if (t != null) return t;
      for (final r in _enRe) {
        if (r.pattern.hasMatch(key)) return jsReplace(key, r.pattern, r.replacement, global: r.global);
      }
      // 补充表（用户 2026-09-24）：源站「中文→英文」表漏掉的界面文案，
      // 例如答题卡弹窗的「题号导航 / 未作答 / 交卷」。只补界面文案。
      final extra = supplementaryEn[key];
      if (extra != null) return extra;
      return s;
    }
    final z = _zhExact[key];
    if (z != null) return z;
    final t = _zh[key];
    if (t != null) return t;
    for (final r in _zhRe) {
      if (r.pattern.hasMatch(key)) return jsReplace(key, r.pattern, r.replacement, global: r.global);
    }
    // 补充表（用户 2026-09-24）：源站把部分界面文案硬编码成英文，
    // 而 i18n.json 只有「中文→英文」方向，这些串在中文模式下查不到译文。
    // 这里按英文原文补中文，只覆盖界面文案，不含题干与选项。
    final extra = supplementaryZh[key];
    if (extra != null) return extra;
    return s;
  }

  /// 翻译一段"界面文案"。返回 null 表示这个串不需要翻译，调用方应保持原文。
  ///
  /// 原型在 DOM 里逐文本节点判断：
  ///   - zh 模式：只处理**不含中文**的节点（英文界面文案换回中文）
  ///   - en 模式：只处理**含中文**的节点
  /// 这道过滤非常重要 —— 题干、原文、transcript、选项属于"题目内容"，
  /// 不能被词典命中。所以这里原样保留该判定。
  String? translate(String text, UiLang lang) {
    if (text.isEmpty || text.trim().isEmpty) return null;
    final hasCjk = cjkRe.hasMatch(text);
    if (lang == UiLang.zh && hasCjk) return null;
    if (lang == UiLang.en && !hasCjk) return null;
    final out = _pick(text, lang);
    return out == text ? null : out;
  }

  /// 题目内容（题干/原文/选项/transcript）直接透传，永不翻译。
  ///
  /// 原型依赖词典范围避免翻译题目，并非 DOM 自动跳过题目节点。
  /// 新页面必须显式将题目内容与界面文案分开使用。
  String content(String s) => s;
}

class _ReRule {
  const _ReRule(this.pattern, this.replacement, this.global);
  final RegExp pattern;
  final String replacement;
  final bool global;
}

/// 题库 —— 对应原型 `questions.js` 的 `const QB = {exam:{skill:{...}}}`。
///
/// 从 assets/data/questions.json 载入（由 questions.js 原样导出），
/// 因此题干、选项、答案、解析与原型逐字一致。
class QuestionBank {
  QuestionBank._(this._raw);

  final Map<String, dynamic> _raw;

  static QuestionBank? _cached;
  static QuestionBank get instance {
    final b = _cached;
    if (b == null) throw StateError('题库未加载，请先 await QuestionBank.load()');
    return b;
  }

  static bool get isLoaded => _cached != null;

  static Future<QuestionBank> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/questions.json');
    _cached = QuestionBank._(json.decode(raw) as Map<String, dynamic>);
    return _cached!;
  }

  /// 对应原型 `qb(skill)`：取当前考试类型下的某科数据。
  ///
  /// ```js
  /// function qb(skill){ return (QB[examType]&&QB[examType][skill])||{}; }
  /// ```
  Map<String, dynamic> skill(String skill, ExamType exam) {
    final byExam = _raw[exam.name];
    if (byExam is! Map) return const {};
    final bySkill = byExam[skill];
    if (bySkill is! Map) return const {};
    return bySkill.cast<String, dynamic>();
  }

  Map<String, dynamic> get ielts =>
      (_raw['ielts'] as Map).cast<String, dynamic>();
  Map<String, dynamic> get toefl =>
      (_raw['toefl'] as Map).cast<String, dynamic>();

  /// 题型列表（对应 `qb(skill).types`）。
  List<Map<String, dynamic>> types(String skillKey, ExamType exam) {
    final t = skill(skillKey, exam)['types'];
    if (t is! List) return const [];
    return t.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
}