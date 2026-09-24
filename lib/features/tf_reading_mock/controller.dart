import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
class TfReadingMockData {
 static Map<String,dynamic>? cache;
 static Future<Map<String,dynamic>> load()async=>cache??=jsonDecode(await rootBundle.loadString('assets/data/tf_reading_mock.json')) as Map<String,dynamic>;
}
class TfReadingMockController {
 TfReadingMockController(this.app,this.data,this.part){index=app.session['$prefix${words?'Para':'Idx'}'] as int? ?? 0;
  left=app.session[clockKey] as int? ?? (config['sec'] as int);
  final raw=app.session['${prefix}Vals'] as Map? ?? {};for(final e in raw.entries){values[e.key.toString()]=e.value;}}
 final AppState app;final Map<String,dynamic> data;final int part;
 late int index,left;final values=<String,dynamic>{};
 String get prefix=>'tfR$part';String get clockKey=>'tfR${part==4?3:part}Left';
 bool get words=>part==1||part==3;
 Map get config=>data['parts']['$part'];
 List get items=>config[words?'paras':'qs'];
 dynamic get current=>items[index];
 int get total=>config['total'];
 int get blankCount=>(current as List).whereType<List>().length;
 int get filled=>List.generate(blankCount,(i)=>i).where((i)=>(values['${index}_$i']??'').toString().trim().isNotEmpty).length;
 dynamic inherited(String key,dynamic fallback){for(var i=index;i>=0;i--){if(items[i][key]!=null)return items[i][key];}return fallback;}
 List get document=>inherited('ad',config['ad']) as List;
 String get title=>inherited('title',config['title']);
 void input(int blank,String value){values['${index}_$blank']=value;save();}
 void pick(int n){values['$index']=n;save();}
 void jump(int i){index=i;save();}
 void save()=>app.session.addAll({'$prefix${words?'Para':'Idx'}':index,'${prefix}Vals':Map<String,dynamic>.from(values),clockKey:left});
 void start(int n){final cfg=data['parts']['$n'];app.session.addAll({'tfR$n${n==1||n==3?'Para':'Idx'}':0,'tfR${n}Vals':<String,dynamic>{},if(n!=4)'tfR${n}Left':cfg['sec']});app.go(route(n));}
 static SurgoPage route(int n)=>[SurgoPage.tfRead1Q,SurgoPage.tfRead2Q,SurgoPage.tfRead3Q,SurgoPage.tfRead4Q][n-1];
 void previous(){if(index>0){jump(index-1);}else if(part==2){start(1);}else if(part==4){app.go(SurgoPage.tfRead3Q);}}
 /// null = local advance, route = next screen, tfReadFb = source fixed marking.
 SurgoPage? next(){if(index<items.length-1){jump(index+1);return null;}if(part==1){start(2);return SurgoPage.tfRead2Q;}if(part==3){start(4);return SurgoPage.tfRead4Q;}if(part==2){app.go(SurgoPage.tfReadModEnd);return SurgoPage.tfReadModEnd;}feedback();return SurgoPage.tfReadFb;}
 void feedback(){app.session.addAll({'tfRfbMod':part>=3?'m2':'m1','tfRfbType':'w'});}
 SurgoPage? tick(){left--;save();if(left>0)return null;if(part==2){app.go(SurgoPage.tfReadModEnd);return SurgoPage.tfReadModEnd;}feedback();return SurgoPage.tfReadFb;}
}
