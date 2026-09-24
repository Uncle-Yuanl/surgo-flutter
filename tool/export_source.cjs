// Read-only H5 -> lossless Flutter assets + JS oracle. Node built-ins only.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const source = path.resolve(process.argv.find(x => x.startsWith('--source='))?.slice(9) || path.join(root, '../surgo-mobile-new'));
const check = process.argv.includes('--check');
const read = f => fs.readFileSync(path.join(source, f), 'utf8');
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const context = vm.createContext({window: {}, NodeFilter: {SHOW_TEXT: 4}});
vm.runInContext(read('i18n.js'), context, {timeout: 2000});
vm.runInContext(read('questions.js') + '\nthis.bank = QB;', context, {timeout: 2000});
const tables = context.window;
const data = {};
for (const name of ['SURGO_EN', 'SURGO_EN_RE', 'SURGO_ZH', 'SURGO_ZH_RE']) {
  data[name] = name.endsWith('_RE') ? tables[name].map(([re, replace]) => [re.source, replace, re.flags]) : tables[name];
}
// Execute the original trStr/applyLang implementations, with only a tiny text-node DOM adapter.
const app = read('app.js');
const end = app.indexOf('// ===== 首页设置弹窗');
assert(end > 0, 'Cannot locate original translation block');
vm.runInContext(app.slice(0, end), context, {timeout: 2000});
function translate(input, lang) {
  const node = {nodeValue: input, parentElement: {closest: () => null}};
  let visited = false;
  context.document = {createTreeWalker: () => ({nextNode: () => visited ? null : (visited = true, node)})};
  context.scope = {querySelectorAll: () => []};
  context.input = input;
  vm.runInContext(`uiLang=${JSON.stringify(lang)}; applyLang(scope);`, context);
  return node.nodeValue;
}
const fixtures = [];
for (const name of ['SURGO_EN', 'SURGO_ZH']) {
  const lang = name === 'SURGO_EN' ? 'en' : 'zh';
  for (const key of Object.keys(tables[name])) {
    for (const input of [key, `  ${key}  `]) fixtures.push({lang, input, expected: translate(input, lang)});
  }
}
// These source expressions are simple anchored templates. Generate a matching seed,
// assert it against the actual RegExp, and retain direct replacements plus applyLang
// results (some whitespace-anchored rules intentionally cannot match after trim()).
function sample(pattern) {
  return pattern.replace(/^\^/, '').replace(/\$$/, '')
    .replace(/\(\\d\+\)/g, '12').replace(/\(\\d\)/g, '3')
    .replace(/\(\\d\+\\\.\\d\+\)/g, '12.5')
    .replace(/\(\.\+\)/g, '示例 Example')
    .replace(/\[–-\]/g, '–')
    .replace(/\\([/().])/g, '$1');
}
const regex = [];
for (const name of ['SURGO_EN_RE', 'SURGO_ZH_RE']) {
  const lang = name === 'SURGO_EN_RE' ? 'en' : 'zh';
  tables[name].forEach(([re, replacement], index) => {
    const input = sample(re.source);
    assert(re.test(input), `${name}[${index}] sample failed: ${re.source} => ${input}`);
    re.lastIndex = 0;
    regex.push({table: name, index, pattern: re.source, flags: re.flags, replacement, input, expected: input.replace(re, replacement)});
    fixtures.push({lang, input, expected: translate(input, lang)});
  });
}
const additional = [
  ['(a)(b)', '', '$2/$1/$$/$&/$`/$\'', 'xxabyy'],
  ['(x)?(a)', 'g', '$1-$2-$12-$99-$0', 'aaa'],
  ['a', 'gi', 'b', 'AaA'],
  ['^a', 'm', '$&!', 'x\na'],
  ['a.b', 's', '$&!', 'a\nb'],
  ['(?<word>a)', '', '$<word> $<absent>', 'a'],
  ['(?<word>a)?b', '', '$<word>', 'b'],
  ['(a)', '', '$01 $10 $00', 'a']
];
for (const [pattern, flags, replacement, input] of additional) regex.push({pattern, flags, replacement, input, expected: input.replace(new RegExp(pattern, flags), replacement)});
fixtures.push(...['', '  ', 'English passage not in table', '未匹配的中文', '20天', '1 万', '你即将进入模块 2。请继续。'].flatMap(input => ['en', 'zh'].map(lang => ({lang, input, expected: translate(input, lang)}))));
function walk(dir, prefix = '') {
  return fs.readdirSync(dir, {withFileTypes:true}).flatMap(e => {
    const rel = path.posix.join(prefix, e.name);
    return e.isDirectory() ? walk(path.join(dir,e.name), rel) : [{path:rel, sha256:hash(fs.readFileSync(path.join(dir,e.name)))}];
  }).sort((a,b) => a.path.localeCompare(b.path));
}
const manifest = {
  formatVersion: 1,
  sourceFiles: Object.fromEntries(['app.js','index.html','questions.js','i18n.js'].map(f => [f, hash(fs.readFileSync(path.join(source,f)))])),
  assets: walk(path.join(source, 'assets')),
  tables: Object.fromEntries(Object.entries(data).map(([k,v]) => [k, Object.keys(v).length])),
  dictionaryCases: fixtures.length,
  regexCases: regex.length,
  questionSha256: hash(JSON.stringify(context.bank)),
  note: 'This verifies exported data, NOT native page/logic equivalence.'
};
const outputs = {
  'assets/data/questions.json': context.bank,
  'assets/data/i18n.json': data,
  'assets/data/source_manifest.json': manifest,
  'test/fixtures/translation_oracle.json': {cases: fixtures, regex}
};
for (const [file, obj] of Object.entries(outputs)) {
  const target = path.join(root, file);
  const text = JSON.stringify(obj, null, 2) + '\n';
  if (check) assert.equal(fs.readFileSync(target,'utf8'), text, `${file} differs from original runtime data`);
  else { fs.mkdirSync(path.dirname(target), {recursive:true}); fs.writeFileSync(target, text); }
}
console.log(JSON.stringify({check, tables: manifest.tables, cases: fixtures.length, regex: regex.length, sourceFiles: manifest.sourceFiles}, null, 2));
