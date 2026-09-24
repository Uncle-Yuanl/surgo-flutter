import '../../widgets/source_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import '../../theme/tokens.dart';

class TaskBriefData {
  TaskBriefData(this.raw);
  final Map<String,dynamic> raw;
  static TaskBriefData? _cache;
  static Future<TaskBriefData> load() async => _cache ??= TaskBriefData(jsonDecode(await rootBundle.loadString('assets/data/task_brief.json')));
  static const starts={
    'wordfill':'startTfDailyWords','liferead':'startTfDailyLife','acadread':'startTfDailyAcad',
    'respond':'startTfDailyResp','convo':'startTfDailyConvo','announce':'startTfDailyAnn','lecture':'startTfDailyLect',
    'sent':'startTfDailySent','email':'startTfDailyEmail','disc':'startTfDailyDisc',
    'retell':'startTfDailyRetell','interview':'startTfDailyInterview',
  };
  String module(AppState s)=>s.session['tfBriefMod'] as String? ?? 'writing';
  String task(AppState s) { final mod=module(s);return switch(mod){
    'reading'=>s.session['tfReadTask'] as String? ?? 'wordfill',
    'listening'=>s.session['tfLisTask'] as String? ?? 'respond',
    'writing'=>s.session['tfWrTask'] as String? ?? 'sent',
    _=>s.session['tfSpTask'] as String? ?? 'retell',
  }; }
  Map<String,dynamic>? entry(AppState s)=>(raw['TF_BRIEF'][module(s)]?[task(s)] as Map?)?.cast<String,dynamic>();
  SurgoPage back(AppState s)=>SurgoPageX.fromKey('${module(s)}Daily')??SurgoPage.writingDaily;
  void start(AppState s) {
    final key=task(s);
    if(key=='pron'){s.session['selWizCard']='pron';s.go(SurgoPage.pronCourse);return;}
    final name=starts[key];
    if(name==null){s.go(back(s));return;}
    final seed=Map<String,dynamic>.from(jsonDecode(jsonEncode(raw['startup'][name])));
    final target=SurgoPageX.fromKey(seed.remove('target'))!;
    s.session.addAll(seed);
    if(key=='wordfill')s.session.remove('tfDwController');
    if(key=='liferead')s.session.remove('tfDlController');
    if(key=='acadread')s.session.remove('tfDaController');
    s.go(target);
  }
}
class TaskBriefPage extends StatefulWidget {
  const TaskBriefPage({super.key});
  @override
  State<TaskBriefPage> createState()=>_TaskBriefPageState();
}
class _TaskBriefPageState extends State<TaskBriefPage> {
  TaskBriefData? data;
  @override
  void initState(){super.initState();TaskBriefData.load().then((d){if(mounted)setState(()=>data=d);});}
  @override
  Widget build(BuildContext context){
    final s=context.watch<AppState>(); final d=data;
    if(d==null)return const Center(child:CircularProgressIndicator());
    final e=d.entry(s);
    if(e==null)return Column(children:[const SurgoTopBar(),SurgoButton('返回',onTap:()=>s.go(d.back(s)))]);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const SurgoTopBar(),
      SurgoCard(padding:const EdgeInsets.fromLTRB(18,18,18,14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          SvgPicture.asset('assets/images/${d.raw['TF_TASK_ICON'][d.task(s)]}.svg',width:56,height:56),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[const T('题型说明',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:11.5,fontWeight:FontWeight.w800,color:Color(0xFFC8A24A))),const SizedBox(width:9),
              Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:3),decoration:BoxDecoration(color:const Color(0xFFF2EDE2),borderRadius:BorderRadius.circular(20)),child:T(e['mod'],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:10.5,fontWeight:FontWeight.w700,color:Color(0xFF6F6757))))]),
            const SizedBox(height:3),T(e['title'],style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:21,fontWeight:FontWeight.w800,letterSpacing:-.4)),
          ])),
        ]),
        const SizedBox(height:9),T(e['desc'],style:const TextStyle(fontSize:13,height:1.55,color:Color(0xFF6F6757))),
        const SizedBox(height:13),const Divider(height:1,color:Color(0xFFEEE7D8)),
        const SizedBox(height:13),_label(Icons.list_alt,'你将完成'),const SizedBox(height:9),
        for(var i=0;i<(e['steps'] as List).length;i++) Padding(padding:const EdgeInsets.only(bottom:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:24,height:24,alignment:Alignment.center,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFFF5C63F)),child:SourceText('${i+1}',style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:12,fontWeight:FontWeight.w800))),
          const SizedBox(width:12),Expanded(child:T(e['steps'][i],style:const TextStyle(fontSize:13,height:1.5,color:Color(0xFF3A3630)))),
        ])),
        _box(_label(Icons.schedule,'计时与媒体'),T(e['time'],style:const TextStyle(fontSize:12,height:1.55,color:Color(0xFF6F6757)))),
        _box(_label(Icons.touch_app_outlined,'操作预览'),Wrap(spacing:7,runSpacing:7,children:[for(final chip in e['chips'])Container(
          padding:const EdgeInsets.symmetric(horizontal:11,vertical:4),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xFFECE5D6)),borderRadius:BorderRadius.circular(20)),
          child:T(chip,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:11.5,fontWeight:FontWeight.w700,color:Color(0xFF6F6757))))]),yellow:true),
        Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:const Color(0xFFE8F3EA),borderRadius:BorderRadius.circular(14)),
          child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.cloud_upload_outlined,size:17,color:Color(0xFF4C9A63)),SizedBox(width:10),
            Expanded(child:T('作答仅属于本次托福训练，会自动保存，并可在刷新后恢复。',style:TextStyle(fontSize:11.5,height:1.5,color:Color(0xFF4C7655))))])),
        const SizedBox(height:12),SurgoButton(e['cta'],key:const ValueKey('brief-start'),onTap:()=>d.start(s)),
        TextButton(onPressed:()=>s.go(d.back(s)),child:const T('返回',style:TextStyle(fontSize:12,color:Color(0xFF8D8371)))),
      ])),
    ]);
  }
  Widget _label(IconData icon,String text)=>Row(children:[Icon(icon,size:19,color:const Color(0xFFC8A24A)),const SizedBox(width:8),T(text,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:13,fontWeight:FontWeight.w800))]);
  Widget _box(Widget title,Widget body,{bool yellow=false})=>Container(margin:const EdgeInsets.only(top:9),padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
    decoration:BoxDecoration(color:yellow?const Color(0xFFFDF8E6):Colors.white,border:Border.all(color:yellow?const Color(0xFFF3E7C2):const Color(0xFFECE5D6)),borderRadius:BorderRadius.circular(14)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[title,const SizedBox(height:5),body]));
}
