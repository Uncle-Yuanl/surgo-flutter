import 'package:flutter_test/flutter_test.dart';
import 'package:surgo_flutter/features/pron_practice/practice_controller.dart';
void main(){
 test('one simulated recording at a time,15seconds cap,self assessment',(){
  final c=PracticeController(sentence:false);c.mic(0);c.tick();c.mic(1);
  expect(c.at(0).recording,false);expect(c.at(0).done,true);expect(c.at(0).seconds,1);
  for(var i=0;i<15;i++){c.tick();}expect(c.at(1).done,true);expect(c.at(1).recording,false);expect(c.at(1).seconds,15);
  c.judge(1,false);expect(c.at(1).judged,true);expect(c.at(1).ok,false);
  c.mic(1);expect(c.at(1).judged,false);expect(c.at(1).seconds,0);
 });
 test('sentence stops at30seconds; immediate stop records1second like source',(){
  final c=PracticeController(sentence:true);c.mic(0);c.mic(0);expect(c.at(0).seconds,1);
  c.mic(0);for(var i=0;i<30;i++){c.tick();}expect(c.at(0).done,true);expect(c.at(0).seconds,30);
 });
 test('fixed source words and sentence remain exact',(){
  expect(practiceWords,[['library','/ˈlaɪbrəri/','n. 图书馆'],['relevant','/ˈreləvənt/','adj. 相关的']]);
  expect(practiceSentence,'Larry really likes reading in the library.');
 });
}
