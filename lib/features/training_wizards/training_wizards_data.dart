import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 写作/听力/口语/词汇日常训练向导的静态数据 —— 由 `tool/export_training_wizards.cjs`
/// 从原型 `app.js` 无损导出到 `assets/data/training_wizards.json`：
///
/// - `WIZ`：雅思侧四个模块的向导配置（卡片版式 or 双卡版式的文案/题型）。
/// - `TFWR_TASKS` / `TFLIS_TASKS` / `TFLIS_DIFFS` / `TFSP_TASKS`：托福侧任务与难度。
/// - `TF_TASK_ICON`：任务 key → 图标文件名（不含扩展名）。
///
/// 字段名一律沿用原型变量名，不改文案。阅读向导在 `reading_wizard` 里单独实现，
/// 本数据不含 `RTYPES`/`TFREAD_*`。
class TrainingWizardsData {
  TrainingWizardsData({
    required this.wiz,
    required this.tfWrTasks,
    required this.tfLisTasks,
    required this.tfLisDiffs,
    required this.tfSpTasks,
    required this.tfTaskIcon,
  });

  /// 原型 `const WIZ={...}`，key = reading/listening/writing/speaking/vocab。
  final Map<String, WizConfig> wiz;

  /// 原型 `const TFWR_TASKS=[...]`（托福写作任务，无难度）。
  final List<TfTask> tfWrTasks;

  /// 原型 `const TFLIS_TASKS=[...]`（托福听力任务）。
  final List<TfTask> tfLisTasks;

  /// 原型 `const TFLIS_DIFFS=[...]`（托福听力难度分档）。
  final List<TfDiff> tfLisDiffs;

  /// 原型 `const TFSP_TASKS=[...]`（托福口语任务，无难度）。
  final List<TfTask> tfSpTasks;

  /// 原型 `const TF_TASK_ICON={...}`。
  final Map<String, String> tfTaskIcon;

  static TrainingWizardsData? _cache;

  WizConfig config(String key) => wiz[key]!;

  /// 原型 `tfTaskIcon(task)` 的资源路径版本；命中返回 svg 路径，否则 null。
  String? tfIconAsset(String task) {
    final n = tfTaskIcon[task];
    return n == null ? null : 'assets/images/$n.svg';
  }

  static Future<TrainingWizardsData> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/training_wizards.json');
    _cache = fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  static TrainingWizardsData fromJson(Map<String, dynamic> j) => TrainingWizardsData(
        wiz: (j['WIZ'] as Map).map(
          (k, v) => MapEntry(k as String, WizConfig.fromJson(v as Map<String, dynamic>)),
        ),
        tfWrTasks: (j['TFWR_TASKS'] as List)
            .map((e) => TfTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfLisTasks: (j['TFLIS_TASKS'] as List)
            .map((e) => TfTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfLisDiffs: (j['TFLIS_DIFFS'] as List)
            .map((e) => TfDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfSpTasks: (j['TFSP_TASKS'] as List)
            .map((e) => TfTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        tfTaskIcon: (j['TF_TASK_ICON'] as Map)
            .map((k, v) => MapEntry(k as String, v as String)),
      );
}

/// 原型 `WIZ[key]` 单项。卡片版式（listening/writing/speaking）用 [cards]；
/// 双卡版式（reading/vocab）用 [fullTtl]/[fullSub]/[singleSub]/[ph]/[opts]。
class WizConfig {
  WizConfig({
    required this.h1,
    required this.sub,
    required this.topic,
    this.fullTtl,
    this.fullSub,
    this.singleSub,
    this.ph,
    required this.cards,
    required this.opts,
  });

  final String h1;
  final String sub;

  /// 原型 `topic:true` —— 是否显示「话题（选填）」输入框。
  final bool topic;

  // 双卡版式字段：
  final String? fullTtl;
  final String? fullSub;
  final String? singleSub;
  final String? ph;

  /// 卡片版式的任务卡（原型 `c.cards`）。双卡版式为空列表。
  final List<WizCard> cards;

  /// 双卡「专注单一」下拉选项（原型 `WIZ[key].opts`）。卡片版式为空列表。
  final List<({String value, String label})> opts;

  /// 原型 `c.cards` 存在时走卡片版式，否则走双卡版式。
  bool get hasCards => cards.isNotEmpty;

  factory WizConfig.fromJson(Map<String, dynamic> j) => WizConfig(
        h1: j['h1'] as String,
        sub: j['sub'] as String,
        topic: (j['topic'] as bool?) ?? false,
        fullTtl: j['fullTtl'] as String?,
        fullSub: j['fullSub'] as String?,
        singleSub: j['singleSub'] as String?,
        ph: j['ph'] as String?,
        cards: (j['cards'] as List? ?? const [])
            .map((e) => WizCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        opts: (j['opts'] as List? ?? const [])
            .map((e) => (
                  value: (e as Map)['value'] as String,
                  label: e['label'] as String,
                ))
            .toList(),
      );
}

/// 原型 `WIZ[key].cards` 单项。[types] 是该 Part 的题型序列（下游作答模块用）。
class WizCard {
  WizCard({
    required this.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.tag,
    required this.rec,
    required this.types,
  });

  final String key;

  /// 原型图标路径（如 `assets/ic_l_conv.svg`）。
  final String icon;
  final String title;
  final String sub;

  /// 原型 `cd.tag`（可空，如「10 题」「约 20 分钟」）。
  final String? tag;

  /// 原型 `cd.rec`（是否「推荐」角标）。
  final bool rec;

  /// 原型 `cd.types`（该 Part 的题型序列，可空）。
  final List<String> types;

  /// 把原型 `assets/x.svg` 映射到 Flutter 资源目录 `assets/images/x.svg`。
  String get iconAsset => icon.replaceFirst('assets/', 'assets/images/');

  factory WizCard.fromJson(Map<String, dynamic> j) => WizCard(
        key: j['key'] as String,
        icon: j['icon'] as String,
        title: j['title'] as String,
        sub: j['sub'] as String,
        tag: j['tag'] as String?,
        rec: (j['rec'] as bool?) ?? false,
        types: (j['types'] as List? ?? const []).map((e) => e as String).toList(),
      );
}

/// 原型 TFWR_TASKS / TFLIS_TASKS / TFSP_TASKS 单项。
class TfTask {
  TfTask({
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

  factory TfTask.fromJson(Map<String, dynamic> j) => TfTask(
        key: j['key'] as String,
        n: (j['n'] as num).toInt(),
        title: j['title'] as String,
        sub: j['sub'] as String,
        tag: j['tag'] as String,
      );
}

/// 原型 `TFLIS_DIFFS` 单项（`{k,label}`）。
class TfDiff {
  TfDiff({required this.k, required this.label});

  final String k;
  final String label;

  factory TfDiff.fromJson(Map<String, dynamic> j) =>
      TfDiff(k: j['k'] as String, label: j['label'] as String);
}
