import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/loop_video.dart';
import 'controller.dart';

/// Legacy source speakingSession is a preview; the daily wizard bypasses it.
class SpeakingSessionPage extends StatefulWidget {
 const SpeakingSessionPage({super.key});
 @override
 State<SpeakingSessionPage> createState()=>_SpeakingSessionPageState();
}
class _SpeakingSessionPageState extends State<SpeakingSessionPage> {
 Timer? timer; int left=120,over=0;
 @override
 void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;
  setState((){if(left>0){left--;}else{over++;}});
  if(left==0&&over==0)showDialog<void>(context:context,useRootNavigator:false,builder:(ctx)=>Dialog(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[const LoopVideo(asset:'assets/video/timeup.mp4'),const T('已经超时了，你需要加快一点速度',style:SurgoText.sheetTitle),SurgoButton('返回作答',onTap:()=>Navigator.pop(ctx))]))));
 });}
 @override
 void dispose(){timer?.cancel();super.dispose();}
 @override
 Widget build(BuildContext context){final app=context.watch<AppState>(),card=context.read<AppState>().session['selWizCard'];
  final tf=app.examType==ExamType.toefl,d=QuestionBank.instance.skill('speaking',app.examType)['daily'] as Map;
  final q=OralTask.fromBank(app.examType,card as String?);
  final title=tf?'TOEFL 口语 · 接受访谈':card=='p1'?'IELTS 口语 · Part 1 面谈':card=='p3'?'IELTS 口语 · Part 3 讨论':card=='pron'?'口语 · 发音专项训练':'IELTS 口语 · Part 2 长时独白';
  final sub=tf?'听问题后作答，每题约 45 秒，无准备时间。':card=='p1'?'就熟悉话题作答，每题约 15–30 秒。':card=='p3'?'围绕话题展开更深入的双向讨论。':card=='pron'?'Listen and Repeat — 听示范后跟读，系统跟读并对比评分。':'看题卡准备 1 分钟，然后录音陈述 1–2 分钟。';
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const SurgoTopBar(),Row(mainAxisAlignment:MainAxisAlignment.center,children:[SourceText(oralTime(left>0?left:over),style:SurgoText.countdownNumber),const SizedBox(width:10),T(left>0?'本次练习时长':'已超时',style:SurgoText.countdownLabel)]),const SizedBox(height:16),
   T('${app.session['sessionMode']=='mock'?'模拟考':'日常训练'} · 口语',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:10,fontWeight:FontWeight.w700,color:Color(0xff5a4b9e))),const SizedBox(height:10),T(title,style:SurgoText.h1),T(sub,style:SurgoText.sub),const SizedBox(height:16),
   SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    if(card=='pron'&&!tf)...[
     const T('跟读句子',style:SurgoText.cardTitle),
     for(final pair in const [
      ['Please put on your safety goggles before you start.','木工课场景 · 跟读一次'],
      ['Always keep your fingers away from the blade.','木工课场景 · 跟读一次'],
      ['You can borrow up to five books at a time for three weeks.','图书馆前台 · 跟读一次'],
      ['Please return the books to the desk on the second floor.','图书馆前台 · 跟读一次'],
      ['The orientation session will begin at nine in the main hall.','校园信息台 · 跟读一次'],
      ['The exhibit on the third floor shows how machines have changed over the last century.','科学博物馆导览 · 跟读一次'],
      ['Please stay with the group and do not touch any of the displays during the tour.','科学博物馆导览 · 跟读一次'],
     ])Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText(pair[0],style:const TextStyle(fontSize:16,height:1.5)),T(pair[1],style:const TextStyle(fontSize:11,color:SurgoColors.muted))])),
    ]else if(q.kind=='cue')...[
     SourceText(q.cue,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:20,fontWeight:FontWeight.w800,height:1.4)),const SizedBox(height:12),
     SourceText('You should say:\n${(d['part2']['points'] as List).map((s)=>'· $s').join('\n')}',style:const TextStyle(fontSize:13,height:1.6,color:SurgoColors.muted)),
    ]else...[
     SourceText('${tf?'':'Topic: '}${q.topic}',style:SurgoText.cardTitle),const SizedBox(height:8),SourceText(q.questions.map((s)=>'· $s').join('\n'),style:const TextStyle(fontSize:17,height:1.5)),
    ],
   ])),const SizedBox(height:16),const T('支持回放录音，日常训练可反复练习同一题。',style:SurgoText.sub),const SizedBox(height:20),
   SurgoCard(child:Column(children:[const T('准备 00:60 · 陈述 02:00'),const SizedBox(height:24),SurgoButton('进入口语考试',onTap:()=>requestOralStart(app)),const SizedBox(height:12),SurgoButton('查看批改示例',primary:false,onTap:()=>app.go(SurgoPage.speakingReview))])),
  ]);
 }
}
