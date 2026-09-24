// Only evaluate the isolated source literal, never the browser application.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const src = fs.readFileSync(path.resolve(root, '../surgo-mobile-new/app.js'), 'utf8');
const start = src.indexOf('const RF_DEMO = ');
const end = src.indexOf('\n};', start) + 3;
if (start < 0 || end < start) throw new Error('RF_DEMO literal boundary missing');
const literal = src.slice(start + 'const RF_DEMO = '.length, end).replace(/;$/, '');
const data = vm.runInNewContext('(' + literal + ')', Object.create(null), {timeout: 1000});
const out = JSON.stringify({source: 'app.js RF_DEMO',
  literalSha256: crypto.createHash('sha256').update(literal).digest('hex'), passages: data}, null, 2) + '\n';
const target = path.join(root, 'assets/data/reading_feedback_mock.json');
if (process.argv.includes('--check')) {
  if (!fs.existsSync(target) || fs.readFileSync(target, 'utf8') !== out) throw new Error('Export differs');
} else { fs.writeFileSync(target, out); }
const qs = Object.values(data).flatMap(p => p.qs);
const right = qs.filter(q => q.mine.trim().toUpperCase() === q.correct.trim().toUpperCase()).length;
console.log(`RF_DEMO ${Object.keys(data).length} passages, ${right}/${qs.length} correct; fixed score6.5`);
