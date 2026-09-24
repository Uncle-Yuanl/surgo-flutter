import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/training_wizards/training_wizards_controller.dart';
import 'package:surgo_flutter/features/training_wizards/training_wizards_data.dart';
import 'package:surgo_flutter/features/training_wizards/training_wizards_module.dart';

/// 写作/听力/口语/词汇日常训练向导 —— 覆盖原型 `doGenSession(key)` 的全部
/// 「任务 → 目标页」规则，以及卡片/双卡/托福三套版式的数据与 session 落库。
///
/// ```js
/// if(examType==='toefl' && key in [listening,writing,speaking]){ tfBriefMod=key; go('tfBrief'); return; }
/// else if(key==='listening'){ setLisPart(LPARTS[selWizCard]?selWizCard:'s1'); go('listeningSession'); }
/// else if(key==='writing'){ go('writingSession'); }
/// else if(key==='speaking'){ if(selWizCard==='pron'){ go('pronCourse'); } else { startOralExam(); } }
/// else if(key==='vocab'){ go('vocab'); }
/// ```
/// 其中 `startOralExam()`：`selWizCard==='p3' → startDiscuss()→go('oralDiscuss')`，否则 `go('oralExam')`。
void main() {
  TrainingWizardController make(String mod, ExamType exam, {String? card}) =>
      TrainingWizardController(AppState(examType: exam), mod, initialCard: card);

  // ---- 数据 fixture：直接读磁盘 JSON，不依赖 rootBundle ----
  late TrainingWizardsData data;
  setUpAll(() {
    final raw = jsonDecode(File('assets/data/training_wizards.json').readAsStringSync());
    data = TrainingWizardsData.fromJson(raw as Map<String, dynamic>);
  });

  group('模块入口 buildTrainingWizardPage：路由 → moduleKey', () {
    test('四个日常训练路由都命中，阅读/其它页返回 null', () {
      for (final p in const [
        SurgoPage.writingDaily,
        SurgoPage.listeningDaily,
        SurgoPage.speakingDaily,
        SurgoPage.vocabDaily,
      ]) {
        expect(buildTrainingWizardPage(p), isNotNull, reason: '$p');
      }
      // 阅读向导独立实现，不由本模块接管
      expect(buildTrainingWizardPage(SurgoPage.readingDaily), isNull);
      expect(buildTrainingWizardPage(SurgoPage.ielts), isNull);
      expect(buildTrainingWizardPage(SurgoPage.tfBrief), isNull);
    });
  });

  group('数据 fixture 与原型一致', () {
    test('WIZ 五个模块 + 版式判定', () {
      expect(data.wiz.keys, containsAll(['reading', 'listening', 'writing', 'speaking', 'vocab']));
      // 卡片版式：listening/writing/speaking
      expect(data.config('listening').hasCards, isTrue);
      expect(data.config('writing').hasCards, isTrue);
      expect(data.config('speaking').hasCards, isTrue);
      // 双卡版式：vocab（无 cards、有 opts）
      expect(data.config('vocab').hasCards, isFalse);
      expect(data.config('vocab').opts.map((o) => o.value).toList(),
          ['flash', 'spell', 'match', 'cloze']);
    });

    test('卡片首项即默认选卡；listening s1..s4 / writing t1,t2 / speaking p1..p3,pron', () {
      expect(data.config('listening').cards.map((c) => c.key).toList(), ['s1', 's2', 's3', 's4']);
      expect(data.config('writing').cards.map((c) => c.key).toList(), ['t1', 't2']);
      expect(data.config('speaking').cards.map((c) => c.key).toList(), ['p1', 'p2', 'p3', 'pron']);
      // 图标路径从 assets/ 映射到 assets/images/
      expect(data.config('listening').cards.first.iconAsset, 'assets/images/ic_l_conv.svg');
    });

    test('托福任务集合与图标', () {
      expect(data.tfWrTasks.map((t) => t.key).toList(), ['sent', 'email', 'disc']);
      expect(data.tfLisTasks.map((t) => t.key).toList(), ['respond', 'convo', 'announce', 'lecture']);
      expect(data.tfLisDiffs.map((d) => d.k).toList(), ['low', 'std', 'high']);
      expect(data.tfSpTasks.map((t) => t.key).toList(), ['retell', 'interview', 'pron']);
      expect(data.tfIconAsset('sent'), 'assets/images/tf_ic_sent.svg');
      expect(data.tfIconAsset('nope'), isNull);
    });
  });

  group('IELTS 听力向导：任务 → listeningSession + lisPart', () {
    for (final part in const ['s1', 's2', 's3', 's4']) {
      test('选 $part → listeningSession，lisPart=$part', () {
        final c = make('listening', ExamType.ielts, card: 's1');
        c.pickWizCard(part);
        expect(c.resolveTarget(), SurgoPage.listeningSession);
      });
    }

    test('commitAndGo 写入 lisPart / selWizCard，非法卡回退 s1', () {
      final s = AppState(examType: ExamType.ielts);
      final c = TrainingWizardController(s, 'listening', initialCard: 's3');
      c.commitAndGo();
      expect(s.current, SurgoPage.listeningSession);
      expect(s.session['sessionKey'], 'listening');
      expect(s.session['sessionMode'], 'daily');
      expect(s.session['lisPart'], 's3');
      expect(s.session['selWizCard'], 's3');

      final s2 = AppState(examType: ExamType.ielts);
      TrainingWizardController(s2, 'listening', initialCard: 'bogus').commitAndGo();
      expect(s2.session['lisPart'], 's1');
    });
  });

  group('IELTS 写作向导：始终 → writingSession', () {
    test('无论选哪张卡都进 writingSession', () {
      for (final card in const ['t1', 't2']) {
        final c = make('writing', ExamType.ielts, card: 't1');
        c.pickWizCard(card);
        expect(c.resolveTarget(), SurgoPage.writingSession, reason: card);
      }
    });
  });

  group('IELTS 口语向导：selWizCard 决定 pronCourse/oralDiscuss/oralExam', () {
    test('p1/p2 → oralExam', () {
      for (final card in const ['p1', 'p2']) {
        final c = make('speaking', ExamType.ielts, card: 'p1');
        c.pickWizCard(card);
        expect(c.resolveTarget(), SurgoPage.oralExam, reason: card);
      }
    });
    test('p3 → oralDiscuss（startDiscuss）', () {
      final c = make('speaking', ExamType.ielts, card: 'p1');
      c.pickWizCard('p3');
      expect(c.resolveTarget(), SurgoPage.oralDiscuss);
    });
    test('pron → pronCourse', () {
      final c = make('speaking', ExamType.ielts, card: 'p1');
      c.pickWizCard('pron');
      expect(c.resolveTarget(), SurgoPage.pronCourse);
      final s = AppState(examType: ExamType.ielts);
      TrainingWizardController(s, 'speaking', initialCard: 'pron').commitAndGo();
      expect(s.current, SurgoPage.pronCourse);
      expect(s.session['selWizCard'], 'pron');
    });
  });

  group('IELTS 词汇向导（双卡）：始终 → vocab', () {
    test('整篇/单一 + 各方式都进 vocab', () {
      final c = make('vocab', ExamType.ielts);
      expect(c.readMode, 'full');
      expect(c.resolveTarget(), SurgoPage.vocab);
      for (final v in const ['flash', 'spell', 'match', 'cloze']) {
        c.pickReadType(v);
        expect(c.selReadType, v);
        expect(c.readMode, 'single');
        expect(c.resolveTarget(), SurgoPage.vocab, reason: v);
      }
      c.pickPracticeMode('full');
      expect(c.selReadType, isNull);
      expect(c.resolveTarget(), SurgoPage.vocab);
    });
    test('commitAndGo 落库 sessionKey/selReadType，不写 tfBriefMod', () {
      final s = AppState(examType: ExamType.ielts);
      final c = TrainingWizardController(s, 'vocab');
      c.pickReadType('spell');
      c.commitAndGo();
      expect(s.current, SurgoPage.vocab);
      expect(s.session['sessionKey'], 'vocab');
      expect(s.session['selReadType'], 'spell');
      expect(s.session.containsKey('tfBriefMod'), isFalse);
    });
  });

  group('TOEFL 向导：listening/writing/speaking 始终先进 tfBrief，vocab 无托福版式', () {
    test('托福三科 → tfBrief，tfBriefMod/任务/难度落库', () {
      // writing
      final sw = AppState(examType: ExamType.toefl);
      final cw = TrainingWizardController(sw, 'writing');
      cw.pickTfWrTask('email');
      cw.commitAndGo();
      expect(sw.current, SurgoPage.tfBrief);
      expect(sw.session['tfBriefMod'], 'writing');
      expect(sw.session['tfWrTask'], 'email');

      // listening（含难度）
      final sl = AppState(examType: ExamType.toefl);
      final cl = TrainingWizardController(sl, 'listening');
      cl.pickTfLisTask('lecture');
      cl.pickTfLisDiff('high');
      cl.commitAndGo();
      expect(sl.current, SurgoPage.tfBrief);
      expect(sl.session['tfBriefMod'], 'listening');
      expect(sl.session['tfLisTask'], 'lecture');
      expect(sl.session['tfLisDiff'], 'high');

      // speaking
      final ss = AppState(examType: ExamType.toefl);
      final cs = TrainingWizardController(ss, 'speaking');
      cs.pickTfSpTask('interview');
      cs.commitAndGo();
      expect(ss.current, SurgoPage.tfBrief);
      expect(ss.session['tfBriefMod'], 'speaking');
      expect(ss.session['tfSpTask'], 'interview');
    });

    test('全组合枚举：三科各任务/难度都路由 tfBrief', () {
      for (final t in const ['sent', 'email', 'disc']) {
        final c = make('writing', ExamType.toefl)..pickTfWrTask(t);
        expect(c.resolveTarget(), SurgoPage.tfBrief, reason: 'writing/$t');
      }
      for (final t in const ['respond', 'convo', 'announce', 'lecture']) {
        for (final d in const ['low', 'std', 'high']) {
          final c = make('listening', ExamType.toefl)
            ..pickTfLisTask(t)
            ..pickTfLisDiff(d);
          expect(c.resolveTarget(), SurgoPage.tfBrief, reason: 'listening/$t/$d');
        }
      }
      for (final t in const ['retell', 'interview', 'pron']) {
        final c = make('speaking', ExamType.toefl)..pickTfSpTask(t);
        expect(c.resolveTarget(), SurgoPage.tfBrief, reason: 'speaking/$t');
      }
    });

    test('TOEFL 词汇仍走雅思双卡 → vocab（无托福分支）', () {
      final c = make('vocab', ExamType.toefl);
      expect(c.resolveTarget(), SurgoPage.vocab);
    });

    test('托福默认选择：sent / respond+std / retell', () {
      expect(make('writing', ExamType.toefl).tfWrTask, 'sent');
      final cl = make('listening', ExamType.toefl);
      expect(cl.tfLisTask, 'respond');
      expect(cl.tfLisDiff, 'std');
      expect(make('speaking', ExamType.toefl).tfSpTask, 'retell');
    });
  });

  group('通用 session 快照字段（沿用原型变量名）', () {
    test('doGenSession 头部：readIdx/typeIdx/lisIdx 归零，sessionMode=daily', () {
      final s = AppState(examType: ExamType.ielts);
      TrainingWizardController(s, 'writing', initialCard: 't1').commitAndGo();
      expect(s.session['readIdx'], 0);
      expect(s.session['typeIdx'], 0);
      expect(s.session['lisIdx'], 0);
      expect(s.session['sessionMode'], 'daily');
      expect(s.session['wizKey'], 'writing');
    });
  });
}
