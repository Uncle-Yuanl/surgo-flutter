import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/widgets/continue_sheet.dart';
import 'package:surgo_flutter/features/ielts_listening/listening_data.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await Translator.load();await QuestionBank.load();await ContinueData.load();await IeltsListeningData.load();});
 Future<void> mount(WidgetTester t,AppState app)async{await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:MaterialApp(home:Builder(builder:(ctx)=>Scaffold(body:TextButton(onPressed:()=>showContinueSheet(ctx),child:const Text('open')))))));await t.tap(find.text('open'));await t.pumpAndSettle();}
 for(final lang in UiLang.values){testWidgets('continue tabs390 ${lang.name}, recommended follows filtered index',(t)async{final app=AppState(lang:lang);await mount(t,app);for(var i=0;i<5;i++){expect(find.byKey(ValueKey('continue-item-$i')),findsOneWidget);}await t.tap(find.byKey(const ValueKey('continue-tab-mock')));await t.pump();expect(find.byKey(const ValueKey('continue-item-0')),findsNothing);expect(find.byKey(const ValueKey('continue-item-3')),findsOneWidget);await t.tap(find.byKey(const ValueKey('continue-item-3')));await t.pumpAndSettle();expect(app.current,SurgoPage.speakingDaily);expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());});}
 for(final i in [0,1,2,4]){testWidgets('continue source item$i writes exact done counts and preserves mode',(t)async{final app=AppState()..session.addAll({'sessionMode':'mock','lisPart':'s1','selWizCard':'t2'});await mount(t,app);await t.ensureVisible(find.byKey(ValueKey('continue-item-$i')));await t.tap(find.byKey(ValueKey('continue-item-$i')));await t.pumpAndSettle();expect(app.session['sessionMode'],'mock');
  if(i==0){expect(app.current,SurgoPage.writingSession);}else if(i==2){expect(app.current,SurgoPage.listeningSession);final n=(IeltsListeningData.cache!.raw['parts']['s1']['qs'] as List).length;expect(app.session['lisDone'],Set.of(List.generate((n*.8).round(),(i)=>i)));expect(app.session['lisIdx'],(n*.8).round());}else{expect(app.current,SurgoPage.readingSession);final n=(QuestionBank.instance.skill('reading',app.examType)['daily']['questions'] as List).length;expect(app.session['readDone'],Set.of(List.generate((n*(i==1 ? .6 : .1)).round(),(i)=>i)));expect(app.session['selReadType'],null);}
  expect(t.takeException(),isNull);await t.pumpWidget(const SizedBox.shrink());});}
}
