const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
// TOEFL 口语日常训练 · 听后复述(tfRt) / 接受访谈(tfIv) 均无真实音频/录音调用：RunAudio 只用
// setInterval 模拟播放，作答阶段只跑计时器。导出仅取源码里真实存在的题量/时长/倍速档/逐题
// 批改，不臆造任何 AI 反馈或音频内容。数值通过 Node vm 执行原始源码片段获得，非近似。
const c=vm.createContext({});
const slice=(a,b)=>s.slice(s.indexOf(a),s.indexOf(b,s.indexOf(a)));
// 常量声明（const 只进 vm 词法作用域，需在同 context 的后续脚本里引用）
vm.runInContext(slice('const TSO_RATES=','function tsoAudioCard'),c);
vm.runInContext(slice('const TFRT_TOTAL=','function tfRtCur'),c);
vm.runInContext(slice('const TFIV_TOTAL=','function tfIvCur'),c);
vm.runInContext(slice('const TFRTFB_QS=','function tfRtFbBars'),c);
vm.runInContext(slice('const TFIVFB_QS=','function tfInterviewFbView'),c);
// 视图内联文案（playTitle/playSub/answerSub）
const litOf=(fn,key)=>{const src=slice(`function ${fn}(`,'\n}');const m=new RegExp(`${key}:('(?:\\\\.|[^'])*')`).exec(src);return m?vm.runInContext(m[1],c):'';};
// 反馈页固定字段（HTML 里静态写死，非 AI）
const fbStr=(fn,cls)=>{const src=slice(`function ${fn}(`,'\n}');return new RegExp(`<div class=\\"${cls}\\">([^<]+)`).exec(src)[1];};
const subsOf=fn=>{const src=slice(`function ${fn}(`,'\n}');return vm.runInContext(/const subs=(\[[^;]+\]);/.exec(src)[1],c);};
const weakOf=fn=>{const src=slice(`function ${fn}(`,'\n}');
  return {tags:[...src.matchAll(/tffb-wtag [pbc]\">([^<]+)/g)].map(m=>m[1]),
    q:/tffb-wq\">([^<]+)/.exec(src)[1], a:/tffb-wa\">([^<]+)/.exec(src)[1]};};
const build=(P,tag,view,fb,qs)=>({
  prefix:tag,
  total:vm.runInContext(`${P}_TOTAL`,c), ansSec:vm.runInContext(`${P}_ANS_SEC`,c),
  segments:vm.runInContext(`${P}_SEGS`,c), rates:vm.runInContext('TSO_RATES',c),
  playTitle:litOf(view,'playTitle'), playSub:litOf(view,'playSub'), answerSub:litOf(view,'answerSub'),
  feedback:{score:fbStr(fb,'tffb-score-n'), description:fbStr(fb,'tffb-score-d'),
    subs:subsOf(fb), weak:weakOf(fb), questions:vm.runInContext(qs,c)},
});
const data={
  retell:build('TFRT','tfRt','tfDailyRetellView','tfRetellFbView','TFRTFB_QS'),
  interview:build('TFIV','tfIv','tfDailyInterviewView','tfInterviewFbView','TFIVFB_QS'),
};
const dst=path.join(root,'assets/data/tf_speaking_daily.json'),text=JSON.stringify(data,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log(Object.fromEntries(Object.entries(data).map(([k,v])=>[k,{total:v.total,ansSec:v.ansSec,segs:v.segments.length,rates:v.rates,feedback:v.feedback.questions.length,score:v.feedback.score}])));
