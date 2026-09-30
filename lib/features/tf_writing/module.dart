import '../../widgets/session_tags.dart';
import '../../widgets/pill_tab.dart';
import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/marking_dialog.dart';
import '../../widgets/correction_dialog.dart';
import 'controller.dart';
import 'setup.dart';
Widget? buildTfWritingPage(SurgoPage p)=>[SurgoPage.tfWr1Q,SurgoPage.tfWr2Q,SurgoPage.tfWr3Q].contains(p)?TfWritingPage(page:p):buildTfWritingSetup(p);
class TfWritingPage extends StatefulWidget{const TfWritingPage({super.key,required this.page});final SurgoPage page;@override State<TfWritingPage> createState()=>_TfWritingPageState();}
class _TfWritingPageState extends State<TfWritingPage>{
 Map<String,dynamic>? d;TfSentenceController? sentence;Timer? timer;final body=TextEditingController(),subject=TextEditingController();
 int get task=>widget.page==SurgoPage.tfWr1Q?1:widget.page==SurgoPage.tfWr2Q?2:3;
 AppState get app=>context.read<AppState>();
 bool get daily=>app.session['tfw${task}Daily']==true;
 int get left=>app.session['tfw${task}Left'] as int? ??[0,410,420,600][task];
 @override void initState(){super.initState();TfWritingData.load().then((data){if(!mounted)return;setState(()=>d=data);sentence=TfSentenceController(app,data);
  body.text=app.session['tfw${task}Body'] as String? ??'';subject.text=app.session['tfw2Subj'] as String? ??'';
  timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;if(left<=0){timer?.cancel();return;}
   setState((){if(task==1){sentence!.tick();}else{app.session['tfw${task}Left']=left-1;}});if(task==2&&left<=240)app.session['tfw2ReqOpen']=true;
   if(left==0){timer?.cancel();if(task!=1)submit();}
  });
 });}
 @override void dispose(){timer?.cancel();body.dispose();subject.dispose();super.dispose();}
 void submit(){timer?.cancel();
  if(task==1){sentence!.sync();if(daily){showCorrection(context,SurgoPage.tfSentFb);}else{app.go(SurgoPage.tfWr2Intro);}}
  else if(task==2){if(daily){showCorrection(context,SurgoPage.tfEmailFb);}else{app.go(SurgoPage.tfWr3Intro);}}
  else{if(daily){showCorrection(context,SurgoPage.tfDiscFb);}else{app.session['tfwFbType']='s';showMarking(context,SurgoPage.tfWriteFb,'正在批改任务 3 / 3, Task 3');}}
 }
 void tab(String v)=>setState(()=>app.session['tfwTab']=v);
 @override Widget build(BuildContext context){if(d==null)return const Center(child:CircularProgressIndicator());final write=app.session['tfwTab']=='write';
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   // 用户 2026-09-24：计时代替顶栏 logo。
   SurgoTopBar(onBack:daily?()=>app.go(SurgoPage.ielts):()=>showExamExit(context),
    center:Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:7),decoration:BoxDecoration(color:left<=60?SurgoColors.overrun:SurgoColors.ink,borderRadius:BorderRadius.circular(20)),child:SourceText('⏱ 00:${(left~/60).toString().padLeft(2,'0')}:${(left%60).toString().padLeft(2,'0')}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,height:1.3,fontWeight:FontWeight.w800,color:Colors.white)))),
   SessionTags(mock:!daily,subject:'托福写作',part:'Task $task'),
   if(task==1)_sentence()else...[
    // 用户 2026-09-25：托福所有 tab 统一成雅思阅读模考篇章 tab 的胶囊样式。
    // （覆盖了 09-24「对齐雅思写作日常训练黄色荧光笔下划线」那一版。）
    Padding(padding:const EdgeInsets.only(bottom:14),child:Row(children:[
     Expanded(child:_tab('题目',!write,()=>tab('topic'))),
     const SizedBox(width:6),
     Expanded(child:_tab('写作',write,()=>tab('write'))),
    ])),
    if(write)_editor()else...[_topic(),SurgoButton('去写作 →',onTap:()=>tab('write'))],
   ]
  ]);
 }
 /// tab —— 用户 2026-09-25：统一成雅思阅读模考篇章 tab 的胶囊样式
 /// （选中：淡黄底 + 黄色描边 + 深色粗体；未选中：无底灰字）。
 /// key 保留 `tfw-tab-$label`，既有测试不受影响。
 Widget _tab(String label,bool active,VoidCallback onTap)=>SurgoPillTab(
  key:ValueKey('tfw-tab-$label'),
  label:label,selected:active,onTap:onTap,fontSize:15,maxLines:1);
 /// Part 2 题目区的 meta 标签：源数据写的是中文，题目区统一用英文。
 static const _metaEn={'你的身份':'Your role','收件人':'Recipient','语气':'Tone'};
 Widget chip(String t,{Color? color})=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:color??SurgoColors.yellowTint,borderRadius:BorderRadius.circular(9)),child:SourceText(t,style:const TextStyle(fontSize:14,color:SurgoColors.ink)));
 Widget draggable(int bank,{int? slot})=>Draggable<(int,int?)>(data:(bank,slot),feedback:Material(color:Colors.transparent,child:chip(sentence!.current['bank'][bank])),childWhenDragging:Opacity(opacity:.25,child:chip(sentence!.current['bank'][bank])),child:chip(sentence!.current['bank'][bank]));
 Widget _sentence(){final c=sentence!;var index=-1;final remaining=(c.current['bank'] as List).length-c.slots.where((b)=>b!=null).length;
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   // 用户 2026-09-24：题号与圆点调到题目上方。
   SourceText('QUESTION ${c.index+1} OF 10',style:SurgoText.cardDesc),const SizedBox(height:8),
   Wrap(spacing:5,children:[for(var i=0;i<10;i++)Container(width:11,height:11,decoration:BoxDecoration(shape:BoxShape.circle,color:i==c.index?SurgoColors.yellow:c.done.length>i&&c.done[i]?SurgoColors.ink:c.seen.length>i&&c.seen[i]?Colors.pink.shade100:SurgoColors.line))]),
   const SizedBox(height:16),
   SourceText(c.current['q'],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:22,fontWeight:FontWeight.w800,height:1.4)),
   const SizedBox(height:20),const T('拖动 词库里的单词到空格。想撤销就把它拖回词库。',style:SurgoText.cardDesc),const SizedBox(height:14),
   Wrap(spacing:6,runSpacing:9,children:[for(final part in c.current['parts'])if(part!='_')chip(part,color:Colors.white)else _slot(++index),SourceText(c.current['tail'])]),const SizedBox(height:24),
   DragTarget<(int,int?)>(onAcceptWithDetails:(v){if(v.data.$2!=null)setState(()=>c.remove(v.data.$2!));},builder:(_,__,___)=>SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[T('词库 · $remaining 剩余',style:SurgoText.cardDesc),const SizedBox(height:12),Wrap(spacing:7,runSpacing:9,children:[for(var i=0;i<(c.current['bank'] as List).length;i++)c.slots.contains(i)?Opacity(opacity:.2,child:chip(c.current['bank'][i])):draggable(i)])]))),
   Row(children:[Expanded(child:SurgoButton('上一题',primary:false,onTap:c.index==0?null:()=>setState(()=>c.move(-1)))),const SizedBox(width:12),Expanded(child:SurgoButton(c.index==9?(daily?'提交':'下一部分 →'):(daily?'下一题':'下一段 →'),onTap:(){if(c.index==9){submit();}else{setState(()=>c.move(1));}}))]),
  ]);
 }
 Widget _slot(int i)=>DragTarget<(int,int?)>(onWillAcceptWithDetails:(v)=>v.data.$2!=i,onAcceptWithDetails:(v)=>setState(()=>sentence!.drop(v.data.$1,i,from:v.data.$2)),builder:(_,candidate,__)=>Container(key:ValueKey('sentence-slot-$i'),constraints:const BoxConstraints(minWidth:60,minHeight:40),decoration:BoxDecoration(color:candidate.isNotEmpty?SurgoColors.yellowTint:Colors.white,border:Border.all(color:SurgoColors.yellow),borderRadius:BorderRadius.circular(10)),child:sentence!.slots[i]==null?const Padding(padding:EdgeInsets.all(10),child:T('拖入',style:SurgoText.cardDesc)):draggable(sentence!.slots[i]!,slot:i)));
 Widget _topic(){final item=TfWritingData.item(app,d!,task,task==2?'TFW2':'TFW3');return SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  // 用户 2026-09-24：Part 2 这整块都是题目，所以全部保持英文（不过词典）；
  // 正文段显式用正文字体族。meta 的标签在源数据里是中文，这里改用英文。
  if(task==2)...[const Text('Essentials',style:SurgoText.cardEn),const SizedBox(height:10),Text(item['title'],style:SurgoText.cardTitle),const SizedBox(height:15),Text(item['ctx'],style:const TextStyle(fontFamily:SurgoFontFamily.body,fontFamilyFallback:SurgoFontFamily.fallback,fontSize:15,height:1.7)),const SizedBox(height:18),
   for(final m in item['meta'])Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[SizedBox(width:110,child:Text(_metaEn[m[0]]??m[0],style:SurgoText.cardDesc)),Expanded(child:Text(m[1],style:SurgoText.rowLabel))])),
   const Text('Requirements',style:SurgoText.cardTitle),if(app.session['tfw2ReqOpen']==true)const Text('Tick each requirement as your draft covers it.',style:SurgoText.cardDesc),
   for(var i=0;i<(item['reqs'] as List).length;i++)CheckboxListTile(contentPadding:EdgeInsets.zero,title:Text(item['reqs'][i],style:const TextStyle(fontFamily:SurgoFontFamily.body,fontFamilyFallback:SurgoFontFamily.fallback,fontSize:14,height:1.5)),value:(app.session['tfw2ReqChecked'] as List? ??[false,false,false])[i],onChanged:app.session['tfw2ReqOpen']==true?(v)=>setState((){final checks=List<bool>.from(app.session['tfw2ReqChecked']??[false,false,false]);checks[i]=v!;app.session['tfw2ReqChecked']=checks;}):null),
  ]else...[
   // Part 3：kicker/note 源数据本就是中文界面标注，按语言走词典；
   // 题干 prompt 与讨论帖正文是题目内容，保持英文并用正文字体族。
   SourceText(item['kicker'],style:SurgoText.cardEn),const SizedBox(height:12),Text(item['prompt'],style:SurgoText.cardTitle),const SizedBox(height:14),SourceText(item['note'],style:SurgoText.cardDesc),
   for(final post in item['posts'])Padding(padding:const EdgeInsets.only(top:18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[CircleAvatar(child:Text(post['ini'])),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(post['name'],style:SurgoText.rowLabel),Text(post['txt'],style:const TextStyle(fontFamily:SurgoFontFamily.body,fontFamilyFallback:SurgoFontFamily.fallback,fontSize:14,height:1.6))]))])),
  ]
 ]));}
 Widget _editor(){final item=TfWritingData.item(app,d!,task,task==2?'TFW2':'TFW3');return Column(children:[SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  if(task==2)...[T('收件人  ${item['to']}',style:SurgoText.rowLabel),TextField(controller:subject,decoration:InputDecoration(hintText:item['subjPh']),onChanged:(v)=>app.session['tfw2Subj']=v)],
  if(task==3)const T('你的回应',style:SurgoText.cardTitle),
  TextField(key:const ValueKey('tf-writing-body'),controller:body,minLines:13,maxLines:null,decoration:InputDecoration(hintText:item['bodyPh'],border:InputBorder.none),style:const TextStyle(fontSize:15,height:1.7),onChanged:(v)=>setState(()=>app.session['tfw${task}Body']=v)),
  SourceText('${TfSentenceController.words(body.text)} / ${item['min']} ${app.lang==UiLang.en?'words':'词'}',style:SurgoText.cardDesc),
 ])),SurgoButton(daily&&task==2?'提交批改':'提交',onTap:submit)]);}
}
