import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/tf_reading_mock/controller.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late Map<String,dynamic> data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await TfReadingMockData.load();});
 test('original displayed totals differ from actual question-array lengths, no fabricated questions',(){
  expect(data['parts']['2']['total'],35);expect((data['parts']['2']['qs'] as List).length,15);
  expect(data['parts']['4']['total'],15);expect((data['parts']['4']['qs'] as List).length,5);
 });
 test('module1 returning to words resets; module2 returning preserves shared9min',(){
  final app=AppState();var c=TfReadingMockController(app,data,1);c.input(0,'value longer than width');c.tick();c.jump(1);expect(c.left,1799);expect(c.next(),SurgoPage.tfRead2Q);
  c=TfReadingMockController(app,data,2);expect(c.left,360);c.pick(2);c.previous();expect(app.current,SurgoPage.tfRead1Q);expect(app.session['tfR1Vals'],isEmpty);expect(app.session['tfR1Left'],1800);
  c=TfReadingMockController(app,data,3);c.input(0,'test');c.tick();c.next();c=TfReadingMockController(app,data,4);expect(c.left,539);c.pick(3);c.previous();expect(app.current,SurgoPage.tfRead3Q);expect((app.session['tfR3Vals'] as Map)['0_0'],'test');
  c.left=1;expect(c.tick(),SurgoPage.tfReadFb);expect(app.session['tfRfbMod'],'m2');
 });
 test('documents and titles inherited across question groups; no answer gate',(){
  final c=TfReadingMockController(AppState(),data,2);c.jump(1);expect(c.document,data['parts']['2']['ad']);c.jump(5);expect(c.title,isNot('Read an advertisement.'));c.jump(14);expect(c.next(),SurgoPage.tfReadModEnd);
 });
 for(final page in [SurgoPage.tfRead1Q,SurgoPage.tfRead2Q,SurgoPage.tfRead3Q,SurgoPage.tfRead4Q,SurgoPage.tfReadModEnd,SurgoPage.tfReadModLoad,SurgoPage.tfReadMod2Intro,SurgoPage.tfReadFb]){
  testWidgets('${page.name} native390 content and interactions',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
   final app=AppState(current:page,examType:ExamType.toefl);
   await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:SurgoShell())));await t.pump();await t.pump(const Duration(milliseconds:400));
   expect(find.byType(PlaceholderPage),findsNothing);expect(find.byWidgetPredicate((w)=>w is CircularProgressIndicator&&w.value==null),findsNothing);
   if(page==SurgoPage.tfRead1Q||page==SurgoPage.tfRead3Q){await t.ensureVisible(find.byKey(const ValueKey('tfrm-word-0_0')));await t.enterText(find.byKey(const ValueKey('tfrm-word-0_0')),'longer than width');await t.pump();}
   if(page==SurgoPage.tfRead2Q||page==SurgoPage.tfRead4Q){await t.ensureVisible(find.byKey(const ValueKey('tfrm-pick-1')));await t.tap(find.byKey(const ValueKey('tfrm-pick-1')));await t.pump();}
   if(page==SurgoPage.tfReadModLoad){await t.pump(const Duration(milliseconds:1600));await t.pump(const Duration(milliseconds:201));expect(app.current,SurgoPage.tfReadMod2Intro);}
   if(page==SurgoPage.tfReadFb){await t.tap(find.byKey(const ValueKey('tfrfb-m2')));await t.pump();expect(app.session['tfRfbMod'],'m2');expect(find.byKey(const ValueKey('tfrfb-p')),findsNothing);}
   expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());
  });
 }
}
