import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/ielts_mock_writing/controller.dart';
import 'package:surgo_flutter/features/ielts_mock_writing/page.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await QuestionBank.load();await Translator.load();});
 test('shared clock, whitespace words and source two-strike current task gate',(){
  final app=AppState(),c=IeltsMockWritingController(AppState());
  expect(c.config(1)['chartSeries'],isNotEmpty);expect(c.minimum,150);
  c.type('one-two 中文 100');expect(c.words(1),3);expect(c.end(),'short');expect(c.warnCount,1);
  c.select(2);expect(c.minimum,250);expect(c.end(),'shortEnd');
  c.type(List.filled(250,'word').join(' '));expect(c.end(),'end');
  c.tick();c.select(1);expect(c.left,3599);expect(c.words(1),3);
  c.left=1;expect(c.tick(),true);expect(c.left,0);
  final restore=IeltsMockWritingController(c.app);expect(restore.texts,c.texts);expect(restore.left,0);
  app.dispose();
 });
 testWidgets('mock writing task switching retains drafts, first warning cannot submit',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  final app=AppState(current:SurgoPage.mockWritingQ);
  await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Scaffold(body:SingleChildScrollView(padding:const EdgeInsets.all(18),child:const IeltsMockWritingPage())))));
  // 用户 2026-09-24：首屏是【题目】tab，先切到任务1 才有作答区。
  await t.tap(find.byKey(const ValueKey('mw-tab-1')));await t.pump();
  await t.ensureVisible(find.byKey(const ValueKey('mw-draft')));await t.enterText(find.byKey(const ValueKey('mw-draft')),'My test draft');await t.pump();
  await t.ensureVisible(find.byKey(const ValueKey('mw-tab-2')));await t.tap(find.byKey(const ValueKey('mw-tab-2')));await t.pump();
  expect(find.text('0 words / 250 words'),findsOneWidget);
  await t.tap(find.byKey(const ValueKey('mw-tab-1')));await t.pump();expect(find.text('My test draft'),findsOneWidget);
  await t.ensureVisible(find.byKey(const ValueKey('mw-submit')));await t.tap(find.byKey(const ValueKey('mw-submit')));await t.pumpAndSettle();
  expect(find.text('字数不足'),findsOneWidget);await t.tap(find.text('继续').last);await t.pumpAndSettle();expect(app.current,SurgoPage.mockWritingQ);expect(app.session['mwWarnCount'],1);
  await t.tap(find.byKey(const ValueKey('mw-submit')));await t.pumpAndSettle();expect(find.text('结束考试'),findsWidgets);expect(app.session['mwWarnCount'],2);
  expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());
 });
}
