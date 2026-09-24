import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'controller.dart';
class TfReadMockReview extends StatefulWidget {
 const TfReadMockReview({super.key});
 @override
 State<TfReadMockReview> createState()=>_TfReadMockReviewState();
}
class _TfReadMockReviewState extends State<TfReadMockReview> {
 Map? data;late String mod,type;
 @override
 void initState(){super.initState();final s=context.read<AppState>().session;mod=s['tfRfbMod'] as String? ?? 'm1';type=s['tfRfbType'] as String? ?? 'w';TfReadingMockData.load().then((d){if(mounted)setState(()=>data=d['feedback']);});}
 Map get current=>data![mod];
 List get types=>current['types'];
 void select(String m,String t){setState((){mod=m;final keys=(data![m]['types'] as List).map((e)=>e['key']).toList();type=keys.contains(t)?t:keys.first;});context.read<AppState>().session.addAll({'tfRfbMod':mod,'tfRfbType':type});}
 @override
 Widget build(BuildContext context){if(data==null)return const Center(child:CircularProgressIndicator());final app=context.read<AppState>(),qs=current['qs'][type] as List,src=current['src'][type] as Map;return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  const SurgoTopBar(title:'练习回顾'),SurgoCard(color:SurgoColors.yellowSoft,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('最终成绩 · Upper',style:SurgoText.cardTitle),const SourceText('5.0 /6   (4.5-5.5)',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:32,fontWeight:FontWeight.w800)),const T('最终阅读分基于你的 Upper 卷表现。日常材料是明显强项；学术文章的细节定位需加强。',style:SurgoText.cardDesc),const T('SURGO 练习估分。最终分基于你的正式模块（模块2）表现；模块1用于定级。',style:SurgoText.sub)])),const SizedBox(height:14),
  Row(children:[for(final pair in [('m1','模块1 · 定级'),('m2','模块2 · Upper')])Expanded(child:TextButton(key:ValueKey('tfrfb-${pair.$1}'),onPressed:()=>select(pair.$1,type),child:T(pair.$2,style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight:FontWeight.w800,color:mod==pair.$1?SurgoColors.ink:SurgoColors.muted))))]),
  SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('总体 · 练习估分'),const SourceText('5.0 / 6.0',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:30,fontWeight:FontWeight.w800)),T(mod=='m1'?'定级表现良好——你已进入 Upper（高阶）卷。':'Upper 卷表现稳定，最终分基于本模块。',style:SurgoText.cardDesc),const T('练习估分仅供参考，不代表官方托福分数。',style:SurgoText.sub)])),const SizedBox(height:14),
  SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('各题型得分',style:SurgoText.cardTitle),for(final row in types)Padding(padding:const EdgeInsets.only(top:12),child:Column(children:[Row(children:[Expanded(child:SourceText(row['name'],style:const TextStyle(fontSize:12))),SourceText('${(row['score'] as num).toStringAsFixed(1)}/6',style:const TextStyle(fontSize:12))]),const SizedBox(height:6),LinearProgressIndicator(value:(row['score'] as num)/6,color:SurgoColors.yellow)]))])),const SizedBox(height:14),
  SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('薄弱项分析',style:SurgoText.cardTitle),const T('仅基于本次作答总结，并附带匹配练习。以你的界面语言显示。',style:SurgoText.sub),for(final w in current['weak'])Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(spacing:8,runSpacing:4,children:[for(final tag in w['tags'])T(tag,style:const TextStyle(fontSize:10))]),T(w['q'],style:SurgoText.cardTitle),T(w['a'],style:SurgoText.cardDesc)])),const T('仅记录本次能明确看到的问题；不诊断口音、听力或设备问题，也不下长期结论。',style:SurgoText.sub),SurgoButton('练习你最弱的题型 →',onTap:(){app.examType=ExamType.toefl;app.go(SurgoPage.readingDaily);})])),const SizedBox(height:14),
  Wrap(spacing:8,runSpacing:8,children:[for(final t in types)ChoiceChip(key:ValueKey('tfrfb-${t['key']}'),label:SourceText(t['name'],style:const TextStyle(fontSize:11)),selected:type==t['key'],onSelected:(_)=>select(mod,t['key']))]),const SizedBox(height:14),
  SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SourceText(src['label'],style:SurgoText.cardTitle),const SizedBox(height:12),SourceText.rich(TextSpan(children:[for(final r in src['rows'])...[
   TextSpan(text:r[0]),TextSpan(text:r[1],style:TextStyle(backgroundColor:qs[(r[2] as int)-1]['ok']?const Color(0xffe7f5e8):const Color(0xffffe7e2))),TextSpan(text:' ${r[2]} ',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:10,fontWeight:FontWeight.w800)),TextSpan(text:r[3]),
  ]]),style:const TextStyle(fontSize:14,height:1.7))])),const SizedBox(height:14),
  const T('逐题分析',style:SurgoText.cardTitle),for(final q in qs)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[T('第 ${q['n']}'),const Spacer(),T(q['ok']?'表现良好':'错误')]),const SizedBox(height:8),const T('题目',style:SurgoText.sub),SourceText(q['q'],style:SurgoText.cardTitle),const T('你的作答',style:SurgoText.sub),SourceText(q['mine'],style:TextStyle(color:q['ok']?Color(0xff36825a):SurgoColors.danger,fontSize:14)),if(q['ans']!=null)...[const T('正确答案',style:SurgoText.sub),SourceText(q['ans'],style:const TextStyle(color:Color(0xff36825a)))],if(q['why']!=null)...[const SizedBox(height:12),const T('解析',style:SurgoText.cardTitle),T(q['why'],style:SurgoText.cardDesc),const T('原文依据：'),SourceText(q['evi'],style:const TextStyle(fontSize:12,height:1.6))]]))),
  SurgoButton('回到首页',onTap:()=>app.go(SurgoPage.ielts)),
 ]);}
}
