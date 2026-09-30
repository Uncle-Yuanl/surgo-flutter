import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/features/tf_speaking_daily/controller.dart';
import 'package:surgo_flutter/widgets/demo_audio.dart';

// 演示用真实数据的段带着 audio（{ asset, sec }）。放不了真音频的地方（这里的 widget 测试、原生端：
// demoAudio.available 为 false）必须仍是原型的计时模拟，音频卡的三个键也照原型的算法走。
void main() {
  test('段上带 audio 而放不了真音频：仍是原型的计时模拟', () {
    expect(demoAudio.available, false);
    final c = TfSpeakingController(AppState(), 'retell', {
      'prefix': 'tfRt', 'total': 2, 'ansSec': 7, 'rates': [0.75, 1, 1.25, 1.5],
      'segments': [
        {'sec': 3, 'ansSec': 8, 'audio': {'asset': 'assets/data/aud_x.mp3', 'sec': 3.4}},
        {'sec': 4, 'ansSec': 8, 'audio': {'asset': 'assets/data/aud_y.mp3', 'sec': 4.3}},
      ],
    });
    expect(c.clip, isNull);
    expect(c.playing, true);
    c.audioTick();
    expect([c.audio, c.phase, c.progress], [1, 'play', 1 / 3]);
    c.audioTick();
    c.audioTick();
    expect([c.audio, c.phase, c.playing], [3, 'ready', false]);
    // 快退只挪进度、不动阶段；播放键就是重播。
    c.skip(-15);
    expect([c.audio, c.phase], [0, 'ready']);
    c.skip(2);
    c.toggle();
    expect([c.audio, c.phase], [0, 'play']);
    c.setRate(3);
    expect(c.audioInterval, 667);
    c.begin();
    c.audioTick();
    expect([c.phase, c.left], ['answer', 8]);
  });
}
