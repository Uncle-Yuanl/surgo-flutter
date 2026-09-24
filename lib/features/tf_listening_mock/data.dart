import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads the TOEFL listening MOCK question bank exported from the authoritative
/// sibling `app.js` (see tool/export_tf_listening_mock.cjs). Everything here is
/// verbatim source data: segments, per-question audio lengths, the fixed
/// feedback report and transcript. Nothing is generated at runtime.
class TfListeningMockData {
  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>> load() async => _cache ??=
      jsonDecode(await rootBundle.loadString('assets/data/tf_listening_mock.json'))
          as Map<String, dynamic>;
}
