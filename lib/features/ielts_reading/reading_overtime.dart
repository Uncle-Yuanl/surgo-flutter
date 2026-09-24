import 'package:flutter/material.dart';
import '../../widgets/t.dart';
import '../../widgets/styled_loop_video.dart';
import '../../theme/tokens.dart';

// Final Chromium media compositing adds1 to the decoded250 edge: use the
// displayed251 (#FBFBFB), measured in both language screenshots, not raw canvas.
const readingOvertimeBackground = Color(0xfffbfbfb);

Future<void> showReadingOvertime(BuildContext context) => showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      barrierColor: const Color(0x73140f05),
      useSafeArea: false,
      builder: (ctx) => DefaultTextStyle(
        style: DefaultTextStyle.of(context).style,
        child: Dialog(
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: readingOvertimeBackground,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 330, maxHeight: MediaQuery.sizeOf(ctx).height - 48),
            child: SingleChildScrollView(
              child: Container(
                key: const ValueKey('reading-overtime'),
                width: 330,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                color: readingOvertimeBackground,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                          child: StyledLoopVideo(
                              asset: 'assets/video/timeup.mp4',
                              width: 212,
                              height: 212,
                              radius: 14)),
                      const SizedBox(height: 14.5),
                      const T('已经超时了，你需要加快一点速度',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 17,
                              height: 1.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1c1a17))),
                      const SizedBox(height: 26),
                      GestureDetector(
                          key: const ValueKey('reading-overtime-close'),
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                              padding: const EdgeInsets.all(17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xfffbd45f),
                                  borderRadius: BorderRadius.circular(26)),
                              child: const T('返回作答',
                                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xff3a2e00))))),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
