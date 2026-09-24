import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{await Translator.load();await QuestionBank.load();});
 for(final lang in UiLang.values){for(final page in [SurgoPage.writingImprove,SurgoPage.writingBands,SurgoPage.writingL1Error,SurgoPage.writingL1Detail]){
  testWidgets('${page.name} ${lang.name} content fits390',(t)async{
   await t.binding.setSurfaceSize(const Size(390,844));addTearDown(()=>t.binding.setSurfaceSize(null));
   final app=AppState(current:page,lang:lang);
   await t.runAsync(()async{await t.pumpWidget(ChangeNotifierProvider.value(value:app,child:const MaterialApp(home:SurgoShell())));});
   await t.pump();await t.pump(const Duration(milliseconds:400));
   expect(find.byType(PlaceholderPage),findsNothing);expect(find.byType(CircularProgressIndicator),findsNothing);
   expect(find.byType(SingleChildScrollView),findsWidgets);expect(find.byType(Text),findsWidgets);expect(t.takeException(),isNull);
   await t.pumpWidget(const SizedBox.shrink());
  });
 }}
}
