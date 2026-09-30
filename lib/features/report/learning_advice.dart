import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// Skill identifiers for tab selection
const String kSkillListening = 'listening';
const String kSkillReading = 'reading';
const String kSkillWriting = 'writing';
const String kSkillSpeaking = 'speaking';

/// Demo data structure for advice items (not derived from actual student data)
class _DemoAdviceItem {
  final String title;
  final String trend; // 'improving' | 'declining' | 'stable'
  final int observationCount;
  final double progress; // 0.0 to 1.0
  final bool hasTarget;
  final String practiceText;

  const _DemoAdviceItem({
    required this.title,
    required this.trend,
    required this.observationCount,
    required this.progress,
    this.hasTarget = false,
    required this.practiceText,
  });
}

/// Learning advice widget showing improvement areas per skill
///
/// **DEMO DATA ONLY** - All advice content is hardcoded for demonstration
/// and is NOT derived from actual student performance data.
class LearningAdvice extends StatefulWidget {
  const LearningAdvice({
    super.key,
    required this.chinese,
    required this.selectedSkill,
    required this.onSelectSkill,
    required this.onPractice,
    this.real,
  });

  final bool chinese;
  final String selectedSkill;
  final ValueChanged<String> onSelectSkill;
  final void Function(String skill, int rank) onPractice;

  /// 演示用真实数据（learner_profile.json 的 `<考试>.report`）：`advice` 是各科的
  /// 可进步项（后端能力画像里掌握度最低的三项 `top` + 其余 `more`），`teacher` 是后端存的
  /// 能力点评（没有就不画点评卡）。为 null 时用下面写死的演示内容。
  final Map<String, dynamic>? real;

  @override
  State<LearningAdvice> createState() => _LearningAdviceState();
}

class _LearningAdviceState extends State<LearningAdvice> {
  bool _teacherExpanded = false;
  bool _moreSuggestionsExpanded = false;

  String _pick(Object pair) => '${(pair as List)[widget.chinese ? 1 : 0]}';
  Map? get _teacher => widget.real?['teacher'] as Map?;
  Map? get _area => (widget.real?['advice'] as Map?)?[widget.selectedSkill];
  List<String> get _more => widget.real != null
      ? [for (final label in (_area?['more'] as List? ?? const [])) _pick(label)]
      : widget.chinese
          ? _demoMoreSuggestions
          : const [
              'Identify intent',
              'Follow structure',
              'Separate facts and views',
              'Record numbers and times'
            ];

  // DEMO DATA - Clearly marked as demonstration content not from actual analysis
  static const Map<String, List<_DemoAdviceItem>> _demoAdviceData = {
    kSkillListening: [
      _DemoAdviceItem(
        title: '识别转折信息',
        trend: 'improving',
        observationCount: 18,
        progress: 0.42,
        hasTarget: true,
        practiceText: '先做听力日常训练，练到能快速识别题型',
      ),
      _DemoAdviceItem(
        title: '捕捉关键细节',
        trend: 'declining',
        observationCount: 21,
        progress: 0.33,
        practiceText: '先做听力日常训练，练到能从容应对真题',
      ),
      _DemoAdviceItem(
        title: '理解同义替换',
        trend: 'stable',
        observationCount: 24,
        progress: 0.56,
        practiceText: '先做听力日常训练，练到能在定时间',
      ),
    ],
    kSkillReading: [
      _DemoAdviceItem(
        title: '识别转折信息',
        trend: 'improving',
        observationCount: 18,
        progress: 0.42,
        hasTarget: true,
        practiceText: '先做听力日常训练，练到能快速识别题型',
      ),
      _DemoAdviceItem(
        title: '捕捉关键细节',
        trend: 'declining',
        observationCount: 21,
        progress: 0.33,
        practiceText: '先做听力日常训练，练到能从容应对真题',
      ),
      _DemoAdviceItem(
        title: '理解同义替换',
        trend: 'stable',
        observationCount: 24,
        progress: 0.56,
        practiceText: '先做听力日常训练，练到能在定时间',
      ),
    ],
    kSkillWriting: [
      _DemoAdviceItem(
        title: '识别转折信息',
        trend: 'improving',
        observationCount: 18,
        progress: 0.42,
        hasTarget: true,
        practiceText: '先做听力日常训练，练到能快速识别题型',
      ),
      _DemoAdviceItem(
        title: '捕捉关键细节',
        trend: 'declining',
        observationCount: 21,
        progress: 0.33,
        practiceText: '先做听力日常训练，练到能从容应对真题',
      ),
      _DemoAdviceItem(
        title: '理解同义替换',
        trend: 'stable',
        observationCount: 24,
        progress: 0.56,
        practiceText: '先做听力日常训练，练到能在定时间',
      ),
    ],
    kSkillSpeaking: [
      _DemoAdviceItem(
        title: '识别转折信息',
        trend: 'improving',
        observationCount: 18,
        progress: 0.42,
        hasTarget: true,
        practiceText: '先做听力日常训练，练到能快速识别题型',
      ),
      _DemoAdviceItem(
        title: '捕捉关键细节',
        trend: 'declining',
        observationCount: 21,
        progress: 0.33,
        practiceText: '先做听力日常训练，练到能从容应对真题',
      ),
      _DemoAdviceItem(
        title: '理解同义替换',
        trend: 'stable',
        observationCount: 24,
        progress: 0.56,
        practiceText: '先做听力日常训练，练到能在定时间',
      ),
    ],
  };

  static const List<String> _demoMoreSuggestions = [
    '识别说话者意图',
    '跟随讲座结构',
    '区分事实与观点',
    '记录数字与时间',
  ];

  String _getTeacherComment() => _teacher != null
      ? _pick(_teacher!['full'])
      : widget.chinese
      ? '最近的练习中，你已经能更稳定地捕捉主要信息，阅读中的定位过程也更清楚了。接下来可以把重点放在“论点展开”和“段落衔接”：写完一个观点后，补充具体例子，再解释例子为什么能支持这个观点。听力继续关注转折后的关键信息，不必同时增加太多练习内容。每次练完回看一个最想改进的地方，逐步把方法用熟。'
      : 'You identify main ideas more consistently and locate reading details more clearly. Focus next on argument development and paragraph cohesion: add a concrete example after each claim, then explain how it supports that claim. In listening, notice key information after a contrast. Review one priority after each practice and use the method repeatedly.';
  String _getTeacherCommentSummary() => _teacher != null
      ? _pick(_teacher!['summary'])
      : widget.chinese
      ? '主要信息捕捉与阅读定位更稳定。接下来优先练习论点展开和段落衔接。'
      : 'Main-idea identification and reading location are improving. Prioritize argument development and paragraph cohesion next.';

  String _skillLabel(String skill) {
    if (widget.chinese) {
      switch (skill) {
        case kSkillListening:
          return '听力';
        case kSkillReading:
          return '阅读';
        case kSkillWriting:
          return '写作';
        case kSkillSpeaking:
          return '口语';
        default:
          return skill;
      }
    } else {
      switch (skill) {
        case kSkillListening:
          return 'Listening';
        case kSkillReading:
          return 'Reading';
        case kSkillWriting:
          return 'Writing';
        case kSkillSpeaking:
          return 'Speaking';
        default:
          return skill;
      }
    }
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      // 真实数据里证据还不够看出走向的项：不画趋势。
      case 'unknown':
        return const SizedBox.shrink();
      case 'improving':
        return const Text('↗',
            style: TextStyle(
                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF219653)));
      case 'declining':
        return const Text('↘',
            style: TextStyle(
                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE1553B)));
      default:
        return const Text('→',
            style: TextStyle(
                fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE0A000)));
    }
  }

  String _trendText(String trend) {
    if (trend == 'unknown') return '';
    if (widget.chinese) {
      switch (trend) {
        case 'improving':
          return '在进步';
        case 'declining':
          return '在下滑';
        default:
          return '没变化';
      }
    } else {
      switch (trend) {
        case 'improving':
          return 'improving';
        case 'declining':
          return 'declining';
        default:
          return 'stable';
      }
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'improving':
        return const Color(0xFF219653);
      case 'declining':
        return const Color(0xFFE1553B);
      default:
        return const Color(0xFFE0A000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          widget.chinese ? '可以进步的地方' : 'Areas for Improvement',
          style: const TextStyle(
            fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: SurgoColors.ink,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.chinese
              ? '按科目查看前三项重点，其余建议收在下方。${widget.real == null ? '以下为演示分析，不代表真实测评结果。' : ''}'
              : 'Tap subjects above to switch. Each shows key items, '
                  'with suggestions and follow-ups below. Practice first then return.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A8378)),
        ),
        const SizedBox(height: 16),

        // Teacher comment card（真实数据里学员没生成过能力点评就不画）
        if (widget.real == null || _teacher != null) ...[
          _buildTeacherCommentCard(),
          const SizedBox(height: 18),
        ],

        // Skill tabs
        _buildSkillTabs(),
        const SizedBox(height: 18),

        // Top 3 advice items
        ..._buildAdviceItems(),

        // More suggestions
        if (_more.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildMoreSuggestions(),
        ],
      ],
    );
  }

  Widget _buildTeacherCommentCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E8),
        border: Border.all(color: const Color(0xFFF5D35C), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B48C14),
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE9A8),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('😊', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.chinese ? '老师给你的点评' : 'Teacher\'s Feedback',
                  style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment text
          GestureDetector(
            key: const ValueKey('teacher-expand'),
            onTap: () => setState(() => _teacherExpanded = !_teacherExpanded),
            child: Text(
              _teacherExpanded
                  ? _getTeacherComment()
                  : _getTeacherCommentSummary(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A4640),
                height: 1.7,
              ),
            ),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () =>
                      setState(() => _teacherExpanded = !_teacherExpanded),
                  child: Text(
                      widget.chinese
                          ? (_teacherExpanded ? '收起全文' : '展开全文')
                          : (_teacherExpanded ? 'Show less' : 'Read more'),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xff8f6e16))))),
          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildYellowPill(widget.chinese ? '点评提到的是' : 'Review criteria'),
              if (_teacher != null)
                for (final tag in _teacher!['tags'] as List)
                  _buildYellowPill(_pick(tag))
              else ...[
                _buildYellowPill(widget.chinese ? '论点展开' : 'Arguments'),
                _buildYellowPill(widget.chinese ? '段落衔接' : 'Cohesion'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYellowPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE9A8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6A5600),
        ),
      ),
    );
  }

  Widget _buildSkillTabs() {
    const skills = [
      kSkillListening,
      kSkillReading,
      kSkillWriting,
      kSkillSpeaking,
    ];

    return Row(
      children: skills.map((skill) {
        final isSelected = skill == widget.selectedSkill;
        return Expanded(
          child: GestureDetector(
            key: ValueKey('advice-tab-$skill'),
            onTap: () => widget.onSelectSkill(skill),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFDE9A8)
                    : const Color(0xFFF5F0E3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      child: Text(
                    _skillLabel(skill),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF3A2E00)
                          : const Color(0xFF8A8378),
                    ),
                  )),
                  const SizedBox(width: 4),
                  if (isSelected)
                    const Icon(Icons.expand_more,
                        size: 16, color: Color(0xFF3A2E00)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildAdviceItems() {
    final top = _area?['top'] as List?;
    final items = widget.real != null
        ? [
            for (final a in top ?? const [])
              _DemoAdviceItem(
                  title: _pick(a['title']),
                  trend: a['trend'] as String? ?? 'unknown',
                  observationCount: a['count'] as int,
                  progress: (a['progress'] as num).toDouble(),
                  practiceText: '')
          ]
        : _demoAdviceData[widget.selectedSkill] ?? [];
    final widgets = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 16));
      widgets.add(_buildAdviceCard(i + 1, items[i]));
    }

    return widgets;
  }

  String _adviceTitle(int rank) {
    final top = _area?['top'] as List?;
    if (top != null) return _pick(top[rank - 1]['title']);
    final map = widget.chinese
        ? {
            'listening': ['识别转折信息', '捕捉关键细节', '理解同义替换'],
            'reading': ['定位细节信息', '理解句间逻辑', '识别作者观点'],
            'writing': ['论点展开', '段落衔接', '语法准确性'],
            'speaking': ['回答展开', '表达连贯', '词汇准确性'],
          }
        : {
            'listening': [
              'Identify contrast',
              'Capture key details',
              'Recognize paraphrases'
            ],
            'reading': [
              'Locate details',
              'Follow sentence logic',
              'Identify viewpoints'
            ],
            'writing': [
              'Develop arguments',
              'Link paragraphs',
              'Grammar accuracy'
            ],
            'speaking': [
              'Extend answers',
              'Speak coherently',
              'Vocabulary accuracy'
            ],
          };
    return map[widget.selectedSkill]![rank - 1];
  }

  Widget _buildAdviceCard(int rank, _DemoAdviceItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5E5B8), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank and title
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C534),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A2E00),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _adviceTitle(rank),
                        style: const TextStyle(
                          fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrendIcon(item.trend),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _trendText(item.trend),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _trendColor(item.trend),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title label
          Text(
            _adviceTitle(rank),
            style: const TextStyle(
              fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: SurgoColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEADF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Progress
                      FractionallySizedBox(
                        widthFactor: item.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1553B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Target marker
                      if (item.hasTarget)
                        Positioned(
                          left: item.progress * 200,
                          top: -1,
                          child: Container(
                            width: 2,
                            height: 10,
                            color: const Color(0xFF8A8378),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Observation count
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.chinese ? '需要多花时间' : 'Needs more time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE1553B),
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  widget.chinese
                      ? '观察到 ${item.observationCount} 次'
                      : 'Observed ${item.observationCount}x',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8A8378),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Practice recommendation
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 16, color: Color(0xFF8A8378)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.chinese
                      ? '先做${_skillLabel(widget.selectedSkill)}日常训练，练到能定位到具体题型'
                      : 'Start ${_skillLabel(widget.selectedSkill).toLowerCase()} daily practice to target this skill.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A6459),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Practice button
          GestureDetector(
            key: ValueKey('advice-practice-${widget.selectedSkill}-$rank'),
            onTap: () => widget.onPractice(widget.selectedSkill, rank),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C534),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.chinese ? '去练这个 →' : 'Practice this →',
                    style: const TextStyle(
                      fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A2E00),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5E5B8), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const ValueKey('advice-more'),
            onTap: () => setState(
                () => _moreSuggestionsExpanded = !_moreSuggestionsExpanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.chinese
                        ? '其余建议放在后面，先练好上面几项再回来'
                        : 'These are later items, return after practicing above',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6A6459),
                    ),
                  ),
                ),
                Icon(
                  _moreSuggestionsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF8A8378),
                ),
              ],
            ),
          ),
          if (_moreSuggestionsExpanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _more.map((text) => _buildYellowPill(text)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
