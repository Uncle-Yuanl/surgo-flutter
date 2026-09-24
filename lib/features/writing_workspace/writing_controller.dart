import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../app/i18n.dart';
class WritingController {
 WritingController(this.state);
 final AppState state;
 Map<String,dynamic> get bank=>QuestionBank.instance.skill('writing',state.examType);
 String get key=>state.examType==ExamType.toefl?'email':switch(state.session['selWizCard']){'t1'=>'task1','letter'=>'letter',_=>'task2'};
 Map<String,dynamic> get task=>Map<String,dynamic>.from(bank['daily']?[key]??{});
 Map<String,dynamic> get plan=>Map<String,dynamic>.from(bank['plan']?[key]??{});
 Map<String,dynamic>? get analysis=>(bank['analysis']?[task['type']] as Map?)?.cast<String,dynamic>();
 static const steps=['analysis','arg','para','vocab'];
 String get step=>state.session['planStepCur'] as String? ??'analysis';
 set step(String v)=>state.session['planStepCur']=v;
 Set<int> get args=>state.session.putIfAbsent('planArgs',()=> <int>{}) as Set<int>;
 Set<int> get vocab=>state.session.putIfAbsent('planVocab',()=> <int>{}) as Set<int>;
 int get argIndex=>args.isEmpty?0:args.first;
 List get paras {
  final byArg=plan['parasByArg'];
  if(byArg is List) {
   return (argIndex<byArg.length?byArg[argIndex]:null)??(byArg.isNotEmpty?byArg[0]:null)??plan['paras']??[];
  }
  return byArg?[argIndex.toString()]??byArg?['0']??plan['paras']??[];
 }
 String get tab=>state.session['weTab'] as String? ??'topics';
 set tab(String v)=>state.session['weTab']=v;
 String get draft=>state.session['weDraft'] as String? ??'';
 set draft(String v)=>state.session['weDraft']=v;
 static int words(String s)=>RegExp(r"[A-Za-z0-9'’\-]+").allMatches(s.trim()).length;
 void startPlan(){step='analysis';args.clear();vocab.clear();state.go(SurgoPage.writingPlan);}
 bool next(){if(step=='arg'&&args.isEmpty)return false;final i=steps.indexOf(step);if(i<3){step=steps[i+1];state.go(SurgoPage.writingPlan);}else{tab='topics';state.session['wePlanOpen']=false;state.go(SurgoPage.writingCompose);}return true;}
 void prev(){final i=steps.indexOf(step);if(i>0){step=steps[i-1];state.go(SurgoPage.writingPlan);}else{state.go(SurgoPage.writingSession);}}
 void pickArg(int i){args.clear();args.add(i);}
 void toggleVocab(int i){if(!vocab.remove(i))vocab.add(i);}
}
