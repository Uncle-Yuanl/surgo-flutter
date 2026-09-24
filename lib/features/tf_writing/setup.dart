import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
Widget? buildTfWritingSetup(SurgoPage p)=>[SurgoPage.mockWritingTf,SurgoPage.tfWr1Intro,SurgoPage.tfWr2Intro,SurgoPage.tfWr3Intro].contains(p)?TfWritingSetup(page:p):null;
class TfWritingSetup extends StatelessWidget{
 const TfWritingSetup({super.key,required this.page});final SurgoPage page;
 static const summaries=[
  ('Build a Sentence','Drag words from the bank into the blanks to build correct sentences.','10 questions · 6:50'),
  ('Write an Email','Reply to a real situation, covering three required points.','1 task · 7:00'),
  ('Academic Discussion','Join a class discussion with a 100-word-minimum post.','1 task · 10:00')];
 static const titles=['组句','写电子邮件','学术讨论'];
 static const descriptions=['将单词移动到空格中，组成语法正确、且符合给定语境的句子。','你将阅读一段简短情境并撰写一封电子邮件作为回应。限时 7 分钟。你的邮件应涵盖所有要求点，并使用恰当的语气。','参与课堂讨论，发表一篇不少于 100 词的帖子。'];
 @override Widget build(BuildContext context){final app=context.read<AppState>();final task=page==SurgoPage.tfWr1Intro?1:page==SurgoPage.tfWr2Intro?2:3,summary=page==SurgoPage.mockWritingTf;
  void start(){if(summary){app.go(SurgoPage.tfWr1Intro);return;}
   app.session['tfw${task}Daily']=false;app.session['tfw${task}Left']=[0,410,420,600][task];
   if(task==1){app.session.addAll({'tfw1Idx':0,'tfw1Skipped':1,'tfw1Slots':List<int?>.filled(6,null)});}else{app.session['tfw${task}Body']='';app.session['tfwTab']='topic';app.session['tfwTabPage']='tfWr${task}Q';if(task==2)app.session.addAll({'tfw2Subj':'','tfw2ReqOpen':false,'tfw2ReqChecked':[false,false,false]});}
   app.go([SurgoPage.tfWr1Q,SurgoPage.tfWr2Q,SurgoPage.tfWr3Q][task-1]);
  }
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[SurgoTopBar(back:summary?SurgoPage.ielts:SurgoPage.mockWritingTf),
   const T('TOEFL WRITING',style:SurgoText.cardEn),const T('MOCK EXAM · REAL TIMING',style:SurgoText.cardDesc),T(summary?'3 TASKS · ABOUT 24 MIN':'TASK $task OF 3',style:SurgoText.cardDesc),
   SurgoHeading(summary?'Writing (Mock Exam)':titles[task-1],subtitle:summary?'Three tasks, exactly like the real test. The timer starts when a task begins and your work is saved automatically after every task.':descriptions[task-1]),
   if(summary)for(var i=0;i<3;i++)SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SourceText('${i+1}   ${summaries[i].$1}',style:SurgoText.cardTitle),SourceText(summaries[i].$2,style:SurgoText.cardDesc),const SizedBox(height:10),SourceText(summaries[i].$3,style:SurgoText.cardEn)])),
   if(!summary)...[
    if(task==1)const SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[T('一个合适的句子',style:SurgoText.cardTitle),T('• 符合书面学术场景的最佳语序'),T('• 语法正确'),T('• 仅使用所提供的标点')])),
    SurgoCard(color:SurgoColors.yellowTint,child:T(task==2?'本任务限时 7 分钟。计时器会显示你完成本任务的剩余时间。':'计时器将显示你完成本任务的剩余时间。',style:SurgoText.cardDesc)),
   ],SurgoButton(summary?'I am ready, start task 1':'开始第 $task / 3 项任务',onTap:start),const SizedBox(height:12),SurgoButton(summary?'Back':'返回',primary:false,onTap:()=>app.go(summary?SurgoPage.ielts:SurgoPage.mockWritingTf)),
  ]);
 }
}
