import '../../app/app_state.dart';

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
  TfMockController(this.app, this.module) {
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

  /// One second of forced playback. Unlocks to the answer phase once the whole
  /// recording has "played" (mirrors the source audio setInterval).
  void audioTick() {
    if (phase != 'play') return;
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
    }
    save();
    return true;
  }
}
