import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/phone_frame.dart';
import 'notification_data.dart';

/// User-requested extension, not a claimed 142nd H5 migration route.
/// A nested native Navigator route preserves the page and scroll position below.
Future<void> openAllNotifications(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/notifications'),
        builder: (_) => const AllNotificationsPage()));

class AllNotificationsPage extends StatelessWidget {
  const AllNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    return Material(
        color: SurgoColors.warmWhite,
        textStyle: const TextStyle(
            fontFamily: 'VioletSans',
            height: kTextHeightNone,
            fontSize: 14,
            letterSpacing: 0,
            color: SurgoColors.ink),
        child: Stack(children: [
          Positioned.fill(
              top: 52,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 18, 12),
                    child: Row(children: [
                      IconButton(
                          key: const ValueKey('all-notifications-back'),
                          tooltip: zh ? '返回' : 'Back',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(zh ? '全部消息通知' : 'All notifications',
                              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 22, fontWeight: FontWeight.w800))),
                    ])),
                Expanded(
                    child: ListView.separated(
                  key: const ValueKey('all-notifications-list'),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                  itemCount: surgoNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = surgoNotifications[index];
                    return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          key: ValueKey('notification-${item.id}'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.pop(context);
                            app.go(SurgoPage
                                .report); // Preserve existing fixture action.
                          },
                          child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  border: Border.all(color: SurgoColors.line),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                            color: SurgoColors.yellowTint,
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        child: Icon(item.icon,
                                            color: SurgoColors.ink, size: 21)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(item.title(zh),
                                              style: const TextStyle(
                                                  fontFamily: 'VioletSans',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: SurgoColors.ink)),
                                          const SizedBox(height: 6),
                                          Text(item.detail(zh),
                                              style: const TextStyle(
                                                  fontFamily: 'VioletSans',
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: Color(0xff777164))),
                                        ])),
                                  ])),
                        ));
                  },
                )),
              ])),
          const Positioned(top: 0, left: 0, right: 0, child: PhoneStatusBar()),
          const Positioned(top: 0, left: 0, right: 0, child: PhoneNotch()),
        ]));
  }
}
