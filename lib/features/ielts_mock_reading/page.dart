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
import '../ielts_reading/exam_figure.dart';
import 'controller.dart';
class IeltsMockReadingPage extends StatefulWidget {
 const IeltsMockReadingPage({super.key});
 @override
 State<IeltsMockReadingPage> createState()=>_IeltsMockReadingPageState();
}
class _IeltsMockReadingPageState extends State<IeltsMockReadingPage> {
 IeltsMockReadingController? c;Timer? timer;double? sheet;
 final article=ScrollController(),questions=ScrollController();
 final keys=<int,GlobalKey>{};
 @override
 void initState(){super.initState();final app=context.read<AppState>();IeltsMockReadingData.load().then((data){if(!mounted)return;setState(()=>c=IeltsMockReadingController(app,data));timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;final zero=c!.tick();setState((){});if(zero)mark();});});}
 @override
 void dispose(){timer?.cancel();article.dispose();questions.dispose();super.dispose();}
 void mark(){timer?.cancel();showMarking(context,SurgoPage.readingFeedback,'正在批改任务 ${c!.passage} / 3, Passage ${c!.passage}');}
 void select(int n){setState(()=>c!.select(n));if(article.hasClients)article.jumpTo(0);if(questions.hasClients)questions.jumpTo(0);}
 void end()=>showDialog<void>(context:context,useRootNavigator:false,builder:(ctx)=>Dialog(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const T('结束考试？',style:SurgoText.sheetTitle),const SizedBox(height:12),T('你已作答 ${c!.answers.length} / ${c!.total} 题。提交后将无法继续修改答案。',style:SurgoText.cardDesc),const SizedBox(height:20),Row(children:[Expanded(child:SurgoButton('继续作答',primary:false,onTap:()=>Navigator.pop(ctx))),const SizedBox(width:10),Expanded(child:SurgoButton('结束考试',onTap:(){Navigator.pop(ctx);mark();}))])]))));
 @override
 Widget build(BuildContext context){final x=c;if(x==null)return const Center(child:CircularProgressIndicator());return LayoutBuilder(builder:(context,box){
  final h=(sheet??box.maxHeight*.45).clamp(130.0,box.maxHeight-265);
  // 用户 2026-09-25：答题面板两边贴边 —— 外层不再吃 18px，
  // 改由顶栏/标签/篇章 tab/文章卡各自加 18，面板保持 0。
  return Padding(padding:const EdgeInsets.fromLTRB(0,8,0,0),child:Column(children:[
   // User 2026-09-24: every timer sits at the top, on the home row.
   Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[IconButton(onPressed:()=>showExamExit(context),icon:SvgPicture.asset('assets/images/home_icon.svg',width:28,height:28)),Expanded(child:Center(child:SourceText('${(x.left~/60).toString().padLeft(2,'0')}:${(x.left%60).toString().padLeft(2,'0')}',key:const ValueKey('mr-clock'),style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:20,fontWeight:FontWeight.w800,color:x.left<=300&&x.left>0?SurgoColors.overrun:SurgoColors.ink)))),
    // Clear of the global settings/notification buttons in the shell.
    const SizedBox(width:86)])),
   // 用户 2026-09-24：做题页左上角三段标题。
   Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:SessionTags(mock:true,subject:'雅思阅读',part:'篇章 ${x.passage}')),
   // 用户 2026-09-24：选中篇章要有明显区分 —— 黄底胶囊 + 深色粗体。
   Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[for(final n in [1,2,3])Expanded(child:GestureDetector(key:ValueKey('mr-passage-$n'),onTap:()=>select(n),behavior:HitTestBehavior.opaque,child:Container(margin:const EdgeInsets.symmetric(horizontal:3),padding:const EdgeInsets.symmetric(vertical:9),alignment:Alignment.center,decoration:BoxDecoration(color:x.passage==n?SurgoColors.yellowTint:Colors.transparent,borderRadius:BorderRadius.circular(18),border:Border.all(color:x.passage==n?SurgoColors.yellow:Colors.transparent)),child:T('篇章 $n',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w800,color:x.passage==n?SurgoColors.onYellowStrong:SurgoColors.muted)))))])),
   const SizedBox(height:8),
   // 用户 2026-09-24：版式参考日常训练 —— 文章放白色圆角卡（圆角22 + 软阴影）。
   Expanded(child:SingleChildScrollView(controller:article,padding:const EdgeInsets.symmetric(horizontal:18),child:Container(margin:const EdgeInsets.only(bottom:4),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),boxShadow:const [BoxShadow(color:Color(0x143c321e),blurRadius:18,offset:Offset(0,8))]),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[T('篇章 ${x.passage}',style:const TextStyle(fontSize:12,color:SurgoColors.muted)),const SizedBox(height:4),SourceText(x.current['title'],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:19,fontWeight:FontWeight.w800,height:1.3)),const SizedBox(height:12),for(final p in x.current['paras'])Padding(padding:const EdgeInsets.only(bottom:12),child:SourceText('${p[0]} ${p[1]}',style:const TextStyle(fontSize:15,height:1.65)))])))),
   // 题目面板：黄色把手条 + 已答进度，对齐日常训练。
   SizedBox(height:h,child:Container(clipBehavior:Clip.antiAlias,decoration:const BoxDecoration(color:Colors.white,borderRadius:SurgoRadius.sheetTopAll,boxShadow:[BoxShadow(color:Color(0x213c3214),blurRadius:34,offset:Offset(0,-10))]),child:Column(children:[
    GestureDetector(key:const ValueKey('mr-drag'),behavior:HitTestBehavior.opaque,onVerticalDragUpdate:(d)=>setState(()=>sheet=h-d.delta.dy),child:ColoredBox(color:const Color(0xfffdecb0),child:Padding(padding:const EdgeInsets.fromLTRB(18,5,18,7),child:Column(children:[Container(width:44,height:4,decoration:BoxDecoration(color:const Color(0x403a2e00),borderRadius:BorderRadius.circular(4))),const SizedBox(height:6),Row(children:[Expanded(child:T('已作答 ${x.answers.length} / ${x.total}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w700,color:SurgoColors.onYellowStrong))),const Flexible(child:T('上拉展开 / 下拉收起',textAlign:TextAlign.right,style:TextStyle(fontSize:10.5,fontWeight:FontWeight.w600,color:Color(0xffa08a4a))))])])))),
    Expanded(child:SingleChildScrollView(controller:questions,child:Padding(padding:const EdgeInsets.fromLTRB(18,4,18,18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     for(var i=0;i<x.questions.length;i++)question(i),
     // 用户 2026-09-25：结束考试接在题目最后（跟着题目一起滚）。
     const SizedBox(height:10),
     SurgoButton('结束考试',key:const ValueKey('mr-end'),onTap:end),
    ])))),
   ]))),
   // 用户 2026-09-25：去掉面板下面那条题号格，以及「部分 2 / 部分 3」那一条
   // （顶部篇章 tab 已能切换，重复入口）；结束考试已移到题目最后。
  ]));
 });}
 Widget question(int i){final x=c!,q=x.questions[i] as Map,gi=x.base(x.passage)+i,g=x.group(i),type=q['type'];
  final List options=type=='mc'||type=='mchoice'?q['opts']??[]:type=='tfng'?['TRUE','FALSE','NOT GIVEN']:type=='ynng'?['YES','NO','NOT GIVEN']:[];
  final letters=g['letters'] as List? ?? ['A','B','C','D','E','F','G','H'];
  return Column(key:keys.putIfAbsent(gi,()=>GlobalKey()),crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   if(q['group']!=null)...[const SizedBox(height:14),SourceText(q['group'],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,fontWeight:FontWeight.w800)),SourceText(q['instr']??'',style:const TextStyle(fontSize:12,height:1.5)),const SizedBox(height:12),
    if(q['box']!=null&&q['nobox']!=true)Container(padding:const EdgeInsets.all(12),color:const Color(0xfff7f3eb),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[for(var n=0;n<(q['box'] as List).length;n++)SourceText('${letters[n]}  ${q['box'][n]}',style:const TextStyle(fontSize:12,height:1.8))])),
    if(q['sumText']!=null)...[SourceText(q['sumTitle']??'',style:SurgoText.cardTitle),SourceText(q['sumText'],style:const TextStyle(fontSize:13,height:1.6))],
    // 演示用真实数据（tool/demo_export）的示意图题带真实图（figure）；原型数据没有，仍画自带的示意图。
    if(type=='diagram')q['figure']!=null?ExamFigure(q['figure']):SizedBox(height:100,child:CustomPaint(painter:_Bamboo())),
   ],
   const SizedBox(height:10),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText('${gi+1}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w800)),const SizedBox(width:8),Expanded(child:SourceText(q['q']??'',style:const TextStyle(fontSize:14,height:1.5))),if(type=='match')DropdownButton<int>(key:ValueKey('mr-match-$gi'),value:x.answers[gi] as int?,hint:const SourceText('—'),items:[const DropdownMenuItem<int>(value:null,child:SourceText('—')),for(var n=0;n<letters.length;n++)DropdownMenuItem(value:n+1,child:SourceText(letters[n].toString()))],onChanged:(v)=>setState(()=>x.pick(gi,v)))]),
   // 选项字母徐标对齐日常训练：32px 白底 / 选中填黄。
   for(var oi=0;oi<options.length;oi++)Padding(padding:const EdgeInsets.only(top:8),child:InkWell(key:ValueKey('mr-pick-$gi-$oi'),onTap:()=>setState(()=>x.pick(gi,oi+1)),borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:x.answers[gi]==oi+1?SurgoColors.yellowTint:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:x.answers[gi]==oi+1?SurgoColors.yellow:SurgoColors.line)),child:Row(children:[Container(width:32,height:32,alignment:Alignment.center,decoration:BoxDecoration(color:x.answers[gi]==oi+1?SurgoColors.yellow:Colors.white,border:Border.all(color:x.answers[gi]==oi+1?SurgoColors.yellow:SurgoColors.line),borderRadius:BorderRadius.circular(9)),child:SourceText(type=='tfng'?['T','F','N'][oi]:type=='ynng'?['Y','N','N'][oi]:'ABCDEFGH'[oi],style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,height:1.4,fontWeight:FontWeight.w800,color:x.answers[gi]==oi+1?Colors.white:SurgoColors.muted))),const SizedBox(width:14),Expanded(child:SourceText(options[oi],style:const TextStyle(fontSize:14.5,height:1.4)))])))),
   if(options.isEmpty&&type!='match')TextFormField(key:ValueKey('mr-input-$gi'),initialValue:x.answers[gi] is Map?x.answers[gi]['v']:'',onChanged:(v)=>setState(()=>x.type(gi,v)),decoration:const InputDecoration(hintText:'______'),style:const TextStyle(fontSize:14)),
   const SizedBox(height:8),
  ]);
 }
}
class _Bamboo extends CustomPainter {
 @override
 void paint(Canvas c,Size s){final p=Paint()..color=const Color(0xffc4d69f);for(var i=0;i<4;i++){final r=Rect.fromLTWH(s.width*.35,8+i*21,35,20);c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(4)),p);c.drawLine(r.bottomLeft,r.bottomRight,Paint()..color=const Color(0xff557e3b)..strokeWidth=3);}c.drawLine(Offset(s.width*.35+35,50),Offset(s.width*.75,50),Paint()..color=SurgoColors.ink);final t=TextPainter(text:const TextSpan(text:'?',style:TextStyle(color:SurgoColors.ink,fontSize:16)),textDirection:TextDirection.ltr)..layout();t.paint(c,Offset(s.width*.77,40));}
 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
