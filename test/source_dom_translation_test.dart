import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();setUpAll(SourceNodeTranslations.load);
 test('2026 route-specific translations exactly match captured original applyLang nodes',(){
  final source=jsonDecode(File('test/fixtures/source_dom_nodes.json').readAsStringSync());var count=0;
  for(final entry in SourceNodeTranslations.routes.entries){for(final lang in (entry.value as Map).entries){final row=(source['rows'] as List).firstWhere((r)=>r['route']==entry.key&&r['lang']==lang.key);
   for(final pair in (lang.value as Map).entries){expect((row['nodes'] as List).any((n)=>n['before'].trim()==pair.key&&n['after'].trim()==pair.value),true);count++;}
  }}expect(count,2026);
  expect(SourceNodeTranslations.lookup('unseen question','vocabWord','zh'),'unseen question');expect(SourceNodeTranslations.lookup('Identify','oralExam','zh'),'Identify');
 });
 testWidgets('route allowlist changes source display only, preserves input and unmatched text',(t)async{
  final state=AppState(current:SurgoPage.vocabWord),draft=TextEditingController(text:'Identify');
  await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(home:Scaffold(body:Column(children:[const SourceText('Identify'),const SourceText('custom question'),TextField(controller:draft)])))));
  expect(find.text('识别'),findsOneWidget);expect(draft.text,'Identify');expect(find.text('custom question'),findsOneWidget);
  await t.pumpWidget(const SizedBox.shrink());draft.dispose();
 });
}
