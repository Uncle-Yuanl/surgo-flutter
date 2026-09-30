import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../oral_daily/controller.dart';
class IeltsMockSpeakingData {
 static Map<String,dynamic>? cache;
 static Future<Map<String,dynamic>> load()async=>cache??=jsonDecode(await rootBundle.loadString('assets/data/ielts_mock_speaking.json')) as Map<String,dynamic>;
}
class IeltsMockSpeakingController extends ChangeNotifier {
 IeltsMockSpeakingController(this.app,this.data,{OralSpeech? speech,required this.mark}):speech=speech??NativeOralSpeech(),revision=app.revision{part=app.session['spqPart'] as String? ?? 'p1';reset(part);}
 /// 建控制器时的 AppState.revision：每次换页它都加一，对不上就是这一页已经被换走了（还要淡出 300 毫秒才 dispose）。
 final int revision;
 final AppState app;final Map<String,dynamic> data;final OralSpeech speech;final VoidCallback mark;
 late String part;int index=0,left=300,recSec=0,prep=60,recLeft=120,round=1,phaseLeft=5;
 String phase='prep',turn='ask',note='';bool recording=false,busy=false,disposed=false;
 final List<Map<String,dynamic>> turns=[];Timer? clock,recordTimer;final List<Timer> pending=[];int epoch=0;
 /// 考官的提问没能读出声音的那几题（题号）：页面把题目文字显示出来。
 final Set<int> unheard={};
 Map get cfg=>data['SPQ'][part];
 void emit(){if(disposed)return;app.session.addAll({'spqPart':part,'spqIdx':index,'spqLeft':left,'spqRec':recording,'spqBusy':busy,'spqRecSec':recSec,'spqTurns':List.of(turns),'sp2Phase':phase,'sp2Prep':prep,'sp2RecLeft':recLeft,'sp2Note':note,'sp3Phase':turn,'sp3Left':left,'sp3Round':round,'sp3PhaseLeft':phaseLeft});notifyListeners();}
 void later(int ms,VoidCallback callback){pending.add(Timer(Duration(milliseconds:ms),(){if(!disposed)callback();}));}
 void reset(String p){clock?.cancel();recordTimer?.cancel();speech.stop();epoch++;for(final t in pending){t.cancel();}pending.clear();part=p;index=0;left=cfg['sec'];turns.clear();unheard.clear();recording=false;busy=false;recSec=0;
  if(p=='p2'){phase='prep';prep=cfg['prep'];recLeft=cfg['rec'];note='';}
  if(p=='p3'){turn='ask';phaseLeft=data['SP3_SWAP'];round=1;}
 }
 void start(){clock?.cancel();clock=Timer.periodic(const Duration(seconds:1),(_)=>tick());if(part!='p3')later(260,()=>play(index,auto:part=='p1'));emit();}
 void select(String p){reset(p);start();}
 Future<void> play(int qi,{bool auto=false})async{
  // 被换走的页面不再提问：这时再放，考官的声音会在下一个页面上响一下。
  if(app.revision!=revision)return;
  final qs=cfg['qs'] as List,text=qi<qs.length?qs[qi] as String:'';speech.stop();final generation=++epoch;
  if(auto){busy=true;recording=false;emit();}
  // busy 只由提问结束来解除：提问途中手点重播会作废那一次朗读，所以重播结束时也要解除，否则麦克风一直点不动。
  void done(){if(disposed||generation!=epoch)return;if(auto||busy){busy=false;startRec();}emit();}
  await speech.speak(text,started:(){},ended:done,failed:(_){if(disposed||generation!=epoch)return;unheard.add(qi);emit();later(900,done);});
 }
 void startRec(){if(busy)return;recording=true;recSec=0;recordTimer?.cancel();recordTimer=Timer.periodic(const Duration(seconds:1),(_){if(recording){recSec++;emit();}});emit();}
 void mic(){
  if(part=='p2'){
   if(phase=='prep'){phase='rec';prep=0;recording=true;emit();}else if(phase=='rec'){phase='done';recording=false;clock?.cancel();emit();later(600,finish);}
   return;
  }
  if(busy)return;
  if(!recording){startRec();return;}
  recording=false;recordTimer?.cancel();final qs=cfg['qs'] as List;
  turns.add({'q':index<qs.length?qs[index]:'','dur':recSec});
  if(index+1>=(cfg['n'] as int)){emit();later(600,finish);return;}
  index++;emit();later(500,()=>play(index,auto:true));
 }
 void tick(){
  if(part=='p3'){
   if(left>0)left--;if(phaseLeft>0)phaseLeft--;
   if(phaseLeft<=0){turn=turn=='ask'?'ans':'ask';phaseLeft=data['SP3_SWAP'];if(turn=='ask')round++;recording=turn=='ans';}
   emit();if(left<=0)finish();return;
  }
  if(part=='p2'){
   if(phase=='prep'){if(prep>0)prep--;if(prep<=0){phase='rec';recording=true;}}
   else if(phase=='rec'){if(recLeft>0)recLeft--;if(recLeft<=0){phase='done';recording=false;clock?.cancel();emit();later(700,finish);return;}}
  }
  if(left>0)left--;emit();if(left<=0)finish();
 }
 void finish(){clock?.cancel();recordTimer?.cancel();speech.stop();epoch++;recording=false;busy=false;
  if(part=='p1'){select('p2');}else if(part=='p2'){select('p3');}else{emit();mark();}}
 @override
 void dispose(){if(disposed)return;disposed=true;clock?.cancel();recordTimer?.cancel();epoch++;speech.stop();for(final t in pending){t.cancel();}super.dispose();}
}
