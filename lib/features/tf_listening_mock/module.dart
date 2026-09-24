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
import '../../widgets/marking_dialog.dart';
import 'data.dart';
import 'controller.dart';
import 'feedback.dart';

/// Route <-> module-key map for the seven question routes. All seven are the
/// same parameterised page; only the exported JSON differs (segments, timing,
/// lock style, grouping).
const _routeModule = <SurgoPage, String>{
  SurgoPage.tfListenQ: 'listen',
  SurgoPage.tfConvQ: 'conv',
  SurgoPage.tfAnnQ: 'ann',
  SurgoPage.tfTalkQ: 'talk',
  SurgoPage.tfM2P1Q: 'm2p1',
  SurgoPage.tfM2P2Q: 'm2p2',
  SurgoPage.tfM2P3Q: 'm2p3',
};

/// nextRoute token (from JSON `next`) -> destination page.
const _nextPage = <String, SurgoPage>{
  'conv': SurgoPage.tfConvQ,
  'ann': SurgoPage.tfAnnQ,
  'talk': SurgoPage.tfTalkQ,
  'modEnd': SurgoPage.tfModEnd,
  'm2p2': SurgoPage.tfM2P2Q,
  'm2p3': SurgoPage.tfM2P3Q,
};

/// Chinese label used for the marking dialog when module 2 part 3 submits.
const _markLabel = '正在批改听力作答, module 2';

/// Feature entry: returns the widget for any of the 11 native mock listening
/// routes, or null so the shell can try the next builder.
Widget? buildTfListeningMockPage(SurgoPage p) {
  if (_routeModule.containsKey(p)) return TfMockQuestionPage(page: p);
  switch (p) {
    case SurgoPage.tfModEnd:
      return const TfModEndPage();
    case SurgoPage.tfModLoad:
      return const TfModLoadPage();
    case SurgoPage.tfMod2Intro:
      return const TfMod2IntroPage();
    case SurgoPage.tfListenFb:
      return const TfListenFeedbackPage();
    default:
      return null;
  }
}

/// Resets a module's saved session state so it starts fresh at segment 0,
/// mirroring the source `startTfX` reset calls.
void _resetModule(AppState app, Map module) {
  final prefix = module['prefix'] as String;
  app.session.removeWhere((k, _) =>
      k == '${prefix}Idx' ||
      k == '${prefix}Phase' ||
      k == '${prefix}Left' ||
      k == '${prefix}Audio' ||
      k == '_${prefix}Picks' ||
      k == '_${prefix}Notes');
}

// ============================================================ question page
class TfMockQuestionPage extends StatefulWidget {
  const TfMockQuestionPage({super.key, required this.page});
  final SurgoPage page;
  @override
  State<TfMockQuestionPage> createState() => _TfMockQuestionPageState();
}

class _TfMockQuestionPageState extends State<TfMockQuestionPage> {
  Map<String, dynamic>? _data;
  TfMockController? c;
  Timer? _audio, _timer;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    TfListeningMockData.load().then((raw) {
      if (!mounted) return;
      final key = _routeModule[widget.page]!;
      setState(() {
        _data = raw;
        c = TfMockController(app, (raw['modules'] as Map)[key] as Map<String, dynamic>);
      });
      notes.text = c!.notes[c!.index] ?? '';
      _startPhase();
    });
  }

  /// Drive whichever timer the current phase needs (playback or countdown).
  void _startPhase() {
    _audio?.cancel();
    _timer?.cancel();
    final x = c!;
    if (x.phase == 'play') {
      _audio = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(x.audioTick);
        if (x.phase != 'play') {
          _audio?.cancel();
          _startPhase(); // unlocked -> start countdown
        }
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final zero = x.tick();
        setState(() {});
        if (zero) _advance();
      });
    }
  }

  void _advance() {
    _audio?.cancel();
    _timer?.cancel();
    final x = c!;
    if (x.next()) {
      notes.text = x.notes[x.index] ?? '';
      setState(() {});
      _startPhase();
      return;
    }
    // Module finished -> run the source transition.
    final app = context.read<AppState>();
    if (x.nextRoute == 'mark') {
      showMarking(context, SurgoPage.tfListenFb, _markLabel);
      return;
    }
    final dest = _nextPage[x.nextRoute]!;
    final destKey = _routeForModule(dest);
    if (destKey != null) {
      _resetModule(app, (_data!['modules'] as Map)[destKey] as Map);
    }
    app.go(dest);
  }

  String? _routeForModule(SurgoPage p) => _routeModule[p];

  @override
  void dispose() {
    _audio?.cancel();
    _timer?.cancel();
    notes.dispose();
    super.dispose();
  }

  String _clock(int v) =>
      '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final x = c;
    if (x == null) return const Center(child: CircularProgressIndicator());
    final playing = x.playing;
    final locked = x.style == 'locked';
    // Header countdown: shows the full answer window while playing, then ticks.
    final headSecs = playing ? x.answerSec : x.left;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 用户 2026-09-24：计时代替顶栏 logo 的位置，不再单独占一行。
      SurgoTopBar(
        center: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
              color: (!playing && x.left <= 5)
                  ? SurgoColors.overrun
                  : SurgoColors.ink,
              borderRadius: BorderRadius.circular(20)),
          child: SourceText('⏱ 00:00:${headSecs.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontFamilyFallback: SurgoFontFamily.fallback,
                  fontSize: 14,
                  height: 1.3,
                  color: Colors.white,
                  fontWeight: FontWeight.w800)),
        ),
      ),
      // 用户 2026-09-24：做题页左上角三段标题。
      SessionTags(
          mock: true,
          subject: '托福听力',
          part: const {
            'listen': '听后选择回应',
            'conv': '听对话',
            'ann': '听通知',
            'talk': '听学术讲座',
            'm2p1': '模块 2 · 第 1 部分',
            'm2p2': '模块 2 · 第 2 部分',
            'm2p3': '模块 2 · 第 3 部分',
          }[x.key]),
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SourceText('第 ${x.index + 1} / ${x.total}', style: SurgoText.cardDesc),
          const SizedBox(height: 10),
          // Audio row (progress simulation — no real audio).
          Row(children: [
            Icon(playing ? Icons.graphic_eq : Icons.check_circle,
                color: playing ? SurgoColors.goldInk : SurgoColors.ok),
            const SizedBox(width: 8),
            SourceText(_clock(x.audio), style: const TextStyle(fontSize: 12)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                    value: (x.audio / x.curSec).clamp(0, 1),
                    color: SurgoColors.yellow,
                    backgroundColor: SurgoColors.track),
              ),
            ),
            SourceText(_clock(x.curSec), style: const TextStyle(fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(playing ? Icons.graphic_eq : Icons.check_circle,
                size: 16, color: playing ? SurgoColors.goldInk : SurgoColors.ok),
            const SizedBox(width: 6),
            T(playing ? '正在播放...' : '播放已完成', style: SurgoText.rowLabel),
          ]),
          if (x.lead != null) ...[
            const SizedBox(height: 12),
            SourceText(x.lead!, style: SurgoText.rowLabel),
          ],
          const SizedBox(height: 14),
          // Body: 'playing' style hides options during playback; 'locked' style
          // shows greyed options that cannot be picked yet.
          if (x.style == 'playing' && playing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(child: T('正在播放...', style: SurgoText.rowLabel)),
            )
          else ...[
            SourceText(x.current['q'] as String, style: SurgoText.rowLabel),
            const SizedBox(height: 12),
            for (final opt in (x.current['opts'] as List))
              Opacity(
                opacity: playing ? .45 : 1,
                child: SurgoCard(
                  padding: const EdgeInsets.all(13),
                  color: x.picks[x.index] == opt[0]
                      ? SurgoColors.yellowTint
                      : Colors.white,
                  onTap: playing ? null : () => setState(() => x.pick(opt[0] as String)),
                  child: Row(children: [
                    SourceText(opt[0] as String, style: SurgoText.rowLabel),
                    const SizedBox(width: 10),
                    Expanded(
                        child: SourceText(opt[1] as String,
                            style: const TextStyle(fontSize: 14, height: 1.5))),
                  ]),
                ),
              ),
            const SizedBox(height: 6),
            SurgoButton(x.nextLabel, onTap: playing ? null : _advance),
          ],
        ]),
      ),
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const T('笔记', style: SurgoText.cardTitle),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 6,
            enabled: !(locked && playing),
            decoration: const InputDecoration(hintText: '边听边记笔记', border: InputBorder.none),
            onChanged: (v) {
              x.notes[x.index] = v;
              x.save();
            },
          ),
        ]),
      ),
    ]);
  }
}

// ====================================================== module-end card
class TfModEndPage extends StatelessWidget {
  const TfModEndPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(),
      const SizedBox(height: 20),
      SurgoCard(
        color: SurgoColors.yellowTint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('听力', style: SurgoText.cardEn),
          const SizedBox(height: 8),
          const T('模块 1 结束', style: SurgoText.h1),
          const SizedBox(height: 12),
          const Divider(color: SurgoColors.line),
          const SizedBox(height: 12),
          const T('阅读部分模块 1 的时间已结束。', style: SurgoText.cardDesc),
          const SizedBox(height: 8),
          const T('点击“继续”进入模块 2。', style: SurgoText.cardDesc),
          const SizedBox(height: 18),
          SurgoButton('继续', onTap: () => state.go(SurgoPage.tfModLoad)),
        ]),
      ),
    ]);
  }
}

// ====================================================== loading transition
class TfModLoadPage extends StatefulWidget {
  const TfModLoadPage({super.key});
  @override
  State<TfModLoadPage> createState() => _TfModLoadPageState();
}

class _TfModLoadPageState extends State<TfModLoadPage> {
  // Progress 0 -> 100% over ~3s, then advance to the module-2 intro (source).
  static const _durMs = 3000;
  Timer? _t;
  int _pct = 0;
  late final int _t0;

  @override
  void initState() {
    super.initState();
    _t0 = DateTime.now().millisecondsSinceEpoch;
    _t = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().millisecondsSinceEpoch - _t0;
      setState(() => _pct = (elapsed / _durMs * 100).round().clamp(0, 100));
      if (_pct >= 100) {
        _t?.cancel();
        Timer(const Duration(milliseconds: 200), () {
          if (mounted) context.read<AppState>().go(SurgoPage.tfMod2Intro);
        });
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/otter_study.png', width: 120, height: 120,
            errorBuilder: (_, __, ___) => const SizedBox(height: 120)),
        const SizedBox(height: 20),
        const T('正在进入第二阶段', style: SurgoText.cardTitle),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(children: [
            LinearProgressIndicator(
                value: _pct / 100, color: SurgoColors.yellow, backgroundColor: SurgoColors.track),
            const SizedBox(height: 8),
            SourceText('$_pct%'),
          ]),
        ),
      ]),
    );
  }
}

// ====================================================== module-2 intro
class TfMod2IntroPage extends StatelessWidget {
  const TfMod2IntroPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(),
      const SizedBox(height: 20),
      SurgoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('模块 2', style: SurgoText.h1),
          const SizedBox(height: 12),
          const Divider(color: SurgoColors.line),
          const SizedBox(height: 12),
          const T('你即将进入模块 2。难度已根据你在模块 1 的表现进行调整。每道题的音频仅播放一遍，不可重播。',
              style: SurgoText.cardDesc),
          const SizedBox(height: 12),
          const T('你已准备好开始本模块。', style: SurgoText.rowLabel),
          const SizedBox(height: 8),
          const T('计时器将显示你完成每道题的剩余时间。', style: SurgoText.cardDesc),
          const SizedBox(height: 8),
          const T('你将无法返回之前的题目。', style: SurgoText.rowLabel),
          const SizedBox(height: 18),
          SurgoButton('我已准备好', onTap: () => state.go(SurgoPage.tfM2P1Q)),
        ]),
      ),
    ]);
  }
}
