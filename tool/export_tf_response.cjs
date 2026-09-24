const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
// Export the TOEFL 日常训练 · 听后选择回应 (tfDailyResp / tfDrFb) content constants
// from the read-only prototype surgo-mobile-new/app.js WITHOUT modifying it.
// We evaluate the exact source constant slices inside a Node vm sandbox — no
// regex JSON parsing — so the data stays byte-for-byte faithful to the source
// object literals (TFDR_SEGS / TFDRFB_WEAK / TFDRFB_QS). TFDR_SEC=20 and
// TFDR_TOTAL=12 come straight from `const TFDR_TOTAL=12, TFDR_SEC=20;` at
// app.js:12674 (the 20-second per-question answer limit).
const root=path.resolve(__dirname,'..'), src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
const ctx=vm.createContext({});

// Slice 1: `const TFDR_TOTAL=12, TFDR_SEC=20;` + `const TFDR_SEGS=[...]`,
// stopping right before `function tfDrCur(`. Captures TFDR_TOTAL, TFDR_SEC and
// the 12 listening-response segments (sec / q / opts) verbatim.
const s1=src.indexOf('const TFDR_TOTAL='), e1=src.indexOf('function tfDrCur(');
assert(s1>=0&&e1>s1,'TFDR_TOTAL..TFDR_SEGS slice');
vm.runInContext(src.slice(s1,e1),ctx);

// Slice 2: `const TFDRFB_WEAK=[...]` through `const TFDRFB_QS=[...]`, stopping
// before `function tfDrFbAudio(`. Captures the fixture feedback verbatim.
const s2=src.indexOf('const TFDRFB_WEAK='), e2=src.indexOf('function tfDrFbAudio(');
assert(s2>=0&&e2>s2,'TFDRFB_* slice');
vm.runInContext(src.slice(s2,e2),ctx);

vm.runInContext('this.data={TFDR_SEGS,TFDR_SEC,TFDR_TOTAL,TFDRFB_WEAK,TFDRFB_QS};',ctx);
const output=ctx.data;
assert.equal(output.TFDR_SEC,20,'per-question answer limit is exactly 20 seconds');
assert.equal(output.TFDR_TOTAL,12,'total question count is 12');
assert.equal(output.TFDR_TOTAL,output.TFDR_SEGS.length,'total matches segment count');

const target=path.join(root,'assets/data/tf_response.json'),text=JSON.stringify(output,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('Verified '+output.TFDR_SEGS.length+' segments ('+output.TFDR_SEC+'s answer limit each), '+output.TFDRFB_QS.length+' feedback cards, '+output.TFDRFB_WEAK.length+' weak items');
