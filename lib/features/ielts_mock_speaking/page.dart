import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import '../../widgets/correction_dialog.dart';
import '../../widgets/marking_dialog.dart';
import '../oral_daily/controller.dart';
import 'controller.dart';
class IeltsMockSpeakingPage extends StatefulWidget {
 const IeltsMockSpeakingPage({super.key,this.speech});final OralSpeech? speech;
 @override
 State<IeltsMockSpeakingPage> createState()=>_IeltsMockSpeakingPageState();
}
class _IeltsMockSpeakingPageState extends State<IeltsMockSpeakingPage>{
 IeltsMockSpeakingController? c;final notes=TextEditingController(),chat=ScrollController();
 @override
 void initState(){super.initState();final app=context.read<AppState>();IeltsMockSpeakingData.load().then((d){if(!mounted)return;final x=IeltsMockSpeakingController(app,d,speech:widget.speech,mark:()=>showMarking(context,SurgoPage.speakingReview,'正在批改口语作答, Part 3'));c=x;x.addListener(changed);x.start();});}
 void changed(){if(!mounted)return;setState((){});if(c!.part=='p1')WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&chat.hasClients)chat.jumpTo(chat.position.maxScrollExtent);});}
 @override
 void dispose(){c?.removeListener(changed);c?.dispose();notes.dispose();chat.dispose();super.dispose();}
 @override
 Widget build(BuildContext context){final x=c;if(x==null)return const Center(child:CircularProgressIndicator());return Padding(padding:const EdgeInsets.fromLTRB(18,8,18,20),child:Column(children:[
  // 用户 2026-09-24：计时统一放顶部中间，与 home 同行。
  // 右侧留 86px 避开 shell 右上角的全局设置/消息按钮，胶囊才真正视觉居中。
  Row(children:[
   IconButton(onPressed:()=>showExamExit(context),icon:SvgPicture.asset('assets/images/home_icon.svg',width:28,height:28)),
   Expanded(child:x.part=='p3'?const SizedBox.shrink():Stack(alignment:Alignment.center,children:[
    // 计时胶囊真正居中；题目序号浮在左侧，不参与居中计算。
    if(x.part=='p1')Align(alignment:Alignment.centerLeft,child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:T('题目 ${x.index+1} / ${x.cfg['n']}',style:const TextStyle(fontSize:12,color:SurgoColors.muted)))),
    Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:SurgoColors.line,width:1.5)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.access_time,size:15,color:Color(0xffc99a1e)),const SizedBox(width:6),SourceText(oralTime(x.left),key:const ValueKey('ims-clock'),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w800))])),
   ])),
   const SizedBox(width:76),
  ]),
  SessionTags(mock:true,subject:'雅思口语',part:'Part ${x.part.substring(1)}'),
  const SizedBox(height:12),
  Wrap(spacing:0,runSpacing:8,children:[for(final p in ['p1','p2','p3'])Padding(padding:const EdgeInsets.only(right:9),child:InkWell(key:ValueKey('ims-$p'),onTap:(){notes.clear();x.select(p);},child:Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:9),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(width:1.5,color:x.part==p?SurgoColors.ink:SurgoColors.line)),child:SourceText('Part ${p[1]}',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:12,fontWeight:FontWeight.w800,color:x.part==p?SurgoColors.ink:SurgoColors.muted)))))]),
  const SizedBox(height:12),Expanded(child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),boxShadow:SurgoShadow.card),padding:const EdgeInsets.all(20),child:x.part=='p3'?discussion():SingleChildScrollView(controller:chat,child:x.part=='p2'?cue():Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[for(var i=0;i<x.turns.length;i++)...[
   examiner(i),Align(alignment:Alignment.centerRight,child:Container(margin:const EdgeInsets.symmetric(vertical:14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:SurgoColors.yellowTint,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[const T('你的作答',style:SurgoText.sub),wave(30),T('已作答 · ${x.turns[i]['dur']}s',style:const TextStyle(fontSize:11))]))),
  ],if(x.index<(x.cfg['n'] as int))examiner(x.index),const SizedBox(height:14),T(x.busy?'考官正在提问…':x.recording?'已自动开始录音':'点击麦克风开始作答',textAlign:TextAlign.center,style:SurgoText.sub)])))),
  Container(margin:const EdgeInsets.only(top:14),padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),decoration:BoxDecoration(color:const Color(0xff141210),borderRadius:BorderRadius.circular(22)),child:Row(children:[if(x.part=='p2')...[
   Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText('${oralTime(x.phase=='prep'?0:120-x.recLeft)}/02:00',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,fontWeight:FontWeight.w800,color:Colors.white)),const T('不可重新录制',style:TextStyle(fontSize:10,color:SurgoColors.muted))])),const SizedBox(width:11),
  ],Expanded(child:ClipRect(child:wave(44,level:true))),const SizedBox(width:14),SizedBox(width:48,height:48,child:Material(color:SurgoColors.yellow,shape:const CircleBorder(),child:InkWell(key:const ValueKey('ims-mic'),onTap:x.mic,customBorder:const CircleBorder(),child:Icon(x.recording?Icons.stop:Icons.mic_none,size:22,color:const Color(0xff3a2e00)))))])),
 ]));}
 Widget wave(int n,{bool level=false})=>SizedBox(height:24,child:FittedBox(fit:BoxFit.scaleDown,child:Row(mainAxisSize:MainAxisSize.min,mainAxisAlignment:MainAxisAlignment.center,children:[for(var i=0;i<n;i++)Container(width:3,margin:const EdgeInsets.symmetric(horizontal:1.5),height:level?(c!.recording?5+(math.sin((c!.recSec+i)*1.7).abs()*17):2):5+(i*7%14).toDouble(),color:SurgoColors.yellow)])));
 Widget examiner(int qi)=>Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:40,height:40,decoration:const BoxDecoration(color:SurgoColors.yellow,shape:BoxShape.circle),clipBehavior:Clip.antiAlias,child:Image.asset('assets/images/otter_study.png',fit:BoxFit.cover)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const T('考官',style:SurgoText.sub),Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:SurgoColors.yellowTint,borderRadius:BorderRadius.circular(14)),child:Row(children:[IconButton(key:ValueKey('ims-play-$qi'),onPressed:()=>c!.play(qi),icon:const Icon(Icons.play_arrow)),Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:wave(26)))]))]))]);
 Widget cue(){final x=c!,card=x.cfg['card'];return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[examiner(0),const SizedBox(height:20),SourceText(card['title'],style:SurgoText.cardTitle),T(card['lead']),for(final b in card['bullets'])SourceText('• $b',style:const TextStyle(fontSize:14,height:1.8)),const SizedBox(height:20),Row(children:[Expanded(child:Column(children:[const T('准备中 · 可做笔记',style:TextStyle(fontSize:10)),SourceText(oralTime(x.prep),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:24,fontWeight:FontWeight.w800))])),Expanded(child:Column(children:[const T('录音限时',style:TextStyle(fontSize:10)),SourceText(oralTime(x.recLeft),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:24,fontWeight:FontWeight.w800))]))]),const SizedBox(height:16),const T('笔记'),TextField(key:const ValueKey('ims-note'),controller:notes,onChanged:(s)=>x.note=s,minLines:3,maxLines:6,decoration:const InputDecoration(hintText:'边听边记笔记'))]);}
 Widget discussion(){final x=c!,ask=x.turn=='ask';return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[SourceText(oralTime(x.left),key:const ValueKey('ims-clock'),style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:32,fontWeight:FontWeight.w900,color:x.left<=30?SurgoColors.danger:SurgoColors.ink)),const SizedBox(height:40),Container(width:150,height:150,decoration:BoxDecoration(shape:BoxShape.circle,color:ask?const Color(0xff121110):SurgoColors.yellow,boxShadow:[BoxShadow(color:ask?const Color(0x1f1c1a17):const Color(0x33f5b301),spreadRadius:12)]),child:Icon(Icons.mic_none,size:44,color:ask?Colors.white:const Color(0xff3a2e00))),const SizedBox(height:28),T(ask?'考官正在提问...':'轮到你了 — 请开始回答',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:12),const T('双向讨论 — 像真实面试一样自然作答。',style:TextStyle(fontSize:11)),const SizedBox(height:16),T('第 ${x.round} 轮',style:const TextStyle(fontSize:10))]));}
}
