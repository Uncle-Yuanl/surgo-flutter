import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/loop_video.dart';
import '../../widgets/audio_card.dart';
import '../../widgets/marking_dialog.dart';
import 'controller.dart';
import 'review.dart';

/// 路由映射：练习页 + 批改反馈页。tfSpeakingRoutes[p] = (kind, isFeedback)
const tfSpeakingRoutes = {
  SurgoPage.tfDailyRetell: ('retell', false),
  SurgoPage.tfRetellFb: ('retell', true),
  SurgoPage.tfDailyInterview: ('interview', false),
  SurgoPage.tfInterviewFb: ('interview', true),
};

Widget? buildTfSpeakingDailyPage(SurgoPage page) => tfSpeakingRoutes[page] == null
    ? null
    : TfSpeakingDailyPage(kind: tfSpeakingRoutes[page]!.$1, feedback: tfSpeakingRoutes[page]!.$2);

class TfSpeakingDailyPage extends StatefulWidget {
  const TfSpeakingDailyPage({super.key, required this.kind, required this.feedback});
  final String kind;
  final bool feedback;
  @override
  State<TfSpeakingDailyPage> createState() => _TfSpeakingDailyPageState();
}

class _TfSpeakingDailyPageState extends State<TfSpeakingDailyPage> {
  TfSpeakingController? c;
  Timer? audioTimer, recTimer;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    TfSpeakingData.load().then((raw) {
      if (!mounted) return;
      setState(() => c = TfSpeakingController(app, widget.kind, raw[widget.kind] as Map<String, dynamic>));
      if (!widget.feedback) {
        if (c!.phase == 'play') _runAudio();
        if (c!.phase == 'answer') _runAnswer();
      }
    });
  }

  // 模拟音频进度：间隔随倍速而变（源 tfRtRunAudio: setInterval(…, 1000/rate)）
  void _runAudio() {
    audioTimer?.cancel();
    if (c!.phase != 'play') return;
    audioTimer = Timer.periodic(Duration(milliseconds: c!.audioInterval), (_) {
      if (!mounted) return;
      setState(c!.audioTick);
      if (c!.phase != 'play') audioTimer?.cancel();
    });
  }

  // 作答 1s 计时器：倒计时→正计时，超时弹一次窗（源 tfRtRunAnswerTimer）
  void _runAnswer() {
    recTimer?.cancel();
    recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final alert = c!.tick();
      setState(() {});
      if (alert) _timeup();
    });
  }

  void _timeup() => showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (ctx) => Dialog(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const LoopVideo(asset: 'assets/video/timeup.mp4'), const SizedBox(height: 14),
          T(widget.kind == 'retell' ? '回答时间已到，你可以继续完成复述' : '回答时间已到，你可以继续完成回答', textAlign: TextAlign.center, style: SurgoText.sheetTitle),
          const SizedBox(height: 14), SurgoButton('继续作答', onTap: () => Navigator.pop(ctx)),
        ])))
      );

  void _retake() {
    recTimer?.cancel();
    setState(c!.retake);
    _runAnswer();
  }

  void _next() {
    final x = c!;
    audioTimer?.cancel();
    recTimer?.cancel();
    if (!x.next()) {
      final route = widget.kind == 'retell' ? SurgoPage.tfRetellFb : SurgoPage.tfInterviewFb;
      showMarking(context, route, widget.kind == 'retell' ? '正在批改日常训练 · 听后复述' : '正在批改日常训练 · 接受访谈');
    } else {
      setState(() {});
      _runAudio();
    }
  }

  @override
  void dispose() {
    audioTimer?.cancel();
    recTimer?.cancel();
    super.dispose();
  }

  String clock(int v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

  // 大计时数字（源 tsoSpeakView bigNum）：作答倒计时 00:00:ss，超时后 +00:mm:ss
  String bigNum(TfSpeakingController x) => x.over
      ? '+00:${(x.ansUp ~/ 60).toString().padLeft(2, '0')}:${(x.ansUp % 60).toString().padLeft(2, '0')}'
      : '00:00:${x.left.clamp(0, x.ansSec).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final x = c;
    if (x == null) return const Center(child: CircularProgressIndicator());
    if (widget.feedback) return TfSpeakingReview(kind: widget.kind, data: x.data);

    final playing = x.phase == 'play', ready = x.phase == 'ready', answer = x.phase == 'answer';
    final topClock = answer ? bigNum(x) : (playing || ready ? clock(x.audio) : '00:00:${x.ansSec.toString().padLeft(2, '0')}');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 用户 2026-09-24：计时代替顶栏 logo 的位置。
      SurgoTopBar(center: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(color: x.over ? SurgoColors.overrun : SurgoColors.ink, borderRadius: BorderRadius.circular(20)),
        child: SourceText('⏱ ${answer ? bigNum(x) : topClock}', style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 14, height: 1.3, color: Colors.white, fontWeight: FontWeight.w800)))),
      SessionTags(mock: false, subject: '托福口语', part: widget.kind == 'retell' ? '听读复述' : '参加访谈'),
      // 用户 2026-09-24：标签连带音频卡移到返回箭头的下一行（第 2、3 部分同改）。
      // 播放/确认阶段展示音频卡；作答阶段隐藏（源 tsoSpeakView）。
      if (playing || ready) ...[
        _audioCard(x, playing),
        const SizedBox(height: 16),
      ],
      // 作答阶段的中央大计时
      if (answer) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Center(
        child: SourceText(bigNum(x), style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 40, fontWeight: FontWeight.w900, color: x.over ? SurgoColors.overrun : SurgoColors.ink)))),
      // 用户 2026-09-24：语音球上下太挤，补间距（作答态已有大计时占位，少留一些）。
      SizedBox(height: answer ? 10 : 22),
      // 圆形头像/麦克风（作答=麦克风态，其余=提问态）
      // 用户 2026-09-24：语音球缩小（150→118，图标 44→36，光环 12→10）。
      Center(child: Container(width: 118, height: 118, decoration: BoxDecoration(shape: BoxShape.circle,color:answer?SurgoColors.yellow:const Color(0xff121110),boxShadow:[BoxShadow(color:answer?const Color(0x33f5b301):const Color(0x1f1c1a17),spreadRadius:10)]),
        child: Icon(Icons.mic_none, color: answer?const Color(0xff3a2e00):Colors.white, size: 36))),
      const SizedBox(height: 26),
      Center(child: T(_title(x, playing, ready, answer), style: SurgoText.sheetTitle, textAlign: TextAlign.center)),
      const SizedBox(height: 6),
      Center(child: T(_sub(x, playing, ready, answer), style: SurgoText.cardDesc, textAlign: TextAlign.center)),
      const SizedBox(height: 14),
      const SizedBox(height: 12),
      Center(child: T('第 ${x.index + 1} / ${x.total}', style: SurgoText.cardDesc)),
      const SizedBox(height: 14),
      _foot(x, playing, ready, answer),
    ]);
  }

  String _title(TfSpeakingController x, bool playing, bool ready, bool answer) {
    if (answer) return '轮到你了 — 请开始回答';
    if (ready) return '准备好开始了吗？';
    return x.data['playTitle'] as String;
  }

  String _sub(TfSpeakingController x, bool playing, bool ready, bool answer) {
    if (answer) return x.data['answerSub'] as String;
    if (ready) return '可反复重听音频，确认后再开始答题。';
    return x.data['playSub'] as String;
  }

  /// 用户 2026-09-24：音频卡改用与雅思听力日常训练一致的 AudioCard。
  Widget _audioCard(TfSpeakingController x, bool playing) => AudioCard(
        title: x.data['playTitle'] as String,
        subtitle: playing ? '正在播放...' : '本次训练中可按需重播与变速。',
        elapsed: clock(x.audio),
        total: clock(x.sec),
        progress: x.audio / x.sec,
        playing: playing,
        speedLabel: '${x.rates[x.rate]}X',
        speeds: [for (final r in x.rates) '${r}X'],
        onSpeed: (v) {
          final i = x.rates.indexWhere((r) => '${r}X' == v);
          if (i < 0) return;
          setState(() => x.setRate(i));
          _runAudio();
        },
        onToggle: () { setState(x.replay); _runAudio(); },
        onSeek: (s) => setState(() => x.audio = (x.audio + s).clamp(0, x.sec)),
        onRestart: () { setState(x.replay); _runAudio(); },
      );

  Widget _foot(TfSpeakingController x, bool playing, bool ready, bool answer) {
    if (answer) {
      // 重新录制 + 下一段/提交（Row 中约束两颗 SurgoButton 各占半宽）
      return Row(children: [
        Expanded(child: SurgoButton('↻ 重新录制', primary: false, onTap: _retake)),
        const SizedBox(width: 12),
        Expanded(child: SurgoButton(x.isLast ? '提交' : '下一段', onTap: _next)),
      ]);
    }
    if (ready) return SurgoButton('开始答题', onTap: () { setState(x.begin); _runAnswer(); });
    return SurgoButton('播放中...', onTap: null);
  }
}
