import '../../app/app_state.dart';
import '../../app/i18n.dart';

/// app.js mwCfg / mwWords / mwEndExam. Only current task triggers word gate.
class IeltsMockWritingController {
 IeltsMockWritingController(this.app){task=app.session['mwTask'] as int? ?? 1;left=app.session['mwLeft'] as int? ?? 3600;warnCount=app.session['mwWarnCount'] as int? ?? 0;
  final raw=app.session['mwText'] as Map? ?? {};for(final n in [1,2]){texts[n]=(raw[n]??raw['$n']??'').toString();}}
 final AppState app;
 late int task,left,warnCount;
 final Map<int,String> texts={};
 /// 演示用真实数据带 mock.task1/2（一场真实模考的两道题，tool/demo_export/mock_writing.cjs）；
 /// 原型数据的 mock 只有 intro/summary，仍读日常那两题。
 Map<String,dynamic> config(int n){final w=QuestionBank.instance.skill('writing',app.examType);return Map<String,dynamic>.from(w['mock']?['task$n'] ?? w['daily']?['task$n'] ?? {});}
 int get minimum=>(config(task)['minWords'] as int?) ?? (task==1?150:250);
 int get minutes=>(config(task)['minutes'] as int?) ?? (task==1?20:40);
 int words(int n){final v=(texts[n]??'').trim();return v.isEmpty?0:v.split(RegExp(r'\s+')).length;}
 void type(String v){texts[task]=v;save();}
 void select(int n){if(n!=1&&n!=2)return;task=n;save();}
 bool tick(){if(left>0)left--;save();return left<=0;}
 String end(){if(words(task)<minimum){warnCount++;save();return warnCount<=1?'short':'shortEnd';}return 'end';}
 void save()=>app.session.addAll({'mwTask':task,'mwText':Map<int,String>.from(texts),'mwLeft':left,'mwWarnCount':warnCount});
}
