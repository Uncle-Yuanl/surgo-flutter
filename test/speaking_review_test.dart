import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();setUpAll(()async{await Translator.load();await QuestionBank.load();});
 Future<void> pump(WidgetTester t,AppState state,Key key)async{
  await t.runAsync(() async {await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:key,home:const SurgoShell())));});
  await t.pump();await t.pump(const Duration(milliseconds:400));
 }
 testWidgets('fixed speaking review renders every Part tab natively at 390px',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  // Full-mock mode exposes all three Part tabs together.
  for(final part in ['p1','p2','p3']){
   final state=AppState(current:SurgoPage.speakingReview)..session.addAll({'sessionMode':'mock','spReviewPart':part});
   await pump(t,state,ValueKey('mock-$part'));
   expect(find.byType(PlaceholderPage),findsNothing);
   expect(find.text('第 1 部分'),findsWidgets);expect(find.text('Part 2'),findsWidgets);expect(find.text('Part 3'),findsWidgets);
   expect(t.takeException(),isNull);
  }
 });
 testWidgets('Part 3 shows 10 rounds plus the examiner overall card',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final state=AppState(current:SurgoPage.speakingReview)..session.addAll({'sessionMode':'mock','selWizCard':'p1'});
  await pump(t,state,const ValueKey('rounds'));
  // Switch to the Part 3 tab, then assert all ten rounds + examiner overall.
  await t.ensureVisible(find.text('Part 3').first);await t.pumpAndSettle();
  await t.runAsync(() async {await t.tap(find.text('Part 3').first);await t.pump();});
  await t.pump();await t.pump(const Duration(milliseconds:400));
  for(var r=1;r<=10;r++){expect(find.text('第 $r 轮对话'),findsOneWidget);}
  expect(find.text('考官总评'),findsOneWidget);
  // Fixed source question text (English content) is rendered raw, not translated.
  expect(find.text('Why do people like to visit different places?'),findsOneWidget);
  expect(t.takeException(),isNull);
 });
 testWidgets('daily training lands on the practised Part only',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final state=AppState(current:SurgoPage.speakingReview)..session.addAll({'sessionMode':'daily','selWizCard':'p2'});
  await pump(t,state,const ValueKey('daily'));
  // Only the Part 2 tab is offered; the fixed cue-card coverage block is shown.
  expect(find.text('第 1 部分'),findsNothing);expect(find.text('Part 3'),findsNothing);
  expect(find.text('▤ 话题卡要点覆盖'),findsOneWidget);
  expect(find.byType(PlaceholderPage),findsNothing);expect(t.takeException(),isNull);
 });
}
