import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// 阅读日常训练向导的静态数据 —— 由运行时从原型 `app.js` 无损导出到
/// `assets/data/reading_wizard.json`（含 RTYPES / TFREAD_TASKS /
/// TFREAD_DIFFS / TF_TASK_ICON 原文）。字段名与原型变量名一致，不改文案。
class ReadingWizardData {
  ReadingWizardData({
    required this.rtypes,
    required this.tfReadTasks,
    required this.tfReadDiffs,
    required this.tfTaskIcon,
  });

  /// 原型 `const RTYPES=[...]` —— IELTS「专注单一」的题型下拉来源。
  final List<RType> rtypes;

  /// 原型 `const TFREAD_TASKS=[...]` —— TOEFL 阅读三个任务卡。
  final List<TfReadTask> tfReadTasks;

  /// 原型 `const TFREAD_DIFFS=[...]` —— 难度分档。
  final List<TfReadDiff> tfReadDiffs;

  /// 原型 `const TF_TASK_ICON={...}` —— 任务 key → 图标文件名（不含扩展名）。
  final Map<String, String> tfTaskIcon;

  static ReadingWizardData? _cache;

  /// 与原型 `wizOptions('reading')` 等价：`RTYPES.map(t=>({value:t.key,label:t.name}))`。
  List<({String value, String label})> get readingOptions =>
      rtypes.map((t) => (value: t.key, label: t.name)).toList();

  /// `tfTaskIcon(task)` —— 命中则返回资源路径，否则 null（与原型返回空串一致的语义）。
  String? tfIconAsset(String task) {
    final n = tfTaskIcon[task];
    return n == null ? null : 'assets/images/$n.svg';
  }

  static Future<ReadingWizardData> load() async {
    if (_cache != null) return _cache!;
    // 直接读字节再解码：rootBundle.loadString 对 50 KB 以上的文件会另起 isolate 解码，
    // widget 测试（路由审计）的假时钟等不到它；演示用真实数据的这个文件超过了 50 KB。
    final raw = utf8.decode(Uint8List.sublistView(
        await rootBundle.load('assets/data/reading_wizard.json')));
    _cache = fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  static ReadingWizardData fromJson(Map<String, dynamic> j) => ReadingWizardData(
        rtypes: (j['RTYPES'] as List)
            .map((e) => RType.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfReadTasks: (j['TFREAD_TASKS'] as List)
            .map((e) => TfReadTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfReadDiffs: (j['TFREAD_DIFFS'] as List)
            .map((e) => TfReadDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfTaskIcon: (j['TF_TASK_ICON'] as Map)
            .map((k, v) => MapEntry(k as String, v as String)),
      );
}

/// 原型 RTYPES 单项。除向导用到的 key/name/mins 外，其余原文（题干、原文、
/// 选项、instr…）整体保留在 [raw]，供下游作答模块无损取用。
class RType {
  RType({required this.key, required this.name, required this.mins, required this.raw});

  final String key;
  final String name;

  /// 原型 `mins`（题目长度/建议时长）—— 保留「length」信息不丢。
  final num mins;

  /// 该题型的完整原始 JSON（含 instr / kind / article / items / options…）。
  final Map<String, dynamic> raw;

  factory RType.fromJson(Map<String, dynamic> j) => RType(
        key: j['key'] as String,
        name: j['name'] as String,
        mins: (j['mins'] as num?) ?? 0,
        raw: j,
      );
}

/// 原型 `TFREAD_TASKS` 单项。
class TfReadTask {
  TfReadTask({
    required this.key,
    required this.n,
    required this.title,
    required this.sub,
    required this.tag,
  });

  final String key;
  final int n;
  final String title;
  final String sub;
  final String tag;

  factory TfReadTask.fromJson(Map<String, dynamic> j) => TfReadTask(
        key: j['key'] as String,
        n: (j['n'] as num).toInt(),
        title: j['title'] as String,
        sub: j['sub'] as String,
        tag: j['tag'] as String,
      );
}

/// 原型 `TFREAD_DIFFS` 单项（`{k,label}`）。
class TfReadDiff {
  TfReadDiff({required this.k, required this.label});

  final String k;
  final String label;

  factory TfReadDiff.fromJson(Map<String, dynamic> j) =>
      TfReadDiff(k: j['k'] as String, label: j['label'] as String);
}
