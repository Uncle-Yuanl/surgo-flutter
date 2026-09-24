import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'mock_intro_content.dart';
import 'mock_ready_sheet.dart';

Widget? buildMockIntroPage(SurgoPage p)=>[SurgoPage.mockReading,SurgoPage.mockReadingIntro,SurgoPage.mockListening,SurgoPage.mockListeningIntro,SurgoPage.mockSpeaking,SurgoPage.mockSpeakingIntro,SurgoPage.mockWritingIntro].contains(p)?MockIntroPage(page:p):null;

/// 用户 2026-09-24：三个「准备」中间页（阅读 / 听力 / 口语 Intro）不再整页展示，
/// 改成进入即弹「准备好了吗？」弹窗（[showMockReadySheet]），弹窗自然结束后直接
/// 进入作答页；点掉/返回则退回上一页。文案、时长与状态重置沿用原有常量。
const _readyDialogIntro = <SurgoPage>{
  SurgoPage.mockReadingIntro,
  SurgoPage.mockListeningIntro,
  SurgoPage.mockSpeakingIntro,
};
class MockIntroPage extends StatelessWidget {
 const MockIntroPage({super.key,required this.page});final SurgoPage page;
 @override Widget build(BuildContext context){
  // 三个准备中间页改为纯弹窗形态。
  if(_readyDialogIntro.contains(page))return _ReadyDialogIntro(page:page);
  return _body(context);
 }
 Widget _body(BuildContext context){
  final s=context.watch<AppState>(),tf=context.watch<AppState>().examType==ExamType.toefl;
  final reading=[SurgoPage.mockReading,SurgoPage.mockReadingIntro].contains(page),listening=[SurgoPage.mockListening,SurgoPage.mockListeningIntro].contains(page),writing=page==SurgoPage.mockWritingIntro;
  final intro=[SurgoPage.mockReadingIntro,SurgoPage.mockListeningIntro,SurgoPage.mockSpeakingIntro].contains(page);
  final subject=reading?'reading':listening?'listening':writing?'writing':'speaking';
  final isTf=tf&&page!=SurgoPage.mockReadingIntro&&page!=SurgoPage.mockListeningIntro&&!writing;
  final tag=reading?(isTf?'TOEFL READING':'IELTS ACADEMIC READING'):listening?(isTf?'TOEFL LISTENING':'IELTS LISTENING'):writing?'IELTS ACADEMIC WRITING':isTf?'TOEFL SPEAKING':'IELTS SPEAKING';
  final meta=reading?(isTf?'2 MODULES · UP TO 50 QUESTIONS':'3 PASSAGES · 40 QUESTIONS · 60 MIN'):listening?(isTf?'2 MODULES · UP TO 47 QUESTIONS':'4 PARTS · 40 QUESTIONS · ABOUT 30 MIN'):writing?'2 TASKS · 60 MIN':isTf?(intro?'TASK 1 OF 2':'2 TASK TYPES · MICROPHONE NEEDED'):'3 PARTS · 11-14 MIN · MICROPHONE NEEDED';
  String title,sub='',note='',cta;
  List<MockPart> parts=[];List<MockTip> tips=[];
  if(reading){
   title=intro?'Ready to start Academic Reading?':isTf?'Reading (Mock Exam)':'Academic Reading (Mock Exam)';
   if(intro){sub='You have sixty minutes to work through three passages and forty questions in total.';note='The clock starts as soon as you begin.';}
   else if(isTf){sub='Three task types across two modules. You can move freely inside a module, but a module you have finished cannot be reopened.';}else{tips=kReadingTipsIelts;}
   if(!intro)parts=isTf?kReadingPartsToefl:kReadingPartsIelts;
   cta=intro?'Start Passage 1':isTf?'I am ready, start module 1':'I confirm, start Passage 1';
  }else if(listening){
   title=intro?'Ready to start Listening?':'Listening (Mock Exam)';
   if(intro){sub='A short introduction plays first. It explains that the recording plays once only, and the exam then begins at questions 1 to 6.';note='The recording plays once only. You cannot pause, rewind or replay it.';}
   else if(isTf){sub='Four task types across two modules. Every recording plays once, so listen closely and use the notes panel as you go.';}else{tips=kListeningTipsIelts;}
   if(!intro)parts=isTf?kListeningPartsToefl:kListeningPartsIelts;
   cta=intro?'Start Part 1':isTf?'I am ready, start module 1':'I confirm, start Part 1';
  }else if(writing){
   title='Academic Writing (Mock Exam)';sub='Two tasks share a single sixty-minute clock. Task 2 carries twice the marks of Task 1, so most candidates spend about twenty minutes on Task 1 and forty on Task 2.';
   parts=kWritingTasks;tips=kWritingNote;cta='I confirm, start the 60-minute clock';
  }else{
   title=intro?(isTf?'听后复述':'Ready to start Speaking?'):'Speaking (Mock Exam)';
   if(intro){sub=isTf?'你将听到一句话。请仔细听，并原样复述——不要改变任何单词或语序。计时器会显示你回答的剩余时间。':'The examiner asks the questions and recording starts automatically after each one. The exam runs through Part 1, Part 2 and Part 3 in order.';
    note=isTf?'不提供准备时间。':'One minute of preparation is given in Part 2 only, and it is timed.';
   }else{parts=isTf?kSpeakingPartsToefl:kSpeakingPartsIelts;tips=isTf?kSpeakingTipsToefl:kSpeakingTipsIelts;}
   cta=intro?(isTf?'开始听读复述':'Start Part 1'):isTf?'I am ready, check my microphone':'I confirm, check my microphone';
  }
  final back=intro?reading?SurgoPage.mockReading:listening?SurgoPage.mockListening:SurgoPage.mockSpeaking:SurgoPage.ielts;
  Future<void> start()async{
   if(subject=='speaking'&&!intro){s.go(SurgoPage.mockSpeakingIntro);return;}
   if(!isTf&&!(listening&&intro)){await showMockReadySheet(context,kMockReady[subject]!);if(!context.mounted)return;}
   if(reading){isTf?applyReadingToefl(s):applyReadingIelts(s);}else if(listening){isTf?applyListeningToefl(s):applyListeningIelts(s);}else if(writing){applyWriting(s);}else{isTf?applySpeakingToefl(s):applySpeakingIelts(s);}
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   SurgoTopBar(back:back),Wrap(spacing:8,runSpacing:7,children:[_tag(tag,true),_tag(writing?'MOCK EXAM · ONE SHARED CLOCK':'MOCK EXAM · REAL TIMING',false),_tag(meta,false)]),
   SurgoHeading(title,subtitle:sub.isEmpty?null:sub),
   if(!writing)for(final tip in tips)_tip(tip),
   for(final part in parts)SurgoCard(padding:const EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    CircleAvatar(radius:15,backgroundColor:SurgoColors.yellowTint,child:SourceText(part.num,style:const TextStyle(fontSize:13,color:SurgoColors.ink))),const SizedBox(width:12),
    // 用户 2026-09-24：本页小字放大，字号规则对齐雅思阅读
    // （标题 Outfit w800、说明与标签 13px）。全局 cardDesc/cardEn 仍是 11px，
    // 这里只在本页覆盖，避免波及其它上百个页面。
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     T(part.title,style:const TextStyle(fontFamily:'Outfit',fontFamilyFallback:SurgoFontFamily.fallback,fontSize:16,fontWeight:FontWeight.w800,height:1.35,color:SurgoColors.ink)),
     const SizedBox(height:6),
     T(part.desc,style:const TextStyle(fontSize:13,height:1.6,color:SurgoColors.muted)),
     const SizedBox(height:9),
     T(part.chip,style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w700,color:SurgoColors.yellow)),
    ])),
   ])),
   if(writing)for(final tip in tips)_tip(tip),if(note.isNotEmpty)SurgoCard(color:SurgoColors.yellowTint,child:T(note,style:const TextStyle(fontSize:13,height:1.6,color:SurgoColors.ink))),
   const SizedBox(height:14),SurgoButton(cta,key:const ValueKey('mock-intro-start'),onTap:start),const SizedBox(height:12),SurgoButton(isTf&&intro&&subject=='speaking'?'返回':'Back',primary:false,onTap:()=>s.go(back)),
  ]);
 }
 // 本页小字放大（用户 2026-09-24），字号规则对齐雅思阅读。
 Widget _tip(MockTip t)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[T(t.bold,style:const TextStyle(fontFamily:'Outfit',fontFamilyFallback:SurgoFontFamily.fallback,fontSize:15,fontWeight:FontWeight.w800,height:1.4,color:SurgoColors.ink)),T(t.rest,style:const TextStyle(fontSize:13,height:1.6,color:SurgoColors.muted))]));
 Widget _tag(String t,bool yellow)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:6),decoration:BoxDecoration(color:yellow?SurgoColors.yellowTint:Colors.white,borderRadius:BorderRadius.circular(20)),child:T(t,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:11.5,fontWeight:FontWeight.w700)));
}

/// 准备中间页的弹窗形态：进入路由即弹「准备好了吗？」。
///
/// 弹窗自然走完（2s 进度 + 220ms 尾巴）后执行原有的状态重置并进入作答页；
/// 若被返回键关掉则退回上一页，不进考试。页面本身只留一层底色，不再画整页内容。
class _ReadyDialogIntro extends StatefulWidget {
  const _ReadyDialogIntro({required this.page});
  final SurgoPage page;
  @override
  State<_ReadyDialogIntro> createState() => _ReadyDialogIntroState();
}

class _ReadyDialogIntroState extends State<_ReadyDialogIntro> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (_opened || !mounted) return;
    _opened = true;
    final state = context.read<AppState>();
    final toefl = state.examType == ExamType.toefl;
    final reading = widget.page == SurgoPage.mockReadingIntro;
    final listening = widget.page == SurgoPage.mockListeningIntro;
    final subject = reading
        ? 'reading'
        : listening
            ? 'listening'
            : 'speaking';
    // 用户要求「所有准备页都改成弹窗」，所以这里不再沿用源站
    // `!isTf && !(listening && intro)` 的跳过条件：TOEFL 分支与听力准备页
    // 现在同样走弹窗。分支与状态重置保持不变。
    await showMockReadySheet(context, kMockReady[subject]!);
    if (!mounted) return;
    // 与原整页 start() 完全一致的分支与状态重置。
    if (reading) {
      toefl ? applyReadingToefl(state) : applyReadingIelts(state);
    } else if (listening) {
      toefl ? applyListeningToefl(state) : applyListeningIelts(state);
    } else {
      toefl ? applySpeakingToefl(state) : applySpeakingIelts(state);
    }
  }

  // 这些路由仍走 shell 的 SingleChildScrollView，高度无界，因此不能用
  // SizedBox.expand（会 RenderBox was not laid out）。给一个自然高度占位即可，
  // 可见内容全部在弹窗里。
  @override
  Widget build(BuildContext context) => const SizedBox(
      key: ValueKey('mock-ready-intro'), height: 420, width: double.infinity);
}
