#!/usr/bin/env node
// 把本地后端库里一位学员（demo.config.json）的真实作答导出成演示数据 demo_data/*.json（题图是 *.png）。
//
// 以 assets/data 里的原型文件为底，只替换各模块映射出来的部分，其余原样保留。Vercel 构建时
// tool/vercel_build.sh 把 demo_data/ 盖到 assets/data/ 上；仓库里的原型数据不动，同事的测试照跑。
// 只读（db.cjs）；号主已同意公开作答（owner 2026-09-30），但姓名、邮箱、手机号和库里的各种 id
// 一律不许出现在输出里，检查不过就不写文件。
//
// 用法：node tool/demo_export/export.cjs   （需要本机 docker 里跑着后端栈的 surgo-postgres）
const fs = require('fs');
const path = require('path');
const { rows, lit } = require('./db.cjs');

const ROOT = path.resolve(__dirname, '../..');
const config = require('./demo.config.json');
// 本目录下除了这几个共用文件，每个 .cjs 是一个模块：exports.build(config) 返回 { 文件名: 替换部分 }。
// 值是 Buffer 的是二进制文件（题图，见 media.cjs），原样写出，不参与合并。
const SHARED = ['export.cjs', 'db.cjs', 'text.cjs', 'media.cjs'];
const MODULES = fs.readdirSync(__dirname)
  .filter((f) => f.endsWith('.cjs') && !SHARED.includes(f))
  .sort()
  .map((f) => require(`./${f}`));

const proto = (file) => JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data', file), 'utf8'));
const isObj = (v) => v && typeof v === 'object' && !Array.isArray(v);
/** 对象逐键合并，数组和标量整体替换。 */
const merge = (base, patch) =>
  isObj(base) && isObj(patch)
    ? Object.fromEntries([...new Set([...Object.keys(base), ...Object.keys(patch)])].map((k) => [k, k in patch ? merge(base[k], patch[k]) : base[k]]))
    : patch;

const files = {};
const binaries = {};
for (const m of MODULES) {
  for (const [file, patch] of Object.entries(m.build(config))) {
    // 文件名是模块里写死的，这里只防着把库里的 id 带进文件名。
    if (!/^[a-z][a-z0-9_]*\.[a-z0-9]+$/.test(file) || file.includes(config.learner)) throw new Error(`${file}: unexpected output file name; nothing written`);
    if (Buffer.isBuffer(patch)) binaries[file] = patch;
    else files[file] = merge(files[file] ?? proto(file), patch);
  }
}

const learner = rows(`select jsonb_build_object('name', display_name, 'email', email, 'phone', phone)
  from users where id::text like ${lit(`${config.learner}%`)}`)[0] || {};
const checks = [
  ['an email address', (t) => /[\w.+-]+@[\w-]+\.[a-z]{2,}/i.test(t)],
  ['a mobile number', (t) => /(?<!\d)1[3-9]\d{9}(?!\d)/.test(t)],
  ['a database id', (t) => /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i.test(t)],
  ["the learner's name, email or phone", (t) => [learner.name, learner.email, learner.phone].some((v) => v && t.includes(v))],
];

const texts = Object.entries(files).map(([file, data]) => [file, `${JSON.stringify(data, null, 1)}\n`]);
for (const [file, text] of texts) {
  const hit = checks.find(([, test]) => test(text));
  if (hit) throw new Error(`${file}: contains ${hit[0]}; nothing written`);
}
const out = path.join(ROOT, 'demo_data');
fs.mkdirSync(out, { recursive: true });
for (const [file, text] of texts) {
  fs.writeFileSync(path.join(out, file), text);
  console.log(`demo_data/${file}: ${text.length} bytes`);
}
// 题图是后端存的原始字节（内容不是文本，上面的检查只查 JSON）。
for (const [file, bytes] of Object.entries(binaries)) {
  fs.writeFileSync(path.join(out, file), bytes);
  console.log(`demo_data/${file}: ${bytes.length} bytes`);
}
