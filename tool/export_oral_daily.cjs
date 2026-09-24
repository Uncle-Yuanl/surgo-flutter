const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),qb=fs.readFileSync(path.join(root,'../surgo-mobile-new/questions.js'),'utf8');
function fixture(exam,card,actions){
 let clock=0,id=0,pending=new Map(),spoken=null;
 const element={textContent:'',style:{},classList:{add(){},remove(){}},querySelector(){return null;}};
 const c=vm.createContext({console,examType:exam,selWizCard:card,route:'oralExam',
  oralState:'note',oralTimer:null,oralQIdx:0,oralNote:'',oralSpeaking:false,oralHeard:new Set(),
  setTimeout:(fn,ms)=>{pending.set(++id,{fn,at:clock+ms});return id;},
  setInterval:(fn,ms)=>{pending.set(++id,{fn,at:clock+ms,repeat:ms});return id;},
  clearTimeout:n=>pending.delete(n),clearInterval:n=>pending.delete(n),alert:()=>{},
  SpeechSynthesisUtterance:function(text){this.text=text;},
  document:{getElementById:()=>element,querySelector:()=>null},
  window:{speechSynthesis:{cancel(){},speak(u){spoken=u;u.onstart?.();}}},
 });
 c.go=x=>c.route=x;
 vm.runInContext(qb+'\nfunction qb(skill){return QB[examType][skill]||{}}\n'+src.slice(src.indexOf('function oralTask(){'),src.indexOf('// Part 2 的 points')),c);
 const task=JSON.parse(vm.runInContext('JSON.stringify(oralTask())',c));
 const snap=()=>JSON.parse(vm.runInContext('JSON.stringify({phase:oralState,index:oralQIdx,note:oralNote,recSec:oralRecSec,turn:d3Turn,round:d3Round,answerSec:d3Sec,askSec:d3AskSec,route})',c));
 const frames=[];
 for(const a of actions){
  if(a.wait!==undefined){const end=clock+a.wait;for(;;){const next=[...pending].filter(([,v])=>v.at<=end).sort((a,b)=>a[1].at-b[1].at||a[0]-b[0])[0];if(!next)break;const [n,t]=next;clock=t.at;if(t.repeat)t.at+=t.repeat;else pending.delete(n);t.fn();}clock=end;}
  else if(a.endSpeech){spoken?.onend?.();}
  else if(a.note!==undefined)c.oralNote=a.note;
  else vm.runInContext(a.call+'()',c);
  frames.push({action:a,state:snap()});
 }
 return {exam,card,task,frames};
}
const output=[
 fixture('ielts','p1',[{call:'startOralExam'},{wait:400},{endSpeech:true},{call:'oralMic'},{wait:7000},{call:'oralMic'},{call:'oralRetake'},{call:'oralMic'},{wait:30000},{call:'oralSubmitAnswer'},{wait:350},{endSpeech:true}]),
 fixture('ielts','p2',[{call:'startOralExam'},{wait:400},{endSpeech:true},{wait:2099},{wait:1},{note:'source note'},{call:'oralMic'},{wait:119000},{wait:1000},{call:'oralSubmitAnswer'}]),
 fixture('toefl','interview',[{call:'startOralExam'},{wait:400},{endSpeech:true},{call:'oralMic'},{wait:30000}]),
 fixture('ielts','p3',[{call:'startOralExam'},{wait:200},{endSpeech:true},{wait:4800},{wait:30000},{wait:315000}]),
];
const target=path.join(root,'test/fixtures/oral_daily_oracle.json'),text=JSON.stringify(output,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('Verified 4 oral source scenarios / '+output.reduce((n,s)=>n+s.frames.length,0)+' snapshots');
