// Exports TOEFL listening MOCK question data + fixed feedback from the
// authoritative sibling app.js (surgo-mobile-new). The native Flutter port
// re-uses the exact segments, per-question timings and transition chain; this
// script never invents audio, scores or transcripts — it only lifts the
// literals verbatim so the app can render them without a WebView.
//
// Modules chain (source): tfListenQ -> tfConvQ -> tfAnnQ -> tfTalkQ -> tfModEnd
//   -> tfModLoad -> tfMod2Intro -> tfM2P1Q -> tfM2P2Q -> tfM2P3Q -> tfListenFb
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const src = fs.readFileSync(path.join(root, '../surgo-mobile-new/app.js'), 'utf8');

// Pull a top-level `const NAME=<literal>;` out of app.js by matching brackets
// while skipping string bodies ('...', "...", `...`). Returns the raw literal
// text after the `=` up to (not including) the terminating `;`.
function grab(name) {
  const start = src.indexOf('const ' + name + '=');
  if (start < 0) throw new Error('missing ' + name);
  let i = src.indexOf('=', start) + 1;
  let depth = 0, quote = null;
  const begin = i;
  for (; i < src.length; i++) {
    const ch = src[i];
    if (quote) {
      if (ch === '\\') { i++; continue; }
      if (ch === quote) quote = null;
      continue;
    }
    if (ch === "'" || ch === '"' || ch === '`') { quote = ch; continue; }
    if (ch === '[' || ch === '{' || ch === '(') depth++;
    else if (ch === ']' || ch === '}' || ch === ')') depth--;
    else if (ch === ';' && depth === 0) break;
  }
  return src.slice(begin, i);
}

const ctx = vm.createContext({});
function evalLit(name) { return vm.runInContext('(' + grab(name) + ')', ctx); }

const segsOf = {
  listen: 'TF_SEGS',
  conv: 'TF2_SEGS',
  ann: 'TF3_SEGS',
  talk: 'TF4_SEGS',
  m2p1: 'TFM2_SEGS',
  m2p2: 'TFP2_SEGS',
  m2p3: 'TFP3_SEGS',
};

// Per-module metadata that governs the native controller/UI parameterisation.
// prefix   : source variable prefix (session-key parity)
// style    : 'locked'  -> options visible but greyed & un-pickable while playing
//            'playing' -> body shows only the "正在播放..." animation while playing
// grouped  : consecutive segments sharing `audio` reuse the recording (no replay)
// answerSec: countdown seconds per question (talk / m2p3 = 30, others = 20)
// next     : transition after the module's last segment
const meta = {
  listen: { prefix: 'tf', total: 12, answerSec: 20, style: 'locked', grouped: false, next: 'conv' },
  conv: { prefix: 'tf2', total: 6, answerSec: 20, style: 'playing', grouped: true, next: 'ann' },
  ann: { prefix: 'tf3', total: 6, answerSec: 20, style: 'playing', grouped: true, next: 'talk' },
  talk: { prefix: 'tf4', total: 8, answerSec: 30, style: 'playing', grouped: true, next: 'modEnd' },
  m2p1: { prefix: 'tfM2', total: 3, answerSec: 20, style: 'locked', grouped: false, next: 'm2p2' },
  m2p2: { prefix: 'tfP2', total: 4, answerSec: 20, style: 'playing', grouped: true, next: 'm2p3' },
  m2p3: { prefix: 'tfP3', total: 8, answerSec: 30, style: 'playing', grouped: true, next: 'mark' },
};

const modules = {};
for (const [key, m] of Object.entries(meta)) {
  const segments = evalLit(segsOf[key]);
  assert.ok(Array.isArray(segments) && segments.length > 0, key + ' segments');
  modules[key] = { key, ...m, segments };
}

const feedback = {
  typesM1: evalLit('TFFB_TYPES_M1'),
  typesM2: evalLit('TFFB_TYPES_M2'),
  qs: evalLit('TFFB_QS'),
  transcript: evalLit('TFFB_TRANSCRIPT'),
};

const data = { modules, feedback };
const dst = path.join(root, 'assets/data/tf_listening_mock.json');
const text = JSON.stringify(data, null, 2) + '\n';
if (process.argv.includes('--check')) {
  assert.equal(fs.readFileSync(dst, 'utf8'), text);
  console.log('tf_listening_mock.json up to date');
} else {
  fs.writeFileSync(dst, text);
  console.log(Object.fromEntries(Object.entries(modules).map(
    ([k, v]) => [k, { total: v.total, segs: v.segments.length, answerSec: v.answerSec, style: v.style }])));
  console.log('feedback types m1/m2:', feedback.typesM1.length, feedback.typesM2.length,
    'qs:', Object.keys(feedback.qs).join(','));
}
