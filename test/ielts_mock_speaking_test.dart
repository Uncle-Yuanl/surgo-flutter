import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/ielts_mock_speaking/controller.dart';
import 'package:surgo_flutter/features/ielts_mock_speaking/page.dart';
import 'package:surgo_flutter/features/oral_daily/controller.dart';
class Speech implements OralSpeech {
 VoidCallback? end;String? text;int calls=0;
 @override Future<void> speak(String t,{required VoidCallback started,required VoidCallback ended,required ValueChanged<String> failed})async{text=t;end=ended;calls++;started();}
 @override Future<void> stop()async{}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late Map<String,dynamic> data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await IeltsMockSpeakingData.load();});
 testWidgets('Part1 source260ms speech then auto record; 10 turns then600ms Part2',(t)async{
  final speech=Speech(),app=AppState();var marked=0;
  final c=IeltsMockSpeakingController(app,data,speech:speech,mark:()=>marked++);c.start();
  await t.pump(const Duration(milliseconds:259));expect(speech.calls,0);await t.pump(const Duration(milliseconds:1));expect(c.busy,true);c.mic();expect(c.recording,false);
  for(var i=0;i<10;i++){speech.end!();expect(c.recording,true);await t.pump(const Duration(seconds:2));c.mic();expect(c.turns.last['dur'],2);if(i<9){await t.pump(const Duration(milliseconds:500));expect(c.index,i+1);expect(c.busy,true);}}
  expect(c.part,'p1');await t.pump(const Duration(milliseconds:599));expect(c.part,'p1');await t.pump(const Duration(milliseconds:1));expect(c.part,'p2');expect(c.prep,60);expect(marked,0);c.dispose();
 });
 testWidgets('Part2 60s prep120s rec+700ms transition, manual stop600ms',(t)async{
  final app=AppState()..session['spqPart']='p2';final c=IeltsMockSpeakingController(app,data,speech:Speech(),mark:(){});c.start();
  await t.pump(const Duration(seconds:60));expect(c.phase,'rec');expect(c.recLeft,120);expect(c.left,180);
  await t.pump(const Duration(seconds:120));expect(c.phase,'done');await t.pump(const Duration(milliseconds:699));expect(c.part,'p2');await t.pump(const Duration(milliseconds:1));expect(c.part,'p3');
  c.select('p2');c.mic();expect(c.prep,0);expect(c.phase,'rec');c.mic();await t.pump(const Duration(milliseconds:599));expect(c.part,'p2');await t.pump(const Duration(milliseconds:1));expect(c.part,'p3');c.dispose();
 });
 testWidgets('Part3 ask/answer5s only simulated,270s marks',(t)async{
  final app=AppState()..session['spqPart']='p3';final speech=Speech();var marked=0;final c=IeltsMockSpeakingController(app,data,speech:speech,mark:()=>marked++);c.start();
  await t.pump(const Duration(seconds:5));expect(c.turn,'ans');expect(c.recording,true);expect(c.round,1);await t.pump(const Duration(seconds:5));expect(c.turn,'ask');expect(c.round,2);expect(speech.calls,0);
  await t.pump(const Duration(seconds:260));expect(marked,1);expect(c.left,0);expect(c.recording,false);c.dispose();
 });
 testWidgets('all three parts390: audio-only P1, cue notes P2, no extra next P3',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));final app=AppState(current:SurgoPage.mockSpeakingQ);
  await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Scaffold(body:IeltsMockSpeakingPage(speech:Speech())))));await t.pump();
  expect(find.text(data['SPQ']['p1']['qs'][0]),findsNothing);expect(find.byKey(const ValueKey('ims-note')),findsNothing);
  await t.tap(find.byKey(const ValueKey('ims-p2')));await t.pump();expect(find.text(data['SPQ']['p2']['card']['title']),findsOneWidget);expect(find.byKey(const ValueKey('ims-note')),findsOneWidget);
  await t.tap(find.byKey(const ValueKey('ims-p3')));await t.pump();expect(find.text('04:30'),findsOneWidget);expect(find.text('回答完毕'),findsNothing);expect(t.takeException(),isNull);
  await t.pumpWidget(const SizedBox.shrink());
 });
}
