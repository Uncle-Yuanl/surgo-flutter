const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),src=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),q=fs.readFileSync(path.join(root,'../surgo-mobile-new/questions.js'),'utf8');
const c=vm.createContext({});vm.runInContext(q+'\nfunction qb(k){return QB.ielts[k]||{}}\n'+src.slice(src.indexOf('const MRQ_P2 ='),src.indexOf('// 阅读模考答题页：左文章'))+'\nthis.data=[mrCfg(1),mrCfg(2),mrCfg(3)];',c);
const text=JSON.stringify(c.data,null,2)+'\n',target=path.join(root,'assets/data/ielts_mock_reading.json');
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(target,'utf8'),text);else fs.writeFileSync(target,text);
console.log('IELTS mock reading exact passages/questions: '+c.data.map(p=>p.qs.length).join('/'));
