import '../../app/learner_profile.dart';
import '../../app/routes.dart';

const learningSkills = ['writing', 'reading', 'listening', 'speaking'];
String skillName(String key, bool zh) => {
      'writing': zh ? '写作' : 'Writing',
      'reading': zh ? '阅读' : 'Reading',
      'listening': zh ? '听力' : 'Listening',
      'speaking': zh ? '口语' : 'Speaking',
    }[key]!;

/// Explicit local demo. Eligibility counts are cumulative; score window is30days.
/// This is not a backend estimator or an official exam result.
///
/// 演示用真实数据（learner_profile.json 的 `<考试>.report`，tool/demo_export/learner.cjs
/// 按后端学情内核的口径算好）有就以它为底：四科估分、总分、目标、近 30 天次数、
/// 八周趋势、各题型练习数；没有就是下面写死的原型值。几种演示状态（early / partial /
/// strong / no_target）照旧在这份底数上变。
class LearningReportData {
  LearningReportData(
      {required this.exam,
      this.scenario = 'full',
      double? targetOverride,
      this.dateOverride})
      : target = targetOverride ??
            (scenario == 'no_target' ? null : _defaultTarget(exam));
  final ExamType exam;
  final String scenario;
  final double? target;
  final DateTime? dateOverride;

  /// 真实学员的报告数据；原型数据下是 null。
  Map<String, dynamic>? get real =>
      LearnerProfile.exam(exam)['report'] as Map<String, dynamic>?;
  // 真实数据里目标可以是 null（没设目标分）。
  static double? _defaultTarget(ExamType exam) {
    final real = LearnerProfile.exam(exam)['report'] as Map?;
    if (real != null) return (real['target'] as num?)?.toDouble();
    return exam == ExamType.ielts ? 7.0 : 5.0;
  }

  bool get toefl => exam == ExamType.toefl;
  int get maxScore => toefl ? 6 : 9;
  DateTime? get examDate {
    final days = LearnerProfile.daysToExam;
    return dateOverride ??
        (scenario == 'no_target' || days == null
            ? null
            : DateTime.now().add(Duration(days: days)));
  }

  int? get daysLeft {
    final date = examDate;
    if (date == null) return null;
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays
        .clamp(0, 9999);
  }

  Map<String, double> get scores {
    if (scenario == 'early') return {};
    // 真实数据里还没出分的科目不在表里（缺分不算零分）。
    final scored = real?['scores'] as Map?;
    final map = scored != null
        ? {
            for (final k in learningSkills)
              if (scored[k] != null) k: (scored[k] as num).toDouble()
          }
        : toefl
            ? {'writing': 4.5, 'reading': 4.0, 'listening': 5.0, 'speaking': 4.5}
            : {'writing': 6.5, 'reading': 5.5, 'listening': 7.0, 'speaking': 6.0};
    if (scenario == 'strong') {
      return {for (final k in learningSkills) k: toefl ? 5.5 : 7.5};
    }
    if (scenario == 'partial') {
      return {
        for (final k in const ['reading', 'listening'])
          if (map[k] != null) k: map[k]!
      };
    }
    return map;
  }

  /// 同龄人平均：只有原型有这组演示值。真实数据没有同龄人 / 百分位的来源，返回空表，
  /// 学情页据此不画雷达图上的同龄人虚线和图例、「超过 x% 的同龄考生」那一块、
  /// 「超过 12 万名考生…」那一行。
  Map<String, double> get peers => real != null
      ? const {}
      : toefl
          ? {'writing': 4.3, 'reading': 4.4, 'listening': 4.3, 'speaking': 4.2}
          : {'writing': 6.0, 'reading': 6.0, 'listening': 5.8, 'speaking': 5.9};
  // 真实数据带后端算好的总分（四科半分取整后平均、再取半分）；strong 是原型的演示分，照原型算。
  double? get overall => scores.length != 4
      ? null
      : (scenario == 'strong' ? null : real?['overall'] as num?)?.toDouble() ??
          double.parse((scores.values.reduce((a, b) => a + b) / scores.length)
              .toStringAsFixed(1));
  String get overallText => overall?.toStringAsFixed(1) ?? '—';
  double? get gap => overall == null || target == null
      ? null
      : double.parse((target! - overall!).clamp(0.0, 99.0).toStringAsFixed(1));
  String? get weakest => scores.isEmpty
      ? null
      : (scores.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
          .first
          .key;
  List<int> get weeklyPractice => scenario == 'early'
      ? [0, 0, 0, 1, 2, 3, 2, 4]
      : (real?['weeklyPractice'] as List?)?.cast<int>() ??
          [8, 10, 9, 12, 14, 11, 16, 18];
  List<double?> get weeklyScores {
    if (scores.length != 4) return List.filled(8, null);
    final weeks = scenario == 'strong' ? null : real?['weeklyScores'] as List?;
    if (weeks != null) return [for (final v in weeks) (v as num?)?.toDouble()];
    return [
      null,
      if (toefl) 3.5 else 5.5,
      if (toefl) 4.0 else 5.7,
      null,
      if (toefl) 4.0 else 6.0,
      if (toefl) 4.2 else 6.1,
      if (toefl) 4.4 else 6.2,
      overall
    ];
  }

  int get last30Practices =>
      scenario == 'early' ? 9 : real?['last30'] as int? ?? 59;
  int get prior30Practices =>
      scenario == 'early' ? 3 : real?['prior30'] as int? ?? 47;

  /// 学情页「今日能力点评」的真实版：`[{text: [英文, 中文], bold}]`；原型数据下是 null。
  List? get review => real?['review'] as List?;

  /// 某科累计的有效评分练习数：真实数据是一次作答算一次；原型是各题型之和。
  int scoredPractices(String skill, bool zh) =>
      (real?['practices'] as Map?)?[skill] as int? ??
      requirements(skill, zh).fold(0, (n, r) => n + r.completed);
  List<LearningRequirement> requirements(String skill, bool zh) {
    final names = toefl
        ? switch (skill) {
            'reading' => zh
                ? ['补全单词', '日常阅读', '学术文章']
                : ['Complete words', 'Daily-life text', 'Academic passage'],
            'listening' => zh
                ? ['听力回应', '对话', '公告', '学术讲座']
                : [
                    'Listen and respond',
                    'Conversation',
                    'Announcement',
                    'Academic talk'
                  ],
            'writing' => zh
                ? ['组句', '邮件写作', '学术讨论']
                : ['Build a sentence', 'Email', 'Academic discussion'],
            _ => zh ? ['听后复述', '访谈'] : ['Listen and repeat', 'Interview'],
          }
        : switch (skill) {
            'reading' => zh
                ? [
                    '选择题',
                    '判断正误',
                    '判断观点',
                    '信息匹配',
                    '标题匹配',
                    '特征匹配',
                    '句尾匹配',
                    '句子填空',
                    '摘要填空',
                    '图表填空',
                    '简答题'
                  ]
                : [
                    'Multiple choice',
                    'True/False/Not given',
                    'Yes/No/Not given',
                    'Information matching',
                    'Heading matching',
                    'Feature matching',
                    'Ending matching',
                    'Sentence completion',
                    'Summary completion',
                    'Diagram completion',
                    'Short answer'
                  ],
            'listening' => ['Part 1', 'Part 2', 'Part 3', 'Part 4'],
            'writing' => ['Task 1', 'Task 2'],
            _ => ['Part 1', 'Part 2', 'Part 3'],
          };
    final ready = scores.containsKey(skill);
    // 真实数据：各题型累计的有效评分练习数，顺序同上面的题型表。
    final done = (real?['done'] as Map?)?[skill] as List?;
    return [
      for (var i = 0; i < names.length; i++)
        LearningRequirement(
            names[i],
            done != null && i < done.length
                ? done[i] as int
                : ready
                    ? 5 + i
                    : (i == 0 ? 2 : 1),
            5)
    ];
  }
}

class LearningRequirement {
  const LearningRequirement(this.name, this.completed, this.required);
  final String name;
  final int completed, required;
  int get remaining => (required - completed).clamp(0, required);
}
