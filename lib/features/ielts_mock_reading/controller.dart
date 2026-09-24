import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
class IeltsMockReadingData {
 static List? cache;
 static Future<List> load() async => cache??=jsonDecode(await rootBundle.loadString('assets/data/ielts_mock_reading.json')) as List;
}
class IeltsMockReadingController {
 IeltsMockReadingController(this.app,this.passages){passage=app.session['mrPas'] as int? ?? 1;left=app.session['mrLeft'] as int? ?? 3600;
  final raw=app.session['mrAns'] as Map? ?? {};for(final e in raw.entries){answers[int.parse(e.key.toString())]=e.value;}}
 final AppState app;
 final List passages;
 late int passage,left;
 final Map<int,dynamic> answers={};
 Map get current=>passages[passage-1] as Map;
 List get questions=>current['qs'];
 int base(int n)=>passages.take(n-1).fold(0,(sum,p)=>sum+(p['qs'] as List).length);
 int get total=>passages.fold(0,(sum,p)=>sum+(p['qs'] as List).length);
 int count(int n){final b=base(n),len=(passages[n-1]['qs'] as List).length;return answers.keys.where((k)=>k>=b&&k<b+len).length;}
 Map group(int i){for(var k=i;k>=0;k--){if(questions[k]['group']!=null)return questions[k] as Map;}return questions.first as Map;}
 void select(int n){if(n<1||n>3)return;passage=n;save();}
 void pick(int global,int? value){if(value==null){answers.remove(global);}else{answers[global]=value;}save();}
 void type(int global,String value){if(value.trim().isEmpty){answers.remove(global);}else{answers[global]={'v':value};}save();}
 bool tick(){if(left>0)left--;save();return left==0;}
 void save()=>app.session.addAll({'mrPas':passage,'mrLeft':left,'mrAns':Map<int,dynamic>.from(answers)});
}
