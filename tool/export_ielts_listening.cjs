const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),c=vm.createContext({});
let a=s.indexOf('const LPARTS='),b=s.indexOf("let lisPart=",a);vm.runInContext(s.slice(a,b)+';this.parts=LPARTS;',c);
a=s.indexOf('function lisMapSvg()');b=s.indexOf('function lisMapBlock',a);vm.runInContext(s.slice(a,b)+';this.map=lisMapSvg();',c);
const feedback={};for(let n=1;n<=4;n++){
 a=s.indexOf(`function lfBody${n}(){`);b=s.indexOf('  const '+(n<=2?'tHtml':'qcards')+'=',a);
 const prefix=s.slice(a+`function lfBody${n}(){`.length,b);
 feedback[n]=vm.runInNewContext(`(()=>{${prefix};return {qs,${n<=2?'transcript':'tHtml'}};})()`);
}
const data={parts:c.parts,mapSvg:c.map,feedback,audioDuration:225};
const dest=path.join(root,'assets/data/ielts_listening.json'),text=JSON.stringify(data,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dest,'utf8'),text);else fs.writeFileSync(dest,text);
console.log('Exported exact4parts, map, all feedback data; simulated225s audio');
