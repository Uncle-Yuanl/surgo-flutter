const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),c=vm.createContext({});
vm.runInContext(s.slice(s.indexOf('const WF_T2 ='),s.indexOf('function wfHeadHtml('))+';this.data={WF_T2,WF_T2_ESSAY,WF_T2_NOTES,WF_T2_L1_ESSAY,WF_T2_L1};',c);
function fn(name){const start=s.indexOf(`function ${name}(){`);return s.slice(start,s.indexOf('\n}',start)+2);}
let body=fn('writingFeedbackView');body=body.slice(body.indexOf('  const crit='),body.indexOf('  const critX'));
c.data.task1=vm.runInNewContext(`(()=>{${body};return {crit,tips,essay:essayHtml,notes};})()`);
body=fn('writingL1View');body=body.slice(body.indexOf('  const essayHtml='),body.indexOf('  const isT2'));
c.data.l1task1=vm.runInNewContext(`(()=>{${body};return {essay:essayHtml,items};})()`);
body=fn('writingBandsView');c.data.bands=vm.runInNewContext(`(()=>{${body.slice(body.indexOf('  const para='),body.indexOf('  return'))};return {para,bands};})()`);
for(const name of ['writingImproveView','writingL1DetailView']){const full=fn(name);c.data[name]=vm.runInNewContext(`(${full})()`);}
const text=JSON.stringify(c.data,null,2)+'\n',file=path.join(root,'assets/data/writing_review.json');if(process.argv.includes('--check'))assert.equal(fs.readFileSync(file,'utf8'),text);else fs.writeFileSync(file,text);
console.log('Exact IELTS fixed reviews exported; source markup retained only for extracting annotation spans');
