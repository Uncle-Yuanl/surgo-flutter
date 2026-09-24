import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/notifications/notifications_page.dart';
import 'package:surgo_flutter/features/notifications/notification_data.dart';
import 'package:surgo_flutter/widgets/global_menu.dart';
import 'package:surgo_flutter/widgets/t.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
  });
  Future<AppState> mount(WidgetTester t, UiLang lang) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final state = AppState(current: SurgoPage.ielts, lang: lang);
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: state,
        child:
            MaterialApp(theme: SurgoTheme.build(), home: const SurgoShell())));
    await t.pumpAndSettle();
    return state;
  }

  Future<void> openMenu(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('global-消息通知')));
    await t.pumpAndSettle();
  }

  for (final lang in UiLang.values) {
    testWidgets(
        '${lang.name} home white compact banner matches reference2 CTA overlaps IP',
        (t) async {
      await mount(t, lang);
      final image = find.byKey(const ValueKey('home-complete-illustration'));
      final asset = t.widget<Image>(image);
      expect((asset.image as AssetImage).assetName, 'assets/images/otter6.png');
      expect(asset.fit, BoxFit.contain);
      expect(asset.width, 88);
      expect(asset.height, 109);
      final surface=t.widget<Container>(find.byKey(const ValueKey('home-ip-card')));
      expect((surface.decoration as BoxDecoration).color,Colors.white);
      expect(surface.constraints!.maxHeight,140);
      final card = t.getRect(find.byKey(const ValueKey('home-ip-card')));
      expect(card.contains(t.getRect(image).topLeft), isTrue);
      expect(card.contains(t.getRect(image).bottomRight), isTrue);
      final imageRect = t.getRect(image),
          ctaRect = t.getRect(find.byKey(const ValueKey('home-continue')));
      expect(imageRect.overlaps(ctaRect),isTrue);
      expect(imageRect.top-card.top,closeTo(14*card.height/140,.1));
      expect(imageRect.left, greaterThanOrEqualTo(18));
      expect(imageRect.right, lessThanOrEqualTo(372));
      final label = t.widget<T>(
          find.byWidgetPredicate((w) => w is T && w.text == 'Reading'));
      expect(label.style!.fontSize, 13);
      final countdown = t.widget<TSpan>(find.byType(TSpan).first);
      expect(countdown.style!.fontSize, 10);
      expect(countdown.highlightStyle!.fontSize, 12);
      expect(t.takeException(), isNull);
    });
    testWidgets(
        '${lang.name} see all opens native page, back restores home, fixture opens report',
        (t) async {
      final app = await mount(t, lang);
      await openMenu(t);
      expect(find.byType(GlobalMenu), findsOneWidget);
      for (final item in surgoNotifications) {
        final text = t.widget<Text>(find.text(item.detail(lang == UiLang.zh)));
        expect(text.style!.fontSize, 13);
      }
      await t.tap(find.byKey(const ValueKey('notifications-see-all')));
      await t.pumpAndSettle();
      expect(find.byType(AllNotificationsPage), findsOneWidget);
      expect(find.byType(GlobalMenu), findsNothing);
      expect(app.current, SurgoPage.ielts);
      for (final item in surgoNotifications) {
        expect(find.byKey(ValueKey('notification-${item.id}')), findsOneWidget);
        expect(find.text(item.detail(lang == UiLang.zh)), findsOneWidget);
      }
      await t.tap(find.byKey(const ValueKey('all-notifications-back')));
      await t.pumpAndSettle();
      expect(find.byType(AllNotificationsPage), findsNothing);
      expect(app.current, SurgoPage.ielts);
      await openMenu(t);
      await t.tap(find.byKey(const ValueKey('notifications-see-all')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('notification-mock-score')));
      await t.pumpAndSettle();
      expect(app.current, SurgoPage.report);
      expect(find.byType(AllNotificationsPage), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
}
