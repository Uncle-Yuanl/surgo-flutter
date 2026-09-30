import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/demo_audio.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
class TfListeningReview extends StatefulWidget {
 const TfListeningReview({super.key,required this.data});final Map<String,dynamic> data;
 @override State<TfListeningReview> createState()=>_TfListeningReviewState();
}
class _TfListeningReviewState extends State<TfListeningReview> {
 Map<String,dynamic> get data=>widget.data;
 /// 逐题分析里点了播放键的那一题（见下面的播放条）。
 Object? _heard;
 @override Widget build(BuildContext context){final state=context.read<AppState>();return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  const SurgoTopBar(title:'练习回顾'),SurgoCard(color:const Color(0xFFFBE7A8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const T('总体 · 练习估分',style:SurgoText.cardDesc),const SizedBox(height:8),SourceText('${data['score']} / 6.0',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:36,fontWeight:FontWeight.w900)),T(data['description'],style:SurgoText.cardDesc),const SizedBox(height:7),const T('练习估分仅供参考，不代表官方托福分数。',style:SurgoText.cardDesc),
  ])),SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('薄弱项分析',style:SurgoText.cardTitle),const SizedBox(height:10),const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',style:SurgoText.cardDesc),const SizedBox(height:12),
   for(final w in data['weak'])SurgoCard(color:SurgoColors.bg,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(spacing:6,children:[for(final tag in w['tags'])T(tag,style:SurgoText.cardEn)]),const SizedBox(height:8),T(w['q'],style:SurgoText.rowLabel),const SizedBox(height:8),T(w['a'],style:SurgoText.cardDesc)])),
   const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。',style:SurgoText.cardDesc),const SizedBox(height:12),SurgoButton('练习你最弱的题型 →',onTap:(){state.examType=ExamType.toefl;state.go(SurgoPage.listeningDaily);}),
  ])),
  if((data['source'] as List).isNotEmpty)SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const SourceText('Transcript',style:SurgoText.cardTitle),const SizedBox(height:12),SourceText.rich(TextSpan(children:[for(final row in data['source'])...[
   TextSpan(text:row[0]),if(row.length>1&&row[1]!=null&&row[1]!='')...[
    TextSpan(text:row[1],style:TextStyle(backgroundColor:_ok(row[2])?const Color(0xFFE7F6EA):const Color(0xFFFDEAEA))),TextSpan(text:' ${row[2]} ',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight:FontWeight.w800)),TextSpan(text:row[3]),
   ]
  ]]),style:const TextStyle(fontSize:14,height:1.8))])),
  SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('逐题分析',style:SurgoText.cardTitle),const SizedBox(height:12),for(final q in data['questions'])SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   // [英文, 中文] 一对：词典只有「第 1」到「第 7」，演示用真实数据一次训练可以有 8 题。
   Row(children:[Expanded(child:T(['Q${q['n']}','第 ${q['n']}'],style:SurgoText.rowLabel)),T(q['ok']?'表现良好':'错误',style:TextStyle(color:q['ok']?Colors.green:Colors.red,fontSize:12))]),const SizedBox(height:10),const T('题目',style:SurgoText.cardDesc),SourceText(q['q'],style:SurgoText.rowLabel),
   // 演示用真实数据的每题带着它那段录音（clip：{ asset, sec }），网页上点这一条真的放：整条都算播放键（只点那个
   // 18 像素的图标，手指很容易点偏），右边那几个字在原型里就是摆设，点了不算。原型数据没有 clip，这一条照旧是摆设。
   // 全站同一时间只放一段，而一段录音常是几题共用的：播放器里是这一段、点的又是这一题，才画它的进度和暂停键。
   if(q['dur']!=null)ListenableBuilder(listenable:demoAudio,builder:(_,__){final Map? clip=demoAudio.available?q['clip']:null;final on=clip!=null&&identical(_heard,q)&&demoAudio.asset==clip['asset'];
    return Padding(padding:const EdgeInsets.symmetric(vertical:12),child:GestureDetector(behavior:HitTestBehavior.opaque,onTap:clip==null?null:(){final sec=(clip['sec'] as num).toDouble();if(on){demoAudio.toggle(clip['asset'],seconds:sec);}else{setState(()=>_heard=q);demoAudio.play(clip['asset'],seconds:sec);}},
     child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:SurgoColors.bg,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[
      Icon(on&&demoAudio.playing?Icons.pause:Icons.play_arrow,size:18),Expanded(child:SourceText('${on?(demoAudio.ended?q['dur']:_clock(demoAudio.position)):'00:00'} / ${q['dur']}',style:const TextStyle(fontSize:10))),
      GestureDetector(onTap:clip==null?null:(){},child:const SourceText('↻15  ↻15  1.0x',style:TextStyle(fontSize:10)))]),const SizedBox(height:6),LinearProgressIndicator(value:on?(demoAudio.position/demoAudio.duration).clamp(0,1):0)]))));}),
   const T('你的作答',style:SurgoText.cardDesc),SourceText(q['mine'],style:TextStyle(fontSize:14,height:1.5,color:q['ok']?Colors.green:Colors.red)),if(q['ans']!=null)...[const T('正确答案',style:SurgoText.cardDesc),SourceText(q['ans'],style:const TextStyle(fontSize:14,color:Colors.green))],
   if(q['why']!=null)...[const SizedBox(height:12),const T('解析',style:SurgoText.rowLabel),T(q['why'],style:SurgoText.cardDesc),const T('原文依据：',style:SurgoText.cardDesc),SourceText(q['evi'],style:const TextStyle(fontSize:13,height:1.5))],
  ]))])),SurgoButton('⌂ 回到首页',onTap:()=>state.go(SurgoPage.ielts)),
 ]);}
 bool _ok(int n){final q=(data['questions'] as List);return n>0&&n<=q.length?q[n-1]['ok']:true;}
 String _clock(double s)=>'${(s~/60).toString().padLeft(2,'0')}:${(s.floor()%60).toString().padLeft(2,'0')}';
}
