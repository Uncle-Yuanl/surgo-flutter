import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/task_brief/task_brief_page.dart';
import 'package:surgo_flutter/features/reading_wizard/reading_wizard_controller.dart';
import 'package:surgo_flutter/features/toefl_words/toefl_words_logic.dart';
import 'package:surgo_flutter/features/toefl_words/toefl_words_page.dart';

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 late TaskBriefData brief;late TfDwContent words;
 setUpAll(()async {await Translator.load();await QuestionBank.load();brief=await TaskBriefData.load();words=await TfDwContent.load();});
 test('all source brief entries and startup seeds',(){
   var count=0;
   final vars={'reading':'tfReadTask','listening':'tfLisTask','writing':'tfWrTask','speaking':'tfSpTask'};
   for(final mod in (brief.raw['TF_BRIEF'] as Map).entries){
     for(final task in (mod.value as Map).keys){
       final state=AppState(examType:ExamType.toefl)..session.addAll({'tfBriefMod':mod.key,vars[mod.key]!:task});
       expect(brief.entry(state),mod.value[task]);brief.start(state);count++;
       if(task=='pron'){expect(state.current,SurgoPage.pronCourse);continue;}
       final seed=brief.raw['startup'][TaskBriefData.starts[task]] as Map;
       expect(state.current.name,seed['target']);
       for(final entry in seed.entries){if(entry.key!='target')expect(state.session[entry.key],entry.value);}
     }
   }
   expect(count,13);
 });
 test('wordfill timer:90s,alert once,overrun,prev retains time,next resets',(){
   final c=TfDwController(words)..start();
   for(var i=0;i<89;i++){expect(c.tick(),false);}
   expect(c.left,1);expect(c.tick(),true);expect(c.over,true);expect(c.up,0);
   expect(c.tick(),false);expect(c.up,1);
   c.setBlank(0,'  ');expect(c.filled(),0);
   c.setBlank(0,'a very long input without an artificial limit');expect(c.filled(),1);
   expect(c.next(),true);expect(c.left,90);c.tick();c.prev();expect(c.left,89);
   expect(c.valueAt(0),'a very long input without an artificial limit');
 });
 testWidgets('wizard choice -> brief -> original90sec gap input -> next and previous',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
   final state=AppState(examType:ExamType.toefl,current:SurgoPage.readingDaily);
   final wizard=ReadingWizardController(state)..pickTfReadTask('wordfill');
   wizard.commitAndGo();expect(state.current,SurgoPage.tfBrief);
   await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:const MaterialApp(home:SurgoShell())));
   await t.pumpAndSettle();expect(find.byType(TaskBriefPage),findsOneWidget);
   await t.ensureVisible(find.byKey(const ValueKey('brief-start')));await t.tap(find.byKey(const ValueKey('brief-start')));
   await t.pumpAndSettle();expect(state.current,SurgoPage.tfDailyWords);expect(find.byType(TfDailyWordsView),findsOneWidget);
   final input=find.byType(TextField).first;await t.ensureVisible(input);await t.enterText(input,'abcdefghijklmno');
   final c=state.session['tfDwController'] as TfDwController;expect(c.valueAt(0),'abcdefghijklmno');
   await t.ensureVisible(find.text('下一段'));await t.tap(find.text('下一段'));await t.pump();expect(c.para,1);expect(c.left,90);
   await t.ensureVisible(find.text('上一题'));await t.tap(find.text('上一题'));await t.pump();expect(c.para,0);expect(c.valueAt(0),'abcdefghijklmno');
   for(var p=0;p<words.total-1;p++) {
     await t.ensureVisible(find.text('下一段'));await t.tap(find.text('下一段'));await t.pump();
   }
   expect(c.isLast,true);
   await t.ensureVisible(find.text('下一部分'));await t.tap(find.text('下一部分'));await t.pump();
   // Advance rendering and the separate 200ms tail timer explicitly; settling
   // animations alone does not wait for a pending source-equivalent timer.
   for(var frame=0;frame<60;frame++) {await t.pump(const Duration(milliseconds:50));}
   await t.pumpAndSettle();
   expect(state.current,SurgoPage.tfDwFb);
   expect(find.text('逐题分析'),findsOneWidget);
   await t.ensureVisible(find.text('⌂ 回到首页'));await t.tap(find.text('⌂ 回到首页'));await t.pumpAndSettle();
   expect(state.current,SurgoPage.ielts);
   await t.pumpWidget(const SizedBox.shrink());await t.pump();wizard.dispose();
 });
}
