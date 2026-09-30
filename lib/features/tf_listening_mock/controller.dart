import '../../app/app_state.dart';
import '../../widgets/demo_audio.dart';

/// Generic, PARAMETERIZED controller for the seven repeated TOEFL listening
/// MOCK question modules (tfListenQ / tfConvQ / tfAnnQ / tfTalkQ /
/// tfM2P1Q / tfM2P2Q / tfM2P3Q). All seven share one source-identical flow:
///
///   forced single playback (content locked) -> playback finishes -> N-second
///   answer countdown -> auto-advance to the next segment; the last segment
///   hands off to the next module/route.
///
/// Only two behaviours vary and are driven entirely by the exported JSON:
///   * style 'locked'  — options are visible but greyed & un-pickable while the
///                       recording plays (module 1 part 1 / module 2 part 1).
///   * style 'playing' — the body shows only the "正在播放…" animation while
///                       playing; options appear on unlock (conversation /
///                       announcement / academic talk / m2 parts 2-3).
///   * grouped         — consecutive segments sharing `audio` reuse the same
///                       recording and are NOT replayed (jump straight to answer).
///
/// The recording is a timing simulation exactly like the source `setInterval`
/// flow — there is NO Audio/TTS call and no invented speech. Answer countdown,
/// segment totals and the transition chain are copied verbatim.
class TfMockController {
  TfMockController(this.app, this.module) : _revision = app.revision {
    index = app.session['${prefix}Idx'] as int? ?? 0;
    phase = app.session['${prefix}Phase'] as String? ?? 'play';
    left = app.session['${prefix}Left'] as int? ?? answerSec;
    audio = app.session['${prefix}Audio'] as int? ?? 0;
    picks = Map<int, String>.from(
        (app.session['_${prefix}Picks'] as Map?) ?? const {});
    notes = Map<int, String>.from(
        (app.session['_${prefix}Notes'] as Map?) ?? const {});
    // A segment reached mid-play with a shared recording never replays.
    if (phase == 'play' && grouped && _sameAudio(index)) {
      audio = curSec;
      phase = 'answer';
      left = answerSec;
    }
  }

  final AppState app;
  final Map<String, dynamic> module;

  String get key => module['key'] as String;
  String get prefix => module['prefix'] as String;
  int get total => module['total'] as int;
  int get answerSec => module['answerSec'] as int;
  String get style => module['style'] as String;
  bool get grouped => module['grouped'] as bool? ?? false;
  String get nextRoute => module['next'] as String;
  List get segments => module['segments'] as List;
  Map get current => segments[index] as Map;
  int get curSec => current['sec'] as int;
  String? get lead => current['lead'] as String?;

  late int index, left, audio;
  late String phase;
  late Map<int, String> picks, notes;

  bool get playing => phase == 'play';
  bool get isLast => index >= total - 1;
  String get nextLabel => isLast ? '下一部分' : '下一段';

  bool _sameAudio(int i) {
    if (i <= 0) return false;
    final prev = segments[i - 1] as Map, cur = segments[i] as Map;
    return prev['audio'] != null && prev['audio'] == cur['audio'];
  }

  void save() => app.session.addAll({
        '${prefix}Idx': index,
        '${prefix}Phase': phase,
        '${prefix}Left': left,
        '${prefix}Audio': audio,
        '_${prefix}Picks': picks,
        '_${prefix}Notes': notes,
      });

  /// 演示用真实数据的每一段带着后端存的那段录音（clip：{ asset, sec }，tool/demo_export 导出），网页上真的放它；
  /// 没有这一项（原型数据）或不在网页上，就是上面说的模拟播放：每秒走 1 秒，走到 sec 秒。
  Map? get clip => demoAudio.available ? current['clip'] as Map? : null;
  // 全站同一时间只放一段：播放器里是这一段，它的位置才算这一段的进度。
  bool get _loaded => clip != null && demoAudio.asset == clip!['asset'];
  double get progress =>
      _loaded ? demoAudio.position / demoAudio.duration : audio / curSec;

  // 建这一页时的 revision（AppState 每次换页加一）。对不上，就是这一页已经被换掉、正在退场：旧页面还要留
  // 300 毫秒的过渡，答题倒计时照跑，恰好在这时走到 0 会自动进下一段——不能让它把下一段的录音放起来。
  final int _revision;

  /// 放这一段的录音。模考只放一遍，没有暂停、拖动和重播；从记着的位置放，是为了中途离开再回来时接着放。
  void listen() {
    if (clip == null || app.revision != _revision) return;
    demoAudio.play(clip!['asset'] as String,
        seconds: (clip!['sec'] as num).toDouble(),
        from: audio >= curSec ? 0 : audio.toDouble());
  }

  /// One second of forced playback. Unlocks to the answer phase once the whole
  /// recording has "played" (mirrors the source audio setInterval).
  void audioTick() {
    if (phase != 'play') return;
    if (clip != null) {
      // 播放器里已经不是这一段：页面正在退场（换页时 AppState.go 先把播放器停了，旧页面还要留 300 毫秒的过渡）。
      // 不动它，更不能再放起来；记着的位置留给下次进来接着放。
      if (!_loaded) return;
      // 位置和放完都读播放器：放不出声时它按时长空走、照样放完，这里不会一直等。
      audio = demoAudio.position.floor().clamp(0, curSec);
      if (demoAudio.ended) {
        audio = curSec;
        phase = 'answer';
        left = answerSec;
      }
      save();
      return;
    }
    audio++;
    if (audio >= curSec) {
      audio = curSec;
      phase = 'answer';
      left = answerSec;
    }
    save();
  }

  /// One second of the answer countdown. Returns true exactly when it hits zero
  /// (the caller then auto-advances, matching the source tf*Advance on 0).
  bool tick() {
    if (phase != 'answer') return false;
    left--;
    if (left <= 0) {
      left = 0;
      save();
      return true;
    }
    save();
    return false;
  }

  void pick(String v) {
    if (phase != 'answer') return; // no answering while playing
    picks[index] = v;
    save();
  }

  /// Advance to the next segment. Returns false when the module is finished
  /// (the last segment has been left) so the page can run the transition.
  bool next() {
    if (phase == 'play') return true; // locked: cannot skip during playback
    if (isLast) return false;
    index++;
    left = answerSec;
    if (grouped && _sameAudio(index)) {
      audio = curSec;
      phase = 'answer';
    } else {
      audio = 0;
      phase = 'play';
      listen();
    }
    save();
    return true;
  }
}
