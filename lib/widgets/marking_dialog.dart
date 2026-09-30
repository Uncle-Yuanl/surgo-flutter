import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import 'demo_audio.dart';
import 'primitives.dart';
import 't.dart';

Future<void> showMarking(BuildContext context,SurgoPage target,String label) {
 demoAudio.stop(); // 交卷了，还在放的录音这就停（不等两秒后换页）
 return showDialog<void>(
  context:context,useRootNavigator:false,barrierDismissible:false,builder:(_)=>_Marking(target:target,label:label));
}
class _Marking extends StatefulWidget {
 const _Marking({required this.target,required this.label});
 final SurgoPage target;
 final String label;
 @override
 State<_Marking> createState()=>_MarkingState();
}
class _MarkingState extends State<_Marking> with SingleTickerProviderStateMixin {
 late final AnimationController progress;
 Timer? tail;
 @override
 void initState(){super.initState();progress=AnimationController(vsync:this,duration:const Duration(seconds:2))
 ..addStatusListener((status){if(status==AnimationStatus.completed)tail=Timer(const Duration(milliseconds:200),(){if(mounted)_go(widget.target);});})..forward();}
 void _go(SurgoPage page){final state=context.read<AppState>();Navigator.pop(context);state.go(page);}
 @override
 void dispose(){tail?.cancel();progress.dispose();super.dispose();}
 @override
 Widget build(BuildContext context){
  final label=widget.label;
  final subject=label.contains('口语')?'口语作答':RegExp('Passage|阅读').hasMatch(label)?'阅读答卷':RegExp('听力|听后|听对话|听通知|听学术').hasMatch(label)?'听力答卷':'作文';
  return Dialog(shape:const RoundedRectangleBorder(borderRadius:SurgoRadius.dialogAll),child:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Image.asset('assets/images/otter_study.png',width:120,height:120),const SizedBox(height:18),T('正在批改你的$subject...',textAlign:TextAlign.center,style:SurgoText.sheetTitle),
   const SizedBox(height:12),const T('考官正按官方评分标准逐题打分，请稍候片刻。',textAlign:TextAlign.center,style:SurgoText.cardDesc),
   const SizedBox(height:18),AnimatedBuilder(animation:progress,builder:(_,__)=>Column(children:[
    LinearProgressIndicator(value:progress.value,color:SurgoColors.yellow,backgroundColor:SurgoColors.track),const SizedBox(height:8),
    Row(children:[Expanded(child:T(label,style:SurgoText.cardDesc)),Text('${(progress.value*100).round()}%')]),
   ])),const SizedBox(height:18),SurgoButton('返回主页，完成后通知我',primary:false,onTap:()=>_go(SurgoPage.ielts)),const SizedBox(height:12),
   const T('所有任务均已保存，不会丢失。你可以放心离开，稍后回来查看成绩。',style:SurgoText.cardDesc),
  ]))));
 }
}
