// 只读查询本机后端栈的 Postgres（docker 容器 surgo-postgres）。
// 每次都包在 BEGIN READ ONLY 里：导出只读已经存好的结果，不写库、不触发任何生成。
const { execFileSync } = require('child_process');

/** 执行一条 SQL，每行结果是一个 JSON 值（用 to_jsonb / jsonb_build_object 拼好）。 */
function rows(sql) {
  const out = execFileSync(
    'docker',
    ['exec', '-i', 'surgo-postgres', 'psql', '-U', 'surgo', '-d', 'surgo', '-v', 'ON_ERROR_STOP=1', '-At'],
    { input: `begin read only;\n${sql};\ncommit;\n`, encoding: 'utf8', maxBuffer: 256 << 20 },
  );
  return out.split('\n').filter((l) => l && l !== 'BEGIN' && l !== 'COMMIT').map((l) => JSON.parse(l));
}

/** 只要一行；没有就报错（配置里的 id 写错时早点失败）。 */
function one(sql, what) {
  const r = rows(sql);
  if (r.length !== 1) throw new Error(`${what}: expected 1 row, got ${r.length}`);
  return r[0];
}

/** SQL 字符串字面量（配置里的 id 只可能是 uuid，这里仍按字面量转义）。 */
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;

module.exports = { rows, one, lit };
