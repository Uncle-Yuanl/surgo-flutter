import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/app/i18n.dart';
/// Initial-state rendering audit only. Full visual/state equivalence is separate.
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await Translator.load();await QuestionBank.load();});
 testWidgets('141 routes x2 UI languages: loaded bodies and layout errors recorded',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),(call) async=>1);
  addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),null));
  final rows=<Map<String,dynamic>>[];
  for(final lang in UiLang.values){for(final page in SurgoPage.values){
   final state=AppState(current:page,lang:lang,examType:page.name.startsWith('tf')?ExamType.toefl:ExamType.ielts);
   final errors=<String>[];
   final oldError=FlutterError.onError;FlutterError.onError=(details){errors.add(details.toString());oldError?.call(details);};
   await t.runAsync(()async{await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:ValueKey('${page.name}-${lang.name}'),home:const SurgoShell())));});
   await t.pump();await t.pump(const Duration(milliseconds:410));
   Object? error;while((error=t.takeException())!=null){errors.add(error.toString());}
   FlutterError.onError=oldError;
   // User-requested flat surfaces across every initial route; chart painters are separate.
   for(final box in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))){
     if(box.decoration is BoxDecoration && (box.decoration as BoxDecoration).gradient!=null){errors.add('Background gradient remains on ${page.name}');}
   }
   final texts=find.byType(Text).evaluate().map((e)=>e.widget as Text).map((w)=>w.data??w.textSpan?.toPlainText()??'').where((s)=>s.trim().isNotEmpty).toSet().toList();
   final loading=find.byWidgetPredicate((w)=>w is CircularProgressIndicator&&w.value==null).evaluate().length;
   rows.add({'key':page.name,'lang':lang.name,'native':find.byType(PlaceholderPage).evaluate().isEmpty,'layoutErrors':errors,'indeterminateIndicators':loading,'text':texts});
  }}
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
  final errors=rows.where((r)=>(r['layoutErrors'] as List).isNotEmpty||r['native']==false||r['indeterminateIndicators']!=0).toList();
  await t.runAsync(()async{final dir=Directory('build/audit')..createSync(recursive:true);File('${dir.path}/bilingual_routes.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'states':rows.length,'failed':errors.length,'routes':rows}));});
  expect(errors,isEmpty,reason:jsonEncode(errors.map((r)=>{'key':r['key'],'lang':r['lang'],'errors':r['layoutErrors'],'loading':r['indeterminateIndicators']}).toList()));
 });
}
