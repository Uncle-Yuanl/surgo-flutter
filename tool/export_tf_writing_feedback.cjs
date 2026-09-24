const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),c=vm.createContext({});
vm.runInContext(s.slice(s.indexOf('const TFWFB_TYPES='),s.indexOf('function tfwFbPickType('))+s.slice(s.indexOf('const TFSENT_FB='),s.indexOf('function tfSentFbView('))+';this.data={TFWFB_TYPES,TFWFB_QS,TFWFB_WEAK,TFSENT_FB};',c);
for(const name of ['tfEmailFbView','tfDiscFbView']){
 const start=s.indexOf(`function ${name}(){`),end=s.indexOf('\n}',start);
 const body=s.slice(start,end);
 const grab=(decl,until)=>body.slice(body.indexOf('  const '+decl+'='),body.indexOf('  const '+until+'='));
 const literal=grab('seg','segHtml')+grab('notes','notesHtml')+grab('subs','subsHtml');
 const x=vm.runInNewContext(`(()=>{${literal};return {seg,notes,subs};})()`);
 x.task=/<div class="twfb-task-b">([^<]+)/.exec(body)[1];
 x.q=/<span class="twfb-q">([^<]+)/.exec(body)[1];
 x.fb=/<div class="twfb-fb-b">([^<]+)/.exec(body)[1];
 x.weak=/<div class="tffb-wa">([^<]+)/.exec(body)[1];
 c.data[name]=x;
}
const text=JSON.stringify(c.data,null,2)+'\n',dst=path.join(root,'assets/data/tf_writing_feedback.json');if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log('Source writing feedback fixtures exported without grading changes');
