import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/features/ielts_listening/source_gap_field.dart';
void main(){
 testWidgets('source onchange only commits changed value at blur/submit, not untouched blur',(t)async{
  final values=<String>[];await t.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[ListeningSourceGap(onValue:values.add),const TextField()]))));
  final first=find.byType(TextField).first,last=find.byType(TextField).last;
  await t.tap(first);await t.tap(last);await t.pump();expect(values,isEmpty);
  await t.enterText(first,'answer');await t.pump();expect(values,isEmpty);await t.tap(last);await t.pump();expect(values,['answer']);
  await t.tap(first);await t.tap(last);await t.pump();expect(values,['answer']);
  await t.enterText(first,'');await t.tap(last);await t.pump();expect(values,['answer','']);await t.pumpWidget(const SizedBox.shrink());
 });
 testWidgets('source oninput emits every edit; map maxlength1 only',(t)async{
  final values=<String>[];await t.pumpWidget(MaterialApp(home:Scaffold(body:ListeningSourceGap(inputEvent:true,maxLength:1,onValue:values.add))));
  await t.enterText(find.byType(TextField),'AB');expect(values,['A']);await t.enterText(find.byType(TextField),'');expect(values,['A','']);await t.pumpWidget(const SizedBox.shrink());
 });
}
