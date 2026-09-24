const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'), src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
const ctx=vm.createContext({});
vm.runInContext(src.slice(src.indexOf('const TF_BRIEF='),src.indexOf('function tfTaskIcon('))+';this.data={TF_BRIEF,TF_TASK_ICON};',ctx);
const starters=['startTfDailyWords','startTfDailyLife','startTfDailyAcad','startTfDailyResp','startTfDailyConvo','startTfDailyAnn','startTfDailyLect','startTfDailySent','startTfDailyEmail','startTfDailyDisc','startTfDailyRetell','startTfDailyInterview'];
// The startup functions only write globals, clear timers and navigate. Execute
// them verbatim using no-op timer cleaners and a captured navigation target.
for(const name of starters){
  const start=src.indexOf(`function ${name}(`);assert(start>=0,name);
  const end=src.indexOf('\n}',start)+2;
  vm.runInContext(src.slice(start,end),ctx);
}
const constants={TFDW_SEC:90,TFDL_SEC:40,TFDA_SEC:40,TFDR_SEC:20,TFDC_SEC:20,TFAN_SEC:20,TFLC_SEC:30,TFW1_TOTAL:10,TFW1_SEC:410,TFW2_SEC:420,TFW3_SEC:600};
const qStart=src.indexOf('const TFW1_QS=');
vm.runInContext(src.slice(qStart,src.indexOf('const TFW1_TOTAL=',qStart))+';this.firstSlots=TFW1_QS[0].parts.filter(x=>x==="_").length;',ctx);
const startup={};
for(const name of starters){
  const c=vm.createContext({...constants});
  for(const cleaner of ['tfDw','tfDl','tfDa','tfDr','tfDc','tfAn','tfLc','tfw1','tfw2','tfRt','tfIv'])c[cleaner+'ClearTimers']=()=>{};
  c.go=x=>c.target=x;c.tfw1Reset=()=>c.tfw1Slots=Array(ctx.firstSlots).fill(null);
  const start=src.indexOf(`function ${name}(`),end=src.indexOf('\n}',start)+2;
  vm.runInContext(src.slice(start,end)+`;${name}();`,c);
  startup[name]=Object.fromEntries(Object.entries(c).filter(([k,v])=>typeof v!=='function'&&!(k in constants)));
}
const output={...ctx.data,startup};
const target=path.join(root,'assets/data/task_brief.json'),text=JSON.stringify(output,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('Verified '+Object.values(output.TF_BRIEF).reduce((n,m)=>n+Object.keys(m).length,0)+' task entries and '+Object.keys(startup).length+' source startup states');
