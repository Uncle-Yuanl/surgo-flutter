import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/pron_course/pron_course_module.dart';

/// pronCourse / pronLesson 两条路由的原生实现测试。
///
/// 断言点全部锚定原型源常量（_extract/logic/fns/pronCourseView.js /
/// pronLessonView.js），确保迁移未偷改文案、步骤、词对与解锁规则。
Future<void> _pump(WidgetTester tester, Widget body, AppState state) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: body),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // T 组件走 Translator.instance；先加载词典避免命中断言。
    await Translator.load();
  });

  group('buildPronCoursePage 路由分发', () {
    test('只认领 pronCourse / pronLesson，其余返回 null', () {
      expect(buildPronCoursePage(SurgoPage.pronCourse), isNotNull);
      expect(buildPronCoursePage(SurgoPage.pronLesson), isNotNull);
      expect(buildPronCoursePage(SurgoPage.pronListen), isNull);
      expect(buildPronCoursePage(SurgoPage.pron2Lesson), isNull);
      expect(buildPronCoursePage(SurgoPage.ielts), isNull);
    });
  });

  group('源常量与原型对齐', () {
    test('pronLesson 步骤 = 讲解/听辨/单词跟读/句子练习/完成', () {
      expect(kPronLessonSteps,
          ['讲解', '听辨', '单词跟读', '句子练习', '完成']);
    });

    test('pronLesson 对比词对 3 组（源 pronLessonView.js）', () {
      expect(kPronLessonPairs, [
        ['light', 'right', '/laɪt/', '/raɪt/'],
        ['load', 'road', '/ləʊd/', '/rəʊd/'],
        ['collect', 'correct', '/kəˈlekt/', '/kəˈrekt/'],
      ]);
    });
  });

  group('pronCourse 页渲染与解锁规则', () {
    testWidgets('未完成：徽章 0/2、两模块均“未开始”', (tester) async {
      final state = AppState(); // session 无 pronM1Done → done=false
      await _pump(tester, buildPronCoursePage(SurgoPage.pronCourse)!, state);

      expect(find.text('发音训练'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(find.text('第 1 阶段'), findsOneWidget);
      expect(find.text('第 2 阶段'), findsOneWidget);
      expect(find.text('未开始'), findsNWidgets(2));
      expect(find.text('已完成'), findsNothing);
    });

    testWidgets('已完成：徽章 1/2、阶段 1“已完成”', (tester) async {
      final state = AppState()..session[kPronM1DoneKey] = true;
      await _pump(tester, buildPronCoursePage(SurgoPage.pronCourse)!, state);

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget); // 阶段 1 状态
      expect(find.text('未开始'), findsOneWidget); // 阶段 2 仍未开始
    });

    testWidgets('阶段 1 恒可点，跳 pronLesson', (tester) async {
      final state = AppState();
      await _pump(tester, buildPronCoursePage(SurgoPage.pronCourse)!, state);

      await tester.tap(find.text('/l/ 与 /r/ —— 发音要领'));
      await tester.pump();
      expect(state.current, SurgoPage.pronLesson);
    });

    testWidgets('未完成时阶段 2 锁定：点击不跳转', (tester) async {
      final state = AppState();
      await _pump(tester, buildPronCoursePage(SurgoPage.pronCourse)!, state);

      await tester.tap(find.text('个性化 /l/·/r/ 词汇练习'));
      await tester.pump();
      expect(state.current, SurgoPage.ielts); // 默认页未变
    });

    testWidgets('已完成时阶段 2 解锁：跳 pron2Lesson', (tester) async {
      final state = AppState()..session[kPronM1DoneKey] = true;
      await _pump(tester, buildPronCoursePage(SurgoPage.pronCourse)!, state);

      await tester.tap(find.text('个性化 /l/·/r/ 词汇练习'));
      await tester.pump();
      expect(state.current, SurgoPage.pron2Lesson);
    });
  });

  group('pronLesson 页渲染与跳转', () {
    testWidgets('标题、步骤、讲解卡、词对齐全', (tester) async {
      final state = AppState();
      await _pump(tester, buildPronCoursePage(SurgoPage.pronLesson)!, state);

      expect(find.text('/l/ 与 /r/ —— 发音要领'), findsOneWidget);
      expect(find.text('/l/ vs /r/ — articulation'), findsOneWidget);
      expect(find.text('1 讲解'), findsOneWidget);
      expect(find.text('2 听辨'), findsOneWidget);
      expect(find.text('对比词对'), findsOneWidget);
      // 三组对比词对的左词
      expect(find.text('light'), findsOneWidget);
      expect(find.text('road'), findsOneWidget);
      expect(find.text('collect'), findsOneWidget);
    });

    testWidgets('底部“下一步：听辨”跳 pronListen', (tester) async {
      final state = AppState();
      await _pump(tester, buildPronCoursePage(SurgoPage.pronLesson)!, state);

      await tester.ensureVisible(find.text('下一步：听辨'));
      await tester.tap(find.text('下一步：听辨'));
      await tester.pump();
      expect(state.current, SurgoPage.pronListen);
    });

    testWidgets('步骤条“2 听辨”可点跳 pronListen', (tester) async {
      final state = AppState();
      await _pump(tester, buildPronCoursePage(SurgoPage.pronLesson)!, state);

      await tester.tap(find.text('2 听辨'));
      await tester.pump();
      expect(state.current, SurgoPage.pronListen);
    });
  });
}
