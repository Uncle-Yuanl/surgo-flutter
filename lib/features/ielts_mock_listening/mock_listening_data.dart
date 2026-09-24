import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';

/// Loads assets/data/ielts_mock_listening.json (exported byte-for-byte from
/// surgo-mobile-new/app.js mockListeningQ*View + lisMapSvg).
class MockListeningData {
  MockListeningData(this.raw);
  final Map<String, dynamic> raw;
  static MockListeningData? cache;
  static Future<MockListeningData> load() async =>
      cache ??= MockListeningData(jsonDecode(await rootBundle.loadString(
          'assets/data/ielts_mock_listening.json')) as Map<String, dynamic>);

  int get sharedTimerSec => raw['sharedTimerSec'] as int;
  int get reviewSec => raw['reviewSec'] as int;
  String get mapSvg => raw['mapSvg'] as String;
  List get parts => raw['parts'] as List;
  Map<String, dynamic> part(int no) =>
      Map<String, dynamic>.from(parts.firstWhere((p) => p['no'] == no) as Map);
  String markLabel(int n) =>
      (raw['markLabelTemplate'] as String).replaceAll('{n}', '$n');
}

/// Which mock-listening page maps to which part number.
const Map<SurgoPage, int> mockListeningPartOf = {
  SurgoPage.mockListeningQ: 1,
  SurgoPage.mockListeningQ2: 2,
  SurgoPage.mockListeningQ3: 3,
  SurgoPage.mockListeningQ4: 4,
};

/// Only mockLeft is shared. Source choices, inputs and answer dots live in
/// the current DOM and are recreated blank on every render/part navigation.
class MockListeningController {
  MockListeningController(this.app, this.data, this.part) {
    // startMockTimer(id==='mockListeningQ'): reset to 30:00 on Part 1 only.
    if (part == 1) {
      app.session['mockLeft'] = data.sharedTimerSec;
    }
    app.session['mockLeft'] ??= data.sharedTimerSec;
    meta = data.part(part);
  }
  final AppState app;
  final MockListeningData data;
  final int part;
  late final Map<String, dynamic> meta;
  final Map<int, dynamic> ans = <int, dynamic>{};
  final Set<int> done = <int>{};

  int get left => (app.session['mockLeft'] as int?) ?? data.sharedTimerSec;

  /// Every mock part covers 10 answers.
  int get dotFrom => meta['dotFrom'] as int;
  List<int> get dots => List.generate(10, (i) => dotFrom + i);

  void pickMc(int n, int optIndex) {
    ans[n] = optIndex;
    done.add(n);
  }

  void pickMatch(int n, String letter) {
    ans[n] = letter;
    done.add(n);
  }

  void fill(int n, String text) {
    ans[n] = text; // The input itself retains whitespace; only the dot trims.
    if (text.trim().isEmpty) {
      done.remove(n);
    } else {
      done.add(n);
    }
  }

  /// Shared 30:00 countdown tick. Returns true once time expires.
  bool tick() {
    final cur = left;
    if (cur > 0) {
      app.session['mockLeft'] = cur - 1;
      return cur - 1 <= 0;
    }
    return true;
  }

  /// Answered count in the current rendered part only.
  int get answeredAll => done.length;
}
