import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/js_replacement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oracle = jsonDecode(File('test/fixtures/translation_oracle.json').readAsStringSync()) as Map;
  setUpAll(() async { await Translator.load(); await QuestionBank.load(); });
  test('all original applyLang outputs, exact/regex/unmatched and whitespace', () {
    for (final row in oracle['cases'] as List) {
      final input = row['input'] as String;
      final lang = row['lang'] == 'en' ? UiLang.en : UiLang.zh;
      expect(Translator.instance.translate(input, lang) ?? input, row['expected'],
        reason: '${row['lang']}: ${jsonEncode(input)}');
    }
  });
  test('all original regex replacements including JS captures and concatenation', () {
    for (final row in oracle['regex'] as List) {
      final flags = row['flags'] as String;
      expect(jsReplace(row['input'], jsRegExp(row['pattern'], flags), row['replacement'], global: flags.contains('g')),
          row['expected'], reason: '${row['pattern']} => ${row['replacement']}');
    }
  });
  test('all four runtime-exported dictionaries are present', () {
    final data = jsonDecode(File('assets/data/i18n.json').readAsStringSync());
    expect((data['SURGO_EN'] as Map).length, 949);
    expect((data['SURGO_ZH'] as Map).length, 428);
    expect((data['SURGO_EN_RE'] as List).length, 62);
    expect((data['SURGO_ZH_RE'] as List).length, 32);
    expect(Translator.instance.trStr('1 万'), '10,000');
    expect(Translator.instance.trStr('你即将进入模块 2。请继续。'), "You're about to start module 2. 请继续。");
  });
  test('question asset and loaded banks have identical nested data', () {
    final data = jsonDecode(File('assets/data/questions.json').readAsStringSync());
    expect(QuestionBank.instance.ielts, data['ielts']);
    expect(QuestionBank.instance.toefl, data['toefl']);
  });
}
