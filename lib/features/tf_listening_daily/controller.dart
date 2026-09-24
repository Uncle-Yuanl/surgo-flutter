import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
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
 void audioTick(){if(phase!='play')return;audio++;if(audio>=current['sec']){audio=current['sec'];phase='ready';}save();}
 void begin(){phase='answer';left=seconds;over=false;up=0;alerted=false;save();}
 bool tick(){if(phase!='answer')return false;if(!over){left--;if(left<=0){left=0;over=true;if(!alerted){alerted=true;save();return true;}}}else{up++;}save();return false;}
 void pick(String v){if(phase=='answer'){picks[index]=v;save();}}
 void replay(){phase='play';audio=0;left=seconds;over=false;up=0;alerted=false;save();}
 bool next(){if(phase=='play')return true;if(isLast)return false;index++;left=seconds;over=false;up=0;alerted=false;
  if(key!='respond'&&segments[index]['aud']==segments[index-1]['aud']){audio=current['sec'];begin();}else{phase='play';audio=0;}save();return true;}
 String get lead {for(var i=index;i>=0;i--){if(segments[i]['lead']!=null)return segments[i]['lead'];}return data['lead'];}
}
