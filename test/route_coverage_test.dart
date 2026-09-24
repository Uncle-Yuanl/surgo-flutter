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

/// This is an honest integration audit, not a claimed parity test. Routes that
/// still render PlaceholderPage are listed as missing, never counted complete.
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await Translator.load();await QuestionBank.load();});
 testWidgets('audit every registered route at390px; write actual missing list',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),(call) async=>1);
  addTearDown(()=>TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),null));
  final routes=<Map<String,dynamic>>[];
  for(final page in SurgoPage.values){
   final state=AppState(current:page,examType:page.name.startsWith('tf')?ExamType.toefl:ExamType.ielts);
   await t.runAsync(()async{await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:ValueKey(page),home:const SurgoShell())));});
   await t.pump(const Duration(milliseconds:60));await t.pump(const Duration(milliseconds:350));
   final errors=<String>[];Object? error;
   while((error=t.takeException())!=null){errors.add(error.toString());}
   final mounted= <String>{};
   for(final element in find.byType(SurgoShell).evaluate()){
    void collect(Element e){mounted.add(e.widget.runtimeType.toString());e.visitChildren(collect);}
    collect(element);
   }
   routes.add({'key':page.name,'native':find.byType(PlaceholderPage).evaluate().isEmpty,'layoutErrors':errors,'mountedTypes':mounted.toList()});
  }
  await t.pumpWidget(const SizedBox.shrink());await t.pump();
  final missing=routes.where((r)=>r['native']==false).map((r)=>r['key']).toList();
  final errors=routes.where((r)=>(r['layoutErrors'] as List).isNotEmpty).toList();
  await t.runAsync(()async{
   Directory('build').createSync(recursive:true);
   File('build/route_coverage.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'total':routes.length,'native':routes.length-missing.length,'missing':missing,'errors':errors,'routes':routes}));
  });
  expect(errors,isEmpty,reason:jsonEncode(errors));
 });
}
