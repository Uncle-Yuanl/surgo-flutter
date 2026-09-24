import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/pages/exam_selection_page.dart';
import 'package:surgo_flutter/features/profile/profile_page.dart';
import 'package:surgo_flutter/features/report/report_page.dart';
import 'package:surgo_flutter/widgets/global_menu.dart';
import 'package:surgo_flutter/widgets/mock_selector.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async { await Translator.load();await QuestionBank.load(); });
  Future<AppState> pump(WidgetTester tester,{SurgoPage page=SurgoPage.exam}) async {
    await tester.binding.setSurfaceSize(const Size(390,844));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final state=AppState(current:page);
    await tester.pumpWidget(ChangeNotifierProvider.value(value:state,child:const MaterialApp(home:SurgoShell())));
    await tester.pumpAndSettle();return state;
  }
  Future<void> tap(WidgetTester t,Finder f) async {await t.ensureVisible(f);await t.tap(f);await t.pumpAndSettle();}
  testWidgets('card selection alone does not switch exam; arrow enters selected exam', (t) async {
    final state=await pump(t);
    expect(find.byType(ExamSelectionPage),findsOneWidget);
    await tap(t,find.byKey(const ValueKey('select-toefl')));
    expect(state.examType,ExamType.ielts);expect(state.current,SurgoPage.exam);
    await tap(t,find.byKey(const ValueKey('enter-toefl')));
    expect(state.examType,ExamType.toefl);expect(state.current,SurgoPage.ielts);
    expect(find.text('今日训练'),findsOneWidget);expect(t.takeException(),isNull);
  });
  testWidgets('settings language -> exam switch -> profile -> logout', (t) async {
    final state=await pump(t,page:SurgoPage.ielts);
    await tap(t,find.byKey(const ValueKey('global-设置')));
    expect(find.byType(GlobalMenu),findsOneWidget);
    await tap(t,find.text('EN'));
    expect(state.lang,UiLang.en);expect(find.byType(GlobalMenu),findsOneWidget);
    await tap(t,find.text('TOEFL'));
    expect(state.examType,ExamType.toefl);expect(find.byType(GlobalMenu),findsNothing);
    await tap(t,find.byKey(const ValueKey('global-设置')));
    await tap(t,find.text('Profile'));
    expect(find.byType(ProfilePage),findsOneWidget);
    await tap(t,find.byKey(const ValueKey('profile-logout')));
    expect(state.current,SurgoPage.exam);expect(t.takeException(),isNull);
  });
  testWidgets('notification fixture opens report and subscription toggles', (t) async {
    final state=await pump(t,page:SurgoPage.ielts);
    await tap(t,find.byKey(const ValueKey('global-消息通知')));
    await tap(t,find.text('模考成绩已更新'));
    expect(state.current,SurgoPage.report);expect(find.byType(ReportPage),findsOneWidget);
    await tap(t,find.text('订阅'));expect(find.text('已订阅'),findsOneWidget);
    // Let the framework report any layout exception with its full widget stack.
  });
  testWidgets('reading generate button remains horizontal and tappable at390px',(t)async{
    await pump(t,page:SurgoPage.readingDaily);
    final button=find.byKey(const ValueKey('reading-generate'));
    await t.ensureVisible(button);
    final size=t.getSize(button);
    expect(size.width,greaterThan(180));expect(size.height,lessThan(70));
    expect(t.takeException(),isNull);
  });
  test('mock selector preserves all four subject route mappings',(){
    expect(mockStartTarget('listening',ExamType.ielts),SurgoPage.mockListening);
    expect(mockStartTarget('reading',ExamType.ielts),SurgoPage.mockReading);
    expect(mockStartTarget('speaking',ExamType.ielts),SurgoPage.mockSpeaking);
    expect(mockStartTarget('writing',ExamType.ielts),SurgoPage.mockWritingIntro);
    expect(mockStartTarget('writing',ExamType.toefl),SurgoPage.mockWritingTf);
  });
}
