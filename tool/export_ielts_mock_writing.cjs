// Read-only H5 -> lossless Flutter asset for the IELTS writing mock (mockWritingQ).
// mwCfg() in app.js reads qb('writing').daily.task1 / .task2 (examType='ielts'),
// so the answer page shows BOTH Task 1 and Task 2 prompts verbatim from questions.js.
// Node built-ins only; mirrors the other tool/export_*.cjs shape.
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const src=fs.readFileSync(path.join(root,'../surgo-mobile-new/questions.js'),'utf8');
const c=vm.createContext({window:{}});
vm.runInContext(src+'\nthis.QB=QB;',c,{timeout:2000});
const daily=(((c.QB||{}).ielts||{}).writing||{}).daily||{};
assert(daily.task1&&daily.task2,'questions.js must expose ielts.writing.daily.task1 and .task2');
// Keep only the fields mockWritingQView() actually reads: prompt (split on \n\n),
// minWords/minutes (with the same 150/20 & 250/40 fallbacks applied by mwCfg),
// and the Task 1 chart series consumed by writingBarChart().
const pick=(t,fallbackWords,fallbackMinutes)=>({
  prompt:String(t.prompt||''),
  minWords:t.minWords||fallbackWords,
  minutes:t.minutes||fallbackMinutes,
  chartTitle:t.chartTitle||'',
  chartYears:t.chartYears||[],
  chartSeries:(t.chartSeries||[]).map(s=>({name:s.name,color:s.color,data:s.data})),
});
const data={task1:pick(daily.task1,150,20),task2:pick(daily.task2,250,40)};
const text=JSON.stringify(data,null,2)+'\n';
const dst=path.join(root,'assets/data/ielts_mock_writing.json');
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(dst,'utf8'),text);
else fs.writeFileSync(dst,text);
console.log('IELTS writing mock: Task1',data.task1.minWords,'words /',data.task1.minutes,'min +',
  data.task1.chartSeries.length,'series; Task2',data.task2.minWords,'words /',data.task2.minutes,'min');
