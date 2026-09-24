// Static source guards ONLY. This does not execute H5 JavaScript or generate
// a dynamic oracle. The filename remains for verify_handover.py discovery.
// --check validates the source statements supporting the Flutter regression.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const src = fs.readFileSync(path.join(root, '../surgo-mobile-new/app.js'), 'utf8');
function section(start, end) {
  const a = src.indexOf(start), b = src.indexOf(end, a + start.length);
  assert(a >= 0 && b > a, start);
  return src.slice(a, b);
}
const start = section('function startMockTimer(reset){', '// 超时提醒弹窗');
assert(start.includes('if(reset) mockLeft=30*60;'));
assert(src.includes("startMockTimer(id==='mockListeningQ')"));
const views = section('function mockListeningQView(){', 'function openEndExamSheet(){');
assert.equal((views.match(/<span class="mq-part-s">0 of 10<\/span>/g) || []).length, 12);
assert(views.includes('onclick="submitMockPart4()"'));
const submit = section('function submitMockPart4(){', 'function pickMockMatch(');
assert(submit.includes('let left=118;'));
assert(submit.includes('if(mq4Timer) clearInterval(mq4Timer);'));
assert(submit.includes('if(left<0)'));
const answer = section('function pickMockMatch(', '// 词汇学习 · 今日复习完成庆祝页');
assert(answer.includes('el.classList.add(\'sel\')'));
assert(answer.includes('el.value.trim().length>0'));
assert(!/mockAns|mockDone/.test(answer));
assert(src.includes('onclick="openExitExamSheet()"'));
const exit = section('function exitExamNow(){', 'function openMockSheet(){');
assert(exit.includes('clearInterval(mockTimer)'));
assert(exit.includes('clearInterval(mq4Timer)'));
assert(exit.includes("go('ielts')"));
console.log('Static H5 guards PASS: render reset, 12 literal inactive counts, DOM-only answers, repeated review submit, exit timer cleanup. No dynamic JS execution.');
