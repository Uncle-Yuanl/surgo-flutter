import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// 全站共用的一个 `<audio>`：同一时间只放一段，换一段就是换 src。接口和 demo_audio_native.dart 一致。
///
/// 只用一个元素是为了手机：iOS 上每个媒体元素的第一次播放必须由点击直接触发，之后才允许程序自己播。
/// [unlockOnFirstTap] 在用户第一次点屏幕时让这个元素放一小段静音，后面进页面就自动开始的音频
/// （托福听力、考官提问）才放得出来；同一次点击里顺带用一句空话解锁浏览器朗读（iOS 是同样的规矩）。
///
/// 放不出来的时候（点击之前被浏览器拦下、文件加载失败）不报错也不卡住：这一段按原型那样只走
/// 进度（[silent] 为 true），到时长照常 [ended]，页面不用另写一套。
class DemoAudio extends ChangeNotifier {
  DemoAudio() {
    for (final type in const ['play', 'playing', 'pause', 'timeupdate', 'durationchange', 'seeked']) {
      _el.addEventListener(type, ((web.Event _) => notifyListeners()).toJS);
    }
    _el.addEventListener('ended', ((web.Event _) => _finish()).toJS);
    _el.addEventListener('error', ((web.Event _) => _goSilent()).toJS);
  }

  final web.HTMLAudioElement _el = web.HTMLAudioElement()..preload = 'auto';
  String? _asset;
  double _seconds = 0, _rate = 1, _silentAt = 0;
  bool _wanted = false, _ended = false, _silent = false, _unlocked = false;
  Timer? _silentTick;

  bool get available => true;

  /// 当前这一段（assets/data/aud_*.mp3），没有就是 null。
  String? get asset => _asset;
  bool get playing => _silent ? _silentTick != null : _asset != null && !_el.paused && !_el.ended;

  /// 当前这一段放到头了（[seek] 回去或重新 [play] 后复位）。
  bool get ended => _asset != null && _ended;

  /// 当前这一段放不出声音，正按时长空走。
  bool get silent => _silent;
  double get position => _silent ? _silentAt : _el.currentTime;
  double get duration {
    final real = _el.duration;
    return !_silent && real.isFinite && real > 0 ? real : _seconds;
  }

  /// 从 [from] 秒开始放 [asset]；[seconds] 是导出时记下的时长（放不出声时按它走进度）。
  void play(String asset, {required double seconds, double from = 0}) {
    _stopSilent();
    final fresh = _asset != asset;
    if (fresh) {
      _asset = asset;
      _el.src = ui_web.assetManager.getAssetUrl(asset);
    }
    _seconds = seconds;
    _ended = false;
    _el.defaultPlaybackRate = _rate;
    _el.playbackRate = _rate;
    // 刚换的 src 本来就从头放，不用再设位置。
    if (!fresh || from > 0) _jump(from);
    _start();
    notifyListeners();
  }

  /// 播放键：没在放这一段（或已放完）就从头放，正在放就暂停，暂停着就接着放。
  void toggle(String asset, {required double seconds}) {
    if (_asset != asset || _ended) {
      play(asset, seconds: seconds);
    } else if (playing) {
      pause();
    } else {
      _resume();
      notifyListeners();
    }
  }

  void pause() {
    _wanted = false;
    _silentTick?.cancel();
    _silentTick = null;
    if (!_silent) _el.pause();
    notifyListeners();
  }

  void seek(double seconds) {
    if (_asset == null) return;
    final to = seconds.clamp(0, duration).toDouble();
    _ended = false;
    if (_silent) {
      _silentAt = to;
      if (_silentTick != null) _runSilent();
    } else {
      _jump(to);
    }
    notifyListeners();
  }

  set rate(double value) {
    _rate = value;
    _el.defaultPlaybackRate = value;
    _el.playbackRate = value;
    if (_silentTick != null) _runSilent();
  }

  /// 离开页面时调用：停下，忘掉当前这一段和倍速。不通知监听者（调用方多半正在 dispose）。
  void stop() {
    _wanted = false;
    _stopSilent();
    _el.pause();
    _asset = null;
    _ended = false;
    _rate = 1;
  }

  /// 应用启动时调用一次，见类注释。
  void unlockOnFirstTap() {
    final handler = ((web.Event _) {
      if (_unlocked) return;
      try {
        web.window.speechSynthesis.speak(web.SpeechSynthesisUtterance(''));
      } catch (_) {
        // 这个浏览器没有朗读接口。
      }
      if (_asset == null) {
        _el.src = _silence;
        _el.play().toDart.then((_) {
          _unlocked = true;
        }, onError: (Object _) {});
      } else if (_silent && _wanted) {
        // 有一段在点击之前被拦下、正空走进度：这次点击把它真的放出来。
        _resume();
      }
    }).toJS;
    // 一次点击会依次触发其中几种，哪一种算「用户手势」各浏览器不同，所以每种都试，直到放成功。
    for (final type in const ['touchend', 'pointerup', 'mouseup', 'click', 'keydown']) {
      web.window.addEventListener(type, handler, true.toJS);
    }
  }

  void _resume() {
    if (_silent) {
      _stopSilent();
      _jump(_silentAt);
    }
    _start();
  }

  void _jump(double to) {
    try {
      _el.currentTime = to;
    } catch (_) {
      // 还没读到元数据时，老的 Safari 设播放位置会抛错：那就从头放。
    }
  }

  void _start() {
    final asset = _asset;
    _wanted = true;
    _el.play().toDart.then((_) {
      _unlocked = true;
    }, onError: (Object _) {
      // 被拦下或加载失败。被后来的 play() / pause() 打断的不算。
      if (_asset == asset && _wanted && _el.paused) _goSilent();
    });
  }

  void _goSilent() {
    if (_asset == null || _silent) return;
    _silent = true;
    final at = _el.currentTime;
    _silentAt = at.isFinite ? at : 0;
    if (_wanted) _runSilent();
    notifyListeners();
  }

  void _runSilent() {
    _silentTick?.cancel();
    final clock = Stopwatch()..start();
    final from = _silentAt;
    _silentTick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _silentAt = from + clock.elapsedMilliseconds / 1000 * _rate;
      if (_silentAt < _seconds) {
        notifyListeners();
      } else {
        _silentAt = _seconds;
        _finish();
      }
    });
  }

  void _stopSilent() {
    _silentTick?.cancel();
    _silentTick = null;
    _silent = false;
  }

  void _finish() {
    _silentTick?.cancel();
    _silentTick = null;
    _wanted = false;
    if (_asset != null) _ended = true;
    notifyListeners();
  }

  /// 0.05 秒的静音 WAV（8 kHz、16 位、单声道），只用来解锁播放。
  static final String _silence = () {
    const bytes = 800;
    final wav = ByteData(44 + bytes);
    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        wav.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    wav.setUint32(4, 36 + bytes, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little);
    wav.setUint16(22, 1, Endian.little);
    wav.setUint32(24, 8000, Endian.little);
    wav.setUint32(28, 16000, Endian.little);
    wav.setUint16(32, 2, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    wav.setUint32(40, bytes, Endian.little);
    return 'data:audio/wav;base64,${base64Encode(wav.buffer.asUint8List())}';
  }();
}

final demoAudio = DemoAudio();
