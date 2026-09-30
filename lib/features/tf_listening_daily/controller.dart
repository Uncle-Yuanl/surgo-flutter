import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../widgets/demo_audio.dart';
class TfListeningData {
 static Map<String,dynamic>? cache;
 static Future<Map<String,dynamic>> load()async=>cache??=jsonDecode(await rootBundle.loadString('assets/data/tf_listening_daily.json'));
}
/// Source daily audio is simulated by interval. There is no Audio/TTS call in
/// tfDr/Dc/An/LcRunAudio; do not invent speech or change their speed intervals.
class TfListeningController {
 TfListeningController(this.app,this.key,this.data){
  index=app.session['${prefix}Idx'] as int? ??0;
  phase=app.session['${prefix}Phase'] as String? ??'play';
  left=app.session['${prefix}Left'] as int? ??seconds;
  audio=app.session['${prefix}Audio'] as int? ??0;
  rate=app.session['${prefix}RateIdx'] as int? ??0;
  picks=Map<int,String>.from(app.session['_${prefix}Picks']??{});
  notes=Map<int,String>.from(app.session['_${prefix}Notes']??{});
 }
 final AppState app;final String key;final Map<String,dynamic> data;
 String get prefix=>data['prefix'];
 int get seconds=>data['seconds'];int get total=>data['total'];
 List get segments=>data['segments'];Map get current=>segments[index];
 late int index,left,audio,rate;late String phase;
 bool over=false,alerted=false;int up=0;late Map<int,String> picks,notes;
 static const rates=[1.0,1.25,1.5,1.75,2.0,.75];
 int get audioInterval=>(1000/rates[rate]).round();
 bool get isLast=>index>=total-1;
 void save(){app.session.addAll({'${prefix}Idx':index,'${prefix}Phase':phase,'${prefix}Left':left,'${prefix}Audio':audio,'${prefix}RateIdx':rate,'_${prefix}Picks':picks,'_${prefix}Notes':notes});}
 /// 演示用真实数据的每一段带着后端存的那段录音（clip：{ asset, sec }，tool/demo_export 导出），网页上真的放它；
 /// 没有这一项（原型数据）或不在网页上，就是原型的模拟播放：每个间隔走 1 秒，走到 sec 秒。
 Map? get clip=>demoAudio.available?current['clip'] as Map?:null;
 double get _length=>(clip!['sec'] as num).toDouble();
 // 全站同一时间只放一段：播放器里是这一段，它的位置、在不在放才算这张音频卡的。
 bool get _loaded=>clip!=null&&demoAudio.asset==clip!['asset'];
 bool get sounding=>clip==null?phase=='play':_loaded&&demoAudio.playing;
 double get progress=>_loaded&&phase=='play'?demoAudio.position/demoAudio.duration:audio/(current['sec'] as int);
 /// 从记着的位置放这一段的录音（已经到头就从头）。
 void listen(){if(clip==null)return;demoAudio.rate=rates[rate];demoAudio.play(clip!['asset'],seconds:_length,from:audio>=current['sec']?0:audio.toDouble());}
 void setRate(int i){rate=i;demoAudio.rate=rates[i];save();}
 void seek(int s){audio=(audio+s).clamp(0,current['sec'] as int);if(_loaded)demoAudio.seek(audio.toDouble());save();}
 void audioTick(){if(phase!='play')return;
  if(clip!=null){
   // 播放器里已经不是这一段：页面正在退场（换页时 AppState.go 先把播放器停了，旧页面还要留 300 毫秒的过渡）。
   // 不动它，更不能再放起来；记着的位置留给下次进来接着放。
   if(!_loaded)return;
   // 位置和放完都读播放器：放不出声时它按时长空走、照样放完，这里不会一直等。
   audio=demoAudio.position.floor().clamp(0,current['sec'] as int);if(demoAudio.ended){audio=current['sec'];phase='ready';}save();return;}
  audio++;if(audio>=current['sec']){audio=current['sec'];phase='ready';}save();}
 void begin(){phase='answer';left=seconds;over=false;up=0;alerted=false;save();}
 bool tick(){if(phase!='answer')return false;if(!over){left--;if(left<=0){left=0;over=true;if(!alerted){alerted=true;save();return true;}}}else{up++;}save();return false;}
 void pick(String v){if(phase=='answer'){picks[index]=v;save();}}
 void _relisten(){phase='play';left=seconds;over=false;up=0;alerted=false;save();}
 void replay(){audio=0;_relisten();listen();}
 /// 播放键。原型里它就是重播；真音频按播放器的习惯：正在放就暂停，暂停着接着放；听完了（或已在答题）
 /// 再点就回到听的阶段，从进度所在的位置放（刚往回拖的那几秒），已经到头就从头。
 void toggle(){if(clip==null){replay();return;}
  if(phase!='play')_relisten();
  if(_loaded&&!demoAudio.ended){demoAudio.toggle(clip!['asset'],seconds:_length);}else{listen();}}
 bool next(){if(phase=='play')return true;if(isLast)return false;index++;left=seconds;over=false;up=0;alerted=false;
  if(key!='respond'&&segments[index]['aud']==segments[index-1]['aud']){audio=current['sec'];begin();}else{phase='play';audio=0;listen();}save();return true;}
 String get lead {for(var i=index;i>=0;i--){if(segments[i]['lead']!=null)return segments[i]['lead'];}return data['lead'];}
}
