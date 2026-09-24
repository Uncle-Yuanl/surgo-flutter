import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/ielts_reading/reading_controller.dart';
import 'package:surgo_flutter/features/ielts_reading/reading_feedback.dart';

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 late ReadingData data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await ReadingData.load();});
 test('all11single types retain exact contents, duration and source selection reset',(){
  expect(data.types.length,11);
  for(final type in data.types){final s=AppState()..session['selReadType']=type['key'];final c=ReadingController(s,data,single:true);
   expect(c.total,type['items'].length);expect(c.left,((type['mins']??9)*60).round());expect(c.article,type['article']??data.raw['fallbackArticle']);
   c.pick('arbitrary');expect(c.done,{0});c.jump(c.total>1?1:0);expect(c.selected,isNull);c.jump(0);expect(c.selected,isNull);expect(c.done,{0});
   c.done.clear();c.commitInput('answer');expect(c.done.isNotEmpty,type['boxInput']==true||type['diagramSvg']!=null);
  }
 });
 test('full source QB and20minute countdown do not fabricate scoring',(){
  final c=ReadingController(AppState(),data,single:false);
  expect(c.items,QuestionBank.instance.ielts['reading']['daily']['questions']);expect(c.left,1200);
  for(var i=0;i<1199;i++){expect(c.tick(),false);}expect(c.tick(),true);expect(c.clock,'00:00');expect(c.tick(),false);expect(c.clock,'00:01');
 });
 testWidgets('full reading -> select -> next/back loses DOM selection -> submit -> fixed source feedback',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final state=AppState(current:SurgoPage.readingSession)..session['sessionMode']='daily';
  await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:const MaterialApp(home:SurgoShell())));await t.pumpAndSettle();
  final option=find.text('Its total distance');await t.ensureVisible(option);await t.tap(option);await t.pump();
  expect((state.session['readDone'] as Set).contains(0),true);
  await t.ensureVisible(find.text('下一步'));await t.tap(find.text('下一步'));await t.pump();expect(state.session['readIdx'],1);
  // Source refreshReadBody rebuilds HTML without applyLang: buttons revert to English.
  await t.ensureVisible(find.text('BACK'));await t.tap(find.text('BACK'));await t.pump();expect(state.session['readIdx'],0);
  await t.tap(find.text('☰ 题号'));await t.pumpAndSettle();
  await t.tap(find.text('交卷'));await t.pump();for(var i=0;i<60;i++){await t.pump(const Duration(milliseconds:50));}await t.pumpAndSettle();
  expect(state.current,SurgoPage.readingFeedback);expect(find.byType(ReadingFeedbackPage),findsOneWidget);
  expect(find.text('6.5'),findsOneWidget);expect(find.text('1/3'),findsOneWidget);
  await t.ensureVisible(find.text('完成，返回首页'));await t.tap(find.text('完成，返回首页'));await t.pumpAndSettle();expect(state.current,SurgoPage.ielts);
 });
 testWidgets('all11single-type pages render at390px without loss of task content',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  for(final type in data.types){
   final state=AppState(current:SurgoPage.typeSession)..session['selReadType']=type['key'];
   await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:ValueKey(type['key']),home:const SurgoShell())));await t.pumpAndSettle();
   expect(find.text('IELTS 阅读 · ${type['name']}'),findsOneWidget);expect(t.takeException(),isNull,reason:type['key']);
  }
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
 });
}
