import '../../widgets/source_text.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'learning_data.dart';
import 'learning_details.dart';
import 'learning_overview.dart';
import 'learning_advice.dart';
import 'learning_trends.dart';
import '../../widgets/t.dart' show langText;

/// 雅思能力报告页 —— 原型 report.js 215-322 行。
///
/// 结构约定：本页产出「自然高度」的 Column，滚动由 shell 的
/// `_ScreenSurface` 单一 `SingleChildScrollView` 统一负责。这里不再出现
/// 顶层 `Expanded` 或内嵌滚动/`SafeArea`——那会与父级的自然高度滚动冲突。
class ReportBackground extends StatelessWidget {
  const ReportBackground({super.key});
  @override
  Widget build(BuildContext context) =>
      const DecoratedBox(decoration: BoxDecoration(color: Color(0xfffbf7ef)));
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _subscribed = false;
  bool _subscriptionTouched = false;
  String _selectedSkill = 'reading';
  String? _expandedSkill;
  String? _scenario;
  double? _target;
  DateTime? _examDate;
  void _practice(String skill, int rank) {
    final app = context.read<AppState>();
    app.session['sessionMode'] = 'daily';
    if (skill == 'reading') app.session['selReadType'] = null;
    // Existing daily selectors honor examType and keep their original workflows.
    app.go(switch (skill) {
      'reading' => SurgoPage.readingDaily,
      'listening' => SurgoPage.listeningDaily,
      'writing' => SurgoPage.writingDaily,
      _ => SurgoPage.speakingDaily
    });
  }

  String T(String s) {
    final tr = Translator.instance;
    final lang = context.read<AppState>().lang;
    return tr.translate(s, lang) ?? s;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final data = LearningReportData(
        exam: state.examType,
        scenario:
            _scenario ?? state.session['reportScenario'] as String? ?? 'full',
        targetOverride: _target ?? state.session['reportTarget-${state.examType.name}'] as double?,
        dateOverride: _examDate ?? state.session['reportDate-${state.examType.name}'] as DateTime?);
    final zh = state.lang == UiLang.zh;
    final scores = data.scores, peers = data.peers;
    final status = {
      for (final s in learningSkills)
        s: !scores.containsKey(s)
            ? 'pending'
            : scores[s]! / data.maxScore >= .77
                ? 'good'
                : scores[s]! / data.maxScore < .65
                    ? 'low'
                    : 'mid'
    };
    final overallStr = data.overallText;
    const beat = 62;
    final max = data.maxScore;
    final goalIsReading = data.real == null || data.weakest == 'reading';

    return Container(
      // Source report has 130px padding + subscription 18px bottom margin;
      // outer has-nav screen adds 120px (shell already adds 140px).
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶栏 rp-head
          SizedBox(
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: -10.5,
                  child: GestureDetector(
                    key: const ValueKey('report-home'),
                    onTap: () => state.go(SurgoPage.ielts),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: SvgPicture.asset('assets/images/home_icon.svg',
                          width: 24, height: 24),
                    ),
                  ),
                ),
                Center(
                  child:
                      Image.asset('assets/images/surgo_logo.png', height: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Hero 卡 rp-hero
          _HeroCard(overall: overallStr, max: max, data: data),
          const SizedBox(height: 18),
          LearningOverview(
              data: data,
              chinese: zh,
              onScenario: (v) => setState(() {
                    _scenario = v;
                    _target = null;
                    _examDate = null;
                    state.session.remove('reportTarget-${state.examType.name}');
                    state.session.remove('reportDate-${state.examType.name}');
                  }),
              onGoal: (v, d) => setState(() {
                    _target = v;
                    _examDate = d;
                    state.session['reportTarget-${state.examType.name}']=v;
                    state.session['reportDate-${state.examType.name}']=d;
                  })),
          const SizedBox(height: 18),

          // 雷达卡 rp-scorecard
          _ScoreCard(
            overall: overallStr,
            max: max,
            scores: scores,
            peers: peers,
            status: status,
            beat: beat,
            T: T,
            data: data,
            selected: _selectedSkill,
            expanded: _expandedSkill,
            onSelect: (v) => setState(() => _selectedSkill = v),
            onExpand: (v) =>
                setState(() => _expandedSkill = _expandedSkill == v ? null : v),
          ),
          const SizedBox(height: 18),

          // 首要提升目标 rp-goal —— 原型 onclick="examType='ielts';selReadType=null;go('readingDaily')"
          if (!data.toefl && data.scenario == 'full') ...[
            // 这张卡写死的是阅读；真实数据下只在最弱的一科确实是阅读时画。
            if (goalIsReading)
            GestureDetector(
              key: const ValueKey('report-goal'),
              onTap: () {
                state.examType = ExamType.ielts;
                state.updateSession({'selReadType': null});
                state.go(SurgoPage.readingDaily);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE9A8),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x2EF5B301),
                        blurRadius: 20,
                        offset: Offset(0, 8))
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Image.asset('assets/images/ic_reading_goal2.png',
                        width: 52, height: 52, fit: BoxFit.contain),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SourceText(T('你的首要提升目标是'),
                              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6A5600))),
                          const SizedBox(height: 3),
                          SourceText(T('Reading 阅读'),
                              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3A2E00))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0x243A2E00),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      alignment: Alignment.center,
                      child: const SourceText('→',
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3A2E00))),
                    ),
                  ],
                ),
              ),
            ),
            // 「超过 12 万名考生…」是同龄人数据，没有就不画。
            if (goalIsReading && peers.isNotEmpty) const SizedBox(height: 8),
            if (goalIsReading && peers.isNotEmpty)
            SourceText.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '${T('超过')} ',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8378))),
                  const TextSpan(
                      text: '12 万',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE0A000))),
                  TextSpan(
                      text: ' ${T('名考生与你有相同的首要提升目标')}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8378))),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            if (goalIsReading) const SizedBox(height: 22),

            // 今日能力点评 rp-review（真实数据下四科没出齐就没有这段点评）
            if (data.real == null || data.review != null) ...[
              _ReviewCard(
                  overall: overallStr,
                  scores: scores,
                  T: T,
                  review: data.review),
              const SizedBox(height: 16),
            ],
          ],
          LearningAdvice(
              chinese: zh,
              selectedSkill: _selectedSkill,
              onSelectSkill: (v) => setState(() => _selectedSkill = v),
              onPractice: _practice,
              real: data.real),
          const SizedBox(height: 18),
          LearningTrends(
              scores: data.weeklyScores,
              practices: data.weeklyPractice,
              maxScore: max.toDouble(),
              target: data.target,
              chinese: zh,
              weekLabels: (data.real?['weekLabels'] as List?)?.cast<String>()),
          const SizedBox(height: 18),

          // 订阅提醒条 rp-sub
          Container(
            decoration: BoxDecoration(
              color: const Color(0xB8FFFFFF),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14B48C14),
                    blurRadius: 26,
                    offset: Offset(0, 10))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE9A8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const SourceText('🔔', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceText(T('订阅报告提醒'),
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: SurgoColors.ink)),
                      const SizedBox(height: 2),
                      SourceText(T('每周生成一份最新能力报告'),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8378))),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  key: const ValueKey('report-subscribe'),
                  onTap: () => setState(() {
                    _subscribed = !_subscribed;
                    _subscriptionTouched = true;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          _subscribed ? const Color(0xFFF5C534) : Colors.white,
                      border: Border.all(
                          color: const Color(0xFFF5C534), width: 1.5),
                      borderRadius: BorderRadius.circular(500),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    child: Text(
                      _subscriptionTouched
                          ? (_subscribed ? '已订阅' : '订阅')
                          : T('订阅'),
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _subscribed
                              ? SurgoColors.ink
                              : const Color(0xFFB98900)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.overall, required this.max, required this.data});
  final LearningReportData data;
  final String overall;
  final int max;

  @override
  Widget build(BuildContext context) {
    final pct = ((data.overall ?? 0) / max * 100).toStringAsFixed(0);
    final lang = context.read<AppState>().lang;
    final tr = Translator.instance;
    String T(String s) => tr.translate(s, lang) ?? s;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1FB48C14), blurRadius: 34, offset: Offset(0, 14))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SourceText(
                  '${T('Nafis 的')}\n${data.toefl ? (lang == UiLang.zh ? '托福能力报告' : 'TOEFL report') : T('雅思能力报告')}',
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: SurgoColors.ink,
                      height: 1.3,
                      letterSpacing: -0.3)),
              const SizedBox(height: 24),
              Row(
                children: [
                  SourceText(T('当前 Band'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8378))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          height: 8,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEADF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: double.parse(pct) / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5B301),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: double.parse(pct) /
                                    100 *
                                    constraints.maxWidth,
                                top: -11,
                                child: FractionalTranslation(
                                  translation: const Offset(-.5, 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141210),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SourceText(overall,
                                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFFC71B))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SourceText(
                // 「属于中高分段」是原型那组分数的说法；真实数据走下面按数字拼的句子。
                data.scenario == 'full' &&
                        !data.toefl &&
                        data.target == 7.0 &&
                        data.real == null
                    ? T('你的综合水平为 Band $overall，属于中高分段。距离目标 7.0 还差 ${(7.0 - double.parse(overall)).toStringAsFixed(1)} 分，继续加油。')
                    : lang == UiLang.zh
                        ? (data.overall == null
                            ? '正在积累练习，还未满足出分条件。缺分不会按0分计算。'
                            : '当前${data.scores.length < 4 ? '阶段估分' : '综合水平'} $overall / $max。${data.target == null ? '设置目标，让训练更有方向。' : data.gap == 0 ? '已达到目标，继续巩固。' : '距离目标${data.target}还差${data.gap}分。'}')
                        : (data.overall == null
                            ? 'More practice is needed before a score can be estimated. Missing is not zero.'
                            : '${data.scores.length < 4 ? 'Provisional' : 'Current'} level $overall / $max. ${data.target == null ? 'Set a learning goal.' : data.gap == 0 ? 'Goal achieved. Keep consolidating.' : '${data.gap}points to your ${data.target}target.'}'),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6A6459), height: 1.6),
              ),
            ],
          ),
          Positioned(
            right: -14,
            top: -10,
            child: Image.asset('assets/images/otter88.png',
                width: 96, filterQuality: FilterQuality.high),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.overall,
    required this.max,
    required this.scores,
    required this.peers,
    required this.status,
    required this.beat,
    required this.T,
    required this.data,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onExpand,
  });
  final LearningReportData data;
  final String selected;
  final String? expanded;
  final ValueChanged<String> onSelect, onExpand;

  final String overall;
  final int max;
  final Map<String, double> scores;
  final Map<String, double> peers;
  final Map<String, String> status;
  final int beat;
  final String Function(String) T;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x19B48C14), blurRadius: 34, offset: Offset(0, 14))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                  child: SourceText(T('你的综合得分是'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.ink))),
              SizedBox(
                height: 46,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 46 * 0.5983,
                      bottom: 46 * (1 - 0.9026),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: const Color(0xFFF5CE4E),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SourceText(overall,
                          style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: SurgoColors.ink,
                              height: 1)),
                    ),
                  ],
                ),
              ),
              SourceText(' / $max',
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A8378))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF5B301), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SourceText(T('你的得分'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8378))),
                ],
              ),
              // 图例的「同龄人平均」跟着虚线走：没有同龄人数据就不画。
              if (peers.isNotEmpty) const SizedBox(width: 22),
              if (peers.isNotEmpty)
              Row(
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                          color: Color(0xFFD8D2E8), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SourceText(T('同龄人平均'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8378))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 306,
            height: 302,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                    top: 20,
                    left: 35,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      builder: (context, t, _) => GestureDetector(
                          key: const ValueKey('learning-radar-hit'),
                          onTapUp: (d) {
                            final delta =
                                d.localPosition - const Offset(118, 118);
                            final s = delta.dx.abs() > delta.dy.abs()
                                ? (delta.dx > 0 ? 'reading' : 'speaking')
                                : (delta.dy > 0 ? 'listening' : 'writing');
                            if (scores.containsKey(s)) onSelect(s);
                          },
                          child: CustomPaint(
                            key: const ValueKey('report-radar-paint'),
                            size: const Size(236, 236),
                            painter: _RadarPainter(
                                scores: scores,
                                peers: peers,
                                max: max,
                                selected: selected,
                                growth:
                                    const Cubic(.34, 1.4, .5, 1).transform(t),
                                alpha: const Cubic(.34, 1.4, .5, 1)
                                    .transform((t / .55).clamp(0.0, 1.0))
                                    .clamp(0.0, 1.0)),
                          )),
                    )),
                // 四轴标签 rp-ax
                Positioned(
                    top: 0,
                    child: GestureDetector(
                        key: const ValueKey('learning-axis-writing'),
                        onTap: () => onSelect('writing'),
                        child: _AxisLabel(
                            name: T('Writing'),
                            score: scores['writing']?.toStringAsFixed(1) ?? '—',
                            status: status['writing']!))),
                Positioned(
                    right: 0,
                    top: 139,
                    child: FractionalTranslation(
                        translation: const Offset(0, -.5),
                        child: GestureDetector(
                            key: const ValueKey('learning-axis-reading'),
                            onTap: () => onSelect('reading'),
                            child: _AxisLabel(
                                name: T('Reading'),
                                score: scores['reading']?.toStringAsFixed(1) ??
                                    '—',
                                status: status['reading']!)))),
                Positioned(
                    bottom: 14,
                    child: GestureDetector(
                        key: const ValueKey('learning-axis-listening'),
                        onTap: () => onSelect('listening'),
                        child: _AxisLabel(
                            name: T('Listening'),
                            score:
                                scores['listening']?.toStringAsFixed(1) ?? '—',
                            status: status['listening']!))),
                Positioned(
                    left: 0,
                    top: 139,
                    child: FractionalTranslation(
                        translation: const Offset(0, -.5),
                        child: GestureDetector(
                            key: const ValueKey('learning-axis-speaking'),
                            onTap: () => onSelect('speaking'),
                            child: _AxisLabel(
                                name: T('Speaking'),
                                score: scores['speaking']?.toStringAsFixed(1) ??
                                    '—',
                                status: status['speaking']!)))),
              ],
            ),
          ),
          const SizedBox(height: 0),
          Text(
              context.watch<AppState>().lang == UiLang.zh
                  ? '当前选中：${skillName(selected, true)} · ${scores[selected]?.toStringAsFixed(1) ?? '待积累'}'
                  : 'Selected: ${skillName(selected, false)} · ${scores[selected]?.toStringAsFixed(1) ?? 'Not scored'}',
              key: const ValueKey('learning-selected'),
              style: const TextStyle(fontSize: 12, color: Color(0xff8f6e16))),
          if (data.weakest != null)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    context.read<AppState>().lang == UiLang.zh
                        ? '重点关注：${skillName(data.weakest!, true)}'
                        : 'Focus: ${skillName(data.weakest!, false)}',
                    style: const TextStyle(
                        fontSize: 11, color: SurgoColors.muted))),
          const SizedBox(height: 18),
          LearningDetails(
              data: data,
              chinese: context.watch<AppState>().lang == UiLang.zh,
              selected: selected,
              expanded: expanded,
              onSelect: onSelect,
              onExpand: onExpand),
          const SizedBox(height: 18),
          // 「超过 62% 的同龄考生」这一块全是同龄人比较，没有同龄人数据就不画。
          if (data.scenario == 'full' && !data.toefl && peers.isNotEmpty)
            Container(
              key: const ValueKey('report-compare'),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3D9),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceText.rich(
                        TextSpan(
                          style: const TextStyle(height: 1.5),
                          children: [
                            TextSpan(
                                text: T('你的综合水平已超过'),
                                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: SurgoColors.ink)),
                            TextSpan(
                                text: ' $beat%',
                                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE0A000))),
                            TextSpan(
                                text: ' ${T('的同龄考生')}',
                                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: SurgoColors.ink)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                          widthFactor: .74,
                          alignment: Alignment.centerLeft,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ReportBullet(
                                    skill: '听力',
                                    percent: '88%',
                                    middle: '比',
                                    suffix: '的同龄人更强'),
                                _ReportBullet(
                                    skill: '阅读',
                                    percent: '34%',
                                    middle: '仅超过',
                                    suffix: '的同龄人'),
                              ])),
                    ],
                  ),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: SvgPicture.asset('assets/images/data_chart.svg',
                        width: 64),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportBullet extends StatelessWidget {
  const _ReportBullet(
      {required this.skill,
      required this.percent,
      required this.middle,
      required this.suffix});
  final String skill, percent, middle, suffix;
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().lang;
    String tr(String s) => (Translator.instance.translate(s, lang) ?? s).trim();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(
          width: 18,
          child: Text('•',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, height: 1.9, color: Color(0xff4a4640)))),
      Expanded(
          child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${tr('你的')} '),
                TextSpan(
                    text: tr(skill),
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffe0a000))),
                TextSpan(text: '${lang == UiLang.en ? '' : ' '}${tr(middle)} '),
                TextSpan(
                    text: percent,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffe0a000))),
                TextSpan(text: ' ${tr(suffix)}'),
              ]),
              style: const TextStyle(
                  fontSize: 11, height: 1.9, color: Color(0xff4a4640)))),
    ]);
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(
      {required this.name, required this.score, required this.status});
  final String name;
  final String score;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'good':
        bg = const Color(0xFFEAF7EF);
        fg = const Color(0xFF219653);
        break;
      case 'mid':
        bg = const Color(0xFFFDF3D6);
        fg = const Color(0xFFE0A000);
        break;
      default:
        bg = const Color(0xFFFCECE8);
        fg = const Color(0xFFE1553B);
    }
    return Column(
      children: [
        SourceText(name,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8378),
                letterSpacing: 0.2)),
        const SizedBox(height: 7),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3))
            ],
          ),
          child: SourceText(score,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(
      {required this.overall,
      required this.scores,
      required this.T,
      this.review});
  final String overall;
  final Map<String, double> scores;
  final String Function(String) T;

  /// 演示用真实数据的点评：`[{text: [英文, 中文], bold}]`，只写数字能说明的几句；
  /// 没有就是下面原型那段（听力强、阅读弱的固定叙述）。
  final List? review;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x19B48C14), blurRadius: 34, offset: Offset(0, 14))
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5C534),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              SourceText(T('今日能力点评'),
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: SurgoColors.ink,
                      letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            // Keep source DOM node spacing; SourceText intentionally trims captures.
            _translatedReview(context),
            key: const ValueKey('report-review-body'),
          ),
        ],
      ),
    );
  }

  TextSpan _translatedReview(BuildContext context) {
    final lang = context.read<AppState>().lang;
    String tr(String text) =>
        (Translator.instance.translate(text, lang) ?? text).trimLeft();
    const body =
        TextStyle(fontSize: 14, color: Color(0xFF4A4640), height: 1.85);
    const strong = TextStyle(
        fontFamily: 'Outfit',
        fontFamilyFallback: SurgoFontFamily.fallback,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: SurgoColors.ink);
    final real = review;
    if (real != null) {
      return TextSpan(style: body, children: [
        for (final part in real)
          TextSpan(
              text: langText(part['text'], lang),
              style: part['bold'] == true ? strong : null)
      ]);
    }
    final original = TextSpan(
      style: body,
      children: [
        TextSpan(text: '你目前的综合水平为 Band $overall，属于中高分段。'),
        TextSpan(
            text: '听力（${scores['listening']!.toStringAsFixed(1)}）是你的强项',
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SurgoColors.ink)),
        const TextSpan(text: '，细节捕捉与关键信息定位都很稳定，保持这个节奏、继续用真题巩固即可。'),
        TextSpan(
            text: '阅读（${scores['reading']!.toStringAsFixed(1)}）是当前最需要突破的一项',
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SurgoColors.ink)),
        TextSpan(
            text:
                '，建议每天精读一篇长文，重点练习段落定位与同义替换。写作与口语处于中游，稳步积累素材和表达框架就能再上一个台阶。距离目标 7.0 还差 ${(7.0 - double.parse(overall)).toStringAsFixed(1)} 分，坚持每日训练，一个月内很有希望达成。'),
      ],
    );
    return TextSpan(style: original.style, children: [
      for (final node in original.children!.cast<TextSpan>())
        TextSpan(
            text:
                '${lang == UiLang.en && node.text!.startsWith('，') ? ' ' : ''}${tr(node.text!)}',
            style: node.style),
    ]);
  }
}

/// 雷达图 CustomPainter —— 原型 SVG 逻辑逐行迁移。
/// 原型 viewBox 300×300、R=104、cx=cy=150；本组件绘制在 236×236 画布上，
/// 因此按 236/300 缩放所有几何量，保持比例一致。
class _RadarPainter extends CustomPainter {
  _RadarPainter(
      {required this.scores,
      required this.peers,
      required this.max,
      this.growth = 1,
      this.selected,
      this.alpha = 1});
  final String? selected;
  final double growth, alpha;
  final Map<String, double> scores;
  final Map<String, double> peers;
  final int max;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 300.0; // 原型 viewBox 300
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = 104.0 * scale;

    Offset pt(String dir, double v) {
      final r = R * v / max;
      switch (dir) {
        case 'top':
          return Offset(cx, cy - r);
        case 'right':
          return Offset(cx + r, cy);
        case 'bottom':
          return Offset(cx, cy + r);
        default:
          return Offset(cx - r, cy); // left
      }
    }

    Path diamond(double k) => Path()
      ..moveTo(cx, cy - R * k)
      ..lineTo(cx + R * k, cy)
      ..lineTo(cx, cy + R * k)
      ..lineTo(cx - R * k, cy)
      ..close();

    // 最外层菱形：填充 #FBF7EE + 描边 #EBE5D9 1.4
    canvas.drawPath(diamond(1), Paint()..color = const Color(0xFFFBF7EE));
    canvas.drawPath(
        diamond(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale
          ..color = const Color(0xFFEBE5D9));

    // 内三档网格：描边 #EFEADF 1.2
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..color = const Color(0xFFEFEADF);
    canvas.drawPath(diamond(0.75), gridPaint);
    canvas.drawPath(diamond(0.5), gridPaint);
    canvas.drawPath(diamond(0.25), gridPaint);

    // 十字线 #EFEADF 1.1
    final linePaint = Paint()
      ..strokeWidth = 1.1 * scale
      ..color = const Color(0xFFEFEADF);
    canvas.drawLine(Offset(cx, cy - R), Offset(cx, cy + R), linePaint);
    canvas.drawLine(Offset(cx - R, cy), Offset(cx + R, cy), linePaint);

    // 刻度标签（用户 2026-09-24，参考图 3）：沿左上轴在各环上标分值。
    // IELTS 满分 9 标 0/3/6/9，TOEFL 满分 6 标 0/2/4/6 —— 都落在 0/.33/.67/1 环上。
    // 必须在数据区之后绘制，否则会被黄色填充盖住；用白色描边 + 深色字心，
    // 保证在网格线、黄色填充、页面底色上都清晰可读。
    void drawTicks() {
      for (final k in const [0.0, 1 / 3, 2 / 3, 1.0]) {
        final value = max * k;
        final label = value == value.roundToDouble()
            ? value.round().toString()
            : value.toStringAsFixed(1);
        // 左上 45°方向，落在菱形边上：x 与 y 各占该环半径的一半。
        final r = R * k;
        final at = Offset(cx - r / 2, cy - r / 2);
        TextPainter make(TextStyle style) => TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: TextDirection.ltr)
          ..layout();
        final base = TextStyle(
            fontFamily: 'Outfit',
            fontFamilyFallback: SurgoFontFamily.fallback,
            fontSize: 11 * scale * 300 / 236,
            fontWeight: FontWeight.w700);
        final halo = make(base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * scale
              ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)));
        final face = make(base.copyWith(
            color: const Color(0xFF6B6255).withValues(alpha: alpha)));
        final origin = at - Offset(halo.width / 2, halo.height / 2);
        halo.paint(canvas, origin);
        face.paint(canvas, origin);
      }
    }

    // 同龄人虚线 —— 原型 stroke-dasharray="5 4"，用 PathMetrics 手绘虚线。
    // 真实数据没有同龄人数据（peers 为空），这条线不画。
    if (peers.length == 4) {
      final peerPath = Path()
        ..moveTo(
            pt('top', peers['writing']!).dx, pt('top', peers['writing']!).dy)
        ..lineTo(pt('right', peers['reading']!).dx,
            pt('right', peers['reading']!).dy)
        ..lineTo(pt('bottom', peers['listening']!).dx,
            pt('bottom', peers['listening']!).dy)
        ..lineTo(pt('left', peers['speaking']!).dx,
            pt('left', peers['speaking']!).dy)
        ..close();
      _drawDashedPath(
        canvas,
        peerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..color = const Color(0xFFB9AFF2)
          ..strokeJoin = StrokeJoin.round,
        dash: 5 * scale,
        gap: 4 * scale,
      );
    }

    canvas.saveLayer(Offset.zero & size,
        Paint()..color = Colors.white.withAlpha((255 * alpha).round()));
    canvas.translate(cx, cy);
    canvas.scale(growth);
    canvas.translate(-cx, -cy);
    // Missing scores never create zero-valued vertices or a filled polygon.
    const direction = {
      'writing': 'top',
      'reading': 'right',
      'listening': 'bottom',
      'speaking': 'left'
    };
    if (scores.length < 4) {
      for (final entry in scores.entries) {
        final p = pt(direction[entry.key]!, entry.value);
        canvas.drawCircle(
            p, 5.5 * scale, Paint()..color = const Color(0xfff2a900));
        if (entry.key == selected) {
          canvas.drawCircle(
              p,
              10 * scale,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2 * scale
                ..color = const Color(0xff6b52d6));
        }
      }
      canvas.restore();
      // 缺科时也要有刻度。
      drawTicks();
      return;
    }
    // 你的得分：径向渐变填充 + #F2A900 3 描边
    final scorePath = Path()
      ..moveTo(
          pt('top', scores['writing']!).dx, pt('top', scores['writing']!).dy)
      ..lineTo(pt('right', scores['reading']!).dx,
          pt('right', scores['reading']!).dy)
      ..lineTo(pt('bottom', scores['listening']!).dx,
          pt('bottom', scores['listening']!).dy)
      ..lineTo(pt('left', scores['speaking']!).dx,
          pt('left', scores['speaking']!).dy)
      ..close();

    canvas.save();
    canvas.translate(0, 6 * scale);
    canvas.drawPath(
        scorePath,
        Paint()
          ..color = const Color(0x47f5b301)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * scale));
    canvas.restore();
    canvas.drawPath(
      scorePath,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.08),
          radius: 0.6,
          colors: [Color(0x8CFFD86B), Color(0x47F5B301)],
        ).createShader(scorePath.getBounds()),
    );

    canvas.drawPath(
      scorePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..color = const Color(0xFFF2A900)
        ..strokeJoin = StrokeJoin.round,
    );

    // 四个顶点圆圈 fill #fff stroke #F2A900 3
    final dotPaint = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = const Color(0xFFF2A900);
    for (final p in [
      pt('top', scores['writing']!),
      pt('right', scores['reading']!),
      pt('bottom', scores['listening']!),
      pt('left', scores['speaking']!),
    ]) {
      canvas.drawCircle(p, 5.5 * scale, dotPaint);
      canvas.drawCircle(p, 5.5 * scale, dotStroke);
    }
    if (selected != null && scores.containsKey(selected)) {
      canvas.drawCircle(
          pt(direction[selected]!, scores[selected]!),
          10 * scale,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * scale
            ..color = const Color(0xff6b52d6));
    }
    canvas.restore();
    // 刻度画在最上层，不被数据区黄色填充遮住。
    drawTicks();
  }

  /// 用路径度量把连续路径切成 [dash] / [gap] 的虚线段。
  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap}) {
    final step = dash + gap;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += step;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.scores != scores ||
      oldDelegate.peers != peers ||
      oldDelegate.max != max ||
      oldDelegate.growth != growth ||
      oldDelegate.alpha != alpha;
}
