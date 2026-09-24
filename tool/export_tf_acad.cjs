const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),c=vm.createContext({});
const a=src.indexOf('const TFDA_TITLE='),b=src.indexOf('let tfDaIdx=',a);
const d=src.indexOf('const TFDAFB_WEAK='),e=src.indexOf('function tfDaFbView(',d);
vm.runInContext(src.slice(a,b)+src.slice(d,e)+';this.data={TFDA_TITLE,TFDA_PARAS,TFDA_TITLE2,TFDA_PARAS2,TFDA_QS,TFDA_SEC,TFDA_TOTAL,TFDAFB_WEAK,TFDAFB_SRC,TFDAFB_QS}',c);
const file=path.join(root,'assets/data/tf_acad.json'),text=JSON.stringify(c.data,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(file,'utf8'),text);else fs.writeFileSync(file,text);
console.log('Exact source academic data:',c.data.TFDA_QS.length,'questions',c.data.TFDA_SEC,'seconds');
