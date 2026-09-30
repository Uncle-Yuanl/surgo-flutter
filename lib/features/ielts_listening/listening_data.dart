import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../widgets/demo_audio.dart';
class IeltsListeningData {
 IeltsListeningData(this.raw);final Map<String,dynamic> raw;
 static IeltsListeningData? cache;
 // 直接读字节再解码：rootBundle.loadString 对 50 KB 以上的文件会另起 isolate 解码，
 // widget 测试（路由审计）的假时钟等不到它；演示用真实数据的这个文件超过了 50 KB。
 static Future<IeltsListeningData> load()async=>cache??=IeltsListeningData(jsonDecode(utf8.decode(Uint8List.sublistView(await rootBundle.load('assets/data/ielts_listening.json')))));
}
class IeltsListeningController {
 IeltsListeningController(this.app,this.data){
  part=app.session['lisPart'] as String? ??'s1';if(data.raw['parts'][part]==null)part='s1';
  meta=Map<String,dynamic>.from(data.raw['parts'][part]);
  done=app.session.putIfAbsent('lisDone',()=> <int>{}) as Set<int>;
  audio=app.session['audioPos'] as double? ??0;
 }
 final AppState app;final IeltsListeningData data;
 late String part;late Map<String,dynamic> meta;late Set<int> done;
 final Map<int,Set<int>> picks={};
 late double audio;
 bool playing=false;String speed='1X';int left=420,over=0;
 List get questions=>meta['qs'];
 int get total=>questions.length+(meta['mapQs'] as List? ??[]).length+(meta['qs2'] as List? ??[]).length;
 void pick(int q,int option,bool multi){final values=picks.putIfAbsent(q,()=>{});if(multi){if(!values.remove(option))values.add(option);}else{values.clear();values.add(option);}if(values.isEmpty){done.remove(q);}else{done.add(q);}}
 void gap(int q,String text,{bool second=false}){if(second&&text.trim().isEmpty){done.remove(q);}else{done.add(q);}}
 /// 演示用真实数据带着这一 Part 的录音（audio：{ asset, sec }，tool/demo_export 导出），网页上真的放它；
 /// 没有这一项（原型数据）或不在网页上，就是原型的模拟播放：进度每 250 毫秒走 0.25 秒，走到 225 秒。
 Map? get clip=>demoAudio.available?meta['audio'] as Map?:null;
 double get length=>(clip?['sec'] as num?)?.toDouble()??225;
 bool get _loaded=>clip!=null&&demoAudio.asset==clip!['asset'];
 void toggle(){
  final c=clip;if(c==null){playing=!playing;return;}
  // 离开再回来时播放器已经停了：从上次的位置接着放。
  if(_loaded&&!demoAudio.ended){demoAudio.toggle(c['asset'],seconds:length);}
  else{demoAudio.play(c['asset'],seconds:length,from:audio>=length?0:audio);}
  playing=demoAudio.playing;
 }
 void setSpeed(String value){speed=value;demoAudio.rate=double.parse(value.replaceAll('X',''));}
 void seek(double seconds){audio=(audio+seconds).clamp(0,length);app.session['audioPos']=audio;if(_loaded)demoAudio.seek(audio);}
 void audioTick(){
  if(clip!=null){if(_loaded){audio=demoAudio.position;playing=demoAudio.playing;app.session['audioPos']=audio;}return;}
  if(!playing)return;seek(.25);if(audio>=225)playing=false;
 }
 bool tick(){if(left>0){left--;return left==0;}over++;return false;}
}
