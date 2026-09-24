import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/features/tf_speaking_daily/controller.dart';
import 'package:surgo_flutter/features/tf_speaking_daily/module.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();late Map<String,dynamic> data;
 setUpAll(()async{await Translator.load();await QuestionBank.load();data=await TfSpeakingData.load();});
 for(final kind in ['retell','interview']){
  test('$kind playback, overtime once, next retains source residual until begin',(){
   final app=AppState(),c=TfSpeakingController(AppState(),kind,data[kind]);expect(c.audioInterval,1000);expect(c.ansSec,kind=='retell'?7:45);
   for(var i=0;i<c.sec;i++){c.audioTick();}expect(c.phase,'ready');c.begin();
   for(var i=0;i<c.ansSec-1;i++){expect(c.tick(),false);}expect(c.tick(),true);expect(c.over,true);expect(c.tick(),false);expect(c.ansUp,1);
   expect(c.next(),true);expect(c.left,0);expect(c.over,true);expect(c.alerted,true);expect(c.ansUp,0);expect(c.phase,'play');
   c.begin();expect(c.left,c.ansSec);expect(c.over,false);expect(c.alerted,false);c.tick();c.retake();expect(c.left,c.ansSec);
   c.index=c.total-1;expect(c.next(),false);app.dispose();
  });
  testWidgets('$kind rendered play clock follows pos not total',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));final app=AppState(examType:ExamType.toefl);
   await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Scaffold(body:SingleChildScrollView(padding:const EdgeInsets.all(18),child:TfSpeakingDailyPage(kind:kind,feedback:false))))));await t.pump();
   expect(find.text('⏱ 00:00'),findsOneWidget);await t.pump(const Duration(seconds:2));expect(find.text('⏱ 00:02'),findsOneWidget);expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());
  });
 }
}
