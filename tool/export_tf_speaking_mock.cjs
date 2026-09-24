const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
// TOEFL 口语「模考」两任务（Task 1 听后复述 tfSpk1 / Task 2 参加访谈 tfSpk2）+ 批改反馈 tfSpeakFb。
// 源 app.js 里播放/录音全是「模拟」：tfS1StartFlow / tfS2StartFlow 只用 setInterval 每 1s 推进
// 计时状态机（instruct→play→ready→answer / play→answer），没有任何真实音频、录音、后端或评分调用。
// 反馈页所有数字与文案都是源码里静态写死（TFSF_TYPES/TFSF_SUB/TFSF_QS + 总分/薄弱项），非 AI 生成。
// 本脚本用 Node vm 执行原始源码常量取「精确」值，不近似、不臆造。与模考日常训练不同：模考没有倍速/重播。
const c=vm.createContext({});
const slice=(a,b)=>s.slice(s.indexOf(a),s.indexOf(b,s.indexOf(a)));
// \uXXXX 出现在模板字符串里，是运行期转义；文本抽取需手动解码回真实字符。
const dec=x=>x.replace(/\\u([0-9a-fA-F]{4})/g,(_,h)=>String.fromCharCode(parseInt(h,16))).replace(/<br>/g,'\n');
// 常量声明（const 进入 vm context 的词法作用域，可被后续同 context 脚本引用）
vm.runInContext(slice('const TFSPK1_SEGS=','function tfS1Cur'),c); // 含 TFSPK1_TOTAL/INSTR_SEC/READY_SEC
vm.runInContext(slice('const TFSPK2_SEGS=','function tfS2Cur'),c); // 含 TFSPK2_TOTAL
vm.runInContext(slice('const TFSF_TYPES=','function tfSfPickType'),c); // 含 TFSF_SUB / TFSF_QS

const introSrc=slice('function tfSpk2IntroView(','function startTfSpk2(');
const briefSrc=slice('function tfSpk2BriefView(','function startTfSpk2Q(');
const fbSrc=slice('function tfSpeakFbView(','\n}');
const pick=(src,cls)=>dec(new RegExp(`${cls}\\">([^<]+)`).exec(src)[1]);
// 反馈页两段 tffb-weak 静态薄弱项：按块拆分，逐块取 tags/q/a
const weak=fbSrc.split('tffb-weak').slice(1).map(ch=>({
  tags:[...ch.matchAll(/tffb-wtag [a-z]\">([^<]+)</g)].map(m=>dec(m[1])),
  q:dec(/tffb-wq\">([^<]+)</.exec(ch)[1]),
  a:dec(/tffb-wa\">([^<]+)</.exec(ch)[1]),
}));

const data={
  task1:{
    total:vm.runInContext('TFSPK1_TOTAL',c),
    instrSec:vm.runInContext('TFSPK1_INSTR_SEC',c),
    readySec:vm.runInContext('TFSPK1_READY_SEC',c),
    segments:vm.runInContext('TFSPK1_SEGS',c),
  },
  task2:{
    total:vm.runInContext('TFSPK2_TOTAL',c),
    intro:{title:pick(introSrc,'ml-ttl'),sub:pick(introSrc,'ml-sub'),note:pick(introSrc,'mli-note')},
    brief:{title:pick(briefSrc,'ml-ttl'),sub:pick(briefSrc,'ml-sub')},
    segments:vm.runInContext('TFSPK2_SEGS',c),
  },
  feedback:{
    score:pick(fbSrc,'tffb-score-n'),
    description:pick(fbSrc,'tffb-score-d'),
    footnote:pick(fbSrc,'tffb-score-f'),
    types:vm.runInContext('TFSF_TYPES',c),
    subs:vm.runInContext('TFSF_SUB',c),
    questions:vm.runInContext('TFSF_QS',c),
    weak,
  },
};
const dst=path.join(root,'assets/data/tf_speaking_mock.json'),text=JSON.stringify(data,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log({task1:{total:data.task1.total,instrSec:data.task1.instrSec,readySec:data.task1.readySec,segs:data.task1.segments.length},
  task2:{total:data.task2.total,segs:data.task2.segments.length},
  feedback:{score:data.feedback.score,types:data.feedback.types.length,subs:data.feedback.subs.length,qr:data.feedback.questions.r.length,qi:data.feedback.questions.i.length,weak:data.feedback.weak.length}});
