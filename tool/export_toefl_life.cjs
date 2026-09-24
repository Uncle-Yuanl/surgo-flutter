const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
// Export the TOEFL 日常训练 · 生活阅读 (tfDailyLife / tfDlFb) content constants
// from the read-only prototype surgo-mobile-new/app.js WITHOUT modifying it.
// We evaluate the exact source constant slices inside a Node vm sandbox — no
// regex JSON parsing — so the data stays byte-for-byte faithful to the source
// object literals (TFDL_AD / TFDL_POST / TFDL_QS / TFDLFB_WEAK / TFDLFB_SRC /
// TFDLFB_QS). TFDL_SEC=40 and TFDL_TOTAL=TFDL_QS.length come straight from
// `const TFDL_TOTAL=TFDL_QS.length, TFDL_SEC=40;` at app.js:9906.
const root=path.resolve(__dirname,'..'), src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
const ctx=vm.createContext({});

// Slice 1: `const TFDL_AD=[...]` through `const TFDL_QS=[...]`, stopping right
// before `const TFDL_TOTAL=...`. Captures TFDL_AD, TFDL_POST, TFDL_QS verbatim.
const s1=src.indexOf('const TFDL_AD='), e1=src.indexOf('const TFDL_TOTAL=');
assert(s1>=0&&e1>s1,'TFDL_AD..TFDL_QS slice');
vm.runInContext(src.slice(s1,e1),ctx);

// The totals/seconds declaration itself (single line).
const s0=src.indexOf('const TFDL_TOTAL='), e0=src.indexOf('\n',s0)+1;
assert(s0>=0&&e0>s0,'TFDL_TOTAL/TFDL_SEC slice');
vm.runInContext(src.slice(s0,e0),ctx);

// Slice 2: `const TFDLFB_WEAK=[...]` through `const TFDLFB_QS=[...]`, stopping
// before `function tfDlFbView(`. Captures the fixture feedback verbatim.
const s2=src.indexOf('const TFDLFB_WEAK='), e2=src.indexOf('function tfDlFbView(');
assert(s2>=0&&e2>s2,'TFDLFB_* slice');
vm.runInContext(src.slice(s2,e2),ctx);

vm.runInContext('this.data={TFDL_AD,TFDL_POST,TFDL_QS,TFDL_SEC,TFDL_TOTAL,TFDLFB_WEAK,TFDLFB_SRC,TFDLFB_QS};',ctx);
const output=ctx.data;
assert.equal(output.TFDL_SEC,40,'per-question limit is exactly 40 seconds');
assert.equal(output.TFDL_TOTAL,output.TFDL_QS.length,'total matches question count');

const target=path.join(root,'assets/data/toefl_life.json'),text=JSON.stringify(output,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('Verified '+output.TFDL_QS.length+' questions ('+output.TFDL_SEC+'s each), '+output.TFDLFB_QS.length+' feedback cards, '+output.TFDLFB_WEAK.length+' weak items');
