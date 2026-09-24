import '../../widgets/session_tags.dart';
import '../../widgets/pill_tab.dart';
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
class TfReadingMockPage extends StatefulWidget {
 const TfReadingMockPage({super.key,required this.part});final int part;
 @override
 State<TfReadingMockPage> createState()=>_TfReadingMockPageState();
}
class _TfReadingMockPageState extends State<TfReadingMockPage> {
 TfReadingMockController? c;Timer? timer;double? sheet;
 final scroll=ScrollController(),qsScroll=ScrollController();
 final fields=<String,TextEditingController>{},focus=<String,FocusNode>{};
 @override
 void initState(){super.initState();final app=context.read<AppState>();TfReadingMockData.load().then((data){if(!mounted)return;setState(()=>c=TfReadingMockController(app,data,widget.part));timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;final target=c!.tick();setState((){});if(target!=null){timer?.cancel();if(target==SurgoPage.tfReadFb)mark();}});});}
 @override
 void dispose(){timer?.cancel();scroll.dispose();qsScroll.dispose();for(final f in fields.values){f.dispose();}for(final f in focus.values){f.dispose();}super.dispose();}
 void mark(){timer?.cancel();showMarking(context,SurgoPage.tfReadFb,'正在批改任务 ${widget.part>=3?2:1} / 2, Module ${widget.part>=3?2:1}');}
 void jump(int i){setState(()=>c!.jump(i));if(scroll.hasClients)scroll.jumpTo(0);if(qsScroll.hasClients)qsScroll.jumpTo(0);}
 void next(){final dest=c!.next();setState((){});if(dest!=null)timer?.cancel();if(dest==SurgoPage.tfReadFb)mark();if(scroll.hasClients)scroll.jumpTo(0);if(qsScroll.hasClients)qsScroll.jumpTo(0);}
 @override
 Widget build(BuildContext context){final x=c;if(x==null)return const Center(child:CircularProgressIndicator());return LayoutBuilder(builder:(ctx,b){final height=(sheet??(x.words?155.0:b.maxHeight*.51)).clamp(110.0,b.maxHeight-175);return Padding(
  // 用户 2026-09-24：答题面板要两边撑满，所以外层不再给左右内边距，
  // 改由顶栏 / tab / 正文卡各自加 13px（原白框宽度保持不变）。
  padding:const EdgeInsets.fromLTRB(0,8,0,0),child:Column(children:[
  Padding(padding:const EdgeInsets.symmetric(horizontal:13),child:Stack(alignment:Alignment.center,children:[Align(alignment:Alignment.centerLeft,child:IconButton(onPressed:()=>showExamExit(context),icon:SvgPicture.asset('assets/images/home_icon.svg',width:28,height:28))),SourceText('${(x.left.clamp(0,99999)~/60).toString().padLeft(2,'0')}:${(x.left.clamp(0,99999)%60).toString().padLeft(2,'0')}',key:const ValueKey('tfrm-clock'),style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:18,fontWeight:FontWeight.w800,color:x.left<=60?SurgoColors.overrun:SurgoColors.ink))])),
  // 用户 2026-09-24：做题页左上角三段标题（在 tab 之上）。
  Padding(padding:const EdgeInsets.fromLTRB(13,0,13,4),child:SessionTags(mock:true,subject:'托福阅读',part:'Part ${widget.part}')),
  // tab：统一成雅思阅读模考的胶囊样式（选中淡黄底 + 黄描边）。
  Padding(padding:const EdgeInsets.symmetric(horizontal:13),child:Row(children:[Expanded(child:tab('Complete the Words',x.words,(){if(widget.part>=3){x.app.go(SurgoPage.tfRead3Q);}else if(!x.words){x.start(1);}})),const SizedBox(width:6),Expanded(child:tab('Read in Daily Life',!x.words&&(widget.part==4||x.index<5),(){if(x.words){x.start(widget.part==1?2:4);}else{jump(0);}})),if(widget.part<3)...[const SizedBox(width:6),Expanded(child:tab('Read an Academic Passage',widget.part==2&&x.index>=5,widget.part==2?()=>jump(5):null))]])),
  const SizedBox(height:10),
  // 用户 2026-09-24：Part2/3 版式参考雅思阅读 —— 正文白卡圆角22 + 软阴影。
  Expanded(child:SingleChildScrollView(controller:scroll,padding:const EdgeInsets.symmetric(horizontal:13),child:Container(margin:const EdgeInsets.only(bottom:4),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),boxShadow:const [BoxShadow(color:Color(0x143c321e),blurRadius:18,offset:Offset(0,8))]),child:x.words?wordBody():Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SourceText(x.title,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:19,fontWeight:FontWeight.w800,height:1.3)),const SizedBox(height:12),for(final l in x.document)Padding(padding:const EdgeInsets.only(bottom:12),child:SourceText(l,style:const TextStyle(fontSize:15,height:1.65)))])))),
  // 题目面板：黄色把手条 + 进度，对齐雅思阅读。
  SizedBox(height:height,child:Container(clipBehavior:Clip.antiAlias,decoration:const BoxDecoration(color:Color(0xfffcf8f5),borderRadius:SurgoRadius.sheetTopAll,boxShadow:[BoxShadow(color:Color(0x213c3214),blurRadius:34,offset:Offset(0,-10))]),child:Column(children:[
   GestureDetector(key:const ValueKey('tfrm-drag'),behavior:HitTestBehavior.opaque,onVerticalDragUpdate:(d)=>setState(()=>sheet=height-d.delta.dy),child:ColoredBox(color:const Color(0xfffdecb0),child:Padding(padding:const EdgeInsets.fromLTRB(18,5,18,7),child:Column(children:[Container(width:44,height:4,decoration:BoxDecoration(color:const Color(0x403a2e00),borderRadius:BorderRadius.circular(4))),const SizedBox(height:6),Row(children:[if(!x.words)Expanded(child:T('第 ${x.current['no']} / ${x.total}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w700,color:SurgoColors.onYellowStrong))),const Flexible(child:T('上拉展开 / 下拉收起',textAlign:TextAlign.right,style:TextStyle(fontSize:10.5,fontWeight:FontWeight.w600,color:Color(0xffa08a4a))))])])))),
   Expanded(child:SingleChildScrollView(controller:qsScroll,padding:const EdgeInsets.fromLTRB(18,4,18,18),child:x.words?wordSheet():questionBody())),
  ]))),
 ]));});}
 /// tab —— 用户 2026-09-25：托福所有 tab 统一成雅思阅读模考篇章 tab 的样式
 /// （选中：淡黄底 + 黄色描边胶囊；未选中：无底灰字）。
 Widget tab(String label,bool selected,VoidCallback? action)=>SurgoPillTab(label:label,selected:selected,onTap:action,source:true,fontSize:11);
 Widget wordBody(){final x=c!;var bi=0;final spans=<InlineSpan>[];for(final item in x.current as List){if(item is String){spans.add(TextSpan(text:item));}else{final n=bi++,key='${x.index}_$n';final ctrl=fields.putIfAbsent(key,()=>TextEditingController(text:x.values[key]??'')),fn=focus.putIfAbsent(key,()=>FocusNode());spans.add(WidgetSpan(alignment:PlaceholderAlignment.middle,child:Row(mainAxisSize:MainAxisSize.min,children:[SourceText(item[0],style:const TextStyle(fontSize:16)),SizedBox(width:(item[1] as int).clamp(2,15)*10.0,child:TextField(key:ValueKey('tfrm-word-$key'),controller:ctrl,focusNode:fn,onChanged:(v)=>setState(()=>x.input(n,v)),style:const TextStyle(fontSize:16),decoration:const InputDecoration(isDense:true,contentPadding:EdgeInsets.symmetric(vertical:3)),textAlign:TextAlign.center)),SourceText('${item[1]}',style:const TextStyle(fontSize:10,color:SurgoColors.muted)),SourceText(item[2],style:const TextStyle(fontSize:16))])));}}
 return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Wrap(spacing:12,runSpacing:8,children:[SourceText('PARAGRAPH ${x.index+1} OF ${x.total}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:11,fontWeight:FontWeight.w800)),T('${x.filled} / ${x.blankCount} 已填',style:const TextStyle(fontSize:11))]),const SizedBox(height:10),const T('填入缺失的字母，补全每个单词。',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:17,fontWeight:FontWeight.w800,height:1.35)),const SizedBox(height:4),const T('小数字表示缺失了几个字母。点击任意空格即可跳转填写。',style:TextStyle(fontSize:13,height:1.6,color:SurgoColors.muted)),const SizedBox(height:16),SourceText.rich(TextSpan(children:spans),style:const TextStyle(fontSize:16,height:2.2)),const SizedBox(height:18),Row(children:[if(x.index>0)...[Expanded(child:SurgoButton('上一题',primary:false,onTap:()=>jump(x.index-1))),const SizedBox(width:10)],Expanded(child:SurgoButton(x.index==x.items.length-1?'下一部分':'下一段',key:const ValueKey('tfrm-next'),onTap:next))])]);}
 Widget wordSheet(){final x=c!;return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[for(var p=0;p<x.items.length;p++)...[
  SourceText('PARAGRAPH ${p+1}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:10,fontWeight:FontWeight.w800)),const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:[for(var i=0;i<(x.items[p] as List).whereType<List>().length;i++)cell('${i+1}',(x.values['${p}_$i']??'').toString().trim().isNotEmpty,()=>focusBlank(p,i))]),const SizedBox(height:10),
 ]]);}
 void focusBlank(int p,int i){if(p!=c!.index)jump(p);WidgetsBinding.instance.addPostFrameCallback((_){if(!mounted)return;focus['${p}_$i']?.requestFocus();});}
 Widget cell(String text,bool done,VoidCallback action)=>InkWell(onTap:action,child:Container(width:28,height:30,alignment:Alignment.center,decoration:BoxDecoration(color:done?SurgoColors.yellow:const Color(0xfffaf8f3),border:Border.all(color:SurgoColors.line),borderRadius:BorderRadius.circular(7)),child:SourceText(text,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:10,fontWeight:FontWeight.w700))));
 Widget questionBody(){final x=c!,q=x.current as Map;final opts=q['opts'] as List? ?? [];return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SourceText(q['q']??'Question ${q['no']}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,fontWeight:FontWeight.w700,height:1.6)),const SizedBox(height:12),
  if(opts.isEmpty)T('第 ${q['no']} 题内容待补充'),
  // 选项字母徐标对齐雅思阅读：32px 白底 / 选中填黄。
  for(var n=0;n<opts.length;n++)Padding(padding:const EdgeInsets.only(bottom:8),child:InkWell(key:ValueKey('tfrm-pick-$n'),onTap:()=>setState(()=>x.pick(n)),borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:x.values['${x.index}']==n?SurgoColors.yellowTint:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:x.values['${x.index}']==n?SurgoColors.yellow:SurgoColors.line)),child:Row(children:[Container(width:32,height:32,alignment:Alignment.center,decoration:BoxDecoration(color:x.values['${x.index}']==n?SurgoColors.yellow:Colors.white,border:Border.all(color:x.values['${x.index}']==n?SurgoColors.yellow:SurgoColors.line),borderRadius:BorderRadius.circular(9)),child:SourceText('ABCDEFGH'[n],style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,height:1.4,fontWeight:FontWeight.w800,color:x.values['${x.index}']==n?Colors.white:SurgoColors.muted))),const SizedBox(width:14),Expanded(child:SourceText(opts[n],style:const TextStyle(fontSize:14.5,height:1.4)))])))),
  Row(children:[Expanded(child:SurgoButton('上一题',primary:false,onTap:(){setState(()=>x.previous());})),const SizedBox(width:10),Expanded(child:SurgoButton(x.index==x.items.length-1?'下一部分':widget.part==4?'下一段':'下一题',key:const ValueKey('tfrm-next'),onTap:next))]),const SizedBox(height:14),T('答题卡  已作答 ${x.values.length} / ${x.items.length}',style:const TextStyle(fontSize:11)),const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:[for(var n=0;n<x.items.length;n++)cell('${x.items[n]['no']}',x.values.containsKey('$n'),()=>jump(n))]),
 ]);}
}
