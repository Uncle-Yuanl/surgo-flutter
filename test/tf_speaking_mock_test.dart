import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/tf_speaking_mock/controller.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late Map<String,dynamic> data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await TfSpeakingMockData.load();});
 test('all Task1 segments exact phase durations, no replay/retake',(){
  final c=TfSpk1Controller(data['task1'])..start();
  for(var n=0;n<c.segments.length;n++){
   expect(c.seg,n);expect(c.phase,'instruct');for(var i=0;i<c.instrSec;i++){expect(c.step(),null);}expect(c.phase,'play');
   for(var i=0;i<c.sec;i++){expect(c.step(),null);}expect(c.phase,'ready');
   for(var i=0;i<c.readySec;i++){expect(c.step(),null);}expect(c.phase,'answer');expect(c.left,c.ansSec);
   for(var i=0;i<c.ansSec-1;i++){expect(c.step(),null);}expect(c.step(),'answer-done');expect(c.left,0);
   expect(c.advance(),n<c.segments.length-1);
  }
 });
 test('all4 interview segments play7 then answer45',(){final c=TfSpk2Controller(data['task2'])..start();expect(c.total,4);
  for(var n=0;n<4;n++){for(var i=0;i<7;i++){c.step();}expect(c.phase,'answer');expect(c.left,45);for(var i=0;i<44;i++){expect(c.step(),null);}expect(c.step(),'answer-done');expect(c.advance(),n<3);}
 });
 for(final page in [SurgoPage.tfSpk1Q,SurgoPage.tfSpk2Intro,SurgoPage.tfSpk2Brief,SurgoPage.tfSpk2Q,SurgoPage.tfSpeakFb]){
  testWidgets('${page.name} shell390 and noninitial speaking phases',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
   final app=AppState(current:page,examType:ExamType.toefl);
   await t.runAsync(()async{await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:SurgoShell())));});await t.pump();await t.pump(const Duration(milliseconds:400));
   expect(find.byType(PlaceholderPage),findsNothing);expect(find.byWidgetPredicate((w)=>w is CircularProgressIndicator&&w.value==null),findsNothing);expect(t.takeException(),isNull);
   if(page==SurgoPage.tfSpk1Q||page==SurgoPage.tfSpk2Q){await t.pump(const Duration(seconds:5));expect(t.takeException(),isNull);await t.pump(const Duration(seconds:7));expect(t.takeException(),isNull);}
   await t.pumpWidget(const SizedBox.shrink());
  });
 }
}
