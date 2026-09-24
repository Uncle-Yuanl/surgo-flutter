import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/toefl_life/toefl_life_logic.dart';
import 'package:surgo_flutter/features/task_brief/task_brief_page.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late TfDlContent data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await TfDlContent.load();});
 test('40second timer,next reset,prev preserves,input retained',(){
  final c=TfDlController(data)..start();expect(c.left,40);c.pick(2);c.tick();expect(c.left,39);expect(c.answered(),1);
  c.next();expect(c.left,40);c.tick();c.prev();expect(c.left,39);expect(c.selected(),2);
  for(var i=0;i<38;i++){expect(c.tick(),false);}expect(c.tick(),true);expect(c.over,true);expect(c.tick(),false);expect(c.up,1);
 });
 test('source and title inherit across questions exactly',(){
  final c=TfDlController(data);String source='ad',title='Read an advertisement.';
  for(var i=0;i<data.questions.length;i++){final q=data.questions[i];source=q.src??source;title=q.title??title;c.jump(i);
   expect(c.title(),title);expect(c.srcLines(),source=='post'?data.post:data.ad);
  }
 });
 testWidgets('all life question pages and source feedback render at390px',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final state=AppState(current:SurgoPage.tfDailyLife,examType:ExamType.toefl);
  await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:const MaterialApp(home:SurgoShell())));await t.pumpAndSettle();
  final c=state.session['tfDlController'] as TfDlController;
  for(var i=0;i<data.questions.length;i++){c.jump(i);state.refresh();await t.pumpAndSettle();expect(find.text(data.questions[i].q),findsOneWidget);expect(t.takeException(),isNull);}
  state.go(SurgoPage.tfDlFb);await t.pumpAndSettle();expect(find.text('逐题分析'),findsOneWidget);expect(t.takeException(),isNull);
  final brief=await TaskBriefData.load();state.session.addAll({'tfBriefMod':'reading','tfReadTask':'liferead'});brief.start(state);await t.pumpAndSettle();
  final fresh=state.session['tfDlController'] as TfDlController;expect(fresh.idx,0);expect(fresh.vals,isEmpty);
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
 });
}
