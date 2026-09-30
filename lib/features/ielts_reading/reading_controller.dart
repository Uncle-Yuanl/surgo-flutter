import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';

class ReadingData {
  ReadingData(this.raw);
  final Map<String, dynamic> raw;
  static ReadingData? cache;
  // 直接读字节再解码：rootBundle.loadString 对 50 KB 以上的文件会另起 isolate 解码，
  // widget 测试（路由审计）的假时钟等不到它；演示用真实数据的这个文件超过了 50 KB。
  static Future<ReadingData> load() async =>
      cache ??= ReadingData(jsonDecode(utf8.decode(Uint8List.sublistView(
          await rootBundle.load('assets/data/ielts_reading.json')))));
  List<Map<String, dynamic>> get types =>
      (raw['types'] as List).cast<Map<String, dynamic>>();
}

/// Mirrors readIdx/typeIdx and readDone/typeDone. Original DOM selections are
/// discarded when refreshReadBody/refreshTypeBody replaces innerHTML. Preserve
/// that behavior: only the answered set persists, NOT answer values or scoring.
class ReadingController {
  ReadingController(this.state, this.data,
      {required this.single, this.auditSeconds}) {
    final key = state.session['selReadType'];
    type = data.types
        .firstWhere((t) => t['key'] == key, orElse: () => data.types.first);
    final r = QuestionBank.instance.skill('reading', state.examType);
    article =
        single ? (type['article'] ?? data.raw['fallbackArticle']) : r['daily'];
    items = single ? type['items'] : (r['daily']['questions'] as List);
    index = (state.session[single ? 'typeIdx' : 'readIdx'] as int? ?? 0)
        .clamp(0, items.length - 1);
    final stored = state.session[single ? 'typeDone' : 'readDone'];
    done =
        stored is Set<int> ? stored : Set<int>.from(stored as Iterable? ?? []);
    state.session[single ? 'typeDone' : 'readDone'] = done;
    final seconds = single ? ((type['mins'] ?? 9) * 60).round() : 1200;
    // Source parseInt(minutes)||20: retain even this zero-minute edge behavior.
    left = auditSeconds ??
        (((seconds ~/ 60) == 0 ? 20 : seconds ~/ 60) * 60 + seconds % 60);
  }
  final AppState state;
  final ReadingData data;
  final bool single;
  // Explicit injection only for the separate visual-audit entry; null in production.
  final int? auditSeconds;
  late Map<String, dynamic> type, article;
  late List items;
  late Set<int> done;
  late int index, left;
  int overtime = 0, used = 0;
  bool fired = false;
  String? selected;
  String input = '';
  int get total => items.length;
  bool get last => index == total - 1;
  String get kind {
    if (single) return type['kind'] as String? ?? 'mc';
    final q = items[index];
    if (q['type'] == 'tfng' || q['type'] == 'ynng') return q['type'];
    return q['opts'] != null ? 'mc' : 'gap';
  }

  dynamic get item => items[index];
  List<String> get options {
    if (kind == 'mc') return List<String>.from(item['opts']);
    if (kind == 'ynng') return ['Yes', 'No', 'Not Given'];
    if (kind == 'tfng') {
      return List<String>.from(single
          ? (type['opts3'] ?? ['True', 'False', 'Not Given'])
          : ['True', 'False', 'Not Given']);
    }
    if (kind == 'match') return List<String>.from(type['options']);
    return [];
  }

  String get question => single
      ? (item is Map
          ? item['q']
          : item is List
              ? item.join('________')
              : item)
      : '${index + 1}. ${item['q']}';
  void mark() {
    done.add(index);
  }

  void pick(String value) {
    selected = value;
    mark();
  }

  // Original single-type inline gaps have NO onchange (boxInput/diagram do).
  void commitInput(String text) {
    input = text;
    if (!single || type['boxInput'] == true || type['diagramSvg'] != null) {
      mark();
    }
  }

  void jump(int to) {
    if (to < 0 || to >= total) return;
    index = to;
    state.session[single ? 'typeIdx' : 'readIdx'] = to;
    selected = null;
    input = '';
    used = 0;
  }

  bool tick() {
    used++;
    if (left > 0) {
      left--;
      if (left == 0 && !fired) {
        fired = true;
        return true;
      }
    } else {
      overtime++;
    }
    return false;
  }

  String get clock {
    final v = left > 0 ? left : overtime;
    return '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
  }
}
