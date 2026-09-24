import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/features/oral_daily/controller.dart';
import 'package:surgo_flutter/widgets/source_text.dart';

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await QuestionBank.load();await Translator.load();});
 for(final route in [SurgoPage.speakingSession,SurgoPage.oralExam]){
  for(final lang in UiLang.values){
   testWidgets('Part2 ${route.name} ${lang.name}: prepare60s no mic, manual enter retains notes',(t)async{
    await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),(_)async=>1);
    addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),null));
    final app=AppState(current:route,lang:lang)..session['selWizCard']='p2';
    await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:MediaQuery(data:MediaQueryData(size:Size(390,844)),child:SurgoShell()))));
    await t.pumpAndSettle();final c=app.session['oralController'] as OralController;
    expect(c.prepLeft,60);expect(c.preparing,true);
    expect(find.byKey(const ValueKey('oral-mic')),findsNothing);
    expect(find.byKey(const ValueKey('oral-retake')),findsNothing);
    expect(t.widget<SourceText>(find.byKey(const ValueKey('oral-prep-clock'))).data,'01:00');
    const text='First idea / 先前填写的笔记';
    final note=find.byKey(const ValueKey('oral-note'));await t.ensureVisible(note);await t.enterText(note,text);
    expect(c.note,text);expect(app.session['oralNote'],text);
    await t.pump(const Duration(seconds:60));await t.pumpAndSettle();
    expect(c.prepLeft,0);expect(c.phase,'note');expect(find.byKey(const ValueKey('oral-mic')),findsNothing);
    final enter=find.byKey(const ValueKey('oral-enter-exam'));await t.ensureVisible(enter);await t.tap(enter);await t.pumpAndSettle();
    expect(app.current,SurgoPage.oralExam);expect(c.phase,'ready');expect(c.note,text);
    expect(t.widget<TextField>(note).controller!.text,text);
    expect(find.byKey(const ValueKey('oral-prep-clock')),findsNothing);
    expect(find.byKey(const ValueKey('oral-mic')),findsOneWidget);
    await t.tap(find.byKey(const ValueKey('oral-mic')));await t.pump(const Duration(seconds:2));expect(c.phase,'rec');expect(c.recSec,2);
    expect(t.widget<TextField>(note).controller!.text,text);expect(t.widget<TextField>(note).enabled,false);
    await t.tap(find.byKey(const ValueKey('oral-mic')));await t.pump();
    await t.tap(find.byKey(const ValueKey('oral-retake')));await t.pump();expect(c.note,text);expect(c.phase,'ready');
    c.quit();await t.pumpWidget(const SizedBox.shrink());await t.pumpAndSettle();expect(t.takeException(),isNull);
   });
  }
 }
 testWidgets('Part2 allows early entry without clearing notes or restarting preparation',(t)async{
  final app=AppState(current:SurgoPage.oralExam)..session['selWizCard']='p2';
  final c=OralController(app);c.start();c.updateNote('keep');await t.pump(const Duration(seconds:5));expect(c.prepLeft,55);
  c.enterCueExam();await t.pump(const Duration(seconds:10));expect(c.phase,'ready');expect(c.note,'keep');expect(c.prepLeft,55);expect(c.recMax,120);c.dispose();
 });
}
