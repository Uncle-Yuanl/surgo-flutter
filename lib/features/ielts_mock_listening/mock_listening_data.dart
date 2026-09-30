import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/demo_audio.dart';

/// Loads assets/data/ielts_mock_listening.json (exported byte-for-byte from
/// surgo-mobile-new/app.js mockListeningQ*View + lisMapSvg).
class MockListeningData {
  MockListeningData(this.raw);
  final Map<String, dynamic> raw;
  static MockListeningData? cache;
  static Future<MockListeningData> load() async =>
      cache ??= MockListeningData(jsonDecode(await rootBundle.loadString(
          'assets/data/ielts_mock_listening.json')) as Map<String, dynamic>);

  int get sharedTimerSec => raw['sharedTimerSec'] as int;
  int get reviewSec => raw['reviewSec'] as int;
  String get mapSvg => raw['mapSvg'] as String;
  List get parts => raw['parts'] as List;
  Map<String, dynamic> part(int no) =>
      Map<String, dynamic>.from(parts.firstWhere((p) => p['no'] == no) as Map);
  String markLabel(int n) =>
      (raw['markLabelTemplate'] as String).replaceAll('{n}', '$n');
}

/// Which mock-listening page maps to which part number.
const Map<SurgoPage, int> mockListeningPartOf = {
  SurgoPage.mockListeningQ: 1,
  SurgoPage.mockListeningQ2: 2,
  SurgoPage.mockListeningQ3: 3,
  SurgoPage.mockListeningQ4: 4,
};

/// Only mockLeft is shared. Source choices, inputs and answer dots live in
/// the current DOM and are recreated blank on every render/part navigation.
class MockListeningController {
  MockListeningController(this.app, this.data, this.part) {
    // startMockTimer(id==='mockListeningQ'): reset to 30:00 on Part 1 only.
    if (part == 1) {
      app.session['mockLeft'] = data.sharedTimerSec;
    }
    app.session['mockLeft'] ??= data.sharedTimerSec;
    meta = data.part(part);
  }
  final AppState app;
  final MockListeningData data;
  final int part;
  late final Map<String, dynamic> meta;
  final Map<int, dynamic> ans = <int, dynamic>{};
  final Set<int> done = <int>{};

  int get left => (app.session['mockLeft'] as int?) ?? data.sharedTimerSec;

  /// Every mock part covers 10 answers.
  int get dotFrom => meta['dotFrom'] as int;
  List<int> get dots => List.generate(10, (i) => dotFrom + i);

  void pickMc(int n, int optIndex) {
    ans[n] = optIndex;
    done.add(n);
  }

  void pickMatch(int n, String letter) {
    ans[n] = letter;
    done.add(n);
  }

  void fill(int n, String text) {
    ans[n] = text; // The input itself retains whitespace; only the dot trims.
    if (text.trim().isEmpty) {
      done.remove(n);
    } else {
      done.add(n);
    }
  }

  /// Shared 30:00 countdown tick. Returns true once time expires.
  bool tick() {
    final cur = left;
    if (cur > 0) {
      app.session['mockLeft'] = cur - 1;
      return cur - 1 <= 0;
    }
    return true;
  }

  /// Answered count in the current rendered part only.
  int get answeredAll => done.length;

  /// 演示用真实数据带着这一 Part 的录音（audio：{ asset, sec }，tool/demo_export 导出），网页上真的放它：
  /// 进页面自己开始、只放一遍，没有暂停、拖动和重放。没有这一项（原型数据）或不在网页上，
  /// 音频卡画的还是 JSON 里写死的进度和时间（audioBarPct / audioTime）。
  Map? get clip => demoAudio.available ? meta['audio'] as Map? : null;
  double get audioLength => (clip!['sec'] as num).toDouble();

  /// 录音放到第几秒；[audioOver]：放完了，或这一 Part 已经交了，之后不再碰播放器。
  double audioAt = 0;
  bool audioOver = false;

  /// 进页面调一次，之后页面的考试计时每秒调一次：记下放到哪了；这一段没在放（也没放完）就从记下的
  /// 位置放上去。进页面那一次就是这样开始的；这一页没有播放键，录音被系统暂停了（切到后台、来电、
  /// 耳机按键）也只能由这里接着放。
  /// 页面已经换走就不再动播放器：换页后本页还要淡出 300 毫秒、计时还在走，这时播放器里已经是
  /// 下一页的录音了。
  void audioTick() {
    final c = clip;
    if (c == null || audioOver || mockListeningPartOf[app.current] != part) {
      return;
    }
    if (demoAudio.asset == c['asset']) {
      // 到头了而播放器还没报「放完」的那一瞬也算放完：这时再让它放，浏览器会从头重放一遍。
      audioOver = demoAudio.ended ||
          demoAudio.position >= demoAudio.duration - .25;
      // 放完就记成总时长：浏览器量的时长和导出时量的会差几十毫秒。
      audioAt = audioOver
          ? audioLength
          : demoAudio.position.clamp(0, audioLength).toDouble();
      if (audioOver || demoAudio.playing) return;
    }
    demoAudio.play(c['asset'], seconds: audioLength, from: audioAt);
  }

  /// 这一 Part 交了（第 4 部分提交、结束考试、时间到）：录音停下，[audioTick] 不再把它放起来。
  void endAudio() {
    if (clip == null || audioOver) return;
    audioOver = true;
    demoAudio.stop();
  }
}
