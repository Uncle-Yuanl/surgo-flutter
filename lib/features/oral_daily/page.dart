import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'controller.dart';

const _mic='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v3.5"/></svg>';
const _back='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M11 6l-6 6 6 6"/></svg>';
class OralDailyPage extends StatefulWidget {
  const OralDailyPage({super.key,this.discussion=false,this.controller});
  final bool discussion;
  final OralController? controller;
  @override
  State<OralDailyPage> createState()=>_OralDailyPageState();
}
class _OralDailyPageState extends State<OralDailyPage> {
  late OralController c;
  late TextEditingController notes;
  @override
  void initState(){super.initState();final app=context.read<AppState>();
    c=widget.controller??app.session['oralController'] as OralController? ?? OralController(app);
    app.session['oralController']=c;
    notes=TextEditingController(text:c.note);
    final start=app.session.remove('oralStartPending')==true;
    if(start){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)c.start();});}
    else if(c.preparing && c.prepTimer==null){c.beginPreparation();}
  }
  @override
  void dispose(){notes.dispose();super.dispose();}
  Widget icon(String svg,double size,[Color color=SurgoColors.ink])=>SvgPicture.string(svg,width:size,height:size,colorFilter:ColorFilter.mode(color,BlendMode.srcIn));
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:c,builder:(context,_){
    final q=c.task;
    if(notes.text!=c.note){notes.value=TextEditingValue(text:c.note,selection:TextSelection.collapsed(offset:c.note.length));}
    return Padding(padding:const EdgeInsets.fromLTRB(20,8,20,0),child:Column(children:[
      // 用户 2026-09-24：标签连带音频卡移到返回箭头的下一行（第 2、3 部分同改）。
      // 外层 Column 是默认 center 对齐，这一块必须显式 Align 到左边，
      // 否则「箭头 + 标签」会被整块居中（用户 2026-09-24：靠左，左对齐）。
      Padding(padding:const EdgeInsets.only(top:6,bottom:10),child:Align(alignment:Alignment.centerLeft,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        SizedBox(width:40,height:40,child:Material(color:Colors.white,shape:const CircleBorder(),elevation:2,
          child:InkWell(key:const ValueKey('oral-back'),customBorder:const CircleBorder(),onTap:c.quit,child:Center(child:icon(_back,20))))),
        const SizedBox(height:10),
        // 统一的三段标题（训练类型 / 科目 / Part）。
        SessionTags(
          mock:c.app.session['sessionMode']=='mock',
          subject:'${c.app.examType==ExamType.toefl?'托福':'雅思'}口语',
          part:'Part ${widget.discussion?'3':RegExp(r'\d+').firstMatch(c.card??(q.kind=='cue'?'p2':'p1'))?.group(0)??'1'}',
          padding:EdgeInsets.zero),
      ]))),
      if(widget.discussion)Expanded(child:_discussion()) else ...[
        Expanded(child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          if(c.preparing)...[
            Center(child:SourceText(oralTime(c.prepLeft),key:const ValueKey('oral-prep-clock'),
              style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:28,fontWeight:FontWeight.w800))),
            const SizedBox(height:6),
            Text(c.app.lang==UiLang.zh
              ? (c.prepLeft>0?'准备时间':'准备时间已结束，点击下方进入口语考试')
              : (c.prepLeft>0?'Preparation time':'Preparation finished. Tap below to enter the speaking test.'),textAlign:TextAlign.center,
              style:const TextStyle(fontSize:12,color:SurgoColors.muted)),const SizedBox(height:16),
          ],
          if(q.kind=='cue')_cue(q) else _audio(q),
          if(!(c.app.examType!=ExamType.toefl&&c.card=='p1'))...[
            const SizedBox(height:20),const T('Note',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:12),
            Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:TextField(key:const ValueKey('oral-note'),controller:notes,enabled:c.phase!='rec',minLines:5,maxLines:8,
              onChanged:c.updateNote,style:const TextStyle(fontSize:14),decoration:const InputDecoration(hintText:'Take notes here …',border:InputBorder.none,contentPadding:EdgeInsets.all(16)))),
          ],
          Padding(padding:const EdgeInsets.symmetric(vertical:16),child:T(c.phase=='note'?(q.kind=='cue'?(c.app.lang==UiLang.zh?'现在是准备时间，请仔细阅读题目并记笔记。':'Now it’s note-taking time, so please read the questions carefully'):'Listen to the question, then answer after the beep'):c.phase=='ready'?'Please answer':'Recording… tap to stop',textAlign:TextAlign.center,style:const TextStyle(fontSize:12,color:Color(0xff7a6a3a),fontWeight:FontWeight.w600))),
          if(c.error!=null)SourceText(c.error!,style:const TextStyle(color:Colors.red,fontSize:12)),
        ]))),
        if(c.preparing) Padding(padding:const EdgeInsets.fromLTRB(0,12,0,22),
          child:Column(children:[
            T('准备 ${oralTime(c.prepLeft)} · 陈述 ${oralTime(c.recMax)}',style:const TextStyle(fontSize:12)),
            const SizedBox(height:12),
            SurgoButton('进入口语考试',key:const ValueKey('oral-enter-exam'),onTap:c.enterCueExam),
          ])) else _recording(),
      ],
    ]));
  });
  Widget _cue(OralTask q)=>SurgoCard(padding:const EdgeInsets.symmetric(horizontal:22,vertical:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    SourceText(q.cue,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,fontWeight:FontWeight.w800,height:1.45)),const SizedBox(height:14),
    const SourceText('You should say:',style:TextStyle(fontSize:14)),const SizedBox(height:9),
    for(final p in q.points)Padding(padding:const EdgeInsets.only(left:10),child:SourceText('• ${p.replaceFirst(RegExp(r'^[A-H][.、)]\s*'),'')}',style:const TextStyle(fontSize:14,height:1.65))),
    if(q.last.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:14),child:SourceText(q.last,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14.5,height:1.5,fontWeight:FontWeight.w800))),
    TextButton.icon(key:const ValueKey('oral-play'),onPressed:c.play,icon:const Icon(Icons.volume_up_outlined,size:19),label:T(c.speaking?'Playing…':'Play question')),
  ]));
  Widget _audio(OralTask q)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xfffdfbf6),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xffefe9dd))),child:Column(children:[
    if(q.questions.length>1)T('Question ${c.index+1} of ${q.questions.length}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:15,fontWeight:FontWeight.w800)),
    const T('The question is spoken aloud. Listen and answer.',style:TextStyle(fontSize:12,height:1.6)),const SizedBox(height:18),
    Row(children:[SourceText(oralTime(c.audioSec),style:const TextStyle(fontSize:10)),const SizedBox(width:10),Expanded(child:LinearProgressIndicator(value:c.audioSec/c.duration,color:SurgoColors.yellow,backgroundColor:const Color(0xffeee6d3),minHeight:6)),const SizedBox(width:10),SourceText(oralTime(c.duration),style:const TextStyle(fontSize:10))]),const SizedBox(height:16),
    SizedBox(width:52,height:52,child:Material(color:c.speaking?const Color(0xff3a2e00):SurgoColors.yellow,shape:const CircleBorder(),child:InkWell(key:const ValueKey('oral-play'),onTap:c.play,customBorder:const CircleBorder(),child:Icon(Icons.play_arrow,size:24,color:c.speaking?SurgoColors.yellow:const Color(0xff3a2e00))))),
  ]));
  Widget _recording()=>Padding(padding:const EdgeInsets.fromLTRB(20,8,20,22),child:Column(children:[
    SizedBox(height:38,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(final h in const [30,52,72,44,84,62,38,78,58,90,66,46,82,54,36,70,60,86,48,34,76,56,42,80,64,88,50,40,72,54,32,66,58,84])Container(width:3,height:38*h/100,margin:const EdgeInsets.symmetric(horizontal:1.5),decoration:BoxDecoration(color:SurgoColors.yellow,borderRadius:BorderRadius.circular(2)))])),
    const SizedBox(height:10),SourceText('${oralTime(c.phase=='rec'||c.phase=='done'?c.recSec:0)}/${oralTime(c.recMax)}',key:const ValueKey('oral-elapsed'),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:14),
    SizedBox(width:88,height:88,child:Material(color:SurgoColors.yellow,shape:const CircleBorder(),elevation:4,shadowColor:SurgoColors.yellow,child:InkWell(key:const ValueKey('oral-mic'),onTap:c.mic,customBorder:const CircleBorder(),child:Center(child:c.phase=='rec'?Container(width:17,height:17,decoration:BoxDecoration(color:const Color(0xff3a2e00),borderRadius:BorderRadius.circular(3))):icon(_mic,32))))),
    const SizedBox(height:12),const T('日常训练：允许超时；可多次重录',style:TextStyle(fontSize:10,color:Color(0xffa99a82))),const SizedBox(height:14),
    Row(children:[Expanded(child:SurgoButton('↻ 重新录制',key:const ValueKey('oral-retake'),primary:false,onTap:c.phase=='done'?c.retake:null)),const SizedBox(width:12),Expanded(child:SurgoButton('提交',key:const ValueKey('oral-submit'),onTap:c.phase=='done'?c.submit:null))]),
  ]));
  Widget _discussion(){final ask=c.turn=='ask';return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
    SizedBox(height:104,child:Center(child:SourceText(oralTime(ask?c.askSec.clamp(0,5):c.answerSec),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:32,fontWeight:FontWeight.w900)))),const SizedBox(height:20),
    Container(width:150,height:150,decoration:BoxDecoration(shape:BoxShape.circle,color:ask?const Color(0xff121110):SurgoColors.yellow,boxShadow:[BoxShadow(color:ask?const Color(0x1f1c1a17):const Color(0x33f5b301),spreadRadius:12)]),child:Center(child:icon(_mic,44,ask?Colors.white:const Color(0xff3a2e00)))),
    const SizedBox(height:26),T(ask?'考官正在提问…':'轮到你了 — 请开始回答',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),T(ask?'问题由语音播出，请仔细听。':'像真实面试一样自然作答。',style:const TextStyle(fontSize:11.5,color:Color(0xff8a8378))),const SizedBox(height:16),T('第 ${c.round} / ${c.task.rounds} 轮',style:const TextStyle(fontSize:10,color:Color(0xffb5ad9e))),
    if(c.error!=null)SourceText(c.error!,style:const TextStyle(color:Colors.red,fontSize:12)),
  ]));}
}
