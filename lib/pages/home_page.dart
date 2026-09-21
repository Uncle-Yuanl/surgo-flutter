import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/t.dart';

/// 首页（`ielts` 页）—— 对应 app.js 第 323-390 行。
///
/// 版式来自这些 CSS 分节（_extract/css/）：
///   141-section-header.css        .sec-hd（标题下那条黄色高亮）
///   142-study-row.css             .study-row / .study-ic
///   145-Course-big-card.css       .crs（大卡）
///   146-daily-challenge-card.css  .challenge
///   147-sound-wave-progress-bar.css  .wave
///   148-yellow-card-variant.css   .crs.yellow
///   161-Continue-course-card.css  .course
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenModule,
    required this.onContinue,
    required this.onReading,
    required this.onListening,
    required this.onWriting,
    required this.onSpeaking,
    required this.onVocab,
    required this.onPrep,
    required this.onTrain,
    required this.onLogo,
  });

  final VoidCallback onOpenModule;
  final VoidCallback onContinue;
  final VoidCallback onReading;
  final VoidCallback onListening;
  final VoidCallback onWriting;
  final VoidCallback onSpeaking;
  final VoidCallback onVocab;
  final VoidCallback onPrep;

  /// `trainGo(page, variant)` —— 第二参数在原型里是 'p2' / 't2' / 's1' 这类变体
  final void Function(String page, String? variant) onTrain;
  final VoidCallback onLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .home-top：顶部只放 logo，点它回考试选择
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: onLogo,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/surgo_logo.png',
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        _ContinueCourseCard(onContinue: onContinue, onTapBody: onOpenModule),
        const SizedBox(height: 16),

        // 六科入口横向滚动
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _StudyItem(
                asset: 'assets/images/ic3_reading.png',
                label: 'Reading',
                onTap: onReading,
              ),
              const SizedBox(width: 12),
              _StudyItem(
                asset: 'assets/images/ic3_listening.png',
                label: 'Listening',
                onTap: onListening,
              ),
              const SizedBox(width: 12),
              _StudyItem(
                asset: 'assets/images/ic3_writing.png',
                label: 'Writing',
                onTap: onWriting,
              ),
              const SizedBox(width: 12),
              _StudyItem(
                asset: 'assets/images/ic3_speaking.png',
                label: 'Speaking',
                onTap: onSpeaking,
              ),
              const SizedBox(width: 12),
              _StudyItem(
                asset: 'assets/images/ic3_vocab.png',
                label: 'Vocabulary',
                onTap: onVocab,
              ),
              const SizedBox(width: 12),
              _StudyItem(
                asset: 'assets/images/ic3_preparing.png',
                label: 'Preparing',
                onTap: onPrep,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const _SectionHeader('Today’s train'),

        // 三张大卡 + 每日挑战
        _CourseCard(
          variant: _CourseVariant.yellow,
          kicker: 'READING · SECTION 3',
          head: '学术长文 阅读理解',
          waveOn: 40,
          meta: '本周进度 2/5',
          onTap: () => onTrain('readingDaily', null),
        ),
        _CourseCard(
          variant: _CourseVariant.dark,
          kicker: 'SPEAKING · PART 2',
          head: '个人陈述 口语训练',
          waveOn: 80,
          meta: '本周进度 4/5',
          onTap: () => onTrain('speakingDaily', 'p2'),
        ),
        _CourseCard(
          variant: _CourseVariant.yellow,
          kicker: 'WRITING · TASK 2',
          head: '议论文 写作精练',
          waveOn: 60,
          meta: '本周进度 3/5',
          onTap: () => onTrain('writingDaily', 't2'),
        ),
        _ChallengeCard(
          onTap: () => onTrain('listeningDaily', 's1'),
          onContinue: () => onTrain('listeningDaily', 's1'),
        ),
      ],
    );
  }
}

// ============================================================ 继续学习卡

/// `.course`（161-Continue-course-card.css）
class _ContinueCourseCard extends StatelessWidget {
  const _ContinueCourseCard({required this.onContinue, required this.onTapBody});

  final VoidCallback onContinue;
  final VoidCallback onTapBody;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapBody,
      child: Container(
        // .course{background:#FCF3D2;border-radius:22px;padding:18px}
        decoration: BoxDecoration(
          color: const Color(0xFFFCF3D2),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            // .course-otter{right:14px;top:14px;width:88px}
            Positioned(
              right: -4,
              top: -4,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/otter6_top.png',
                  width: 88,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题占 66% 宽，右侧留给水獭
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.66,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const T('Welcome back, Nafis!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                            height: 1.2,
                            letterSpacing: -0.3,
                          )),
                      const SizedBox(height: 6),
                      const TSpan(
                        parts: [
                          ('距离你的考试还剩', false),
                          ('20天', true),
                          ('，你的目标是', false),
                          ('7.0', true),
                          ('分', false),
                        ],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF9A9385),
                          height: 1.5,
                        ),
                        highlightStyle: _hl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // .course-cta
                GestureDetector(
                  onTap: onContinue,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5CE4E),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x47F5B301),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    alignment: Alignment.center,
                    child: const T('Continue Writing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.onYellowStrong,
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// `.course .course-sub .hl{font-size:14.5px;font-weight:800;color:#E0A000;text-decoration:underline}`
  static const _hl = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFFE0A000),
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFFE0A000),
  );
}

// ============================================================ 六科入口

/// `.study-item`（142-study-row.css）
class _StudyItem extends StatelessWidget {
  const _StudyItem({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // .study-ic{width:64px;height:64px;border-radius:20px;background:#F6F1E7}
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F1E7),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Image.asset(asset, width: 46, height: 46, fit: BoxFit.contain),
          ),
          const SizedBox(height: 9),
          T(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black)),
        ],
      ),
    );
  }
}

// ============================================================ 分节标题

/// `.sec-hd`（141-section-header.css）—— 标题下方 33% 宽的黄色高亮条。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          // ::before{width:33%;bottom:2px;height:9px;background:var(--yellow);border-radius:3px;opacity:.85}
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.33,
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: SurgoColors.yellow.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          T(
            title,
            uppercase: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 28 / 16,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================ 大卡

enum _CourseVariant { yellow, dark, violet }

/// `.crs`（145/148）—— 大过程卡。
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.variant,
    required this.kicker,
    required this.head,
    required this.waveOn,
    required this.meta,
    required this.onTap,
  });

  final _CourseVariant variant;
  final String kicker;
  final String head;
  final int waveOn;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yellow = variant == _CourseVariant.yellow;
    final dark = variant == _CourseVariant.dark;
    final violet = variant == _CourseVariant.violet;

    final bg = yellow
        ? const Color(0xFFFBD45E)
        : dark
            ? const Color(0xFF2B2A2E)
            : const Color(0xFFBFB6F2);
    final kickerColor = yellow
        ? const Color(0xFFB5820A)
        : violet
            ? const Color(0xFF6B5FC7)
            : SurgoColors.yellow;
    final headColor = yellow
        ? const Color(0xFF2B2410)
        : dark
            ? Colors.white
            : const Color(0xFF231F3A);
    final metaColor = yellow
        ? const Color(0xFF6B5410)
        : dark
            ? const Color(0xB3FFFFFF)
            : const Color(0xFF4A427A);
    final curveColor = yellow
        ? const Color(0x73FFFFFF)
        : violet
            ? const Color(0x59FFFFFF)
            : const Color(0x0FFFFFFF);
    final onColor =
        yellow ? SurgoColors.ink : violet ? const Color(0xFF2B2A2E) : SurgoColors.yellow;
    final offColor = yellow
        ? const Color(0x2E1C1A17)
        : violet
            ? const Color(0x2E2B2A2E)
            : const Color(0x38FFFFFF);
    final goBg = yellow
        ? SurgoColors.ink
        : dark
            ? SurgoColors.yellow
            : Colors.white;
    final goFg = yellow ? Colors.white : SurgoColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // .cdcurve：右侧那个大空心圆环装饰
              Positioned(
                right: -40,
                top: 20,
                child: Container(
                  width: 230,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: curveColor, width: 26),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    T(kicker,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: kickerColor,
                        )),
                    const SizedBox(height: 6),
                    T(head,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                          color: headColor,
                        )),
                    const SizedBox(height: 12),
                    // .wave{height:22px;max-width:72%}
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.72,
                      child: _Wave(on: waveOn, onColor: onColor, offColor: offColor),
                    ),
                    const SizedBox(height: 8),
                    T(meta,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: metaColor,
                        )),
                  ],
                ),
              ),
              // .cgo 右下角圆形箭头
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goBg,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2E000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('→',
                      style: TextStyle(
                          fontSize: 20, color: goFg, height: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ 声波进度

/// `.wave`（147-sound-wave-progress-bar.css）
///
/// 原型 `wave(n)` 生成固定高度的条形：`h = 45 + 40*|sin(i*1.3)|`（百分比）。
/// 前 n% 的条形点亮。
class _Wave extends StatelessWidget {
  const _Wave({
    required this.on,
    required this.onColor,
    required this.offColor,
  });

  final int on;
  final Color onColor;
  final Color offColor;

  /// 原型 wave(n) 固定生成 40 根条形
  static const count = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(count, (i) {
          // app.js wave(): const h=45+Math.round(40*Math.abs(Math.sin(i*1.3)));
          final h = (45 + (40 * math.sin(i * 1.3)).abs().round()).clamp(5, 100);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  heightFactor: (h / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: i < on ? onColor : offColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================ 每日挑战卡

/// `.challenge`（146-daily-challenge-card-ref.css）
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.onTap, required this.onContinue});

  final VoidCallback onTap;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2A2E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: 20,
                child: Container(
                  width: 230,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x0FFFFFFF), width: 26),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const T('每日挑战',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: SurgoColors.yellow,
                        )),
                    const SizedBox(height: 6),
                    const T('保持你的 12 天连胜',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.25,
                        )),
                    const SizedBox(height: 4),
                    const T('听力 · 5 min',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0x80FFFFFF),
                        )),
                    const SizedBox(height: 9),
                    // .dash：14 格，前 12 格点亮
                    Row(
                      children: List.generate(14, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: i < 12
                                    ? SurgoColors.yellow
                                    : const Color(0x2EFFFFFF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const T('今日挑战已就绪',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0x8CFFFFFF),
                            )),
                        GestureDetector(
                          onTap: onContinue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: SurgoColors.yellow,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            child: const T('继续挑战',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
