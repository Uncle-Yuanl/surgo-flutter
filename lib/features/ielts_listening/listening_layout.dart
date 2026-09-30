import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/audio_card.dart';
import '../../widgets/session_tags.dart';
import 'listening_data.dart';

/// 顶部计时 + home，与阅读 [ReadingHeader] 同一套（用户 2026-09-24 要求听力页面
/// 设计与阅读一致）。
class ListeningHeader extends StatelessWidget {
  const ListeningHeader({
    super.key,
    required this.clock,
    required this.over,
    this.homeKey = const ValueKey('listening-home'),
    this.clockKey = const ValueKey('listening-clock'),
    this.onHome,
    this.label = '本次练习时长',
    this.overLabel = '已超时',
  });
  final String clock;
  final bool over;

  /// 各页沿用自己原有的标识，既有测试与审计脚本不受影响。
  final Key homeKey, clockKey;

  /// 模拟考按 home 走「退出考试」确认，而不是直接回首页。
  final VoidCallback? onHome;

  /// 计时下方一行说明：日常训练是「本次练习时长」，模拟考是「考试倒计时」。
  final String label, overLabel;

  /// 与阅读同值：中文副标题行高更大。
  static double contentTop(UiLang lang) => lang == UiLang.zh ? 72 : 67;

  @override
  Widget build(BuildContext context) {
    final zh = context.watch<AppState>().lang == UiLang.zh;
    return Column(children: [
      SizedBox(
          height: 33,
          child: Stack(children: [
            Positioned(
                left: 20,
                top: 6,
                child: GestureDetector(
                    key: homeKey,
                    onTap: onHome ??
                        () => context.read<AppState>().go(SurgoPage.ielts),
                    child: SvgPicture.asset('assets/images/home_icon.svg',
                        width: 24, height: 24))),
            Positioned(
                left: 0,
                right: 0,
                top: 5,
                child: Center(
                    child: Text(clock,
                        key: clockKey,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontFamilyFallback: SurgoFontFamily.fallback,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                            height: 1,
                            color: SurgoColors.ink)))),
          ])),
      const SizedBox(height: 4),
      if (over)
        T(overLabel,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SurgoColors.muted))
      else
        T(label,
            style: TextStyle(
                fontSize: 12,
                height: zh ? 17 / 12 : 1,
                fontWeight: FontWeight.w600,
                color: SurgoColors.muted)),
      const SizedBox(height: 10),
    ]);
  }
}

/// 上半区：标签 + 标题 + 说明 + 白卡音频播放器，对齐阅读的文章区排版。
class ListeningBrief extends StatelessWidget {
  const ListeningBrief({
    super.key,
    required this.controller,
    required this.clock,
    required this.onSeek,
    required this.onToggle,
    required this.onSpeed,
  });
  final IeltsListeningController controller;
  final String Function(num) clock;
  final ValueChanged<double> onSeek;
  final VoidCallback onToggle;
  final ValueChanged<String> onSpeed;

  // 源站 LISTEN_TYPE 文案，一字不改：翻译表按整句匹配，改字会漏翻。
  static const _names = {
    'mc': '选择题',
    'form': '表格填空',
    'matching': '配对题',
    'note': '笔记填空',
  };

  @override
  Widget build(BuildContext context) {
    final x = controller;
    final m = x.meta;
    final zh = x.app.lang == UiLang.zh;
    // 演示用真实数据（tool/demo_export）自带这句说明的中英两份（brief：[英文, 中文]，
    // 题型和题号按真实题目）；原型数据没有，仍按下面的模板拼。
    final brief = m['brief'] as List?;
    final instruction = brief != null
        ? '${brief[zh ? 1 : 0]}'
        : '${m['part']} · ${_names[m['mainType']]}为主，先听录音再作答第 1-${x.questions.length} 题。';
    final rendered =
        Translator.instance.translate(instruction, x.app.lang) ?? instruction;
    final cjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(rendered);
    return SingleChildScrollView(
        key: const ValueKey('listening-brief-scroll'),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 6),
          // 用户 2026-09-24：左上角三段标题，改用公共 SessionTags。
          SessionTags(
              mock: x.app.session['sessionMode'] == 'mock',
              subject: '${x.app.examType.label} ${zh ? '听力' : 'Listening'}',
              part: m['part'] as String?,
              padding: EdgeInsets.zero),
          const SizedBox(height: 10),
          // 用户 2026-09-24：标题与副标题中英要对照 —— 英文模式用 IELTS/TOEFL
          // Listening，不再拼中文「听力」；两行之间加行距。
          // 真实数据里有的练习没有标题（ctx 为 null），就只写科目。
          T('${x.app.examType.label} ${zh ? '听力' : 'Listening'}${m['ctx'] == null ? '' : ' · ${m['ctx']}'}',
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                  letterSpacing: -.3,
                  color: Colors.black)),
          const SizedBox(height: 7),
          T(instruction,
              style: TextStyle(
                  fontSize: 14,
                  height: cjk ? 1.65 : 1.5,
                  color: SurgoColors.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          AudioCard(
              cardKey: const ValueKey('listening-audio-card'),
              title: m['section'] ?? 'Section 3',
              subtitle: m['sectionDesc'] ?? m['ctx'] ?? '',
              elapsed: clock(x.audio),
              total: m['audioDur'] ?? '07:00',
              progress: x.audio / 225,
              playing: x.playing,
              speedLabel: x.speed,
              speeds: const ['0.75X', '1X', '1.25X', '1.5X'],
              onSpeed: onSpeed,
              onToggle: onToggle,
              onSeek: (s) => onSeek(s.toDouble()),
              onRestart: () => onSeek(-225)),
          const SizedBox(height: 22),
        ]));
  }
}
