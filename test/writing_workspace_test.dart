import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/writing_workspace/writing_controller.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();setUpAll(()async{await Translator.load();await QuestionBank.load();});
 test('word count matches source regex and no minimum gate on submit',(){
  expect(WritingController.words("It's a long-term plan—really. 中文 100"),6);
  expect(WritingController.words('中文'),0);
 });
 test('task mapping and argument gate preserve source',(){
  final s=AppState(),c=WritingController(AppState());expect(c.key,'task2');
  s.session['selWizCard']='t1';expect(WritingController(s).key,'task1');s.examType=ExamType.toefl;expect(WritingController(s).key,'email');
  c.startPlan();expect(c.step,'analysis');expect(c.next(),true);expect(c.step,'arg');expect(c.next(),false);
  c.pickArg(1);expect(c.args,{1});expect(c.next(),true);expect(c.step,'para');c.next();expect(c.step,'vocab');c.next();expect(c.state.current,SurgoPage.writingCompose);
  c.draft='A persisted draft';c.tab='essay';expect(c.draft,'A persisted draft');
 });
 testWidgets('confirm -> inline planning -> draft persists between tabs',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final state=AppState(current:SurgoPage.writingSession)..session['selWizCard']='t2';
  await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:const MaterialApp(home:SurgoShell())));await t.pumpAndSettle();
  await t.ensureVisible(find.text('确认题目'));await t.tap(find.text('确认题目'));await t.pumpAndSettle();expect(state.current,SurgoPage.writingPlan);
  final c=WritingController(state);
  c.pickArg(0);c.step='vocab';c.next();await t.pumpAndSettle();expect(state.current,SurgoPage.writingCompose);
  final start=find.text('开始写作');await t.ensureVisible(start);await t.tap(start);await t.pumpAndSettle();
  await t.enterText(find.byKey(const ValueKey('essay-input')),'A long-term plan is useful.');await t.pump();
  expect(c.draft,'A long-term plan is useful.');
  await t.ensureVisible(find.text('题目'));await t.tap(find.text('题目'));await t.pumpAndSettle();
  expect(c.draft,'A long-term plan is useful.');expect(t.takeException(),isNull);
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
 });
}
