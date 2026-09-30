import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';

/// TOEFL 口语日常训练 · 听后复述(tfRt) / 接受访谈(tfIv)。
///
/// 源 app.js 里两者的播放/录音都是「模拟」的：tfRtRunAudio / tfIvRunAudio 只用
/// setInterval 每 (1000/倍速) 毫秒把进度 +1，作答阶段(tfRt/IvRunAnswerTimer)也只跑
/// 一个 1s 计时器，没有任何真实音频或录音 API 调用。此处严格照搬这套计时状态机，
/// 不引入真实媒体、不改动任何时长/倍速/重试/完成规则。
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
  void audioTick() {
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
    save();
  }

  /// 重播：回到 play、进度归零（源 tfRtReplay）。
  void replay() {
    phase = 'play';
    audio = 0;
    save();
  }

  /// 点「开始答题」直接进入录音倒计时（源 tfRtBeginAnswer，无 1s 准备页）。
  void begin() {
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
