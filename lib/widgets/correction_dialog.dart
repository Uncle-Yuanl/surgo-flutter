import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/routes.dart';
import '../features/ielts_reading/reading_overtime.dart' show readingOvertimeBackground;
import '../theme/tokens.dart';
import 'primitives.dart';
import 'styled_loop_video.dart';
import 't.dart';
Future<void> showCorrection(BuildContext c,SurgoPage target)=>showDialog<void>(context:c,useRootNavigator:false,barrierDismissible:false,builder:(_)=>_Correction(target:target));
class _Correction extends StatefulWidget{const _Correction({required this.target});final SurgoPage target;@override State<_Correction> createState()=>_CorrectionState();}
class _CorrectionState extends State<_Correction> with SingleTickerProviderStateMixin{
 late final AnimationController a;Timer? tail;
 @override void initState(){super.initState();a=AnimationController(vsync:this,duration:const Duration(milliseconds:3200))..addStatusListener((s){if(s==AnimationStatus.completed)tail=Timer(const Duration(milliseconds:500),finish);})..forward();}
 void finish(){if(!mounted)return;final s=context.read<AppState>();Navigator.pop(context);s.go(widget.target);}
 @override void dispose(){tail?.cancel();a.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Dialog(child:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
  Image.asset('assets/images/correction_otter.png',height:160),const SizedBox(height:14),const T('作文批改中，先休息一下',style:SurgoText.sheetTitle),const SizedBox(height:18),
  AnimatedBuilder(animation:a,builder:(_,__)=>Column(children:[LinearProgressIndicator(value:a.value,color:SurgoColors.yellow),Text('${(a.value*100).round()}%')])),const SizedBox(height:18),SurgoButton('关闭',onTap:finish),const SizedBox(height:14),
  const T('批改需要一点时间，你可以先关闭页面去完成其他任务。之后在「历史记录」里查看批改结果。',style:SurgoText.cardDesc),
 ]))));
}
/// 退出考试确认 —— 用户 2026-09-24 要求与其它弹窗（超时弹窗）同一套样式，
/// 配图复用「时间到」的 timeup 动画。不再用 Material 默认 AlertDialog。
Future<void> showExamExit(BuildContext context) => showDialog<void>(
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
                key: const ValueKey('exam-exit'),
                width: 330,
                padding: const EdgeInsets.all(28),
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
                      const T('确定要退出考试吗？',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontFamilyFallback: SurgoFontFamily.fallback,
                              fontSize: 17,
                              height: 1.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1c1a17))),
                      const SizedBox(height: 8),
                      const T('进度将为你保留，下次可以接着作答。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: SurgoColors.muted)),
                      const SizedBox(height: 26),
                      GestureDetector(
                          key: const ValueKey('exam-exit-stay'),
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                              padding: const EdgeInsets.all(17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xfffbd45f),
                                  borderRadius: BorderRadius.circular(26)),
                              child: const T('继续考试',
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontFamilyFallback:
                                          SurgoFontFamily.fallback,
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xff3a2e00))))),
                      const SizedBox(height: 10),
                      GestureDetector(
                          key: const ValueKey('exam-exit-leave'),
                          onTap: () {
                            final s = ctx.read<AppState>();
                            Navigator.pop(ctx);
                            s.session['spqRec'] = false;
                            s.session['spqBusy'] = false;
                            s.go(SurgoPage.ielts);
                          },
                          child: Container(
                              padding: const EdgeInsets.all(17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: SurgoColors.line),
                                  borderRadius: BorderRadius.circular(26)),
                              child: const T('退出考试',
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontFamilyFallback:
                                          SurgoFontFamily.fallback,
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xff1c1a17))))),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
