// Exports the four fixed "writing legacy" review pages from the ORIGINAL
// surgo-mobile-new/app.js (writingImproveView / writingBandsView /
// writingL1ErrorView / writingL1DetailView) into structured JSON.
//
// These pages are entirely static in the prototype: no user data flows in.
// We run each view function to obtain its exact HTML, then parse the HTML
// into plain data so the Flutter side renders native Widgets (no WebView).
// Source text, fixed examples, numbered highlight spans, tab labels and the
// NEXT/back navigation targets are all preserved verbatim.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const s = fs.readFileSync(path.join(root, '../surgo-mobile-new/app.js'), 'utf8');

function fn(name) {
  const start = s.indexOf(`function ${name}(){`);
  if (start < 0) throw new Error(`missing ${name}`);
  return s.slice(start, s.indexOf('\n}', start) + 2);
}

// wfHeadHtml/go/setWfTab are referenced only inside onclick strings, never
// executed here, so a bare context with the four functions is enough.
const c = vm.createContext({});
for (const n of ['writingImproveView', 'writingBandsView', 'writingL1ErrorView', 'writingL1DetailView']) {
  vm.runInContext(`${fn(n)};this.${n}=${n};`, c);
}

const decode = (t) => t
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&#39;/g, "'").replace(/&quot;/g, '"');
const strip = (html) => decode(html.replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim();

// Tokenise a .wi-body run into ordered segments the Dart side renders inline:
//   {k:'text', v}  plain source text
//   {k:'qn',   v}  circled annotation number (.wi-qn)
//   {k:'hl',   v}  highlighted source span   (.wi-hl)
function segmentBody(body) {
  const segs = [];
  const re = /<span class="wi-qn">(\d+)<\/span>|<span class="wi-hl">([\s\S]*?)<\/span>/g;
  let last = 0, m;
  const pushText = (raw) => {
    const v = decode(raw.replace(/\s+/g, ' '));
    if (v) segs.push({ k: 'text', v });
  };
  while ((m = re.exec(body))) {
    pushText(body.slice(last, m.index));
    if (m[1] !== undefined) segs.push({ k: 'qn', v: m[1] });
    else segs.push({ k: 'hl', v: decode(m[2].replace(/\s+/g, ' ')) });
    last = re.lastIndex;
  }
  pushText(body.slice(last));
  // Trim outer whitespace only.
  if (segs.length && segs[0].k === 'text') segs[0].v = segs[0].v.replace(/^\s+/, '');
  if (segs.length && segs[segs.length - 1].k === 'text') segs[segs.length - 1].v = segs[segs.length - 1].v.replace(/\s+$/, '');
  return segs.filter((x) => x.v !== '');
}

// ---- IMPROVE (ORIGINAL ANNOTATIONS) ----
const improveHtml = c.writingImproveView();
const improveTitle = strip(/<span class="ra-h">([\s\S]*?)<\/span>/.exec(improveHtml)[1]);
const bodies = [...improveHtml.matchAll(/<div class="wi-body">([\s\S]*?)<\/div>/g)].map((m) => segmentBody(m[1]));
const annoRe = /<div class="wi-anno-old"><span class="wi-anno-n">(\d+)<\/span><span>([\s\S]*?)<\/span><\/div>\s*<div class="wi-anno-new">([\s\S]*?)<\/div>\s*<div class="wi-anno-note">([\s\S]*?)<\/div>/g;
const annoBlocks = [...improveHtml.matchAll(annoRe)].map((m) => ({
  n: m[1], old: strip(m[2]), neu: strip(m[3]), note: strip(m[4]),
}));
const improve = { title: improveTitle, bodies, annotations: annoBlocks };

// ---- BANDS (opening paragraph per band + stars) ----
const bandsHtml = c.writingBandsView();
const bandBackTitle = strip(/<span class="wb-ttl">([\s\S]*?)<\/span>/.exec(bandsHtml)[1]);
const bands = [...bandsHtml.matchAll(/<span class="ra-h">([\s\S]*?)<\/span>[\s\S]*?<div class="wb-stars">([\s\S]*?)<\/div>\s*<div class="wb-para">([\s\S]*?)<\/div>/g)].map((m) => ({
  band: strip(m[1]),
  stars: (m[2].match(/<svg/g) || []).length,
  para: strip(m[3]),
}));

// ---- L1 ERROR (stats + overall evaluation) ----
const l1eHtml = c.writingL1ErrorView();
const l1Stats = [...l1eHtml.matchAll(/<div class="le-stat[^"]*">\s*<span class="le-lbl">([\s\S]*?)<\/span>\s*<span class="le-val[^"]*">([\s\S]*?)<\/span>/g)]
  .map((m) => ({ label: strip(m[1]), value: strip(m[2]), danger: /le-err/.test(m[0]) }));
const l1Title = strip(/<span class="ra-h">([\s\S]*?)<\/span>/.exec(l1eHtml)[1]);
const l1Para = strip(/<div class="wb-para"[^>]*>([\s\S]*?)<\/div>/.exec(l1eHtml)[1]);
const l1error = { title: l1Title, stats: l1Stats, para: l1Para };

// ---- L1 DETAIL (category chips + repeated annotation card) ----
const l1dHtml = c.writingL1DetailView();
const detailBack = strip(/<span class="wb-ttl">([\s\S]*?)<\/span>/.exec(l1dHtml)[1]);
const cats = [...l1dHtml.matchAll(/<span class="ld-cat (\w+)">([\s\S]*?)<\/span>/g)].map((m) => ({ kind: m[1], label: strip(m[2]) }));
const cardHtml = /<div class="ra-card">([\s\S]*?)<\/div>\s*<\/div>/.exec(l1dHtml)[1];
const card = {
  old: strip(/<div class="ld-old">([\s\S]*?)<\/div>/.exec(cardHtml)[1]),
  neu: strip(/<div class="ld-new">([\s\S]*?)<\/div>/.exec(cardHtml)[1]),
  note: strip(/<div class="ld-note">([\s\S]*?)<\/div>/.exec(cardHtml)[1]),
  noteBlue: strip(/<div class="ld-note blue">([\s\S]*?)<\/div>/.exec(cardHtml)[1]),
  tags: [...cardHtml.matchAll(/<span class="ld-tag (\w+)">([\s\S]*?)<\/span>/g)].map((m) => ({ kind: m[1], label: strip(m[2]) })),
};
// The prototype renders the identical card twice (`${card}\n${card}`).
const cardCount = (l1dHtml.match(/<div class="ld-old">/g) || []).length;
const l1detail = { back: detailBack, cats, card, cardCount };

const data = { improve, bandBackTitle, bands, l1error, l1detail };
const text = JSON.stringify(data, null, 2) + '\n';
const file = path.join(root, 'assets/data/writing_legacy.json');
if (process.argv.includes('--check')) {
  assert.equal(fs.readFileSync(file, 'utf8'), text);
  console.log('writing_legacy.json is up to date');
} else {
  fs.writeFileSync(file, text);
  console.log('Exact IELTS fixed IMPROVE/BANDS/L1-ERROR/L1-DETAIL pages exported (source markup parsed to native segments)');
}
