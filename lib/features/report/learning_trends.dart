import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/tokens.dart';

/// Learning Trends Widget - displays score trends and practice counts
/// over 8 weeks with yellow score line and purple practice bars.
///
/// Reference: artifacts/report_reference/B04_这几周的变化.png, D01/D02/D05
/// Style: Rounded translucent cream cards (borderRadius 28, white alpha B8)
/// matching current report design.
///
/// Input: 8 weeks of data
/// - scores: List of 8 double? (nullable for gaps, not zeros)
/// - practices: List of 8 int (practice counts per week)
/// - maxScore: Maximum score value (9 for IELTS, 6 for TOEFL)
/// - target: Optional target score line (nullable)
/// - chinese: Bilingual string toggle (true=Chinese, false=English)
///
/// Features:
/// - CustomPainter for yellow score line + purple practice bars (separate plots)
/// - Week selection via tap-accessible buttons
/// - Selected week detail display
/// - Bounds/scales with empty series messaging
/// - No fake data claims, pure input-driven
class LearningTrends extends StatefulWidget {
  final List<double?> scores;
  final List<int> practices;
  final double maxScore;
  final double? target;
  final bool chinese;

  /// 八周各自周一的日期（"8/10"）；演示用真实数据带上，没有就用图里原来写死的那组。
  final List<String>? weekLabels;

  const LearningTrends({
    super.key,
    required this.scores,
    required this.practices,
    required this.maxScore,
    required this.target,
    required this.chinese,
    this.weekLabels,
  });

  @override
  State<LearningTrends> createState() => _LearningTrendsState();
}

class _LearningTrendsState extends State<LearningTrends> {
  int? _selectedWeek;

  String _t(String en, String zh) => widget.chinese ? zh : en;

  @override
  Widget build(BuildContext context) {
    assert(widget.scores.length == 8 && widget.practices.length == 8,
        'Eight weeks required');
    // Check if we have any data
    final hasScores = widget.scores.any((s) => s != null);
    final hasPractices = widget.practices.any((p) => p > 0);

    if (!hasScores && !hasPractices) {
      return _buildEmptyCard();
    }

    // Calculate score change for header
    final nonNullScores = widget.scores.whereType<double>().toList();
    final String changeText;
    if (nonNullScores.length >= 2) {
      final firstScore = nonNullScores.first;
      final lastScore = nonNullScores.last;
      final change = lastScore - firstScore;
      if (change > 0) {
        changeText =
            '${_t("This period shows upward trend", "这段时间在稳步上升")} (+${change.toStringAsFixed(1)})';
      } else if (change < 0) {
        changeText = _t("Recent 8 weeks average, with some fluctuation",
            "近 8 周的水平变化，和每周练了多少。");
      } else {
        changeText = _t("Stable over the period", "这段时间保持稳定");
      }
    } else {
      changeText = _t("Recent 8 weeks average, with some fluctuation",
          "近 8 周的水平变化，和每周练了多少。");
    }

    return Container(
      key: const ValueKey('trend-chart'),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1FB48C14), blurRadius: 34, offset: Offset(0, 14))
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            _t('These Weeks\' Changes', '这几周的变化'),
            style: const TextStyle(
              fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF141210),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            changeText,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF8A8378),
            ),
          ),
          const SizedBox(height: 20),

          // Insight card (if we have score change)
          if (nonNullScores.length >= 2 &&
              nonNullScores.last > nonNullScores.first)
            _buildInsightCard(
                nonNullScores.first, nonNullScores.last, nonNullScores.length),

          if (nonNullScores.length >= 2 &&
              nonNullScores.last > nonNullScores.first)
            const SizedBox(height: 16),

          // Score chart
          if (hasScores) ...[
            SizedBox(
              height: 160,
              child: _ScoreChart(
                scores: widget.scores,
                maxScore: widget.maxScore,
                target: widget.target,
                chinese: widget.chinese,
                selectedWeek: _selectedWeek,
                onWeekSelected: (week) => setState(() => _selectedWeek = week),
                weekLabels: widget.weekLabels,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Practice bars label
          Text(
            _t('Weekly Practice Count', '每周练习次数'),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8378),
            ),
          ),
          const SizedBox(height: 12),

          // Practice bars
          SizedBox(
            height: 60,
            child: _PracticeBars(
              practices: widget.practices,
              selectedWeek: _selectedWeek,
              onWeekSelected: (week) => setState(() => _selectedWeek = week),
            ),
          ),

          // Selected week detail
          if (_selectedWeek != null) ...[
            const SizedBox(height: 20),
            _buildWeekDetail(_selectedWeek!),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1FB48C14), blurRadius: 34, offset: Offset(0, 14))
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.show_chart,
            size: 48,
            color: Color(0xFFD4CBBF),
          ),
          const SizedBox(height: 12),
          Text(
            _t('No learning data yet', '暂无学习数据'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8378),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t('Start practicing to see your trends', '开始练习后这里会显示您的学习趋势'),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFFABA49A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(double fromScore, double toScore, int weeks) {
    final change = toScore - fromScore;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EE),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up,
                color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Score improving steadily', '这段时间在稳步上升'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t(
                    '$weeks weeks ago from ${fromScore.toStringAsFixed(1)} to current ${toScore.toStringAsFixed(1)} (+${change.toStringAsFixed(1)})',
                    '$weeks 周前的 ${fromScore.toStringAsFixed(1)} 涨到现在的 ${toScore.toStringAsFixed(1)} (+${change.toStringAsFixed(1)})',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A8378),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${change.toStringAsFixed(1)}',
            style: const TextStyle(
              fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDetail(int weekIndex) {
    final score = widget.scores[weekIndex];
    final practice = widget.practices[weekIndex];
    final weekLabel = _t('Week ${weekIndex + 1}', '第 ${weekIndex + 1} 周');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEADF), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekLabel,
                  style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A8378),
                  ),
                ),
                const SizedBox(height: 6),
                if (score != null)
                  Row(
                    children: [
                      Text(
                        _t('Score:', '分数:'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A8378),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF5B301),
                        ),
                      ),
                    ],
                  ),
                if (score == null)
                  Text(
                    _t('No score data', '暂无分数'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFABA49A),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _t('Practice:', '练习:'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF8A8378),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$practice ${_t("times", "次")}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9C6EBC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedWeek = null),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEADF),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.close, size: 16, color: Color(0xFF8A8378)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  final List<double?> scores;
  final double maxScore;
  final double? target;
  final bool chinese;
  final int? selectedWeek;
  final ValueChanged<int> onWeekSelected;
  final List<String>? weekLabels;

  const _ScoreChart({
    required this.scores,
    required this.maxScore,
    required this.target,
    required this.chinese,
    required this.selectedWeek,
    required this.onWeekSelected,
    this.weekLabels,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Chart painter
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScoreChartPainter(
                scores: scores,
                maxScore: maxScore,
                target: target,
              ),
            ),
            // Week selection buttons
            Positioned.fill(
              child: Row(
                children: List.generate(8, (index) {
                  final width = constraints.maxWidth / 8;
                  return GestureDetector(
                    key: ValueKey('trend-week-$index'),
                    onTap: () => onWeekSelected(index),
                    child: Container(
                      width: width,
                      color: Colors.transparent,
                      child: selectedWeek == index
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC71B)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF5B301),
                                  width: 1.5,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
            // Target label (top right)
            if (target != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5B301),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    chinese
                        ? '目标 ${target!.toStringAsFixed(1)}'
                        : 'Target ${target!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Score labels on bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeekLabel(0, chinese),
                  _buildWeekLabel(7, chinese),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekLabel(int index, bool chinese) {
    // Generate date labels (mock - would come from actual data)
    final weekLabels = this.weekLabels ?? const [
      '7/27',
      '8/3',
      '8/10',
      '8/17',
      '8/24',
      '8/31',
      '9/7',
      '9/14'
    ];
    return Text(
      weekLabels[index],
      style: const TextStyle(
        fontSize: 9,
        color: Color(0xFF8A8378),
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<double?> scores;
  final double maxScore;
  final double? target;

  _ScoreChartPainter({
    required this.scores,
    required this.maxScore,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 20; // Reserve 20 for bottom labels
    final chartTop = 10; // Reserve 10 for top padding
    final usableHeight = chartHeight - chartTop;

    // Background beige area (below score line)
    final bgPaint = Paint()
      ..color = const Color(0xFFFDF8E8)
      ..style = PaintingStyle.fill;

    // Draw target line first (dashed, behind everything)
    if (target != null && target! <= maxScore) {
      final targetY = chartTop + usableHeight * (1 - target! / maxScore);
      final dashPaint = Paint()
        ..color = const Color(0xFFE6D5A0)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      double dashWidth = 6;
      double dashSpace = 4;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(math.min(startX + dashWidth, size.width), targetY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Calculate score points
    final points = <Offset>[];
    final segmentWidth = size.width / 8;

    for (int i = 0; i < scores.length; i++) {
      final score = scores[i];
      if (score != null) {
        final x = segmentWidth * (i + 0.5);
        final y = chartTop + usableHeight * (1 - score / maxScore);
        points.add(Offset(x, y));
      }
    }

    if (points.isEmpty) return;

    // Split at missing weeks; never imply measured continuity across a gap.
    final segments = <List<Offset>>[];
    var segment = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      if (scores[i] == null) {
        if (segment.isNotEmpty) segments.add(segment);
        segment = [];
      } else {
        segment.add(Offset(segmentWidth * (i + .5),
            chartTop + usableHeight * (1 - scores[i]! / maxScore)));
      }
    }
    if (segment.isNotEmpty) segments.add(segment);
    for (final part in segments.where((p) => p.length >= 2)) {
      final bgPath = Path()..moveTo(part.first.dx, chartHeight);
      for (final point in part) {
        bgPath.lineTo(point.dx, point.dy);
      }
      bgPath.lineTo(part.last.dx, chartHeight);
      bgPath.close();
      canvas.drawPath(bgPath, bgPaint);
    }

    // Draw yellow score line
    final linePaint = Paint()
      ..color = const Color(0xFFF5B301)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final part in segments.where((p) => p.length >= 2)) {
      final path = Path()..moveTo(part.first.dx, part.first.dy);
      for (final point in part.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw score point circles
    final circlePaint = Paint()
      ..color = const Color(0xFFF5B301)
      ..style = PaintingStyle.fill;
    final circleStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 5, circlePaint);
      canvas.drawCircle(point, 5, circleStrokePaint);
    }

    // Draw current score label (last point)
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final lastScore = scores.whereType<double>().last;
      final textPainter = TextPainter(
        text: TextSpan(
          text: lastScore.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141210),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(lastPoint.dx + 8, lastPoint.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreChartPainter oldDelegate) {
    return scores != oldDelegate.scores ||
        maxScore != oldDelegate.maxScore ||
        target != oldDelegate.target;
  }
}

class _PracticeBars extends StatelessWidget {
  final List<int> practices;
  final int? selectedWeek;
  final ValueChanged<int> onWeekSelected;

  const _PracticeBars({
    required this.practices,
    required this.selectedWeek,
    required this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxPractice = practices.reduce(math.max);
    if (maxPractice == 0) {
      return const Center(
        child: Text(
          'No practice data',
          style: TextStyle(fontSize: 11.5, color: Color(0xFFABA49A)),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(8, (index) {
        final count = practices[index];
        final height = (count / maxPractice * 40).clamp(2.0, 40.0);
        final isSelected = selectedWeek == index;

        return Expanded(
          child: GestureDetector(
            key: ValueKey('trend-week-$index'),
            onTap: () => onWeekSelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF9C6EBC)
                            : const Color(0xFFABA49A),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF9C6EBC)
                          : const Color(0xFFD4CBBF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
