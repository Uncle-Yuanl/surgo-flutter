import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/correction_dialog.dart';
import '../../widgets/marking_dialog.dart';
import 'controller.dart';
class IeltsMockWritingPage extends StatefulWidget {
 const IeltsMockWritingPage({super.key});
 @override
 State<IeltsMockWritingPage> createState()=>_IeltsMockWritingPageState();
}
class _IeltsMockWritingPageState extends State<IeltsMockWritingPage> {
 late IeltsMockWritingController c;
 late TextEditingController draft;
 Timer? timer;
 /// 用户 2026-09-24：三个 tab —— 0=题目（两个题目可收起展开）、1=任务1、2=任务2。
 /// 题目页只读，不影响 c.task 与计时，作答内容仍按 Task 分存。
 int tab = 0;
 /// 风琴页展开状态，默认两个题目都展开。
 final expanded = <int,bool>{1:true,2:true};
 @override
 void initState(){super.initState();c=IeltsMockWritingController(context.read<AppState>());draft=TextEditingController(text:c.texts[c.task]);
  timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;final zero=c.tick();setState((){});if(zero)mark();});}
 @override
 void dispose(){timer?.cancel();draft.dispose();super.dispose();}
 // 评分页按 sessionMode 认模考；不经模考选择弹窗直接进本页（深链、审计入口）时它没设，这里补上。
 void mark(){timer?.cancel();context.read<AppState>().session['sessionMode']='mock';showMarking(context,SurgoPage.writingFeedback,'正在批改任务 1 / 2, Task 1');}
 void end(){final kind=c.end(),first=kind=='short',short=kind!='end';showDialog<void>(context:context,useRootNavigator:false,builder:(ctx)=>Dialog(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
  if(short)Image.asset('assets/images/otter_study.png',height:140),
  T(first?'字数不足':short?'结束考试':'结束考试？',style:SurgoText.sheetTitle),const SizedBox(height:12),
  T(short?'你的答案未达到最低字数。仍可提交，但评分时会扣分。是否继续？':'Task 1 已写 ${c.words(1)} 词，Task 2 已写 ${c.words(2)} 词。提交后将无法继续修改。',style:SurgoText.cardDesc),const SizedBox(height:20),
  Row(children:[Expanded(child:SurgoButton(short?'取消':'继续作答',primary:false,onTap:()=>Navigator.pop(ctx))),const SizedBox(width:12),Expanded(child:SurgoButton(first?'继续':short?'提交':'结束考试',onTap:(){Navigator.pop(ctx);if(!first)mark();}))]),
 ]))));}
 @override
 Widget build(BuildContext context){return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  // 用户 2026-09-24：顶部计时改黑底白字。
  Row(children:[IconButton(key:const ValueKey('mw-home'),onPressed:()=>showExamExit(context),icon:SvgPicture.asset('assets/images/home_icon.svg',width:28,height:28)),Expanded(child:Center(child:Container(key:const ValueKey('mw-clock-box'),padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),decoration:BoxDecoration(color:c.left<=300&&c.left>0?SurgoColors.overrun:SurgoColors.ink,borderRadius:BorderRadius.circular(20)),child:SourceText('${(c.left~/3600).toString().padLeft(2,'0')}:${(c.left%3600~/60).toString().padLeft(2,'0')}:${(c.left%60).toString().padLeft(2,'0')}',key:const ValueKey('mw-clock'),textAlign:TextAlign.center,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,fontWeight:FontWeight.w800,color:Colors.white))))),
   // Clear of the global settings/notification buttons in the shell.
   const SizedBox(width:86)]),
  SessionTags(mock:true,subject:'雅思写作',part:tab==0?null:'Task ${c.task}'),
  Row(children:[for(final n in [0,1,2])Expanded(child:TextButton(key:ValueKey('mw-tab-$n'),onPressed:(){setState((){tab=n;if(n>0){c.select(n);draft.text=c.texts[n]??'';}});},child:Container(padding:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(border:Border(bottom:BorderSide(color:tab==n?SurgoColors.yellow:Colors.transparent,width:4))),child:T(n==0?'题目':'任务 $n',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,fontWeight:FontWeight.w800,color:tab==n?SurgoColors.ink:SurgoColors.muted)))))]),
  const SizedBox(height:14),
  if(tab==0)...[
   // 题目页：两个 Task 做成可收起展开的风琴页（用户 2026-09-24）。
   // 单位用 Text 而非 SourceText：后者只会把 Task1 译成「词/分钟」，两行不一致。
   for(final n in [1,2])_accordion(n),
  ]else...[
   // 用户 2026-09-24：任务页去掉题目（题干与图表），只留作答区。
   // 题目已在【题目】tab 的风琴页里能看全，两处重复没必要。
   SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SourceText('${c.words(c.task)} words / ${c.minimum} words',key:const ValueKey('mw-count'),style:SurgoText.cardTitle),const SizedBox(height:12),TextField(key:const ValueKey('mw-draft'),controller:draft,onChanged:(s)=>setState(()=>c.type(s)),minLines:14,maxLines:24,style:const TextStyle(fontSize:15,height:1.7),decoration:const InputDecoration(hintText:'在此输入你的答案...',border:InputBorder.none)),const SizedBox(height:16),SurgoButton('提交',key:const ValueKey('mw-submit'),onTap:end)])),
  ],
 ]);}
 /// 题目风琴页：点标题行收起 / 展开单个 Task。
 Widget _accordion(int n){
  final open=expanded[n]??true,cfg=c.config(n);
  return Container(
   margin:const EdgeInsets.only(bottom:12),
   decoration:BoxDecoration(color:SurgoColors.card,borderRadius:BorderRadius.circular(18)),
   clipBehavior:Clip.antiAlias,
   child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    InkWell(
     key:ValueKey('mw-acc-$n'),
     onTap:()=>setState(()=>expanded[n]=!open),
     child:Padding(padding:const EdgeInsets.fromLTRB(16,14,14,14),child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text('Writing Task $n',style:const TextStyle(fontFamily:'Outfit',fontFamilyFallback:SurgoFontFamily.fallback,fontSize:15,fontWeight:FontWeight.w800)),
       const SizedBox(height:3),
       Text('${cfg['minWords'] ?? (n==1?150:250)} word · ${cfg['minutes'] ?? (n==1?20:40)} min',style:SurgoText.cardDesc),
      ])),
      Icon(open?Icons.expand_less:Icons.expand_more,size:22,color:SurgoColors.muted),
     ])),
    ),
    if(open)Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     SourceText(cfg['prompt']??'',style:const TextStyle(fontSize:15,height:1.7)),
     if(cfg['chartSeries']!=null)chart(cfg),
     if(cfg['table']!=null)table(cfg['table'] as Map),
    ])),
   ]),
  );
 }
 /// 演示用真实数据：那场模考的 Task 1 是表格题，按数据原生画表（第一行表头、第一列行名）；
 /// 列多，窄屏在表格上横向滑动看。原型数据没有 table 键，走上面的柱状图。
 Widget table(Map data)=>Padding(padding:const EdgeInsets.only(top:16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  SourceText(data['title']??'',style:SurgoText.cardTitle),const SizedBox(height:10),
  SingleChildScrollView(key:const ValueKey('mw-table'),scrollDirection:Axis.horizontal,child:Table(defaultColumnWidth:const FixedColumnWidth(92),columnWidths:const {0:FixedColumnWidth(118)},border:TableBorder.all(color:SurgoColors.line),children:[
   for(final (i,row) in [data['head'] as List,...data['rows'] as List].indexed)TableRow(decoration:BoxDecoration(color:i==0?SurgoColors.yellowTint:null),children:[
    for(final cell in row as List)Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:7),child:SourceText('$cell',style:TextStyle(fontSize:12,height:1.35,fontWeight:i==0?FontWeight.w700:FontWeight.w400)))])])),
 ]));
 Widget chart(Map<String,dynamic> data)=>Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Column(children:[
  SourceText(data['chartTitle']??'',style:SurgoText.cardTitle),const SizedBox(height:10),Wrap(spacing:12,runSpacing:6,children:[for(final s in data['chartSeries'])SourceText(s['name'],style:TextStyle(fontSize:10,color:Color(int.parse((s['color'] as String).replaceFirst('#','ff'),radix:16))))]),const SizedBox(height:10),
  SizedBox(height:185,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(var i=0;i<(data['chartYears'] as List).length;i++)Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[
   Expanded(child:Row(crossAxisAlignment:CrossAxisAlignment.end,mainAxisAlignment:MainAxisAlignment.center,children:[for(final s in data['chartSeries'])Flexible(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[SourceText('${s['data'][i]}',style:const TextStyle(fontSize:10)),Container(width:18,height:(s['data'][i] as num).toDouble()*1.45,color:Color(int.parse((s['color'] as String).replaceFirst('#','ff'),radix:16)))])))])),SourceText('${data['chartYears'][i]}',style:const TextStyle(fontSize:10)),
  ]))])),
 ]));
}
