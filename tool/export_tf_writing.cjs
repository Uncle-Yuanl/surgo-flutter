const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),c=vm.createContext({});
for(const [a,b] of [['const TFW1_QS=','let tfw1Idx='],['const TFW2=','let tfw2Subj='],['const TFW3=','let tfw3Body=']])vm.runInContext(s.slice(s.indexOf(a),s.indexOf(b)),c);
vm.runInContext('this.data={TFW1_QS,TFW1_SEC,TFW1_TOTAL,TFW2,TFW2_SEC,TFW3,TFW3_SEC};',c);
const text=JSON.stringify(c.data,null,2)+'\n',dst=path.join(root,'assets/data/tf_writing.json');if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log('Verified exact sentence/email/discussion data with times',c.data.TFW1_SEC,c.data.TFW2_SEC,c.data.TFW3_SEC);
