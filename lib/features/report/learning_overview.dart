import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'learning_data.dart';
import 'learning_details.dart';

class LearningOverview extends StatelessWidget {
  const LearningOverview(
      {super.key,
      required this.data,
      required this.chinese,
      required this.onScenario,
      required this.onGoal});
  final LearningReportData data;
  final bool chinese;
  final ValueChanged<String> onScenario;
  final void Function(double, DateTime?) onGoal;
  String t(String a, String b) => chinese ? a : b;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xb8ffffff),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14b48c14), blurRadius: 26, offset: Offset(0, 10))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('学情概览', 'Learning overview'),
            style: const TextStyle(
                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        SizedBox(
            height: 142,
            child: Row(
                key: const ValueKey('learning-metric-row'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: _metric(
                          slot: 'level',
                          title: t('现在的水平', 'Current level'),
                          badge: t('练习估分', 'Estimated'),
                          value: data.overall == null
                              ? t('尚未出分', 'Not scored')
                              : '${data.overallText} / ${data.maxScore}',
                          caption: data.scores.length < 4
                              ? t('四科齐全才出总分', 'Needs all4skills')
                              : t('四科已出分', 'All4skills scored'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _metric(
                          slot: 'gap',
                          title: t('离目标还有', 'Goal distance'),
                          badge: data.target == null
                              ? null
                              : '${t('目标', 'Target')} ${data.target!.toStringAsFixed(1)}',
                          value: data.target == null
                              ? t('未设目标', 'No goal')
                              : data.gap == null
                                  ? t('等成绩', 'Awaiting')
                                  : data.gap == 0
                                      ? t('已达标', 'Achieved')
                                      : '${data.gap!.toStringAsFixed(1)} ${t('分', 'pts')}',
                          caption: data.target == null
                              ? t('请设置目标日期', 'Set goal and date')
                              : data.examDate == null
                                  ? t('日期未设置', 'No exam date')
                                  : t('还有${data.daysLeft}天',
                                      '${data.daysLeft}days left'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _metric(
                          slot: 'practice',
                          title: t('最近练了多少', 'Recent practice'),
                          badge: t('近30天', 'Last30d'),
                          value: '${data.last30Practices} ${t('次', 'done')}',
                          // 真实数据可能比前 30 天少（原型的演示值总是多）。
                          caption: data.last30Practices < data.prior30Practices
                              ? t('比前30天少${data.prior30Practices - data.last30Practices}次',
                                  '-${data.prior30Practices - data.last30Practices}vs prior')
                              : t('比前30天多${data.last30Practices - data.prior30Practices}次',
                                  '+${data.last30Practices - data.prior30Practices}vs prior'))),
                ])),
        Wrap(spacing: 12, children: [
          TextButton(
              key: const ValueKey('learning-estimate'),
              style: _link,
              onPressed: () => showLearningExplanation(context, data, chinese),
              child: Text(t('估分说明', 'Estimate explained'),
                  maxLines: 1,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xff8f6e16)))),
          TextButton(
              key: const ValueKey('learning-set-goal'),
              style: _link,
              onPressed: () => _goal(context),
              child: Text(t('设置目标', 'Set goal'),
                  maxLines: 1,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xff8f6e16)))),
        ]),
      ]));
  static final ButtonStyle _link = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 6),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap);
  Widget _metric(
          {required String slot,
          required String title,
          required String value,
          required String caption,
          String? badge}) =>
      Container(
          key: ValueKey('learning-metric-$slot'),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
              color: const Color(0xfffffdf7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffeee7d9))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 12.5,
                    height: 1.3,
                    color: SurgoColors.muted,
                    fontWeight: FontWeight.w700)),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xfff7ecc6),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(badge,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: Color(0xff8f6e16)))),
            ],
            const SizedBox(height: 5),
            SizedBox(
                height: 23,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            maxLines: 1,
                            style: const TextStyle(
                                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 18,
                                height: 1.25,
                                fontWeight: FontWeight.w800))))),
            const SizedBox(height: 4),
            Text(caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5, height: 1.35, color: SurgoColors.muted)),
          ]));
  void _goal(BuildContext context) {
    double goal = data.target ?? (data.toefl ? 5 : 7);
    DateTime? date = data.examDate;
    showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
                    backgroundColor: const Color(0xfffffcf4),
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    title: Text(t('设置学习目标', 'Set your goal')),
                    content: SizedBox(
                        width: 290,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          DropdownButton<double>(
                              key: const ValueKey('learning-target-value'),
                              isExpanded: true,
                              value: goal,
                              items: [
                                for (double v = 1; v <= data.maxScore; v += .5)
                                  DropdownMenuItem(
                                      value: v,
                                      child: Text(v.toStringAsFixed(1)))
                              ],
                              onChanged: (v) => set(() => goal = v!)),
                          TextButton(
                              key: const ValueKey('learning-target-date'),
                              onPressed: () async {
                                final chosen = await showDatePicker(
                                    context: ctx,
                                    useRootNavigator: false,
                                    initialDate: date ??
                                        DateTime.now()
                                            .add(const Duration(days: 20)),
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 1)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 3)));
                                if (chosen != null) set(() => date = chosen);
                              },
                              child: Text(date == null
                                  ? t('选择考试日期', 'Choose exam date')
                                  : '${date!.year}-${date!.month}-${date!.day}')),
                          Text(
                              t('仅保存在本次演示会话',
                                  'Saved in this demo session only'),
                              style: const TextStyle(
                                  fontSize: 11, color: SurgoColors.muted)),
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(t('取消', 'Cancel'))),
                      FilledButton(
                          key: const ValueKey('learning-target-save'),
                          style: FilledButton.styleFrom(
                              backgroundColor: SurgoColors.yellow,
                              foregroundColor: SurgoColors.ink),
                          onPressed: () {
                            onGoal(goal, date);
                            Navigator.pop(ctx);
                          },
                          child: Text(t('保存', 'Save')))
                    ])));
  }
}
