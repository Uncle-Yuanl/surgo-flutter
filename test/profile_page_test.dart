import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/features/profile/profile_page.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(()=>Translator.load());
  Future<AppState> pump(WidgetTester tester,{UiLang lang=UiLang.zh}) async {
    final state=AppState(lang:lang,current:SurgoPage.prep);
    await tester.pumpWidget(ChangeNotifierProvider.value(value:state,child:MaterialApp(home:Scaffold(
      body:SingleChildScrollView(child:ProfilePage(now:DateTime(2026,9,21)))))));
    await tester.pumpAndSettle();
    return state;
  }
  testWidgets('fixture identity scores and exact date from source', (tester) async {
    await pump(tester);
    for(final text in ['Miki Jin','miki.jin@example.com','6.3','/9','20','目标 7.0','2026年10月11日']) {
      expect(find.text(text),findsOneWidget);
    }
    expect(tester.takeException(),isNull);
  });
  testWidgets('English date does not alter source fixture scores',(tester) async {
    await pump(tester,lang:UiLang.en);
    expect(find.text('Oct 11, 2026'),findsOneWidget);
    expect(find.text('6.3'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('all source alert rows open and close; do not invent settings screens',(tester) async {
    await pump(tester);
    for(final label in ['考试信息','账号安全','语言设置','帮助与支持']) {
      final row=find.byKey(ValueKey('profile-$label'));
      await tester.ensureVisible(row);await tester.tap(row);await tester.pumpAndSettle();
      expect(find.text('（原型）$label'),findsOneWidget);
      await tester.tap(find.text('确定'));await tester.pumpAndSettle();
      expect(find.byType(AlertDialog),findsNothing);
    }
    expect(tester.takeException(),isNull);
  });
  testWidgets('logout and back only navigate as source',(tester) async {
    final state=await pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('profile-logout')));
    await tester.tap(find.byKey(const ValueKey('profile-logout')));await tester.pump();
    // 用户 2026-09-25：退出登录回到开屏页（原型此处去的是选科页 exam）。
    expect(state.current,SurgoPage.authSplash);
    // 退出后个人中心已不在视图里，返回键要重新挂载页面才能验证。
    final back=await pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('profile-back')));
    await tester.tap(find.byKey(const ValueKey('profile-back')));await tester.pump();
    expect(back.current,SurgoPage.ielts);
  });
}
