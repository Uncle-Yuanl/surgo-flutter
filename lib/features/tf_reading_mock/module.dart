import '../../widgets/source_text.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'controller.dart';
import 'review.dart';
Widget? buildTfReadingMockPage(SurgoPage p)=>switch(p){SurgoPage.tfReadFb=>const TfReadMockReview(),SurgoPage.tfReadModEnd=>const _Bridge(),SurgoPage.tfReadModLoad=>const _Loading(),SurgoPage.tfReadMod2Intro=>const _Bridge(intro:true),_=>null};
class _Bridge extends StatelessWidget {
 const _Bridge({this.intro=false});final bool intro;
 @override
 Widget build(BuildContext context){final app=context.read<AppState>();return Padding(padding:const EdgeInsets.symmetric(vertical:65),child:SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(!intro)const T('阅读',style:SurgoText.sub),T(intro?'模块 2':'模块 1 结束',style:SurgoText.h1),const Divider(height:32),
  if(intro)...[const T('你即将进入模块 2。本模块共 15 题，限时 9 分钟。难度已根据你在模块 1 的表现进行调整。',style:SurgoText.cardDesc),const SizedBox(height:14),const T('你已准备好开始本模块。',style:SurgoText.cardTitle),const T('计时器将显示你完成本模块的剩余时间。',style:SurgoText.cardDesc),const T('你可以使用“下一题”和“返回”在同一模块内前进或回看。',style:SurgoText.cardDesc),const T('你将无法返回上一个模块。',style:SurgoText.cardTitle)]else...[
   const T('阅读部分模块 1 的时间已结束。',style:SurgoText.cardDesc),const T('点击“继续”进入模块 2。',style:SurgoText.cardDesc)],const SizedBox(height:24),SurgoButton(intro?'我已准备好':'继续',onTap:(){if(intro){app.session.addAll({'tfR3Para':0,'tfR3Vals':<String,dynamic>{},'tfR3Left':540});app.go(SurgoPage.tfRead3Q);}else{app.go(SurgoPage.tfReadModLoad);}}),
 ])));}
}
class _Loading extends StatefulWidget {const _Loading();@override State<_Loading> createState()=>_LoadingState();}
class _LoadingState extends State<_Loading>{Timer? timer,tail;int ticks=0;@override void initState(){super.initState();timer=Timer.periodic(const Duration(milliseconds:50),(_){if(!mounted)return;setState(()=>ticks++);if(ticks>=40){timer?.cancel();tail=Timer(const Duration(milliseconds:200),(){if(mounted)context.read<AppState>().go(SurgoPage.tfReadMod2Intro);});}});}@override void dispose(){timer?.cancel();tail?.cancel();super.dispose();}
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:100),child:Column(children:[Image.asset('assets/images/otter_start5.png',width:180,height:180),const T('正在进入第二阶段',style:SurgoText.h1),const SizedBox(height:20),LinearProgressIndicator(value:ticks/40,color:SurgoColors.yellow),SourceText('${(ticks/40*100).round()}%')]));}
Future<void> preloadTfReadingMock()=>TfReadingMockData.load();
