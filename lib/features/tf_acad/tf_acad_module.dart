import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes.dart';
import '../toefl_life/toefl_life_logic.dart';
import '../toefl_life/toefl_life_page.dart';
import '../toefl_life/toefl_life_feedback.dart';

/// Academic/life use the SAME source transition rules:40s,next resets,prev and
/// jump retain timer. Adapt only the passage schema; preserve all strings.
class TfAcademicData {
 static TfDlContent? _cache;
 static Future<TfDlContent> load()async {
  if(_cache!=null)return _cache!;
  final raw=jsonDecode(await rootBundle.loadString('assets/data/tf_acad.json')) as Map;
  final qs=(raw['TFDA_QS'] as List).asMap().entries.map((entry){
   final q=Map<String,dynamic>.from(entry.value);
   if(q['src']!=null)q['src']=q['src']=='uhi'?'post':'ad';
   if(entry.key==0){q['title']??=raw['TFDA_TITLE'];q['src']??='ad';}
   return q;
  }).toList();
  return _cache=TfDlContent.fromJson({
   'TFDL_AD':raw['TFDA_PARAS'],'TFDL_POST':raw['TFDA_PARAS2'],'TFDL_QS':qs,'TFDL_SEC':raw['TFDA_SEC'],
   'TFDLFB_WEAK':raw['TFDAFB_WEAK'],'TFDLFB_SRC':raw['TFDAFB_SRC'],'TFDLFB_QS':raw['TFDAFB_QS'],
   // 演示用真实数据带这一场的估分；原型数据没有这个键，反馈页用原来写死的分数。
   'TFDLFB_SCORE':raw['TFDAFB_SCORE'],
  });
 }
}
Widget? buildTfAcademicPage(SurgoPage p)=>p==SurgoPage.tfDailyAcad||p==SurgoPage.tfDaFb?_AcademicPage(feedback:p==SurgoPage.tfDaFb):null;
class _AcademicPage extends StatefulWidget {
 const _AcademicPage({required this.feedback});final bool feedback;
 @override State<_AcademicPage> createState()=>_AcademicPageState();
}
class _AcademicPageState extends State<_AcademicPage>{
 TfDlContent? data;
 @override void initState(){super.initState();TfAcademicData.load().then((value){if(mounted)setState(()=>data=value);});}
 @override Widget build(BuildContext context)=>data==null?const Center(child:CircularProgressIndicator()):widget.feedback?TfDlFbView(content:data!,academic:true):TfDailyLifeView(content:data!,academic:true);
}
