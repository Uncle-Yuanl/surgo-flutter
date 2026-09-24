import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/ielts_mock_reading/controller.dart';
import 'package:surgo_flutter/features/ielts_mock_reading/page.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late List data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await IeltsMockReadingData.load();});
 test('40 source questions, inherited headings and answer removal preserve original values',(){
  final c=IeltsMockReadingController(AppState(),data);expect(data.map((p)=>(p['qs'] as List).length).toList(),[14,13,13]);expect(c.total,40);
  c.pick(0,2);c.type(12,'  exact text  ');expect(c.answers[12],{'v':'  exact text  '});c.type(12,'  ');expect(c.answers.containsKey(12),false);
  c.select(3);expect(c.base(3),27);expect(c.group(4)['letters'],['i','ii','iii','iv','v','vi']);expect(c.group(7)['letters'],['A','B','C','D','E']);
  c.tick();c.select(2);expect(c.left,3599);expect(c.count(1),1);c.pick(0,null);expect(c.count(1),0);
  c.left=1;expect(c.tick(),true);expect(IeltsMockReadingController(c.app,data).left,0);
 });
 testWidgets('all three passages390, answers survive switches, sheet drag works',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final app=AppState(current:SurgoPage.mockReadingQ);
  await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:Scaffold(body:IeltsMockReadingPage()))));await t.pump();
  await t.ensureVisible(find.byKey(const ValueKey('mr-pick-0-1')));await t.tap(find.byKey(const ValueKey('mr-pick-0-1')));await t.pump();expect((app.session['mrAns'] as Map)[0],2);
  await t.tap(find.byKey(const ValueKey('mr-passage-2')));await t.pump();expect(find.text('Persuasion and Smell'),findsOneWidget);
  await t.tap(find.byKey(const ValueKey('mr-passage-3')));await t.pump();expect(find.text('The Science of Building with Bamboo'),findsOneWidget);
  await t.ensureVisible(find.byKey(const ValueKey('mr-input-39')));await t.enterText(find.byKey(const ValueKey('mr-input-39')),'nodes');await t.pump();
  final old=t.getTopLeft(find.byKey(const ValueKey('mr-drag'))).dy;await t.drag(find.byKey(const ValueKey('mr-drag')),const Offset(0,60));await t.pump();expect(t.getTopLeft(find.byKey(const ValueKey('mr-drag'))).dy,greaterThan(old));
  await t.tap(find.byKey(const ValueKey('mr-passage-1')));await t.pump();expect((app.session['mrAns'] as Map)[0],2);expect((app.session['mrAns'] as Map)[39],{'v':'nodes'});
  expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());
 });
}
