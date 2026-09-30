import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/learner_profile.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import 'primitives.dart';
import 't.dart';

const mockSubjects = [
  ('listening','Listening','5.5/6','mk_listening.png'),
  ('speaking','Speaking','5.5/6','mk_speaking.png'),
  ('reading','Reading','6.5/6','mk_reading.png'),
  ('writing','Writing','6.0/7','mk_writing.png'),
];
SurgoPage mockStartTarget(String key, ExamType exam) => switch(key) {
  'listening'=>SurgoPage.mockListening,
  'speaking'=>SurgoPage.mockSpeaking,
  'reading'=>SurgoPage.mockReading,
  'writing'=>exam==ExamType.toefl?SurgoPage.mockWritingTf:SurgoPage.mockWritingIntro,
  _=>SurgoPage.examTimer,
};
Future<void> showMockSelector(BuildContext context) {
  final state=context.read<AppState>();
  state.session['mockPick']='listening';
  return showModalBottomSheet<void>(context:context,isScrollControlled:true,
    backgroundColor:Colors.white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(26))),
    builder:(context)=>const _MockSelector());
}
class _MockSelector extends StatefulWidget {
  const _MockSelector();
  @override
  State<_MockSelector> createState()=>_MockSelectorState();
}
class _MockSelectorState extends State<_MockSelector> {
  String chosen='listening';
  // 每科下面那行分数：原型是写死的；演示数据（learner_profile.json 的 mocks）里是该科
  // 最近一次真作答过的模考分 / 满分，没考过就不画。
  String? _score(String key,String prototype){
    final real=LearnerProfile.exam(context.read<AppState>().examType)['mocks'] as Map?;
    return real==null?prototype:real[key] as String?;
  }
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(22,12,22,30),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Container(width:40,height:4,decoration:BoxDecoration(color:const Color(0xFFE3E7EC),borderRadius:BorderRadius.circular(3))),
    const SizedBox(height:18),const T('What do you mock the exam first?',textAlign:TextAlign.center,style:SurgoText.sheetTitle),
    const SizedBox(height:24),GridView.count(crossAxisCount:2,mainAxisSpacing:14,crossAxisSpacing:14,
      shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.15,
      children:[for(final m in mockSubjects) GestureDetector(key:ValueKey('mock-${m.$1}'),onTap:(){setState(()=>chosen=m.$1);context.read<AppState>().session['mockPick']=chosen;},child:Container(
        decoration:BoxDecoration(color:chosen==m.$1?SurgoColors.yellowTint:Colors.white,border:Border.all(color:chosen==m.$1?SurgoColors.yellow:SurgoColors.line,width:1.5),borderRadius:BorderRadius.circular(18)),
        child:Stack(children:[Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Image.asset('assets/images/${m.$4}',height:44,width:44),const SizedBox(height:7),T(m.$2,style:const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:14,fontWeight:FontWeight.w800)),
          if(_score(m.$1,m.$3)!=null)...[const SizedBox(height:4),Text(_score(m.$1,m.$3)!,style:const TextStyle(fontSize:11,color:SurgoColors.muted))]])),
          if(chosen==m.$1) const Positioned(right:10,top:8,child:Icon(Icons.check_circle,size:18,color:SurgoColors.yellow)),
        ])))]),
    const SizedBox(height:22),SurgoButton('Start learning',onTap:(){
      final state=context.read<AppState>();state.session['sessionMode']='mock';state.session['mockPick']=chosen;
      Navigator.pop(context);state.go(mockStartTarget(chosen,state.examType));
    }),
  ]));
}
