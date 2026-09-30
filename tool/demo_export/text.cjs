// 演示数据共用的小工具：分数格式、中英成对、在作文里标批注。

/** 8 → "8.0"，7.5 → "7.5"。 */
const band = (x) => Number(x).toFixed(1);

/** 雅思四舍五入到半分：7.25 → 7.5，7.75 → 8.0。 */
const halfBand = (x) => band(Math.round(Number(x) * 2) / 2);

/**
 * [英文, 中文] 一对，页面的 T 按界面语言取。缺中文时两边都放原文：
 * owner 2026-09-30 定了只有英文的结果保持原文，不做机翻。
 */
const pair = (en, zh) => [en || zh || '', zh || en || ''];

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** 作文里找一段原文：连字符 / 破折号、直引号 / 弯引号、空白都放宽匹配。 */
function locate(text, span) {
  const pattern = escapeRe(span.trim())
    .replace(/[-–—]/g, '[-–—]')
    .replace(/['’‘]/g, "['’‘]")
    .replace(/["“”]/g, '["“”]')
    .replace(/\s+/g, '\\s+');
  const m = new RegExp(pattern).exec(text);
  return m ? { start: m.index, end: m.index + m[0].length } : null;
}

/**
 * 按页面认的格式标批注：<span class="wf-hl">原文<sup>n</sup></span>（L1 用 wf-hl-p）。
 * 找不到或与已标的片段重叠的跳过；返回标好的正文和实际标上的条目（n 从 1 连续编号）。
 */
function annotate(text, items, spanOf, cls) {
  const hits = [];
  for (const item of items) {
    const at = locate(text, spanOf(item));
    if (at && !hits.some((h) => at.start < h.end && h.start < at.end)) hits.push({ ...at, item });
  }
  hits.sort((a, b) => a.start - b.start);
  let out = '';
  let pos = 0;
  hits.forEach((h, i) => {
    out += text.slice(pos, h.start) + `<span class="${cls}">${text.slice(h.start, h.end)}<sup>${i + 1}</sup></span>`;
    pos = h.end;
  });
  return { text: out + text.slice(pos), items: hits.map((h, i) => ({ n: i + 1, item: h.item })) };
}

module.exports = { band, halfBand, pair, annotate };
