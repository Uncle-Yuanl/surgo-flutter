import '../../widgets/session_tags.dart';
import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../widgets/loop_video.dart';
import '../../widgets/audio_card.dart';
import '../../widgets/marking_dialog.dart';
import 'controller.dart';
import 'review.dart';
const tfListeningRoutes={SurgoPage.tfDailyResp:('respond',false),SurgoPage.tfDrFb:('respond',true),SurgoPage.tfDailyConvo:('convo',false),SurgoPage.tfDcFb:('convo',true),SurgoPage.tfDailyAnn:('announce',false),SurgoPage.tfAnFb:('announce',true),SurgoPage.tfDailyLect:('lecture',false),SurgoPage.tfLcFb:('lecture',true)};
Widget? buildTfListeningDailyPage(SurgoPage p)=>tfListeningRoutes[p]==null?null:TfListeningDailyPage(kind:tfListeningRoutes[p]!.$1,feedback:tfListeningRoutes[p]!.$2);
class TfListeningDailyPage extends StatefulWidget {
 const TfListeningDailyPage({super.key,required this.kind,required this.feedback});final String kind;final bool feedback;
 @override State<TfListeningDailyPage> createState()=>_TfListeningDailyPageState();
}
class _TfListeningDailyPageState extends State<TfListeningDailyPage>{
 TfListeningController? c;Timer? audio,timer;final notes=TextEditingController();
 @override void initState(){super.initState();final app=context.read<AppState>();TfListeningData.load().then((raw){if(!mounted)return;
  setState(()=>c=TfListeningController(app,widget.kind,raw[widget.kind]));notes.text=c!.notes[c!.index]??'';
  if(!widget.feedback){_play();timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;final alert=c!.tick();setState((){});if(alert)_timeup();});}
 });}
 void _play(){audio?.cancel();if(c!.phase!='play')return;audio=Timer.periodic(Duration(milliseconds:c!.audioInterval),(_){if(!mounted)return;setState(c!.audioTick);if(c!.phase!='play')audio?.cancel();});}
 void _timeup()=>showDialog<void>(context:context,useRootNavigator:false,builder:(ctx)=>Dialog(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
  const LoopVideo(asset:'assets/video/timeup.mp4'),const SizedBox(height:14),const T('时间到！',style:SurgoText.sheetTitle),const SizedBox(height:14),SurgoButton('继续作答',onTap:()=>Navigator.pop(ctx)),
 ]))));
 @override void dispose(){audio?.cancel();timer?.cancel();notes.dispose();super.dispose();}
 String clock(int v)=>'${(v~/60).toString().padLeft(2,'0')}:${(v%60).toString().padLeft(2,'0')}';
 void _next(){final x=c!;if(x.phase=='play')return;if(!x.next()){timer?.cancel();final route={'respond':SurgoPage.tfDrFb,'convo':SurgoPage.tfDcFb,'announce':SurgoPage.tfAnFb,'lecture':SurgoPage.tfLcFb}[widget.kind]!;
   showMarking(context,route,'正在批改日常训练 · ${ {'respond':'听后选择回应','convo':'听对话','announce':'听通知','lecture':'听学术演讲'}[widget.kind]}');
  }else{notes.text=x.notes[x.index]??'';setState((){});_play();}}
 @override Widget build(BuildContext context){final x=c;if(x==null)return const Center(child:CircularProgressIndicator());if(widget.feedback)return TfListeningReview(data:x.data);
  final playing=x.phase=='play',ready=x.phase=='ready';
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   // 用户 2026-09-24：计时代替顶栏 logo 的位置。
   SurgoTopBar(center:Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:7),decoration:BoxDecoration(color:x.over?SurgoColors.overrun:SurgoColors.ink,borderRadius:BorderRadius.circular(20)),
    child:SourceText(x.over?'⏱ +${clock(x.up)}':'⏱ 00:00:${(x.phase=='answer'?x.left:x.seconds).toString().padLeft(2,'0')}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,height:1.3,color:Colors.white,fontWeight:FontWeight.w800)))),
   SessionTags(mock:false,subject:'托福听力',part:{'respond':'听后选择回应','convo':'听对话','announce':'听通知','lecture':'听学术讲座'}[widget.kind]),
   // 用户 2026-09-24：音频卡与雅思听力日常训练完全一致 —— 直接放在页面上，
   // 不再套在 SurgoCard 里（套层会变成卡中卡且宽度缩小）。
   // shell 已给本页左右 18px，这里只补下间距。
   Padding(padding:const EdgeInsets.only(bottom:16),child:AudioCard(
     title:{'respond':'听后选择回应','convo':'听对话','announce':'听通知','lecture':'听学术讲座'}[widget.kind]!,
     subtitle:playing?'播放中不可作答，请先听完这一段。':'本次训练中可按需重播与变速。',
     elapsed:clock(x.audio),
     total:clock(x.current['sec']),
     progress:x.audio/(x.current['sec'] as int),
     playing:playing,
     speedLabel:'${TfListeningController.rates[x.rate]}X',
     speeds:[for(final r in TfListeningController.rates)'${r}X'],
     onSpeed:(v){final i=TfListeningController.rates.indexWhere((r)=>'${r}X'==v);if(i<0)return;setState(()=>x.rate=i);x.save();_play();},
     onToggle:(){setState(x.replay);_play();},
     onSeek:(s){setState(()=>x.audio=(x.audio+s).clamp(0,x.current['sec'] as int));x.save();},
     onRestart:(){setState(x.replay);_play();},
   )),
   SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    if(x.lead.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:14),child:SourceText(x.lead,style:SurgoText.rowLabel)),
    if(widget.kind!='respond'&&playing)const Padding(padding:EdgeInsets.all(28),child:Center(child:T('正在播放...'))),
    if(widget.kind!='respond'&&ready)const Padding(padding:EdgeInsets.all(20),child:T('可反复重听音频，确认后再开始答题。',style:SurgoText.cardDesc)),
    if(widget.kind=='respond'||x.phase=='answer')...[
     const SizedBox(height:16),SourceText(x.current['q'],style:SurgoText.rowLabel),const SizedBox(height:14),
     for(final option in x.current['opts'])Opacity(opacity:x.phase=='answer'?1:.45,child:SurgoCard(padding:const EdgeInsets.all(13),color:x.picks[x.index]==option[0]?SurgoColors.yellowTint:Colors.white,onTap:x.phase=='answer'?()=>setState(()=>x.pick(option[0])):null,child:Row(children:[SourceText(option[0],style:SurgoText.rowLabel),const SizedBox(width:10),Expanded(child:SourceText(option[1],style:const TextStyle(fontSize:14,height:1.5)))]))),
    ],
    if(x.over)T('已用 ${x.seconds+x.up} 秒，建议限制在 ${widget.kind=='lecture'?'25-35':'15-25'} 秒',style:const TextStyle(fontSize:12,color:SurgoColors.overrun)),
    if(ready)SurgoButton('开始答题',onTap:()=>setState(x.begin))else if(widget.kind=='respond'||x.phase=='answer')SurgoButton(x.isLast?'提交':'下一段',onTap:playing?null:_next),
   ])),SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('笔记',style:SurgoText.cardTitle),TextField(controller:notes,minLines:4,maxLines:7,enabled:widget.kind!='respond'||!playing,decoration:const InputDecoration(hintText:'边听边记笔记',border:InputBorder.none),onChanged:(v){x.notes[x.index]=v;x.save();})])),
  ]);
 }
}
