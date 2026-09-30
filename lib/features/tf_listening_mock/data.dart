import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads the TOEFL listening MOCK question bank exported from the authoritative
/// sibling `app.js` (see tool/export_tf_listening_mock.cjs). Everything here is
/// verbatim source data: segments, per-question audio lengths, the fixed
/// feedback report and transcript. Nothing is generated at runtime.
class TfListeningMockData {
  static Map<String, dynamic>? _cache;
  // 不用 rootBundle.loadString：它对 50 KB 以上的文件在非 web 平台开 isolate 解码，
  // widget 测试的假时钟等不到结果，页面会一直转圈（演示用真实数据的这份 JSON 约 70 KB）。
  static Future<Map<String, dynamic>> load() async => _cache ??= jsonDecode(
          utf8.decode(Uint8List.sublistView(
              await rootBundle.load('assets/data/tf_listening_mock.json'))))
      as Map<String, dynamic>;
}
