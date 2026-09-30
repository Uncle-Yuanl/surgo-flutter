// 托福听力的真音频（演示用真实数据 demo_data/，tool/demo_export 导出）：
// 数据里每个 clip（{ asset, sec }）指的录音文件都在；没有播放器的地方（测试、原生端）带着 clip 的数据
// 照旧走原型的计时模拟。真的出声那一半要在浏览器里看（tool/demo_export/README.md「验证」）。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/features/tf_listening_daily/controller.dart';
import 'package:surgo_flutter/features/tf_listening_mock/controller.dart';

Map<String, dynamic> demo(String file) =>
    jsonDecode(File('demo_data/$file').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final daily = demo('tf_listening_daily.json');
  final mock = demo('tf_listening_mock.json');
  final modules = mock['modules'] as Map<String, dynamic>;

  test('every clip in the demo data is an exported MP3, named without ids', () {
    // 做题页的每一段、批改页的每张题卡。
    final items = <Map>[
      for (final kind in daily.values) ...[...kind['segments'] as List, ...kind['questions'] as List],
      for (final module in modules.values) ...module['segments'] as List,
      for (final cards in (mock['feedback']['qs'] as Map).values) ...cards as List,
    ].cast<Map>();
    final clips = [for (final item in items) if (item['clip'] != null) item['clip'] as Map];
    expect(clips, isNotEmpty);
    for (final clip in clips) {
      final asset = clip['asset'] as String;
      expect(asset, matches(RegExp(r'^assets/data/aud_tf_listening_[a-z0-9]+(_[a-z0-9]+)*_\d+\.mp3$')));
      expect(clip['sec'] as num, greaterThan(0), reason: asset);
      final file = File('demo_data/${asset.split('/').last}');
      expect(file.existsSync(), true, reason: '$asset is not in demo_data/');
      // MP3：ID3 标签，或者直接是帧同步字。
      final bytes = file.openSync();
      final head = bytes.readSync(3);
      bytes.closeSync();
      expect(String.fromCharCodes(head) == 'ID3' || (head[0] == 0xff && head[1] & 0xe0 == 0xe0), true, reason: asset);
    }
    // 做题页放的和批改页放的是同一段。
    const cards = {'r': 'listen', 'c': 'conv', 'a': 'ann', 't': 'talk', 'r2': 'm2p1', 'c2': 'm2p2', 'a2': 'm2p3'};
    (mock['feedback']['qs'] as Map).forEach((type, list) {
      final segments = modules[cards[type]]['segments'] as List;
      expect([for (final q in list as List) q['clip']], [for (final s in segments) s['clip']], reason: '$type');
    });
    for (final kind in daily.values) {
      expect([for (final q in kind['questions'] as List) q['clip']], [for (final s in kind['segments'] as List) s['clip']]);
    }
  });

  test('without a player the clip-carrying data still runs the timed simulation', () {
    for (final entry in daily.entries) {
      final c = TfListeningController(AppState(), entry.key, entry.value as Map<String, dynamic>);
      expect(c.clip, isNull, reason: entry.key); // 测试里没有播放器，数据里有 clip 也不走真音频
      expect(c.sounding, true);
      final sec = c.current['sec'] as int;
      for (var i = 1; i < sec; i++) {
        c.audioTick();
        expect((c.phase, c.audio, c.progress), ('play', i, i / sec), reason: entry.key);
      }
      c.audioTick();
      expect((c.phase, c.audio, c.sounding), ('ready', sec, false), reason: entry.key);
      c.seek(-15);
      expect(c.audio, sec > 15 ? sec - 15 : 0);
      c.toggle(); // 原型：播放键就是从头重播
      expect((c.phase, c.audio), ('play', 0));
      c.setRate(4);
      expect(c.audioInterval, 500);
    }
    for (final entry in modules.entries) {
      final c = TfMockController(AppState(), entry.value as Map<String, dynamic>);
      expect(c.clip, isNull, reason: entry.key);
      for (var i = 1; i < c.curSec; i++) {
        c.audioTick();
        expect((c.phase, c.audio, c.progress), ('play', i, i / c.curSec), reason: entry.key);
      }
      c.audioTick();
      expect((c.phase, c.audio, c.left), ('answer', c.curSec, c.answerSec), reason: entry.key);
    }
  });
}
