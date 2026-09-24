import 'package:flutter_test/flutter_test.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/reading_wizard/reading_wizard_controller.dart';
import 'package:surgo_flutter/features/reading_wizard/reading_gen_overlay.dart';

/// 阅读日常训练向导 —— 覆盖原型 `doGenSession('reading')` 的全部「任务 → 目标页」规则：
///
/// ```js
/// if(examType==='toefl' && key==='reading'){ tfBriefMod='reading'; go('tfBrief'); return; }
/// if(key==='reading'){ go(selReadType ? 'typeSession' : 'readingSession'); }
/// ```
/// 以及 pickPracticeMode / pickReadType 对 selReadType 的影响。
void main() {
  ReadingWizardController make(ExamType exam) =>
      ReadingWizardController(AppState(examType: exam));

  group('IELTS 阅读向导：任务 → 目标页', () {
    test('进入即 full 模式、selReadType 为空 → readingSession', () {
      final c = make(ExamType.ielts);
      expect(c.readMode, 'full');
      expect(c.selReadType, isNull);
      expect(c.resolveTarget(), SurgoPage.readingSession);
    });

    test('选专注单一 + 选题型 → typeSession', () {
      final c = make(ExamType.ielts);
      c.pickPracticeMode('single');
      c.pickReadType('mc');
      expect(c.readMode, 'single');
      expect(c.selReadType, 'mc');
      expect(c.resolveTarget(), SurgoPage.typeSession);
    });

    test('每个 RTYPES 题型选中后都路由到 typeSession', () {
      for (final key in const ['mc', 'tfng', 'yyng', 'imatch', 'hmatch', 'fmatch', 'ematch', 'scomplete', 'summary', 'diagram', 'short']) {
        final c = make(ExamType.ielts);
        c.pickReadType(key);
        expect(c.selReadType, key);
        expect(c.readMode, 'single');
        expect(c.resolveTarget(), SurgoPage.typeSession, reason: 'type=$key');
      }
    });

    test('切回练习整篇会清空 selReadType → readingSession', () {
      final c = make(ExamType.ielts);
      c.pickReadType('summary');
      expect(c.resolveTarget(), SurgoPage.typeSession);
      c.pickPracticeMode('full');
      expect(c.selReadType, isNull);
      expect(c.readMode, 'full');
      expect(c.resolveTarget(), SurgoPage.readingSession);
    });
  });

  group('TOEFL 阅读向导：任务 → 目标页', () {
    test('无论选哪个任务/难度都先进 tfBrief', () {
      for (final task in const ['wordfill', 'liferead', 'acadread']) {
        for (final diff in const ['low', 'std', 'high']) {
          final c = make(ExamType.toefl);
          c.pickTfReadTask(task);
          c.pickTfReadDiff(diff);
          expect(c.tfReadTask, task);
          expect(c.tfReadDiff, diff);
          expect(c.resolveTarget(), SurgoPage.tfBrief, reason: '$task/$diff');
        }
      }
    });

    test('TOEFL 侧 selReadType 不影响目标页（始终 tfBrief）', () {
      final c = make(ExamType.toefl);
      c.pickTfReadTask('acadread');
      expect(c.resolveTarget(), SurgoPage.tfBrief);
    });

    test('默认选择：wordfill / std', () {
      final c = make(ExamType.toefl);
      expect(c.tfReadTask, 'wordfill');
      expect(c.tfReadDiff, 'std');
    });
  });

  group('commitAndGo 写入原始 JS 变量名到 session', () {
    test('IELTS full → readingSession + session 快照', () {
      final s = AppState(examType: ExamType.ielts);
      final c = ReadingWizardController(s);
      c.commitAndGo();
      expect(s.current, SurgoPage.readingSession);
      expect(s.session['sessionKey'], 'reading');
      expect(s.session['sessionMode'], 'daily');
      expect(s.session['readIdx'], 0);
      expect(s.session['typeIdx'], 0);
      expect(s.session['lisIdx'], 0);
      expect(s.session['readMode'], 'full');
      expect(s.session['selReadType'], isNull);
      expect(s.session.containsKey('tfBriefMod'), isFalse);
    });

    test('IELTS single → typeSession + selReadType 落库', () {
      final s = AppState(examType: ExamType.ielts);
      final c = ReadingWizardController(s);
      c.pickReadType('hmatch');
      c.commitAndGo();
      expect(s.current, SurgoPage.typeSession);
      expect(s.session['selReadType'], 'hmatch');
      expect(s.session['readMode'], 'single');
    });

    test('TOEFL → tfBrief + tfBriefMod/tfReadTask/tfReadDiff 落库', () {
      final s = AppState(examType: ExamType.toefl);
      final c = ReadingWizardController(s);
      c.pickTfReadTask('liferead');
      c.pickTfReadDiff('high');
      c.commitAndGo();
      expect(s.current, SurgoPage.tfBrief);
      expect(s.session['tfBriefMod'], 'reading');
      expect(s.session['tfReadTask'], 'liferead');
      expect(s.session['tfReadDiff'], 'high');
      expect(s.session['sessionKey'], 'reading');
      expect(s.session['sessionMode'], 'daily');
    });
  });

  group('生成动画时长常量与原型一致', () {
    test('DUR=2000ms、尾延迟=220ms', () {
      expect(ReadingGenOverlay.genDuration, const Duration(milliseconds: 2000));
      expect(ReadingGenOverlay.tailDelay, const Duration(milliseconds: 220));
    });
  });
}
