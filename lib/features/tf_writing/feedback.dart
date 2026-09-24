import '../../widgets/source_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
Widget? buildTfWritingFeedback(SurgoPage p)=>[SurgoPage.tfSentFb,SurgoPage.tfEmailFb,SurgoPage.tfDiscFb,SurgoPage.tfWriteFb].contains(p)?TfWritingFeedback(page:p):null;
class TfWritingFeedback extends StatefulWidget{const TfWritingFeedback({super.key,required this.page});final SurgoPage page;@override State<TfWritingFeedback> createState()=>_TfWritingFeedbackState();}
class _TfWritingFeedbackState extends State<TfWritingFeedback>{
 Map<String,dynamic>? data;String selected='s';
 @override void initState(){super.initState();selected=context.read<AppState>().session['tfwFbType'] as String? ??'s';rootBundle.loadString('assets/data/tf_writing_feedback.json').then((s){if(mounted)setState(()=>data=jsonDecode(s));});}
 bool get mock=>widget.page==SurgoPage.tfWriteFb;
 String get task=>widget.page==SurgoPage.tfSentFb?'sent':widget.page==SurgoPage.tfEmailFb?'email':'disc';
 void home(){final app=context.read<AppState>();if(!mock)app.examType=ExamType.toefl;app.go(SurgoPage.ielts);}
 @override Widget build(BuildContext context){final d=data;if(d==null)return const Center(child:CircularProgressIndicator());final app=context.read<AppState>();
  final mode=task=='email'?d['tfEmailFbView']:d['tfDiscFbView'];
  final cards=mock?d['TFWFB_QS'][selected]:task=='sent'?d['TFSENT_FB']:[{...mode,'n':1,'ok':task=='disc'}];
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SurgoTopBar(title:'练习回顾',onBack:home),
   SurgoCard(color:const Color(0xFFFBE7A8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const T('总体 · 练习估分',style:SurgoText.cardDesc),SourceText('${mock?'3.2':task=='sent'?'4.5':task=='email'?'3.0':'3.5'} / 6.0',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:36,fontWeight:FontWeight.w900)),const T('观点清晰，需加强语气一致性与结构组织。',style:SurgoText.cardDesc),const T('练习估分仅供参考，不代表官方托福分数。',style:SurgoText.cardDesc)])),
   if(mock)SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('各题型得分',style:SurgoText.cardTitle),for(final type in d['TFWFB_TYPES'])Padding(padding:const EdgeInsets.only(top:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText('${type['name']}   ${type['score']}/6'),LinearProgressIndicator(value:type['score']/6,color:SurgoColors.yellow)]))])),
   SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('薄弱项分析',style:SurgoText.cardTitle),const SizedBox(height:8),const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',style:SurgoText.cardDesc),const SizedBox(height:14),
    const T('写作 · 语气一致性 · 正式度',style:SurgoText.cardEn),const SizedBox(height:8),const T('邮件在正式与随意之间来回切换。',style:SurgoText.rowLabel),const SizedBox(height:8),T(!mock&&task=='email'?mode['weak']:d['TFWFB_WEAK'][0]['a'],style:SurgoText.cardDesc),const SizedBox(height:12),
    const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。',style:SurgoText.cardDesc),const SizedBox(height:12),SurgoButton('练习你最弱的题型 →',onTap:(){app.examType=ExamType.toefl;if(!mock)app.session['tfWrTask']=task;app.go(mock?SurgoPage.writingSession:SurgoPage.writingDaily);})
   ])),
   if(mock)Wrap(spacing:7,runSpacing:7,children:[for(final type in d['TFWFB_TYPES'])ChoiceChip(label:SourceText(type['name'],style:const TextStyle(fontSize:11)),selected:type['key']==selected,onSelected:(_)=>setState((){selected=type['key'];app.session['tfwFbType']=selected;}))]),
   const SizedBox(height:14),const T('逐题分析',style:SurgoText.cardTitle),const SizedBox(height:12),for(final q in cards)_card(q),SurgoButton('⌂ 回到首页',onTap:home),
  ]);
 }
 Widget _card(Map q)=>SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  Row(children:[Expanded(child:T('第 ${q['n']}',style:SurgoText.rowLabel)),T(q['ok']?'表现良好':'错误',style:TextStyle(color:q['ok']?Colors.green:Colors.red,fontSize:12))]),const SizedBox(height:12),const T('考官提问',style:SurgoText.cardDesc),SourceText(q['q'],style:SurgoText.rowLabel),
  if(q['subs']!=null)...[const SizedBox(height:12),Wrap(spacing:14,runSpacing:10,children:[for(final sub in q['subs'])SourceText('${sub[0]}  ${sub[1]}',style:TextStyle(fontSize:12,color:sub[2]=='ok'?Colors.green:Colors.red))])],
  if(q['task']!=null)...[const SizedBox(height:12),const T('题目',style:SurgoText.cardEn),SourceText(q['task'],style:const TextStyle(fontSize:14,height:1.6))]else const T('你的作答',style:SurgoText.cardDesc),const SizedBox(height:12),
  if(q['chips']!=null)Wrap(spacing:5,runSpacing:5,children:[for(final c in q['chips'])Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:c[1]==1?const Color(0xFFFDEAEA):SurgoColors.bg,borderRadius:BorderRadius.circular(9)),child:SourceText(c[0],style:TextStyle(fontSize:13,color:c[1]==1?Colors.red:SurgoColors.ink,decoration:c[1]==1?TextDecoration.lineThrough:null)))])else if(q['seg']!=null)_segments(q['seg'])else SourceText(q['mine']??'',style:const TextStyle(fontSize:14,height:1.7)),
  if(q['notes']!=null)for(final n in q['notes'])Padding(padding:const EdgeInsets.only(top:14),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText('${n[0]}',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, color:n[1]=='ok'?Colors.green:Colors.red,fontWeight:FontWeight.w800)),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText(n[2],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w700,height:1.5)),SourceText(n[3],style:SurgoText.cardDesc)]))])),
  if(q['ans']!=null)...[const SizedBox(height:16),const T('正确答案',style:SurgoText.cardEn),SourceText(q['ans'],style:const TextStyle(fontSize:14,color:Colors.green,height:1.6))],const SizedBox(height:16),const T('反馈',style:SurgoText.cardTitle),SourceText(q['fb'],style:SurgoText.cardDesc),
 ]));
 Widget _segments(List rows)=>SourceText.rich(TextSpan(children:[for(final s in rows)if(s[0]=='br')const TextSpan(text:'\n')else if(s[0]=='num')TextSpan(text:' ${s[2]} ',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight:FontWeight.w800,color:Colors.green))else if(['hl','hit','bad'].contains(s[0]))...[
  TextSpan(text:s[1],style:TextStyle(backgroundColor:s[0]=='bad'||s[2]=='bad'?const Color(0xFFFDEAEA):const Color(0xFFE7F6EA))),TextSpan(text:' ${s[0]=='hl'?s[3]:s[2]} ',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight:FontWeight.w800)),
 ]else TextSpan(text:s[1])]),style:const TextStyle(fontSize:14,height:1.8));
}
