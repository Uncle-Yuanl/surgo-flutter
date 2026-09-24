const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
const a=src.indexOf('const RTYPES=['), b=src.indexOf('\n];',a)+3;assert(a>=0&&b>a);
const ctx=vm.createContext({});vm.runInContext(src.slice(a,b)+';this.types=RTYPES',ctx);
// Default single-type passage is inline in V.typeSession, not the QB passage.
const artStart=src.indexOf("const art=t.article||{");
const artEnd=src.indexOf('\n        ]};',artStart)+12;
assert(artStart>=0&&artEnd>artStart);
vm.runInContext('const t={};'+src.slice(artStart,artEnd)+';this.fallback=art;',ctx);
const obj={types:ctx.types,fallbackArticle:ctx.fallback};
const dst=path.join(root,'assets/data/ielts_reading.json'),text=JSON.stringify(obj,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log('RTYPES:',ctx.types.length,'; fallback:',ctx.fallback.title);
