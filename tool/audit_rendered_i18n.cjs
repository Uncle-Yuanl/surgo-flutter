const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'..'),source=fs.readFileSync(path.join(root,'../surgo-mobile-new/app.js'),'utf8'),dict=fs.readFileSync(path.join(root,'../surgo-mobile-new/i18n.js'),'utf8');
const ctx=vm.createContext({});ctx.window=ctx;vm.runInContext(dict,ctx);
const data=JSON.parse(fs.readFileSync(path.join(root,'build/audit/bilingual_routes.json'),'utf8'));const missed=[];
for(const r of data.routes){for(const text of r.text){ctx.text=text;ctx.lang=r.lang;const expected=vm.runInContext(`(()=>{const m=lang==='en'?SURGO_EN:SURGO_ZH,rs=lang==='en'?SURGO_EN_RE:SURGO_ZH_RE;const t=text.trim();if(m[t]!==undefined)return m[t];for(const [p,v] of rs)if(p.test(t))return t.replace(p,v);return text;})()`,ctx);if(expected!==text)missed.push({route:r.key,lang:r.lang,text,expected});}}
fs.writeFileSync(path.join(root,'build/audit/rendered_i18n_candidates.json'),JSON.stringify({note:'Candidates only: compare actual source text node segmentation and intentional content before replacing.',items:missed},null,2));
console.log('Candidate rendered text differences: '+missed.length);console.log(JSON.stringify(missed.slice(0,30),null,2));
