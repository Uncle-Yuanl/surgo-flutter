import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../widgets/demo_audio.dart';

abstract class OralSpeech {
  Future<void> speak(String text, {required VoidCallback started,
    required VoidCallback ended, required ValueChanged<String> failed});
  Future<void> stop();
}
class NativeOralSpeech implements OralSpeech {
  final FlutterTts tts = FlutterTts();
  /// 手机浏览器的朗读常常既不出声也不报错（iOS 上不是由点击直接触发的朗读会被丢弃，有的安卓
  /// 浏览器没有语音引擎）。这么久还没开始读就按失败报，页面改成把题目显示出来。
  static const startWithin = Duration(milliseconds: 2500);
  Timer? _watch;
  VoidCallback? _clip;
  int _turn = 0;
  @override
  Future<void> speak(String text, {required VoidCallback started,
    required VoidCallback ended, required ValueChanged<String> failed}) async {
    await stop();
    final turn = ++_turn;
    var open = true; // 每次朗读只回一次「结束」或「失败」
    void close(VoidCallback report) { if (!open) return; open = false; _watch?.cancel(); report(); }
    // 演示用真实数据带着考官的原音频（题库 ielts.speaking.examinerAudio：题目原文 → { asset, sec }），
    // 有就放它，不用浏览器朗读；放不出声音同样按失败报。
    final clip = clipFor(text);
    if (clip != null) {
      void watch() {
        if (!demoAudio.silent && !demoAudio.ended) return;
        final silent = demoAudio.silent;
        _dropClip();
        close(silent ? () => failed('audio blocked') : ended);
      }
      _clip = watch;
      demoAudio.addListener(watch);
      started();
      demoAudio.play(clip['asset'] as String, seconds: (clip['sec'] as num).toDouble());
      return;
    }
    try {
      await tts.setLanguage('en-GB');
      await tts.setSpeechRate(.92);
      if (turn != _turn) return; // 等待期间已被 stop()
      tts.setStartHandler(() { _watch?.cancel(); if (open) started(); });
      tts.setCompletionHandler(() => close(ended));
      // 被后一次朗读打断（interrupted / canceled）不算失败。
      tts.setErrorHandler((message) { if (message != 'interrupted' && message != 'canceled') close(() => failed('$message')); });
      _watch = Timer(startWithin, () => close(() { stop(); failed('no speech'); }));
      await tts.speak(text);
    } catch(e) { close(() => failed(e.toString())); }
  }
  /// [text] 这道题的考官原音频（{ asset, sec }）；没有、或不在网页上（放不了）就是 null。
  static Map? clipFor(String text) {
    final Map? clips = QuestionBank.isLoaded && demoAudio.available
      ? QuestionBank.instance.skill('speaking', ExamType.ielts)['examinerAudio'] : null;
    return clips?[text];
  }
  void _dropClip() {
    final watch = _clip;
    if (watch == null) return;
    _clip = null;
    demoAudio.removeListener(watch);
    demoAudio.stop();
  }
  @override
  Future<void> stop() async { _turn++; _watch?.cancel(); _dropClip(); try { await tts.stop(); } catch (_) {} }
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
  /// 读不出声音的那道题的原文：页面把它显示出来（听得到的时候题目只读不显示）。
  String? unheard;
  int index=0, recSec=0, round=1, answerSec=0, askSec=0, audioSec=0, prepLeft=60;
  bool get preparing => task.kind=='cue' && phase=='note';
  bool speaking=false, disposed=false;
  /// 讨论题「考官提问」这一轮的时间已到，只等题目读完。
  bool askOver=false;
  int speechEpoch=0;
  String? get card => app.session['selWizCard'] as String?;
  OralTask get task=>OralTask.fromBank(app.examType,card);
  int get recMax=>task.kind=='cue'?120:30;
  String get spokenText=>task.kind=='cue'
    ? [task.cue,'You should say:',...task.points,task.last].where((s)=>s.isNotEmpty).join('. ')
    : (index<task.questions.length?task.questions[index]:'');
  static int estimate(String text)=>math.max(2,((text.trim().isEmpty?0:text.trim().split(RegExp(r'\s+')).length)*.38+1.2).round());
  /// 提问的秒数：有考官原音频就是它的时长，否则按词数估（原型的算法）。
  int get duration=>secondsOf(spokenText);
  static int secondsOf(String text)=>(NativeOralSpeech.clipFor(text)?['sec'] as num?)?.ceil()??estimate(text);
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
    unheard=null;
    await speech.speak(text,started:(){if(!valid())return;speaking=true;audioSec=0;
      barTimer?.cancel();if(!cue)barTimer=Timer.periodic(const Duration(seconds:1),(t){audioSec=math.min(audioSec+1,secondsOf(text));emit();if(audioSec>=secondsOf(text))t.cancel();});emit();},
      ended:(){if(!valid())return;speaking=false;heard.add(index);barTimer?.cancel();audioSec=secondsOf(text);
        // 原型在讨论题第一轮读完题时也会跳去 oralExam（H5 的行为，测试固定住了）。放考官原音频时不跳：
        // 音频常常在「提问」那几秒之后才放完，一跳就把整轮作答留在了错的页面上。
        if(phase=='note'&&!cue){phase='ready';if(app.current!=SurgoPage.oralExam&&!(card=='p3'&&NativeOralSpeech.clipFor(text)!=null))app.go(SurgoPage.oralExam);}emit();
        if(askOver)answerTurn();},
      // 读不出来就不等了：问答题把题目显示出来、直接可以作答；讨论题（按计时推进）只显示题目。
      failed:(e){if(!valid())return;speaking=false;barTimer?.cancel();if(!cue)unheard=text;
        if(phase=='note'&&!cue&&card!='p3'){heard.add(index);phase='ready';}emit();
        if(askOver)answerTurn();});
  }
  void mic(){
    if(phase=='ready'){phase='rec';recSec=0;recTimer?.cancel();recTimer=Timer.periodic(const Duration(seconds:1),(t){recSec++;if(recSec>=recMax){t.cancel();phase='done';}emit();});emit();}
    else if(phase=='rec'){recTimer?.cancel();phase='done';emit();}
  }
  void retake(){recTimer?.cancel();recSec=0;phase='ready';emit();}
  void submit(){
    if(task.kind!='cue'&&index<task.questions.length-1){index++;phase='note';note='';audioSec=0;unheard=null;emit();later(350,play);}
    else {quitSpeech();app.go(SurgoPage.speakingReview);}
  }
  /// 讨论题「考官提问」这一轮的秒数：原型固定 5 秒；考官的原音频比它长时，等它读完。
  int get askSeconds=>math.max(5,NativeOralSpeech.clipFor(spokenText)==null?0:duration);
  void stopDiscussion(){discussionTimer?.cancel();discussionTick?.cancel();askSec=0;askOver=false;}
  void answerTurn(){if(disposed||turn!='ask')return;turn='answer';answerSec=0;app.go(SurgoPage.oralDiscuss);scheduleDiscussion();emit();}
  void scheduleDiscussion(){
    stopDiscussion();
    if(turn=='ask'){
      later(200,play);askSec=0;
      final ask=askSeconds;
      discussionTick=Timer.periodic(const Duration(seconds:1),(t){askSec++;emit();if(askSec>=ask)t.cancel();});
      discussionTimer=Timer(Duration(seconds:ask),(){
        // 原型到点就换人。放考官原音频时例外：音频要先下载，网络慢时晚几秒才出声，到点还没读完就等它读完，
        // 最多再等 10 秒。
        if(!speaking||NativeOralSpeech.clipFor(spokenText)==null){answerTurn();return;}
        askOver=true;discussionTimer=Timer(const Duration(seconds:10),answerTurn);});
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
