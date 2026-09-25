import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import '../features/notifications/notification_data.dart';
import '../features/notifications/notifications_page.dart';

/// In-phone overlay, not a desktop-wide dialog. Source toggleSetMenu/toggleNoteMenu.
class GlobalMenu extends StatelessWidget {
  const GlobalMenu(
      {super.key, required this.notifications, required this.close});
  final bool notifications;
  final VoidCallback close;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final zh = state.lang == UiLang.zh;
    void go(SurgoPage p) {
      close();
      state.go(p);
    }

    return Material(
        color: Colors.transparent,
        child: Container(
            width: 298,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: const Color(0xFF181A1E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x1AFFFFFF)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x9E000000),
                      blurRadius: 60,
                      offset: Offset(0, 26))
                ]),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: notifications
                    ? [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(zh ? '消息通知' : 'NOTIFICATIONS',
                                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF969DA6))))),
                        for (final item in surgoNotifications)
                          InkWell(
                              onTap: () => go(SurgoPage.report),
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _icon(item.icon),
                                        const SizedBox(width: 11),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(item.title(zh),
                                                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Color(0xFFF1F2F4))),
                                              const SizedBox(height: 3),
                                              Text(item.detail(zh),
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      height: 1.45,
                                                      color: Color(0xFFA3AAB4)))
                                            ]))
                                      ]))),
                        TextButton(
                            key: const ValueKey('notifications-see-all'),
                            onPressed: () {
                              close();
                              openAllNotifications(context);
                            },
                            child: Text(zh ? '查看全部' : 'See all',
                                style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: SurgoColors.yellow))),
                      ]
                    : [
                        _row(
                            Icons.language,
                            zh ? '中英切换' : 'Language',
                            _segment(['中', 'EN'], zh ? 0 : 1, (i) {
                              final page = state.current;
                              state.setLang(i == 0 ? UiLang.zh : UiLang.en);
                              state.go(page);
                              if (page != SurgoPage.ielts) close();
                            })),
                        _row(
                            Icons.school_outlined,
                            zh ? '切换雅思托福' : 'Exam type',
                            _segment(zh ? ['雅思', '托福'] : ['IELTS', 'TOEFL'],
                                state.examType == ExamType.ielts ? 0 : 1, (i) {
                              state.examType =
                                  i == 0 ? ExamType.ielts : ExamType.toefl;
                              go(SurgoPage.ielts);
                            })),
                        const Divider(
                            color: Color(0x14FFFFFF),
                            indent: 10,
                            endIndent: 10,
                            height: 13),
                        _row(
                            Icons.person_outline,
                            zh ? '个人中心' : 'Profile',
                            const Text('›',
                                style: TextStyle(
                                    fontSize: 17, color: Color(0xFF6B7078))),
                            onTap: () => go(SurgoPage.prep)),
                        // 用户 2026-09-25：退出登录后回到开屏页（原来去的是选科页 exam）。
                        _row(Icons.logout, zh ? '退出登录' : 'Log out',
                            const SizedBox.shrink(),
                            danger: true,
                            onTap: () => go(SurgoPage.authSplash)),
                      ])));
  }

  Widget _icon(IconData icon, {bool danger = false}) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: danger ? const Color(0x21FF6B6F) : const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(11)),
      child: Icon(icon,
          size: 17,
          color: danger ? const Color(0xFFFF6B6F) : const Color(0xFFA9AEB7)));
  Widget _row(IconData icon, String label, Widget trailing,
          {VoidCallback? onTap, bool danger = false}) =>
      InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Row(children: [
                _icon(icon, danger: danger),
                const SizedBox(width: 11),
                Expanded(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: danger
                                ? const Color(0xFFFF6B6F)
                                : const Color(0xFFF1F2F4)))),
                trailing
              ])));
  Widget _segment(List<String> labels, int selected, ValueChanged<int> pick) =>
      Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: const Color(0x17FFFFFF),
              borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < labels.length; i++)
              InkWell(
                  onTap: () => pick(i),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                          color: i == selected
                              ? SurgoColors.yellow
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(labels[i],
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 13,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: i == selected
                                  ? const Color(0xFF241C00)
                                  : const Color(0xFF93989F)))))
          ]));
}
