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
import '../../widgets/demo_audio.dart';
import '../../widgets/marking_dialog.dart';
import 'controller.dart';
import 'review.dart';
Widget? buildTfSpeakingMockPage(SurgoPage page)=>switch(page){
 SurgoPage.tfSpk1Q||SurgoPage.tfSpk2Q=>TfSpeakingMockPage(task:page==SurgoPage.tfSpk1Q?1:2),
 SurgoPage.tfSpk2Intro||SurgoPage.tfSpk2Brief=>_Intro(brief:page==SurgoPage.tfSpk2Brief),
 SurgoPage.tfSpeakFb=>FutureBuilder<Map<String,dynamic>>(future:TfSpeakingMockData.load(),builder:(c,s)=>s.hasData?TfSpeakFbReview(fb:s.data!['feedback'] as Map<String,dynamic>):const Center(child:CircularProgressIndicator())),_=>null};
String _time(int sec)=>'${(sec~/60).toString().padLeft(2,'0')}:${(sec%60).toString().padLeft(2,'0')}';
class TfSpeakingMockPage extends StatefulWidget {
 const TfSpeakingMockPage({super.key,required this.task});final int task;
 @override
 State<TfSpeakingMockPage> createState()=>_TfSpeakingMockPageState();
}
class _TfSpeakingMockPageState extends State<TfSpeakingMockPage> {
 TfSpk1Controller? c1;TfSpk2Controller? c2;Timer? timer,tail;bool stopping=false;
 int get seg=>c1?.seg??c2?.seg??0;
 int get audio=>c1?.audio??c2?.audio??0;
 int get left=>c1?.left??c2?.left??0;
 int get sec=>c1?.sec??c2?.sec??1;
 int get total=>c1?.total??c2?.total??1;
 String get phase=>c1?.phase??c2?.phase??'play';
 @override
 void initState(){super.initState();revision=context.read<AppState>().revision;TfSpeakingMockData.load().then((data){if(!mounted)return;final app=context.read<AppState>(),prefix=widget.task==1?'tfS1':'tfS2';
  if(widget.task==1){c1=TfSpk1Controller(data['task1']);c1!.start();c1!.seg=app.session['${prefix}Seg'] as int? ?? 0;}else{c2=TfSpk2Controller(data['task2']);c2!.start();c2!.seg=app.session['${prefix}Seg'] as int? ?? 0;}setState((){});run();});}
 void save(){final p=widget.task==1?'tfS1':'tfS2';context.read<AppState>().session.addAll({'${p}Seg':seg,'${p}Phase':phase,'${p}Audio':audio,'${p}Left':left});}
 /// 演示用真实数据每题带着考官的原音频（segments[].audio：{ asset, sec }，tool/demo_export 导出）：在网页上「正在播放」
 /// 真的放它，只放一遍。这一阶段不数秒：进入时起播，之后每 250 毫秒看一次播放器，进度读它的，放完
 /// （demoAudio.ended；被浏览器拦下、文件加载失败时它按时长空走，同样会到）才进下一阶段。离开页面不用停：
 /// 换页时 AppState.go 统一停。原型数据没有这一项、或不在网页上，是 null，照旧每秒一拍。
 Map? get clip=>demoAudio.available?(c1?.cur??c2!.cur)['audio'] as Map?:null;
 bool get hearing=>phase=='play'&&clip!=null;
 double get played=>hearing&&demoAudio.asset==clip!['asset']?demoAudio.position/demoAudio.duration:audio/sec;
 // 建页时的 AppState.revision。每次换页（go，包括 go 到同一页重建）它都加一，对不上就是这一页已经被换走了
 //（还要淡出 300 毫秒才 dispose）：这之后不再碰播放器，这时再起播，声音会留在下一个页面上没人停。
 late int revision;
 void hear(){if(context.read<AppState>().revision!=revision)return;final c=clip!,asset=c['asset'] as String;
  // 这一题不在播放器里：刚进入播放阶段，或者正放着被别处停掉了——从头放。
  if(demoAudio.asset!=asset){demoAudio.play(asset,seconds:(c['sec'] as num).toDouble());}
  else if(demoAudio.ended){c1?.heard();c2?.heard();}
  else{final at=demoAudio.position.floor().clamp(0,sec);c1?.audio=at;c2?.audio=at;}
 }
 void run(){timer?.cancel();if(hearing)hear();timer=Timer.periodic(Duration(milliseconds:hearing?250:1000),(_){if(!mounted)return;final was=hearing;String? result;
  if(was){hear();}else{result=c1!=null?c1!.step():c2!.step();}
  save();setState((){});
  // 进、出真音频的播放阶段各换一次节拍；出来时从整秒重新数，「准备」和作答的第一秒才是完整的一秒。
  if(result=='answer-done'){stopSheet();}else if(hearing!=was){run();}});}
 void stopSheet(){timer?.cancel();stopping=true;showDialog<void>(context:context,useRootNavigator:false,barrierDismissible:false,builder:(ctx)=>const Dialog(child:Padding(padding:EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[T('停止回答',style:SurgoText.sheetTitle),SizedBox(height:14),T('回答时间已结束。\n请稍候，我们正在保存你的回答。',textAlign:TextAlign.center),SizedBox(height:20),CircularProgressIndicator()]))));
  tail=Timer(const Duration(seconds:2),(){if(!mounted)return;Navigator.of(context).pop();stopping=false;final next=c1!=null?c1!.advance():c2!.advance();if(next){save();setState((){});run();}else if(widget.task==1){context.read<AppState>().go(SurgoPage.tfSpk2Intro);}else{showMarking(context,SurgoPage.tfSpeakFb,'正在批改口语作答, Task 2');}});
 }
 @override
 void dispose(){timer?.cancel();tail?.cancel();super.dispose();}
 @override
 Widget build(BuildContext context){if(c1==null&&c2==null)return const Center(child:CircularProgressIndicator());final answer=phase=='answer';return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  // 用户 2026-09-24：计时代替顶栏 logo，样式与其它考试页统一为黑底胶囊。
  Stack(alignment:Alignment.center,children:[Align(alignment:Alignment.centerLeft,child:IconButton(onPressed:()=>showExamExit(context),icon:SvgPicture.asset('assets/images/home_icon.svg',width:28,height:28))),Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:7),decoration:BoxDecoration(color:SurgoColors.ink,borderRadius:BorderRadius.circular(20)),child:SourceText(answer?'⏱ 00:00:${left.toString().padLeft(2,'0')}':'⏱ ${_time(audio)}',key:const ValueKey('tfsp-clock'),style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,height:1.3,color:Colors.white,fontWeight:FontWeight.w800)))]),
  // 用户 2026-09-24：做题页左上角三段标题。
  SessionTags(mock:true,subject:'托福口语',part:widget.task==1?'听读复述':'参加访谈'),
  Padding(padding:const EdgeInsets.symmetric(vertical:12),child:T('第 ${seg+1} / $total',textAlign:TextAlign.center,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,fontWeight:FontWeight.w800))),
  if(phase=='instruct')SurgoCard(child:Padding(padding:const EdgeInsets.symmetric(vertical:70),child:SourceText(c1!.instruct,style:const TextStyle(fontSize:16,height:1.7))))else...[
   const SizedBox(height:34),Center(child:Container(width:150,height:150,decoration:BoxDecoration(shape:BoxShape.circle,color:answer?SurgoColors.yellow:const Color(0xff121110),boxShadow:[BoxShadow(color:answer?const Color(0x33f5b301):const Color(0x1f1c1a17),spreadRadius:12)]),child:Icon(Icons.mic_none,size:44,color:answer?const Color(0xff3a2e00):Colors.white))),
   const SizedBox(height:28),T(widget.task==1?'仔细听，只复述一次。':answer?'请回答面试官的问题。':'请听面试官的问题。',textAlign:TextAlign.center,style:const TextStyle(fontSize:13)),const SizedBox(height:24),
   if(phase=='play')SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const T('正在播放...',style:SurgoText.cardTitle),T(widget.task==1?'本段录音只播放一次。':'面试官提问中，请仔细听。',style:SurgoText.sub),const SizedBox(height:18),LinearProgressIndicator(value:played,color:SurgoColors.yellow),const SizedBox(height:8),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[SourceText(_time(audio)),SourceText(_time(sec))])])),
   if(phase=='ready')const SurgoCard(child:Padding(padding:EdgeInsets.all(24),child:T('准备...',textAlign:TextAlign.center,style:SurgoText.sheetTitle))),
   if(answer)SurgoCard(child:Column(children:[const T('回答时间',style:SurgoText.cardTitle),const SizedBox(height:18),SourceText('00:00:${left.toString().padLeft(2,'0')}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:28,fontWeight:FontWeight.w800))])),
  ],
 ]);}
}
class _Intro extends StatelessWidget {
 const _Intro({required this.brief});final bool brief;
 @override
 Widget build(BuildContext context){final app=context.read<AppState>(),back=brief?SurgoPage.tfSpk2Intro:SurgoPage.mockSpeaking;return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  SurgoTopBar(onBack:()=>app.go(back)),const SizedBox(height:20),const Wrap(spacing:8,runSpacing:8,children:[SourceText('TOEFL SPEAKING'),SourceText('MOCK EXAM · REAL TIMING'),SourceText('TASK 2 OF 2')]),const SizedBox(height:20),const T('参加访谈',style:SurgoText.h1),const SizedBox(height:16),
  // 访谈情境读 JSON 的 task2.brief.sub：原型数据里就是下面这一段，演示用真实数据（tool/demo_export）是那一场的情境简介。
  if(brief)FutureBuilder<Map<String,dynamic>>(future:TfSpeakingMockData.load(),builder:(c,s)=>SourceText(s.data?['task2']?['brief']?['sub'] as String? ?? 'You have volunteered for a research study at your university about work experience. You will have a short online interview with a researcher. The researcher will ask you some questions.',style:SurgoText.cardDesc))else...[
   const T('在本任务中，你将参加一场简短的访谈。请听每个问题并用自己的话回答。每题有 45 秒作答时间，不提供准备时间。',style:SurgoText.cardDesc),const SizedBox(height:16),const SurgoCard(child:T('每段音频只播放一次，且无法返回上一题。不提供准备时间。提示音后开始作答。',style:SurgoText.cardDesc)),
  ],const SizedBox(height:28),SurgoButton('开始访谈',onTap:(){if(brief)app.session.addAll({'tfS2Seg':0,'tfS2Phase':'play','tfS2Audio':0,'tfS2Left':0});app.go(brief?SurgoPage.tfSpk2Q:SurgoPage.tfSpk2Brief);}),const SizedBox(height:10),SurgoButton('返回',primary:false,onTap:()=>app.go(back)),
 ]);}
}
