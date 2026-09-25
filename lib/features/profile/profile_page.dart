import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';

/// Source V.prep; demo identity/scores are fixtures, not authenticated account data.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.now});
  final DateTime? now;
  static const icons = {
    '考试信息':
        '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>',
    '账号安全':
        '<path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6z"/><path d="M9 12l2 2 4-4"/>',
    '语言设置':
        '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
    '帮助与支持':
        '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.8.4-1 .9-1 1.7M12 17h.01"/>',
  };
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = now ?? DateTime.now();
    final date = DateTime(base.year, base.month, base.day + 20);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateText = state.lang == UiLang.en
        ? '${months[date.month - 1]} ${date.day}, ${date.year}'
        : '${date.year}年${date.month}月${date.day}日';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                key: const ValueKey('profile-back'),
                onTap: () => state.go(SurgoPage.ielts),
                child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: SurgoColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        const SourceText('←', style: TextStyle(fontSize: 12)))),
            const T('个人中心', style: SurgoText.profileTitle),
            const SizedBox(width: 40, height: 40),
          ])),
      Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 18),
          child: Column(children: [
            CustomPaint(
                painter: const _AvatarOuterShadow(),
                child: Container(
                    key: const ValueKey('profile-avatar'),
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                        shape: BoxShape.circle),
                    child: ClipOval(
                        child: Image.asset('assets/images/otter_glasses.png',
                            fit: BoxFit.cover)))),
            const SizedBox(height: 14),
            const SourceText('Miki Jin', style: SurgoText.profileName),
            const SizedBox(height: 4),
            const SourceText('miki.jin@example.com',
                style: TextStyle(fontSize: 13, color: SurgoColors.muted)),
          ])),
      Container(
          key: const ValueKey('profile-stats'),
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: const BoxDecoration(
              color: SurgoColors.yellow,
              borderRadius: SurgoRadius.baseAll,
              boxShadow: SurgoShadow.yellowCard),
          child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Expanded(
                    child: _stat(state.lang, '6.3', '/9', '目前成绩', '目标 7.0')),
                Container(
                    width: 1,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    color: const Color(0x2E3A2E00)),
                Expanded(
                    child: _stat(state.lang, '20', '天', '考试倒计时', dateText)),
              ]))),
      const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: T('设置', style: SurgoText.profileSection)),
      for (final entry in icons.entries)
        GestureDetector(
            behavior: HitTestBehavior.opaque,
            key: ValueKey('profile-${entry.key}'),
            onTap: () => showDialog<void>(
                context: context,
                useRootNavigator: false,
                builder: (c) => AlertDialog(
                        content: Text('（原型）${entry.key}'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const T('OK'))
                        ])),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
                decoration: BoxDecoration(
                    border: entry.key == '帮助与支持'
                        ? null
                        : const Border(
                            bottom: BorderSide(color: SurgoColors.line))),
                child: Row(children: [
                  Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: SurgoColors.line, width: 1.5),
                          borderRadius: BorderRadius.circular(12)),
                      child: SvgPicture.string(
                          '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="#1c1a17" stroke-width="1.8">${entry.value}</svg>',
                          width: 20,
                          height: 20)),
                  const SizedBox(width: 16),
                  Expanded(child: T(entry.key, style: SurgoText.rowLabel)),
                  const SourceText('›',
                      style: TextStyle(fontSize: 18, color: SurgoColors.arrow)),
                ]))),
      GestureDetector(
          behavior: HitTestBehavior.opaque,
          key: const ValueKey('profile-logout'),
          // 用户 2026-09-25：退出登录后回到开屏页。
          // 原型这里去的是选科页（exam），现在有了登录注册流程，改为开屏页，
          // 与全局菜单里的「退出登录」保持一致。
          onTap: () => state.go(SurgoPage.authSplash),
          child: const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 8),
              child: T('退出登录',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SurgoColors.danger)))),
    ]);
  }

  Widget _stat(UiLang lang, String n, String unit, String label, String sub) =>
      Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SourceText(n,
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 36,
                      height: 1,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w900,
                      color: SurgoColors.onYellowStrong)),
              const SizedBox(width: 3),
              Flexible(
                  child: T(unit,
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 15,
                          height:
                              1, // Source unit inherits .pf-stat-n line-height:1.
                          fontWeight: FontWeight.w800,
                          color: SurgoColors.onYellowStrong))),
            ]),
        const SizedBox(height: 9),
        T(label,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 13,
                // Measured source CJK line box is 18px (Latin 13px).
                height: lang == UiLang.zh ? 18 / 13 : 1,
                fontWeight: FontWeight.w800,
                color: SurgoColors.onYellowStrong)),
        const SizedBox(height: 3),
        T(sub,
            style: TextStyle(
                fontSize: 10,
                height: lang == UiLang.zh ? 14 / 10 : 1,
                color: SurgoColors.onYellowSoft)),
      ]);
}

/// CSS outer box-shadow never paints under the transparent replaced image.
class _AvatarOuterShadow extends CustomPainter {
  const _AvatarOuterShadow();
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    // CanvasKit's blurred draw leaked through the difference-path clip in a
    // real Web capture. Clear the interior on its own layer after the blur.
    canvas.saveLayer(bounds.inflate(80), Paint());
    final shadow = SurgoShadow.avatar.single;
    canvas.drawOval(bounds.shift(shadow.offset), shadow.toPaint());
    canvas.drawOval(bounds, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarOuterShadow oldDelegate) => false;
}
