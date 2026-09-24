import 'package:flutter_test/flutter_test.dart';

import 'package:surgo_flutter/app/routes.dart';

/// 这批测试唯一的目的：**守住"不能改动"这条线**。
///
/// 原型 app.js 里 `const V` 注册表有 141 个页面键，快速核对时容易漏或改名。
/// 页面键是路由、定时器、软背景、底部导航这四张清单的交集基础，
/// 一旦少一个键，对应页面就会静默失效（原型的 `if(!V[id])return;` 就是静默返回）。
void main() {
  group('页面清单与原型对齐', () {
    test('页面总数是 141（原型 V 注册表条目数）', () {
      // 用户 2026-09-25：新增 13 个登录注册页（Figma gW9DKhEd6UuQQAnv32BlXH · Page 5）。
      // 原型 app.js 里没有这批页面，所以它们不计入 141。
      // 这条断言守的仍然是「原型页面一个不少、一个不多」——把新增页排除后再比。
      final prototype =
          SurgoPage.values.where((p) => !kAuthPages.contains(p)).toList();
      expect(prototype.length, 141);
      expect(kAuthPages.length, 13);
      expect(SurgoPage.values.length, 141 + 13);
    });

    test('页面键唯一', () {
      final keys = SurgoPage.values.map((p) => p.name).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('键名可从字符串反查（路由/深链用）', () {
      expect(SurgoPageX.fromKey('ielts'), SurgoPage.ielts);
      expect(SurgoPageX.fromKey('mockWritingQ'), SurgoPage.mockWritingQ);
      // 原型里不存在的键应当返回 null，而不是抛异常
      expect(SurgoPageX.fromKey('noSuchPage'), isNull);
    });

    test('底部导航只出现在 ielts / report / prep 三页', () {
      expect(kNavPages.length, 3);
      expect(kNavPages, contains(SurgoPage.ielts));
      expect(kNavPages, contains(SurgoPage.report));
      expect(kNavPages, contains(SurgoPage.prep));
    });

    test('雅思模考作答页共 7 页（EXAM_PAGES）', () {
      expect(kExamPages.length, 7);
      expect(kExamPages, contains(SurgoPage.mockReadingQ));
      expect(kExamPages, contains(SurgoPage.mockSpeakingQ));
    });

    test('软背景页面都在页面清单内（SOFT_PAGES 与 V 的键一致）', () {
      for (final p in kSoftPages) {
        expect(SurgoPage.values, contains(p));
      }
      // 原型 SOFT_PAGES 是一串字符串，长度应与这里一致
      expect(kSoftPages.length, greaterThan(100));
    });
  });
}