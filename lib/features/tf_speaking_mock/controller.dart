import 'dart:convert';
import 'package:flutter/services.dart';

/// TOEFL 口语「模考」数据与计时状态机（Task 1 听后复述 tfSpk1 / Task 2 参加访谈 tfSpk2）。
///
/// 源 app.js 里播放/录音全是「模拟」：tfS1StartFlow / tfS2StartFlow 只用 setInterval 每 1s
/// 推进阶段，没有任何真实音频、录音、后端或评分调用。此处严格照搬这套计时机，不引入真实媒体。
/// 与「日常训练」不同：模考没有倍速/重播/重录，只有单向推进；时长也不同（Task1 指令 5s、播放
/// seg.sec、准备 1s、作答 seg.ansSec；Task2 播放 seg.sec、作答 seg.ansSec）。
class TfSpeakingMockData {
  static Map<String, dynamic>? cache;
  static Future<Map<String, dynamic>> load() async =>
      cache ??= (jsonDecode(await rootBundle.loadString('assets/data/tf_speaking_mock.json')) as Map).cast<String, dynamic>();
}

/// Task 1 · 听后复述。四阶段：instruct(instrSec) -> play(sec) -> ready(readySec) -> answer(ansSec)。
/// 每题结束弹「停止回答」2s 后推进；最后一题结束应跳 tfSpk2Intro。
class TfSpk1Controller {
  TfSpk1Controller(Map<String, dynamic> t1)
      : total = t1['total'] as int,
        instrSec = t1['instrSec'] as int,
        readySec = t1['readySec'] as int,
        segments = (t1['segments'] as List).cast<Map<String, dynamic>>();

  final int total, instrSec, readySec;
  final List<Map<String, dynamic>> segments;

  int seg = 0;
  String phase = 'instruct'; // instruct | play | ready | answer
  int audio = 0; // 播放已过秒数
  int left = 0; // 作答倒计时剩余
  int tick = 0; // 当前阶段内计秒

  Map<String, dynamic> get cur => segments[seg < segments.length ? seg : 0];
  int get sec => cur['sec'] as int;
  int get ansSec => cur['ansSec'] as int;
  String get instruct => cur['instruct'] as String;
  bool get isLast => seg >= segments.length - 1;

  void start() {
    seg = 0;
    phase = 'instruct';
    audio = 0;
    left = instrSec;
    tick = 0;
  }

  /// 每秒推进一次。返回值：'answer-done' 表示作答结束需弹停止窗；否则 null。
  String? step() {
    tick++;
    if (phase == 'instruct') {
      if (tick >= instrSec) {
        tick = 0;
        phase = 'play';
        audio = 0;
      }
      return null;
    }
    if (phase == 'play') {
      audio = tick;
      if (tick >= sec) {
        tick = 0;
        phase = 'ready';
      }
      return null;
    }
    if (phase == 'ready') {
      if (tick >= readySec) {
        tick = 0;
        phase = 'answer';
        left = ansSec;
      }
      return null;
    }
    // answer
    left--;
    if (left <= 0) {
      left = 0;
      return 'answer-done';
    }
    return null;
  }

  /// 推进到下一题（源 tfS1Advance）。返回 false 表示已到最后一题（应跳 Task 2 准备页）。
  bool advance() {
    if (isLast) return false;
    seg++;
    phase = 'instruct';
    audio = 0;
    left = instrSec;
    tick = 0;
    return true;
  }
}

/// Task 2 · 参加访谈。两阶段：play(sec) -> answer(ansSec)。
/// 每题结束弹「停止回答」2s 后推进；最后一题结束应打开批改反馈(tfSpeakFb)。
class TfSpk2Controller {
  TfSpk2Controller(Map<String, dynamic> t2)
      : total = t2['total'] as int,
        segments = (t2['segments'] as List).cast<Map<String, dynamic>>();

  final int total;
  final List<Map<String, dynamic>> segments;

  int seg = 0;
  String phase = 'play'; // play | answer
  int audio = 0;
  int left = 0;
  int tick = 0;

  Map<String, dynamic> get cur => segments[seg < segments.length ? seg : 0];
  int get sec => cur['sec'] as int;
  int get ansSec => cur['ansSec'] as int;
  bool get isLast => seg >= segments.length - 1;

  void start() {
    seg = 0;
    phase = 'play';
    audio = 0;
    left = 0;
    tick = 0;
  }

  String? step() {
    tick++;
    if (phase == 'play') {
      audio = tick;
      if (tick >= sec) {
        tick = 0;
        phase = 'answer';
        left = ansSec;
      }
      return null;
    }
    left--;
    if (left <= 0) {
      left = 0;
      return 'answer-done';
    }
    return null;
  }

  /// 源 tfS2Advance。返回 false 表示已到最后一题（应打开批改反馈）。
  bool advance() {
    if (isLast) return false;
    seg++;
    phase = 'play';
    audio = 0;
    left = 0;
    tick = 0;
    return true;
  }
}
