const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),s=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),data={};
for(const [k,prefix,fn] of [['respond','TFDR','tfDr'],['convo','TFDC','tfDc'],['announce','TFAN','tfAn'],['lecture','TFLC','tfLc']]){
 const c=vm.createContext({});let a=s.indexOf(`const ${prefix}_TOTAL=`),b=s.indexOf(`let ${fn}Idx=`,a);vm.runInContext(s.slice(a,b),c);
 a=s.indexOf(`const ${prefix}FB_WEAK=`);b=s.indexOf(`function ${fn}FbView(`,a);const chunk=s.slice(a,b);vm.runInContext(chunk,c);
 const fb=s.slice(b,s.indexOf('\n}',b)+2);
 vm.runInContext(`this.data={total:${prefix}_TOTAL,seconds:${prefix}_SEC,segments:${prefix}_SEGS,weak:${prefix}FB_WEAK,questions:${prefix}FB_QS,source:typeof ${prefix}FB_SRC==='undefined'?[]:${prefix}FB_SRC,lead:typeof ${prefix}_LEAD==='undefined'?'':${prefix}_LEAD};`,c);
 data[k]=c.data;
 data[k].score=/<div class="tffb-score-n">([^<]+)/.exec(fb)[1];
 data[k].description=/<div class="tffb-score-d">([^<]+)/.exec(fb)[1];
 data[k].prefix=fn;
}
const dst=path.join(root,'assets/data/tf_listening_daily.json'),text=JSON.stringify(data,null,2)+'\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);else fs.writeFileSync(dst,text);
console.log(Object.fromEntries(Object.entries(data).map(([k,v])=>[k,{questions:v.total,seconds:v.seconds,feedback:v.questions.length}])));
