import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/tf_writing/controller.dart';
import 'package:surgo_flutter/features/tf_writing/module.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await Translator.load();await QuestionBank.load();await TfWritingData.load();});
 testWidgets('actual sentence bank drag does not restore stale410sec clock',(t)async{
  await t.binding.setSurfaceSize(const Size(390,1100));addTearDown(()=>t.binding.setSurfaceSize(null));final app=AppState(current:SurgoPage.tfWr1Q)..session.addAll({'tfw1Left':410,'tfw1Done':List.filled(10,false),'tfw1Seen':List.filled(10,false)});
  await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:Scaffold(body:SingleChildScrollView(padding:EdgeInsets.all(18),child:TfWritingPage(page:SurgoPage.tfWr1Q))))));await t.pump();
  await t.pump(const Duration(seconds:5));expect(app.session['tfw1Left'],405);
  final drag=find.byWidgetPredicate((w)=>w is Draggable<(int,int?)>).first;
  final target=find.byKey(const ValueKey('sentence-slot-0'));
  await t.ensureVisible(drag);await t.pump();
  final gesture=await t.startGesture(t.getCenter(drag));await t.pump(const Duration(milliseconds:100));await gesture.moveTo(t.getCenter(target));await t.pump(const Duration(milliseconds:100));await gesture.up();await t.pump();
  expect((app.session['tfw1Slots'] as List)[0],0);expect(app.session['tfw1Left'],405);
  await t.pump(const Duration(seconds:2));expect(app.session['tfw1Left'],403);
  await t.ensureVisible(find.text('下一段 →'));await t.tap(find.text('下一段 →'));await t.pump();expect(app.session['tfw1Idx'],1);expect(app.session['tfw1Left'],403);expect((app.session['tfw1Slots'] as List).every((e)=>e==null),true);
  expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());
 });
}
