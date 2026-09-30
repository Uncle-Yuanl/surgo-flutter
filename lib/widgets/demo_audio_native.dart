import 'package:flutter/foundation.dart';

/// 非网页端（含 widget 测试）没有接播放器：[available] 为 false，页面走原型的计时模拟，
/// 下面这些方法什么都不做。接口和 demo_audio_web.dart 保持一致。
class DemoAudio extends ChangeNotifier {
  bool get available => false;
  String? get asset => null;
  bool get playing => false;
  bool get ended => false;
  bool get silent => false;
  double get position => 0;
  double get duration => 0;
  void unlockOnFirstTap() {}
  void play(String asset, {required double seconds, double from = 0}) {}
  void toggle(String asset, {required double seconds}) {}
  void pause() {}
  void seek(double seconds) {}
  set rate(double value) {}
  void stop() {}
}

final demoAudio = DemoAudio();
