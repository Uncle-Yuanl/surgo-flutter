import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';

abstract class OralSpeech {
  Future<void> speak(String text, {required VoidCallback started,
    required VoidCallback ended, required ValueChanged<String> failed});
  Future<void> stop();
}
class NativeOralSpeech implements OralSpeech {
  final FlutterTts tts = FlutterTts();
  @override
  Future<void> speak(String text, {required VoidCallback started,
    required VoidCallback ended, required ValueChanged<String> failed}) async {
    try {
      await tts.stop();
      await tts.setLanguage('en-GB');
      await tts.setSpeechRate(.92);
      tts.setStartHandler(started);
      tts.setCompletionHandler(ended);
      tts.setErrorHandler((message) => failed(message.toString()));
      await tts.speak(text);
    } catch(e) { failed(e.toString()); }
  }
  @override
  Future<void> stop() async { try { await tts.stop(); } catch (_) {} }
}
class OralTask {
  OralTask(this.data);
  final Map<String,dynamic> data;
  String get kind => data['kind'];
  List<String> get questions => List<String>.from(data['list']);
  String get cue => data['cue'] ?? '';
  String get topic => data['topic'] ?? '';
  List<String> get points => List<String>.from(data['points'] ?? []);
  String get last => data['last'] ?? '';
  int get prep => data['prep'];
  int get answer => data['answer'];
  int get rounds => data['rounds'] ?? 10;
  static OralTask fromBank(ExamType exam, String? card) {
    final d = QuestionBank.instance.skill('speaking',exam)['daily'] as Map? ?? {};
    if(exam==ExamType.toefl || card=='p1' || card=='p3') {
      final p=d[exam==ExamType.toefl?'interview':card=='p1'?'part1':'part3'] as Map? ?? {};
      return OralTask({'kind':exam!=ExamType.toefl&&card=='p3'?'discuss':'qa',
        'list':p['questions']??[],'topic':p['topic']??'','prep':0,
        // 演示用真实数据带 rounds（那次作答实际问了几轮）；原型数据没有这个键，仍是 10 轮。
        'answer':exam==ExamType.toefl?45:30,if(exam!=ExamType.toefl&&card=='p3')'rounds':p['rounds']??10});
    }
    final p=d['part2'] as Map? ?? {}, pts=List<String>.from(p['points']??[]);
    return OralTask({'kind':'cue','cue':p['cue']??'',
      'points':pts.length>1?pts.sublist(0,pts.length-1):pts,'last':pts.length>1?pts.last:'',
      'list':[p['cue']??''],'prep':p['prepSeconds']==null||p['prepSeconds']==0?60:p['prepSeconds'],
      'answer':(p['minutes']==null||p['minutes']==0?2:p['minutes'])*60});
  }
}
String oralTime(int sec) => '${(math.max(0,sec)~/60).toString().padLeft(2,'0')}:${(math.max(0,sec)%60).toString().padLeft(2,'0')}';

/// app.js 1422–1625. Recording is a timer, not microphone capture.
/// User revision: cue has60s explicit preparation, manual enter; other source rules retained.
/// discussion 5s/30s, and oralSpeak's onend can navigate to oralExam from Part3.
class OralController extends ChangeNotifier {
  OralController(this.app,{OralSpeech? speech}):speech=speech??NativeOralSpeech() {
    app.addListener(_routeChanged);
  }
  final AppState app;
  final OralSpeech speech;
  final Set<int> heard={};
  final List<Timer> delayed=[];
  Timer? prepTimer, recTimer, barTimer, discussionTimer, discussionTick;
  String phase='note', note='', turn='ask';
  String? error;
  int index=0, recSec=0, round=1, answerSec=0, askSec=0, audioSec=0, prepLeft=60;
  bool get preparing => task.kind=='cue' && phase=='note';
  bool speaking=false, disposed=false;
  int speechEpoch=0;
  String? get card => app.session['selWizCard'] as String?;
  OralTask get task=>OralTask.fromBank(app.examType,card);
  int get recMax=>task.kind=='cue'?120:30;
  String get spokenText=>task.kind=='cue'
    ? [task.cue,'You should say:',...task.points,task.last].where((s)=>s.isNotEmpty).join('. ')
    : (index<task.questions.length?task.questions[index]:'');
  static int estimate(String text)=>math.max(2,((text.trim().isEmpty?0:text.trim().split(RegExp(r'\s+')).length)*.38+1.2).round());
  int get duration=>estimate(spokenText);
  void emit(){ if(!disposed) { app.session.addAll({'oralState':phase,'oralQIdx':index,
    'oralNote':note,'oralPrepLeft':prepLeft,'oralRecSec':recSec,'oralSpeaking':speaking,'oralHeard':heard.toList(),
    'd3Turn':turn,'d3Round':round,'d3Sec':answerSec,'d3AskSec':askSec});notifyListeners(); } }
  void later(int ms,VoidCallback action){delayed.add(Timer(Duration(milliseconds:ms),(){if(!disposed)action();}));}
  void start(){
    prepTimer?.cancel();phase='note';index=0;note='';heard.clear();
    if(card=='p3'){turn='ask';round=1;answerSec=0;askSec=0;app.go(SurgoPage.oralDiscuss);scheduleDiscussion();}
    else {app.go(SurgoPage.oralExam);
      if(task.kind=='cue'){beginPreparation();} else {later(400,play);}} 
    emit();
  }
  void beginPreparation(){
    prepTimer?.cancel();phase='note';prepLeft=task.prep;
    prepTimer=Timer.periodic(const Duration(seconds:1),(timer){
      if(prepLeft>0){prepLeft--;}if(prepLeft==0){timer.cancel();}emit();
    });emit();
  }
  void updateNote(String value){note=value;app.session['oralNote']=value;}
  void enterCueExam(){
    if(!preparing)return;prepTimer?.cancel();phase='ready';recSec=0;emit();
    if(app.current!=SurgoPage.oralExam)app.go(SurgoPage.oralExam);
  }
  Future<void> play() async {
    if(spokenText.isEmpty)return;
    final text=spokenText, cue=task.kind=='cue', epoch=++speechEpoch;
    bool valid()=>!disposed&&epoch==speechEpoch;
    await speech.speak(text,started:(){if(!valid())return;speaking=true;audioSec=0;error=null;
      barTimer?.cancel();if(!cue)barTimer=Timer.periodic(const Duration(seconds:1),(t){audioSec=math.min(audioSec+1,estimate(text));emit();if(audioSec>=estimate(text))t.cancel();});emit();},
      ended:(){if(!valid())return;speaking=false;heard.add(index);barTimer?.cancel();audioSec=estimate(text);
        if(phase=='note'&&!cue){phase='ready';if(app.current!=SurgoPage.oralExam)app.go(SurgoPage.oralExam);}emit();},
      failed:(e){if(!valid())return;error='（原型）语音播放失败：$e';emit();});
  }
  void mic(){
    if(phase=='ready'){phase='rec';recSec=0;recTimer?.cancel();recTimer=Timer.periodic(const Duration(seconds:1),(t){recSec++;if(recSec>=recMax){t.cancel();phase='done';}emit();});emit();}
    else if(phase=='rec'){recTimer?.cancel();phase='done';emit();}
  }
  void retake(){recTimer?.cancel();recSec=0;phase='ready';emit();}
  void submit(){
    if(task.kind!='cue'&&index<task.questions.length-1){index++;phase='note';note='';audioSec=0;emit();later(350,play);}
    else {quitSpeech();app.go(SurgoPage.speakingReview);}
  }
  void stopDiscussion(){discussionTimer?.cancel();discussionTick?.cancel();askSec=0;}
  void scheduleDiscussion(){
    stopDiscussion();
    if(turn=='ask'){
      later(200,play);askSec=0;
      discussionTick=Timer.periodic(const Duration(seconds:1),(t){askSec++;emit();if(askSec>=5)t.cancel();});
      discussionTimer=Timer(const Duration(seconds:5),(){turn='answer';answerSec=0;app.go(SurgoPage.oralDiscuss);scheduleDiscussion();emit();});
    }else{answerSec=0;discussionTick=Timer.periodic(const Duration(seconds:1),(t){answerSec++;if(answerSec>=30){t.cancel();answered();}emit();});}
  }
  void answered(){stopDiscussion();if(round>=task.rounds){app.go(SurgoPage.speakingReview);return;}
    round++;turn='ask';index=(index+1)%math.max(1,task.questions.length);app.go(SurgoPage.oralDiscuss);scheduleDiscussion();emit();}
  void quitSpeech(){prepTimer?.cancel();speechEpoch++;speech.stop();speaking=false;}
  void quit(){stopDiscussion();quitSpeech();app.go(SurgoPage.speakingDaily);}
  void _routeChanged(){if(!{SurgoPage.oralExam,SurgoPage.oralDiscuss,SurgoPage.speakingSession}.contains(app.current))dispose();}
  @override
  void dispose(){if(disposed)return;disposed=true;app.removeListener(_routeChanged);quitSpeech();
    recTimer?.cancel();barTimer?.cancel();stopDiscussion();for(final t in delayed){t.cancel();}
    if(identical(app.session['oralController'],this))app.session.remove('oralController');super.dispose();}
}
void requestOralStart(AppState app){
  (app.session.remove('oralController') as OralController?)?.dispose();
  app.session['oralStartPending']=true;
  app.go(app.session['selWizCard']=='p3'?SurgoPage.oralDiscuss:SurgoPage.oralExam);
}
