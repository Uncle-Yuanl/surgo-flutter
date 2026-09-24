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
class LearningReportData {
  LearningReportData(
      {required this.exam,
      this.scenario = 'full',
      double? targetOverride,
      this.dateOverride})
      : target = targetOverride ??
            (scenario == 'no_target'
                ? null
                : exam == ExamType.ielts
                    ? 7.0
                    : 5.0);
  final ExamType exam;
  final String scenario;
  final double? target;
  final DateTime? dateOverride;
  bool get toefl => exam == ExamType.toefl;
  int get maxScore => toefl ? 6 : 9;
  DateTime? get examDate =>
      dateOverride ??
      (scenario == 'no_target'
          ? null
          : DateTime.now().add(const Duration(days: 20)));
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
    final map = toefl
        ? {'writing': 4.5, 'reading': 4.0, 'listening': 5.0, 'speaking': 4.5}
        : {'writing': 6.5, 'reading': 5.5, 'listening': 7.0, 'speaking': 6.0};
    if (scenario == 'strong') {
      return {for (final k in learningSkills) k: toefl ? 5.5 : 7.5};
    }
    if (scenario == 'partial') {
      return {'reading': map['reading']!, 'listening': map['listening']!};
    }
    return map;
  }

  Map<String, double> get peers => toefl
      ? {'writing': 4.3, 'reading': 4.4, 'listening': 4.3, 'speaking': 4.2}
      : {'writing': 6.0, 'reading': 6.0, 'listening': 5.8, 'speaking': 5.9};
  double? get overall => scores.length != 4
      ? null
      : double.parse((scores.values.reduce((a, b) => a + b) / scores.length)
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
      : [8, 10, 9, 12, 14, 11, 16, 18];
  List<double?> get weeklyScores => scores.length != 4
      ? List.filled(8, null)
      : [
          null,
          if (toefl) 3.5 else 5.5,
          if (toefl) 4.0 else 5.7,
          null,
          if (toefl) 4.0 else 6.0,
          if (toefl) 4.2 else 6.1,
          if (toefl) 4.4 else 6.2,
          overall
        ];
  int get last30Practices => scenario == 'early' ? 9 : 59;
  int get prior30Practices => scenario == 'early' ? 3 : 47;
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
    return [
      for (var i = 0; i < names.length; i++)
        LearningRequirement(names[i], ready ? 5 + i : (i == 0 ? 2 : 1), 5)
    ];
  }
}

class LearningRequirement {
  const LearningRequirement(this.name, this.completed, this.required);
  final String name;
  final int completed, required;
  int get remaining => (required - completed).clamp(0, required);
}
