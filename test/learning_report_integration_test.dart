import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/report/learning_data.dart';
import 'package:surgo_flutter/features/report/learning_details.dart';
import 'package:surgo_flutter/features/report/learning_trends.dart';
import 'package:surgo_flutter/features/report/learning_overview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
  });
  Future<AppState> mount(WidgetTester t,
      {UiLang lang = UiLang.zh,
      ExamType exam = ExamType.ielts,
      String state = 'full'}) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final app = AppState(current: SurgoPage.report, lang: lang, examType: exam)
      ..session['reportScenario'] = state;
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: SurgoShell()))));
    await t.pumpAndSettle();
    return app;
  }

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('overview three metrics sit side by side in one row', (t) async {
    for (final lang in UiLang.values) {
      await mount(t, lang: lang);
      final labels = lang == UiLang.zh
          ? ['现在的水平', '离目标还有', '最近练了多少']
          : ['Current level', 'Goal distance', 'Recent practice'];
      final rects = labels.map((x) => t.getRect(find.text(x))).toList();
      expect(rects[0].left, lessThan(rects[1].left));
      expect(rects[1].left, lessThan(rects[2].left));
      final cards = ['level', 'gap', 'practice']
          .map((s) => t.getRect(find.byKey(ValueKey('learning-metric-$s'))))
          .toList();
      expect(cards[0].right, lessThanOrEqualTo(cards[1].left));
      expect(cards[1].right, lessThanOrEqualTo(cards[2].left));
      for (final card in cards) {
        expect(card.top, cards[0].top);
        expect(card.height, cards[0].height);
        expect((card.width - cards[0].width).abs(), lessThan(1));
      }
      expect(cards[2].right, lessThanOrEqualTo(390));
      expect(
          find.descendant(
              of: find.byType(LearningOverview),
              matching: find.byType(Divider)),
          findsNothing);
    }
  });
  test('eligibility and absence rules; existing default scores unchanged', () {
    final full = LearningReportData(exam: ExamType.ielts);
    expect(full.overall, 6.3);
    expect(full.gap, .7);
    expect(full.requirements('reading', true).length, 11);
    expect(
        full.requirements('writing', true).every((r) => r.required == 5), true);
    final partial =
        LearningReportData(exam: ExamType.ielts, scenario: 'partial');
    expect(partial.scores.length, 2);
    expect(partial.overall, isNull);
    expect(partial.weeklyScores.every((n) => n == null), true);
    expect(LearningReportData(exam: ExamType.ielts, scenario: 'early').scores,
        isEmpty);
    expect(LearningReportData(exam: ExamType.toefl).maxScore, 6);
    expect(LearningReportData(exam: ExamType.ielts, scenario: 'strong').gap, 0);
    expect(
        LearningReportData(exam: ExamType.ielts, scenario: 'no_target').target,
        isNull);
  });
  for (final exam in ExamType.values) {
    for (final lang in UiLang.values) {
      testWidgets(
          'learning report ${exam.name}/${lang.name} renders all5states without zeros or overflow',
          (t) async {
        for (final state in [
          'full',
          'early',
          'partial',
          'strong',
          'no_target'
        ]) {
          await mount(t, exam: exam, lang: lang, state: state);
          final d =
              t.widget<LearningDetails>(find.byType(LearningDetails)).data;
          expect(d.scenario, state);
          expect(d.maxScore, exam == ExamType.ielts ? 9 : 6);
          if (['partial', 'early'].contains(state)) expect(d.overall, isNull);
          expect(
              find.byKey(const ValueKey('report-radar-paint')), findsOneWidget);
          expect(t.takeException(), isNull);
        }
      });
    }
  }
  testWidgets(
      'radar selects only; skill row toggles evidence; sources explain5/90/30',
      (t) async {
    final app = await mount(t);
    final revision = app.revision;
    await tap(t, 'learning-axis-listening');
    expect(t.widget<LearningDetails>(find.byType(LearningDetails)).selected,
        'listening');
    expect(find.byKey(const ValueKey('learning-evidence-listening')),
        findsNothing);
    await tap(t, 'learning-skill-writing');
    expect(find.byKey(const ValueKey('learning-evidence-writing')),
        findsOneWidget);
    await tap(t, 'learning-skill-writing');
    expect(
        find.byKey(const ValueKey('learning-evidence-writing')), findsNothing);
    await tap(t, 'learning-source');
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.textContaining('5次有效评分'), findsOneWidget);
    expect(find.textContaining('近90天'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('learning-dialog-done')));
    await t.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(app.revision, revision);
  });
  testWidgets(
      'estimate modal closes both ways; goal edits report; advice and week selection',
      (t) async {
    final app = await mount(t, state: 'no_target');
    await tap(t, 'learning-estimate');
    expect(find.textContaining('正式成绩以考试机构'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('learning-dialog-close')));
    await t.pumpAndSettle();
    await tap(t, 'learning-set-goal');
    await t.tap(find.byKey(const ValueKey('learning-target-value')));
    await t.pumpAndSettle();
    await t.tap(find.text('7.5').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('learning-target-save')));
    await t.pumpAndSettle();
    expect(
        t.widget<LearningOverview>(find.byType(LearningOverview)).data.target,
        7.5);
    await tap(t, 'advice-tab-writing');
    expect(t.widget<LearningDetails>(find.byType(LearningDetails)).selected,
        'writing');
    await tap(t, 'teacher-expand');
    expect(find.text('收起全文'), findsOneWidget);
    await tap(t, 'advice-more');
    expect(find.byKey(const ValueKey('advice-more')), findsOneWidget);
    final week = find.byKey(const ValueKey('trend-week-7')).last;
    await t.ensureVisible(week);
    await t.pumpAndSettle();
    await t.tap(week);
    await t.pumpAndSettle();
    expect(
        t.widget<LearningTrends>(find.byType(LearningTrends)).scores.last, 6.3);
    await tap(t, 'advice-practice-writing-1');
    expect(app.current, SurgoPage.writingDaily);
    expect(app.examType, ExamType.ielts);
    expect(t.takeException(), isNull);
  });
}
