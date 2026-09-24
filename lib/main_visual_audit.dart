// Separate build target for real browser screenshot auditing only.
// Production main.dart, routing, data, timings and plugins are unchanged.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_state.dart';
import 'app/i18n.dart';
import 'app/routes.dart';
import 'app/shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([Translator.load(), QuestionBank.load()]);
  final query = Uri.base.queryParameters;
  final page = SurgoPage.values.byName(query['route'] ?? 'exam');
  final state = AppState(
      current: page,
      lang: UiLang.values.byName(query['lang'] ?? 'zh'),
      examType: query['exam'] == 'toefl' || page.name.startsWith('tf')
          ? ExamType.toefl
          : ExamType.ielts);
  // Only audit fixture selection; production routing/state initialization unchanged.
  if (query['card'] != null) state.session['selWizCard'] = query['card'];
  if (query['readType'] != null) {
    state.session['selReadType'] = query['readType'];
  }
  if (query['readIndex'] != null) {
    state.session[page == SurgoPage.typeSession ? 'typeIdx' : 'readIdx'] =
        int.parse(query['readIndex']!);
  }
  if (query['readReview'] != null) {
    state.session['sessionMode'] = query['readReview'] == 'daily' ? 'daily' : 'mock';
    state.session['raPas'] = int.tryParse(query['readReview']!) ?? 1;
  }
  if (query['listenReview'] != null) {
    final value = query['listenReview']!;
    final part = int.tryParse(value.substring(1)) ?? 1;
    state.session.addAll({'sessionMode':value.startsWith('m')?'mock':'daily',
      'lisPart':'s$part','lfPart':part});
  }
  final planStep = query['plan'];
  if (planStep != null) {
    state.session['planStepCur'] = planStep == 'arg-picked'
        ? 'arg'
        : planStep == 'vocab-picked'
            ? 'vocab'
            : planStep;
    state.session['planArgs'] = <int>{
      if (['arg-picked', 'para', 'vocab', 'vocab-picked'].contains(planStep)) 0
    };
    state.session['planVocab'] = <int>{if (planStep == 'vocab-picked') 0};
  }
  final compose = query['compose'];
  if (compose != null) {
    state.session['weTab'] = compose == 'essay' ? 'essay' : 'topics';
    state.session['wePlanOpen'] = !['essay', 'topics'].contains(compose);
    state.session['wePlanMod'] =
        ['analysis', 'arg', 'para', 'vocab'].contains(compose) ? compose : '';
  }
  if(query['reportState']!=null)state.session['reportScenario']=query['reportState'];
  final review = query['review'];
  if (review != null) {
    state.session['wfTask'] = int.parse(review.split('-').first);
    state.session['wfTab'] = review.split('-').last;
  }
  runApp(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'SURGO visual audit — ${page.name}',
        debugShowCheckedModeBanner: false,
        theme: SurgoTheme.build(),
        home: SurgoShell(readingAuditSeconds:query['readSeconds']==null?null:int.parse(query['readSeconds']!)),
      )));
}
