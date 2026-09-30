import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// pronListen（听辨）路由的状态机。
///
/// 逐行对照原型 `app.js` 6293-6327：
/// ```js
/// const PL_PAIRS=[
///   {a:'light', b:'light', ans:'same'},
///   {a:'light', b:'right', ans:'diff'},
///   {a:'collect', b:'correct', ans:'diff'},
///   {a:'glass', b:'glass', ans:'same'}
/// ];
/// let plIdx=0, plPlaying=false, plPicked=null, plResult=null;
/// function plAnswerLbl(){ return PL_PAIRS[plIdx].ans==='same'?'相同':'不同'; }
/// function plPlayPair(){
///   if(plPlaying) return;
///   const p=PL_PAIRS[plIdx];
///   plPlaying=true; go('pronListen');
///   const say=(txt,cb)=>{
///     try{
///       const u=new SpeechSynthesisUtterance(txt);
///       u.lang='en-GB'; u.rate=.85;
///       u.onend=cb; u.onerror=cb;
///       window.speechSynthesis.speak(u);
///     }catch(e){ setTimeout(cb,700); }
///   };
///   say(p.a, ()=>{ setTimeout(()=>say(p.b, ()=>{ plPlaying=false; go('pronListen'); }), 450); });
///   setTimeout(()=>{ if(plPlaying){ plPlaying=false; go('pronListen'); } }, 4000);
/// }
/// function plPick(v){
///   if(plPlaying) return;
///   plPicked=v;
///   plResult=(v===PL_PAIRS[plIdx].ans)?'ok':'bad';
///   go('pronListen');
///   if(plResult==='ok' && plIdx<PL_PAIRS.length-1){
///     setTimeout(()=>{ plIdx++; plPicked=null; plResult=null; go('pronListen'); }, 1200);
///   }
/// }
/// ```
///
/// 音频：原型用浏览器 `SpeechSynthesisUtterance`（英音 en-GB、rate .85）依次
/// 朗读两个词，**不是振荡器**。Flutter 端等价用 `flutter_tts`，参数一字对齐。
/// 无麦克风。

/// 一组听辨词对：[a] 与 [b] 两个词、[ans] 正确答案（same / diff）。
@immutable
class PlPair {
  const PlPair(this.a, this.b, this.ans);
  final String a;
  final String b;
  final String ans; // 'same' | 'diff'
}

/// 源常量 PL_PAIRS（app.js 6293-6298），顺序、词、答案一字不改。
const List<PlPair> kPlPairs = <PlPair>[
  PlPair('light', 'light', 'same'),
  PlPair('light', 'right', 'diff'),
  PlPair('collect', 'correct', 'diff'),
  PlPair('glass', 'glass', 'same'),
];

/// 抽象出可注入的语音后端，便于测试时替换掉真实 TTS。
abstract class PlSpeaker {
  /// 依次朗读 [a] 与 [b]（对应原型 say(a) → 450ms → say(b)）。
  /// 完成（或出错兜底）后回调 [onDone]。
  Future<void> playPair(String a, String b, VoidCallback onDone);

  /// 停止当前朗读。
  Future<void> stop();
}

/// 真实 TTS 后端：flutter_tts，英音、rate .85，匹配原型 SpeechSynthesisUtterance。
class FlutterTtsSpeaker implements PlSpeaker {
  FlutterTtsSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    // 原型：u.lang='en-GB'; u.rate=.85;
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.85);
    _configured = true;
  }

  /// 朗读单个词并等待结束（等价 say(txt,cb)：u.onend=cb;u.onerror=cb）。
  /// 异常时 700ms 兜底回调（原型 catch(e){ setTimeout(cb,700); }）。
  Future<void> _say(String txt) async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      await _configure();
      _tts.setCompletionHandler(finish);
      _tts.setErrorHandler((_) => finish());
      await _tts.speak(txt);
    } catch (_) {
      Future<void>.delayed(const Duration(milliseconds: 700), finish);
    }
    // 手机浏览器的朗读可能既不出声也不回调（见 NativeOralSpeech）；一个词等这么久就往下走。
    return completer.future.timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> playPair(String a, String b, VoidCallback onDone) async {
    // say(p.a, ()=>{ setTimeout(()=>say(p.b, ()=> done ), 450); });
    await _say(a);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _say(b);
    onDone();
  }

  @override
  Future<void> stop() => _tts.stop();
}

/// 听辨控制器：完整复刻原型 pl* 状态与三处 setTimeout。
class PronListenController extends ChangeNotifier {
  PronListenController({PlSpeaker? speaker, List<PlPair>? pairs})
      : _speaker = speaker ?? FlutterTtsSpeaker(),
        pairs = pairs ?? kPlPairs;

  final PlSpeaker _speaker;
  final List<PlPair> pairs;

  // 原型：let plIdx=0, plPlaying=false, plPicked=null, plResult=null;
  int _idx = 0;
  bool _playing = false;
  String? _picked; // 'same' | 'diff' | null
  String? _result; // 'ok' | 'bad' | null

  int get idx => _idx;
  bool get playing => _playing;
  String? get picked => _picked;
  String? get result => _result;
  int get total => pairs.length;
  PlPair get current => pairs[_idx];

  Timer? _fallbackTimer;
  Timer? _advanceTimer;
  bool _disposed = false;

  /// 原型 plAnswerLbl()：same→相同 / diff→不同。
  String answerLabel() => current.ans == 'same' ? '相同' : '不同';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 原型 plPlayPair()。
  Future<void> playPair() async {
    if (_playing) return; // if(plPlaying) return;
    final p = current;
    _playing = true; // plPlaying=true; go('pronListen');
    _notify();

    // 兜底：TTS 不可用时 4 秒后复位（setTimeout(...,4000)）。
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (_playing) {
        _playing = false;
        _notify();
      }
    });

    await _speaker.playPair(p.a, p.b, () {
      // say(p.b, ()=>{ plPlaying=false; go('pronListen'); })
      _fallbackTimer?.cancel();
      _playing = false;
      _notify();
    });
  }

  /// 原型 plPick(v)。
  void pick(String v) {
    if (_playing) return; // if(plPlaying) return;
    _picked = v;
    _result = (v == current.ans) ? 'ok' : 'bad';
    _notify();
    // 答对且非最后一题 → 1200ms 后进下一题。
    if (_result == 'ok' && _idx < pairs.length - 1) {
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 1200), () {
        _idx++;
        _picked = null;
        _result = null;
        _notify();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _fallbackTimer?.cancel();
    _advanceTimer?.cancel();
    _speaker.stop();
    super.dispose();
  }
}
