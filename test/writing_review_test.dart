import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/shell.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();setUpAll(()async{await Translator.load();await QuestionBank.load();});
 testWidgets('fixed original Task1/Task2 and L1 feedback render at390px',(t)async{
  await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
  for(final task in [1,2]){for(final tab in ['mark','l1']){
   final state=AppState(current:SurgoPage.writingFeedback)..session.addAll({'wfTask':task,'wfTab':tab});
   await t.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(key:ValueKey('$task-$tab'),home:const SurgoShell())));await t.pumpAndSettle();
   expect(find.byType(PlaceholderPage),findsNothing);expect(find.text('Task 1'),findsOneWidget);expect(find.text('Task 2'),findsOneWidget);expect(t.takeException(),isNull);
  }}
 });
}
