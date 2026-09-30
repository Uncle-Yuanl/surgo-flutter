import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
class TfWritingData{static Map<String,dynamic>? cache;static Future<Map<String,dynamic>> load()async=>cache??=jsonDecode(await rootBundle.loadString('assets/data/tf_writing.json'));
 /// 第 [n] 项任务的题目。演示用真实数据（tool/demo_export）把模考那一场的题目另存在
 /// `TFW1_QS_MOCK` / `TFW2_MOCK` / `TFW3_MOCK`：日常训练（`tfw1Daily` 等为 true）读原来的键，
 /// 其余情况（页面当模考画）读 `_MOCK`。原型数据没有这些键，日常和模考共用一套题。
 static dynamic item(AppState app,Map data,int n,String key)=>(app.session['tfw${n}Daily']==true?null:data['${key}_MOCK'])??data[key];
}
class TfSentenceController{
 TfSentenceController(this.app,this.data){index=app.session['tfw1Idx'] as int? ??0;left=app.session['tfw1Left'] as int? ??410;
 slots=List<int?>.from(app.session['tfw1Slots']??List.filled(slotCount,null));if(slots.length!=slotCount)slots=List.filled(slotCount,null);
 done=List<bool>.from(app.session['tfw1Done']??[]);seen=List<bool>.from(app.session['tfw1Seen']??[]);}
 final AppState app;final Map<String,dynamic> data;late int index,left;late List<int?> slots;late List<bool> done,seen;
 List get qs=>TfWritingData.item(app,data,1,'TFW1_QS');Map get current=>qs[index];int get slotCount=>(current['parts'] as List).where((x)=>x=='_').length;
 bool get daily=>app.session['tfw1Daily']==true;bool get complete=>slots.isNotEmpty&&slots.every((x)=>x!=null);
 void save(){app.session.addAll({'tfw1Idx':index,'tfw1Left':left,'tfw1Slots':slots,'tfw1Done':done,'tfw1Seen':seen});}
 void sync(){if(done.isNotEmpty){done[index]=complete;if(seen.isNotEmpty)seen[index]=true;}save();}
 void drop(int bank,int to,{int? from}){if(from!=null){final old=slots[to];slots[to]=bank;slots[from]=old;}else{slots[to]=bank;}sync();}
 void remove(int from){slots[from]=null;sync();}
 void move(int delta){sync();index=(index+delta).clamp(0,qs.length-1);if(seen.isNotEmpty)seen[index]=true;slots=List.filled(slotCount,null);save();}
 void tick(){if(left>0)left--;save();}
 static int words(String s)=>s.trim().isEmpty?0:s.trim().split(RegExp(r'\s+')).length;
}
