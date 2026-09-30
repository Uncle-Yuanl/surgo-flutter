import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../widgets/demo_audio.dart';

/// TOEFL 口语日常训练 · 听后复述(tfRt) / 接受访谈(tfIv)。
///
/// 源 app.js 里两者的播放/录音都是「模拟」的：tfRtRunAudio / tfIvRunAudio 只用
/// setInterval 每 (1000/倍速) 毫秒把进度 +1，作答阶段(tfRt/IvRunAnswerTimer)也只跑
/// 一个 1s 计时器，没有任何真实音频或录音 API 调用。此处严格照搬这套计时状态机，
/// 不改动任何时长/倍速/重试/完成规则。
///
/// 例外只有一处：演示用真实数据（tool/demo_export）每段带着考官的原音频，网页上提示音真的放它
/// （见 [TfSpeakingController.clip]）。原型数据、widget 测试和原生端没有这一项，仍是上面的计时模拟；
/// 作答（录音）在哪种数据下都是模拟的，不开麦克风。
class TfSpeakingData {
  static Map<String, dynamic>? cache;
  static Future<Map<String, dynamic>> load() async =>
      cache ??= (jsonDecode(await rootBundle.loadString('assets/data/tf_speaking_daily.json')) as Map).cast<String, dynamic>();
}

class TfSpeakingController {
  TfSpeakingController(this.app, this.kind, this.data) {
    index = app.session['${prefix}Idx'] as int? ?? 0;
    phase = app.session['${prefix}Phase'] as String? ?? 'play';
    audio = app.session['${prefix}Audio'] as int? ?? 0;
    ansUp = app.session['${prefix}AnsUp'] as int? ?? 0;
    // 源 startTfDailyRetell/Interview 及 task_brief 种子都把默认倍速设为档位 1（=1.0x）。
    rate = app.session['${prefix}RateIdx'] as int? ?? 1;
    left = app.session['${prefix}Left'] as int? ?? ansSec;
    over = app.session['${prefix}Over'] as bool? ?? false;
    alerted = app.session['${prefix}Alerted'] as bool? ?? false;
  }
  final AppState app;
  final String kind; // retell | interview
  final Map<String, dynamic> data;

  String get prefix => data['prefix'] as String; // tfRt | tfIv
  int get total => data['total'] as int;
  // 演示用真实数据每句的作答时长不同（8 / 10 / 12 秒），写在段上；原型数据只有整体的一个值。
  int get ansSec => (current['ansSec'] ?? data['ansSec']) as int;
  List get segments => data['segments'] as List;
  List get rates => data['rates'] as List;
  Map get current => (segments[index % segments.length] as Map);
  int get sec => current['sec'] as int;

  late int index, audio, ansUp, rate, left;
  late String phase; // play | ready | answer
  late bool over, alerted;

  int get audioInterval => (1000 / (rates[rate] as num)).round();
  bool get isLast => index >= total - 1;

  /// 这一段考官的原音频（audio：{ asset, sec }，tool/demo_export 导出）。有它且在网页上就真的放：进度、
  /// 在不在放、放没放完都读播放器，这里不另数秒。原型数据没有这一项、或不在网页上，是 null，走计时模拟。
  Map? get clip => demoAudio.available ? current['audio'] as Map? : null;
  bool get loaded => clip != null && demoAudio.asset == clip!['asset'];
  bool get playing => clip == null ? phase == 'play' : loaded && demoAudio.playing;
  double get progress => loaded ? demoAudio.position / demoAudio.duration : audio / sec;

  void _start({double from = 0}) {
    // 播放器在页面离场时把倍速复位了，每次起播都带上这一页选的。
    demoAudio.rate = (rates[rate] as num).toDouble();
    demoAudio.play(clip!['asset'] as String, seconds: (clip!['sec'] as num).toDouble(), from: from);
  }

  void save() => app.session.addAll({
        '${prefix}Idx': index,
        '${prefix}Phase': phase,
        '${prefix}Audio': audio,
        '${prefix}AnsUp': ansUp,
        '${prefix}RateIdx': rate,
        '${prefix}Left': left,
        '${prefix}Over': over,
        '${prefix}Alerted': alerted,
      });

  /// 模拟播放进度：每个 tick +1 秒，播满转 ready（对应源 tfRtRunAudio）。
  ///
  /// 真音频时页面每 250 毫秒调一次，只按播放器的状态同步：在放就是 play，放完或暂停着是 ready（「播放中...」
  /// 只在真的在放时出现）。被浏览器拦下、文件加载失败时播放器按时长空走，同样会放完，不会卡在 play。
  void audioTick() {
    if (clip != null) {
      if (phase == 'answer') return;
      if (!loaded) {
        // 这一段还不在播放器里：刚进页面、换到下一段的第一拍，或者播放器被刚离场的页面停掉了（换页时旧页面
        // 要等 300 毫秒的淡出才 dispose；在设置里切换界面语言就会重建本页）。从记下的位置起播。
        if (phase == 'play') _start(from: audio < sec ? audio.toDouble() : 0.0);
      } else if (demoAudio.ended) {
        audio = sec;
        phase = 'ready';
      } else {
        audio = demoAudio.position.floor().clamp(0, sec);
        phase = demoAudio.playing ? 'play' : 'ready';
      }
      save();
      return;
    }
    if (phase != 'play') return;
    audio++;
    if (audio >= sec) {
      audio = sec;
      phase = 'ready';
    }
    save();
  }

  /// 进度条点击/快进快退（源 tfRtSeek）。
  void seek(int delta) {
    audio = (audio + delta).clamp(0, sec);
    if (audio < sec && phase == 'ready') {
      phase = 'play';
    } else if (audio >= sec && phase == 'play') {
      phase = 'ready';
    }
    save();
  }

  void setRate(int i) {
    rate = i;
    if (clip != null) demoAudio.rate = (rates[i] as num).toDouble();
    save();
  }

  /// 重播：回到 play、进度归零（源 tfRtReplay）。
  void replay() {
    phase = 'play';
    audio = 0;
    if (clip != null) _start();
    save();
  }

  /// 音频卡的播放键。原型里它就是重播；真音频是暂停 / 接着放，放完了再点才从头放。
  void toggle() {
    final c = clip;
    if (c == null) return replay();
    demoAudio.rate = (rates[rate] as num).toDouble();
    demoAudio.toggle(c['asset'] as String, seconds: (c['sec'] as num).toDouble());
    audioTick();
  }

  /// 音频卡的快退 / 快进。原型只挪进度，不动阶段。
  void skip(int delta) {
    if (clip == null) {
      audio = (audio + delta).clamp(0, sec);
    } else if (loaded) {
      demoAudio.seek(demoAudio.position + delta);
      audioTick();
    }
  }

  /// 点「开始答题」直接进入录音倒计时（源 tfRtBeginAnswer，无 1s 准备页）。
  void begin() {
    // 作答时提示音不该还响着（有的浏览器放完后往回拖会自己接着放，同步的那一拍还没来得及转回 play）。
    if (clip != null) demoAudio.pause();
    phase = 'answer';
    left = ansSec;
    ansUp = 0;
    over = false;
    alerted = false;
    save();
  }

  /// 1s 作答计时器：倒计时到 0 转正计时，超时弹窗只弹一次（源 tfRtRunAnswerTimer）。
  bool tick() {
    if (phase != 'answer') return false;
    if (!over) {
      left--;
      if (left <= 0) {
        left = 0;
        over = true;
        if (!alerted) {
          alerted = true;
          save();
          return true;
        }
      }
    } else {
      ansUp++;
    }
    save();
    return false;
  }

  /// 重新录制：回到 ansSec 倒计时（源 tfRtRetake）。
  void retake() {
    left = ansSec;
    ansUp = 0;
    over = false;
    alerted = false;
    save();
  }

  /// 下一段 / 提交。返回 false 表示已到最后一段（应打开批改反馈）。
  bool next() {
    if (isLast) return false;
    index++;
    phase = 'play';
    audio = 0;
    ansUp = 0;
    // Source tfRtNext/tfIvNext deliberately retain left/over/alerted until Answer.
    save();
    return true;
  }
}
