import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/oral_daily/controller.dart';
import 'package:surgo_flutter/features/oral_daily/page.dart';

class FakeSpeech implements OralSpeech {
  VoidCallback? ended;
  String? text;
  @override
  Future<void> speak(String value,{required VoidCallback started,required VoidCallback ended,required ValueChanged<String> failed}) async {text=value;this.ended=ended;started();}
  @override
  Future<void> stop() async {}
}
Map<String,dynamic> snapshot(OralController c)=>{'phase':c.phase,'index':c.index,'note':c.note,'recSec':c.recSec,'turn':c.turn,'round':c.round,'answerSec':c.answerSec,'askSec':c.askSec,'route':c.app.current.name};
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await QuestionBank.load();await Translator.load();});
 final scenarios=jsonDecode(File('test/fixtures/oral_daily_oracle.json').readAsStringSync()) as List;
 // Cue preparation intentionally superseded by user's60s/manual-entry revision.
 // Keep frozen source oracle for unaffected Part1/3/TOEFL scenarios.
 for(final scenario in scenarios.where((s)=>s['task']['kind']!='cue')){
  testWidgets('oral source oracle ${scenario['exam']} ${scenario['card']}',(t)async{
   final app=AppState(current:SurgoPage.oralExam,examType:scenario['exam']=='toefl'?ExamType.toefl:ExamType.ielts);
   app.session['selWizCard']=scenario['card'];
   final speech=FakeSpeech();
   final ctrl=OralController(app,speech:speech);
   addTearDown(ctrl.dispose);
   expect(ctrl.task.data,scenario['task']);
   for(final frame in scenario['frames']){
    final a=frame['action'] as Map;
    if(a.containsKey('wait')) {await t.pump(Duration(milliseconds:a['wait'] as int));}
    else if(a.containsKey('endSpeech')){speech.ended?.call();}
    else if(a.containsKey('note')){ctrl.note=a['note'];}
    else {switch(a['call']){
     case 'startOralExam':ctrl.start();
     case 'oralMic':ctrl.mic();
     case 'oralRetake':ctrl.retake();
     case 'oralSubmitAnswer':ctrl.submit();
     default:fail('Unknown action $a');
    }}
    expect(snapshot(ctrl),frame['state'],reason:'${scenario['card']} action $a');
   }
  });
 }
 testWidgets('Part1 audio-only, no notes, record stop/retake/next at390px',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final app=AppState(current:SurgoPage.oralExam);app.session['selWizCard']='p1';
  final speech=FakeSpeech();
  final ctrl=OralController(app,speech:speech);addTearDown(ctrl.dispose);
  await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Scaffold(body:OralDailyPage(controller:ctrl)))));
  ctrl.start();await t.pump(const Duration(milliseconds:400));speech.ended?.call();await t.pump();
  expect(find.text(ctrl.task.questions.first),findsNothing);expect(find.byKey(const ValueKey('oral-note')),findsNothing);
  await t.tap(find.byKey(const ValueKey('oral-mic')));await t.pump(const Duration(seconds:5));
  expect(ctrl.recSec,5);await t.tap(find.byKey(const ValueKey('oral-mic')));await t.pump();expect(ctrl.phase,'done');
  await t.tap(find.byKey(const ValueKey('oral-retake')));await t.pump();expect(ctrl.phase,'ready');expect(ctrl.recSec,0);
  await t.tap(find.byKey(const ValueKey('oral-mic')));await t.pump(const Duration(seconds:30));
  expect(ctrl.phase,'done');await t.tap(find.byKey(const ValueKey('oral-submit')));await t.pump();expect(ctrl.index,1);expect(ctrl.phase,'note');
  expect(t.takeException(),isNull);ctrl.quit();await t.pumpWidget(const SizedBox.shrink());
 });
 for(final card in ['p2','p3','interview']){
  testWidgets('$card native bounds and controls',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
   final app=AppState(current:card=='p3'?SurgoPage.oralDiscuss:SurgoPage.oralExam,examType:card=='interview'?ExamType.toefl:ExamType.ielts);app.session['selWizCard']=card;
   final c=OralController(app,speech:FakeSpeech());addTearDown(c.dispose);
   await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Scaffold(body:OralDailyPage(discussion:card=='p3',controller:c)))));
   if(card=='p2')expect(find.text(c.task.cue),findsOneWidget);
   if(card=='p3'){expect(find.byKey(const ValueKey('oral-submit')),findsNothing);expect(find.byKey(const ValueKey('oral-mic')),findsNothing);}
   else {expect(find.byKey(const ValueKey('oral-note')),findsOneWidget);}
   expect(t.takeException(),isNull);c.dispose();await t.pumpWidget(const SizedBox.shrink());
  });
 }
}
