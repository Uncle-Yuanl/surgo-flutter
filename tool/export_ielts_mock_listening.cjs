// Exports EXACT IELTS mock-listening data from surgo-mobile-new/app.js
// Source funcs: mockListeningQView / mockListeningQ2View / mockListeningQ3View
//               / mockListeningQ4View, plus lisMapSvg() and the render timers
//               startMockTimer(reset) [30:00 shared, reset only on Part 1] and
//               submitMockPart4()/mq4Timer [118s review before auto-mark].
// Node vm is used to evaluate the literal question/option/table arrays that live
// inside those view functions so the payload stays byte-for-byte faithful.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const src = fs.readFileSync(path.join(root, '../surgo-mobile-new/app.js'), 'utf8');

// Pull a `const NAME=[ ... ]` array literal that appears after `from`, using a
// bracket-depth scan so nested option arrays are captured intact.
function arr(name, from) {
  const marker = `const ${name}=`;
  const i = src.indexOf(marker, from);
  if (i < 0) throw new Error(`array ${name} not found after ${from}`);
  const open = src.indexOf('[', i);
  let depth = 0, end = -1;
  for (let k = open; k < src.length; k++) {
    const ch = src[k];
    if (ch === '[') depth++;
    else if (ch === ']') { depth--; if (depth === 0) { end = k; break; } }
  }
  const literal = src.slice(open, end + 1);
  return vm.runInNewContext(`(${literal})`);
}

const q1 = src.indexOf('function mockListeningQView(){');
const q2 = src.indexOf('function mockListeningQ2View(){');
const q3 = src.indexOf('function mockListeningQ3View(){');
const q4 = src.indexOf('function mockListeningQ4View(){');

// lisMapSvg() — the shared A-G station map rendered in Part 2.
const mapStart = src.indexOf('function lisMapSvg(){');
const mapReturn = src.indexOf('return `', mapStart) + 'return `'.length;
const mapEnd = src.indexOf('`;', mapReturn);
const mapSvg = src.slice(mapReturn, mapEnd).trim();

// Part 1 — 6 single-choice (A/B/C) + 4 short-answer fills.
const p1qs = arr('qs', q1);
const p1fill = arr('fillQs', q1);

// Part 2 — MISSING PERSON table (11-16) + map labels (17-20).
const p2table = arr('table', q2);
const p2map = arr('mapRows', q2);

// Part 3 — matching box + matching Qs (21-25) + MC Qs (26-30).
const p3box = arr('box', q3);
const p3match = arr('matchQs', q3);
const p3mc = arr('mcQs', q3);

// Part 4 — SURVEY METHODS notes (31-36) + sentence completion (37-40).
const p4notes = arr('notes', q4);
const p4sents = arr('sents', q4);

const data = {
  // Shared 30:00 exam clock (startMockTimer): reset ONLY on entering Part 1,
  // continues running across Parts 2-4. Value in seconds.
  sharedTimerSec: 30 * 60,
  // submitMockPart4(): 01:58 review window before auto openMarkSheet.
  reviewSec: 118,
  markLabelTemplate: '正在批改任务 {n} / 4, Part {n}',
  mapSvg,
  parts: [
    {
      no: 1,
      audioTitle: '第 1 部分播放中',
      audioBarPct: 0,
      audioTime: '00:00/07:00',
      tip: '你有约 20 秒查看题目。 (18s)',
      dotFrom: 1,
      next: 'mockListeningQ2',
      groups: [
        { label: 'Questions 1-6', sub: 'Choose the correct answer, A, B or C.' },
        { label: 'Questions 7-10', sub: 'Answer the questions below. Write NO MORE THAN THREE WORDS AND/OR A NUMBER for each answer.' },
      ],
      mc: p1qs.map((q) => ({ n: q[0], q: q[1], opts: q[2] })),
      fills: p1fill.map((q) => ({ n: q[0], q: q[1] })),
    },
    {
      no: 2,
      audioTitle: '第 2 部分播放中',
      audioBarPct: 17,
      audioTime: '01:12/07:00',
      dotFrom: 11,
      next: 'mockListeningQ3',
      groups: [
        { label: 'Questions 11-16', sub: 'Complete the table below. Write NO MORE THAN TWO WORDS AND/OR A NUMBER for each answer.' },
        { label: 'Questions 17-20', sub: 'Label the map below. Write the correct letter, A-G, next to Questions 17-20.' },
      ],
      tableTitle: 'MISSING PERSON DESCRIPTION',
      table: p2table.map((r) => ({ key: r[0], val: r[1], n: r[2] || 0 })),
      mapQs: p2map.map((r) => ({ n: r[0], label: r[1] })),
    },
    {
      no: 3,
      audioTitle: '第 3 部分播放中',
      audioBarPct: 5,
      audioTime: '00:19/07:00',
      dotFrom: 21,
      next: 'mockListeningQ4',
      groups: [
        { label: 'Questions 21-25', sub: 'What comment does each student make about the topics? Choose your answers from the box and write the correct letter, A-F, next to Questions 21-25.' },
        { label: 'Questions 26-30', sub: 'Choose the correct answer, A, B or C.' },
      ],
      matchBox: p3box,
      matchLetters: ['A', 'B', 'C', 'D', 'E', 'F'],
      match: p3match.map((q) => ({ n: q[0], q: q[1] })),
      mc: p3mc.map((q) => ({ n: q[0], q: q[1], opts: q[2] })),
    },
    {
      no: 4,
      audioTitle: '第 4 部分播放中',
      audioBarPct: 0,
      audioTime: '00:00/07:00',
      tip: '你有约 20 秒查看题目。 (15s)',
      dotFrom: 31,
      next: null, // submit -> review countdown -> feedback
      groups: [
        { label: 'Questions 31-36', sub: 'Complete the notes below. Write NO MORE THAN TWO WORDS AND/OR A NUMBER for each answer.' },
        { label: 'Questions 37-40', sub: 'Complete the sentences below. Write NO MORE THAN TWO WORDS AND/OR A NUMBER for each answer.' },
      ],
      notesTitle: 'SURVEY METHODS',
      notes: p4notes.map((q) => ({ n: q[0], head: q[1], tail: (q[2] || '').trim() })),
      sents: p4sents.map((q) => ({ n: q[0], head: q[1], tail: (q[2] || '').trim() })),
    },
  ],
};

const dest = path.join(root, 'assets/data/ielts_mock_listening.json');
const text = JSON.stringify(data, null, 2) + '\n';
if (process.argv.includes('--check')) {
  assert.equal(fs.readFileSync(dest, 'utf8'), text);
  console.log('ielts_mock_listening.json is up to date');
} else {
  fs.writeFileSync(dest, text);
  console.log('Exported exact 4 parts (40 Qs), map svg, audio state, shared 30:00 + 118s review');
}
