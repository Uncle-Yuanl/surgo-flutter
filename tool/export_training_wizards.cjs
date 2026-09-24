const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
// 无损导出写作/听力/口语/词汇日常训练向导的静态数据 —— 与原型 app.js 逐字对应：
//   WIZ            第 1669 行起（雅思侧卡片/双卡版式的文案与题型）
//   TFLIS_TASKS 等 第 12609 行起（托福听力任务 + 难度）
//   TF_TASK_ICON   第 14901 行起（任务 key → 图标文件名）
//   TFWR_TASKS     第 14996 行起（托福写作任务）
//   TFSP_TASKS     第 15048 行起（托福口语任务）
// 阅读向导已由 export_reading.cjs 覆盖，这里不重复导出 TFREAD_*/RTYPES。
const grab=(from,to)=>{const a=src.indexOf(from),b=src.indexOf(to,a);assert(a>=0&&b>a,`${from} .. ${to}`);return src.slice(a,b);};
const code=[
  grab('const WIZ={','// 三个托福阅读任务'),
  grab('const TFLIS_TASKS=[','function pickTfLisTask'),
  grab('const TF_TASK_ICON={','function tfTaskIcon('),
  grab('const TFWR_TASKS=[','let tfWrTask'),
  grab('const TFSP_TASKS=[','let tfSpTask'),
  ';this.out={WIZ,TFWR_TASKS,TFLIS_TASKS,TFLIS_DIFFS,TFSP_TASKS,TF_TASK_ICON};',
].join('\n');
const ctx=vm.createContext({});
vm.runInContext(code,ctx);
const out=ctx.out;
// 词汇向导没有托福版式，仍走雅思双卡；这里只做完整性校验，不改动任何文案。
assert(out.WIZ.reading&&out.WIZ.listening&&out.WIZ.writing&&out.WIZ.speaking&&out.WIZ.vocab);
assert(out.TFWR_TASKS.length===3&&out.TFLIS_TASKS.length===4&&out.TFSP_TASKS.length===3);
assert(out.TFLIS_DIFFS.length===3);
const dst=path.join(root,'assets/data/training_wizards.json'),text=JSON.stringify(out,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log('WIZ:',Object.keys(out.WIZ).length,'; TFWR/TFLIS/TFSP:',out.TFWR_TASKS.length,out.TFLIS_TASKS.length,out.TFSP_TASKS.length,'; icons:',Object.keys(out.TF_TASK_ICON).length);
