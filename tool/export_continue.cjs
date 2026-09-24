const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
// Home「继续学习」弹窗的 5 条固定项：app.js CONTINUE_ITEMS（12224-12230）。
// 逐字导出 tab/ic/kicker/name/pct/go，不改文案、不改顺序。
const a=src.indexOf('const CONTINUE_ITEMS=['), b=src.indexOf('\n];',a)+3;assert(a>=0&&b>a);
const ctx=vm.createContext({});vm.runInContext(src.slice(a,b)+';this.items=CONTINUE_ITEMS',ctx);
const items=ctx.items;
assert.equal(items.length,5,'CONTINUE_ITEMS 应为 5 条');
for(const it of items){assert(['daily','mock'].includes(it.tab));assert.equal(typeof it.ic,'string');assert.equal(typeof it.kicker,'string');assert.equal(typeof it.name,'string');assert.equal(typeof it.pct,'number');assert.equal(typeof it.go,'string');}
const obj={items};
const dst=path.join(root,'assets/data/continue.json'),text=JSON.stringify(obj,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log('CONTINUE_ITEMS:',items.length,'; go:',items.map(i=>i.go).join(','));
