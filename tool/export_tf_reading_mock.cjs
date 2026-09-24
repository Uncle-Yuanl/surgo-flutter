const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8');
const c=vm.createContext({});vm.runInContext(src.slice(src.indexOf('const TFRD1_PARAS='),src.indexOf('// ================= TOEFL 写作模考 · 确认页'))+`
this.out={parts:{
1:{paras:TFRD1_PARAS,total:TFRD1_TOTAL,sec:TFRD1_SEC},
2:{qs:TFRD2_QS,total:TFRD2_TOTAL,sec:TFRD2_SEC,ad:TFRD2_AD,title:'Read an advertisement.'},
3:{paras:TFRD3_PARAS,total:TFRD3_TOTAL,sec:TFRD3_SEC},
4:{qs:TFRD4_QS,total:TFRD4_TOTAL,sec:TFRD3_SEC,ad:TFRD4_NOTICE,title:'Read a notice.'}},
feedback:{m1:{types:TFRFB_TYPES_M1,src:TFRFB_SRC,qs:TFRFB_QS,weak:TFRFB_WEAK},m2:{types:TFRFB_TYPES_M2,src:TFRFB_SRC_M2,qs:TFRFB_QS_M2,weak:TFRFB_WEAK_M2}}};`,c);
const text=JSON.stringify(c.out,null,2)+'\n',target=path.join(root,'assets/data/tf_reading_mock.json');
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('TOEFL mock reading exact parts: '+Object.values(c.out.parts).map(p=>p.paras?p.paras.length+' paragraphs':p.qs.length+' questions').join(', '));
