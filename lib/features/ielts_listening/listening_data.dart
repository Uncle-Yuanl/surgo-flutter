import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
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
 void seek(double seconds){audio=(audio+seconds).clamp(0,225);app.session['audioPos']=audio;}
 void audioTick(){if(!playing)return;seek(.25);if(audio>=225)playing=false;}
 bool tick(){if(left>0){left--;return left==0;}over++;return false;}
}
