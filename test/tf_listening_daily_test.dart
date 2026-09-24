import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/tf_listening_daily/controller.dart';
import 'package:surgo_flutter/features/ielts_listening/listening_data.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late Map<String,dynamic> data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await TfListeningData.load();});
 test('daily replayable audio,choice lock,rate and answer reset rules',(){
  for(final key in data.keys){final c=TfListeningController(AppState(),key,data[key]);c.pick('A');expect(c.picks,isEmpty);
   while(c.phase=='play'){c.audioTick();}expect(c.phase,'ready');expect(c.left,c.seconds);c.pick('B');expect(c.picks,isEmpty);
   c.begin();c.pick('B');expect(c.picks[0],'B');for(var i=0;i<c.seconds-1;i++){expect(c.tick(),false);}expect(c.tick(),true);expect(c.tick(),false);expect(c.up,1);
   c.next();expect(c.left,c.seconds);expect(c.phase,key=='respond'?'play':'answer');
   c.replay();expect(c.phase,'play');expect(c.audio,0);expect(c.picks[0],'B');
  }
 });
 test('IELTS audio is225s simulation independent of speed display',()async{
  final d=await IeltsListeningData.load();final c=IeltsListeningController(AppState(),d);c.playing=true;c.speed='1.5X';c.audioTick();expect(c.audio,.25);c.seek(300);expect(c.audio,225);
  c.pick(0,1,true);expect(c.done,{0});c.pick(0,1,true);expect(c.done,isEmpty);c.gap(1,'');expect(c.done,{1});c.gap(2,'',second:true);expect(c.done,{1});
 });
 testWidgets('all8daily listening route bodies at390px',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  for(final page in [SurgoPage.tfDailyResp,SurgoPage.tfDrFb,SurgoPage.tfDailyConvo,SurgoPage.tfDcFb,SurgoPage.tfDailyAnn,SurgoPage.tfAnFb,SurgoPage.tfDailyLect,SurgoPage.tfLcFb]){
   final state=AppState(current:page,examType:ExamType.toefl);await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:ValueKey(page),home:const SurgoShell())));await t.pumpAndSettle();expect(find.byType(PlaceholderPage),findsNothing);expect(t.takeException(),isNull,reason:page.name);
  }
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
 });
}
