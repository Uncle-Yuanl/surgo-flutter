// 雅思听力：日常四个 Part（做题页 + 回顾）、模考四个 Part（考试页 + 回顾）。
// 数据全部来自后端已存的结果：ielts_attempts + ielts_generated_items（旧版日常）、
// ielts_listening_daily_sessions（现行日常：题目、判分、原文、解析、分析）、
// ielts_mock_exam_*（模考的题目、答案键、原文、作答、成绩）。音频在原型里是模拟的，不导；
// 图示标注题的图（ielts_listening_daily_media 记的 PNG，存在后端的文件存储里）原样导出。
const fs = require('fs');
const path = require('path');
const { one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');
const { stored, figure } = require('./media.cjs');

// 日常练习每个 Part 是各自的一次作答。
const DAILY = {
  1: { attempt: '1f1435e6-724b-4d1b-ac60-729ccaddb7f4' }, // ielts_attempts：酒店订房表格填空，10 题对 5
  2: { session: 'b664a7d2-b2f8-438b-be79-56986ab9e87b' }, // ielts_listening_daily_sessions：笔记填空 + 图示标注
  3: { session: '83753ac0-49a2-4311-ae5d-deb754d8b587' }, // 选择 + 配对
  4: { session: '43294b62-16bd-4830-af2c-220f10d8126a' }, // 摘要填空
};
// 模考（ielts_mock_exam_sessions.id）：四个 Part 40 题；学员没作答就到时交卷了（0 题对）。
const MOCK = '8c537028-34d6-4453-ac63-44614e86741e';

// 题型名（[英文, 中文]）和做题页说明模板用的原型题型键。
const NAMES = {
  form: { name: ['Form completion', '表格填空'], main: 'form' },
  note: { name: ['Note completion', '笔记填空'], main: 'note' },
  summary: { name: ['Summary completion', '摘要填空'], main: 'note' },
  completion: { name: ['Completion', '填空题'], main: 'note' },
  multiple_choice: { name: ['Multiple choice', '选择题'], main: 'mc' },
  matching: { name: ['Matching', '配对题'], main: 'matching' },
  visual_labelling: { name: ['Diagram labelling', '图示标注'], main: 'matching' },
};
const BLANK = '—'; // 没作答

const proto = (file) => JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../assets/data', file), 'utf8'));
/** 整块替换原型的一个对象：导出时对象是逐键合并的，原型有而这里没给的键要显式清掉。 */
const replace = (base, real) => ({ ...Object.fromEntries(Object.keys(base).map((k) => [k, null])), ...real });
const norm = (s) => String(s ?? '').trim().replace(/\s+/g, ' ').toLowerCase();
const label = (from, to) => (from === to ? `Question ${from}` : `Questions ${from}-${to}`);
const named = (type) => {
  if (!NAMES[type]) throw new Error(`listening: no name for question type ${type}`);
  return NAMES[type];
};
const tag = (types) => [0, 1].map((k) => `🏷 ${[...new Set(types)].map((t) => named(t).name[k]).join(' · ')}`);
const show = (o) => `${o.id}. ${o.text}`;

// ---------- 读库，整理成同一种结构 ----------
// part: { n, title, groups: [{ type, title, instruction, options, figure, questions }], lines: [原文一行], review,
//         figures: { 文件名: PNG 字节 } }
// question: { n, text, given, ok, answer, quote, at: { line, start }, why }

/** 旧版日常（ielts_attempts）：一组表格填空，原文是带说话人的文本，解析只有英文。 */
function legacyPart(n, id, learner) {
  const a = one(
    `select jsonb_build_object('band', a.band, 'detail', a.detail, 'item', g.content)
     from ielts_attempts a join ielts_generated_items g on g.id = a.generated_item_id
     where a.id = ${lit(id)} and a.module = 'listening' and a.user_id::text like ${lit(`${learner}%`)}`,
    `listening attempt ${id}`,
  );
  const { item, detail } = a;
  const pq = Object.fromEntries(detail.per_question.map((p) => [p.id, p]));
  const sa = detail.student_analysis || {};
  const lines = item.transcript.split('\n');
  return {
    n,
    title: null, // 旧版题目没有标题
    lines,
    groups: [{
      type: 'form',
      instruction: item.instructions.join(' '),
      questions: item.questions.map((q) => ({
        n: q.number,
        text: q.question,
        given: pq[q.number].given,
        ok: pq[q.number].correct,
        answer: String(pq[q.number].expected),
        quote: q.source_support,
        why: pair(q.distractor_analysis),
      })),
    }],
    review: {
      band: a.band == null ? null : band(a.band),
      right: detail.correct,
      total: detail.total,
      ...(sa.predicted_band ? { text: [`Predicted band: ${sa.predicted_band}`, `预估分数：${sa.predicted_band}`] } : {}),
      // 后端给的薄弱题型和对应的改进建议（一一对应，只有英文）。
      weak: (sa.weakness_patterns || []).flatMap((t, i) => (sa.improvement_strategies?.[i]
        ? [{ label: named(t === 'completion' ? 'form' : t).name, text: pair(sa.improvement_strategies[i]) }] : [])),
    },
  };
}

/** 现行日常（ielts_listening_daily_sessions）。 */
function sessionPart(n, id, learner) {
  const s = one(
    `select jsonb_build_object('pc', s.public_content, 'result', s.result,
      'visuals', (select jsonb_agg(jsonb_build_object('group', m.group_id, 'scope', m.storage_scope, 'key', m.object_key,
          'sha256', m.sha256, 'size', m.size_bytes, 'mime', m.mime_type, 'width', m.width, 'height', m.height, 'alt', m.alt_text))
        from ielts_listening_daily_media m where m.session_id = s.id and m.media_kind = 'visual' and m.state = 'ready'))
     from ielts_listening_daily_sessions s
     where s.id = ${lit(id)} and s.part = ${Number(n)} and s.status = 'completed' and s.user_id::text like ${lit(`${learner}%`)}`,
    `listening daily session ${id}`,
  );
  const { pc, result } = s;
  const figures = {};
  const number = Object.fromEntries(pc.answer_units.map((u) => [u.answer_unit_id, u.number]));
  const scored = Object.fromEntries(result.score.per_answer_unit.map((u) => [u.answer_unit_id, u]));
  const explained = Object.fromEntries((result.explanations || []).map((e) => [e.answer_unit_id, e]));

  // 原文：同一个人连着说的几句并成一行；说话人角色各不相同就写角色，否则写名字。
  const speakers = result.transcript.speakers;
  const byRole = new Set(speakers.map((p) => p.role)).size === speakers.length;
  const who = (sid) => {
    const p = speakers.find((x) => x.speaker_id === sid);
    return byRole && p?.role ? p.role : sid.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
  };
  const lines = [];
  const where = {}; // segment_id → 在哪一行、从第几个字符起
  let last = null;
  for (const seg of result.transcript.segments) {
    if (seg.speaker_id !== last) lines.push(`${who(seg.speaker_id)}:`);
    last = seg.speaker_id;
    where[seg.segment_id] = { line: lines.length - 1, start: lines[lines.length - 1].length + 1 };
    lines[lines.length - 1] += ` ${seg.text}`;
  }

  const groups = pc.groups.map((g) => {
    const options = g.options?.length ? g.options : null;
    const text = (id2) => (options?.find((o) => norm(o.id) === norm(id2)));
    const layout = g.layout;
    const entries = layout.questions || layout.entries || layout.segments || layout.sentences || layout.steps || layout.labels;
    const type = g.question_type === 'completion' ? (g.completion_subtype || 'completion') : g.question_type;
    named(type);
    // 这组题的图：题目快照里可能还写着 pending，以媒体表为准。对象键带着 id，只用来读文件，不进输出。
    const visual = (s.visuals || []).find((v) => v.group === g.group_id && v.mime === 'image/png');
    const name = `fig_listening_p${n}.jpg`;
    if (visual) {
      if (figures[name]) throw new Error(`listening part ${n}: more than one figure`);
      figures[name] = stored(visual, `listening part ${n} figure`);
    }
    return {
      type,
      qtype: g.question_type,
      title: g.title,
      ...(visual ? { figure: figure(name, visual) } : {}),
      // 图示标注：每个位置只有编号，题干是整组共用的那句。
      instruction: [layout.kind === 'visual_labels' ? layout.prompt : null, g.instruction].filter(Boolean).join(' '),
      options,
      questions: entries.map((e) => {
        const u = scored[e.answer_unit_id];
        const ex = explained[e.answer_unit_id];
        const given = String(u.given ?? '').trim();
        const quote = u.source_support?.quote;
        // 答对的题后端不再存标准答案；存的标准答案是小写的，依据句里有就按原文的大小写显示。
        let expected = u.expected?.[0] ?? given;
        const found = quote && !options ? quote.toLowerCase().indexOf(expected.toLowerCase()) : -1;
        if (found >= 0) expected = quote.slice(found, found + expected.length);
        const at = u.source_support && where[u.source_support.segment_id];
        return {
          n: number[e.answer_unit_id],
          text: e.prompt ?? e.text ?? layout.prompt,
          stem: layout.kind !== 'visual_labels',
          given: options ? (text(given) ? show(text(given)) : '') : given,
          ok: u.correct,
          answer: options ? show(text(expected)) : expected,
          quote,
          at: at && { line: at.line, start: at.start + u.source_support.start_char },
          why: ex && pair(ex.explanation_en, ex.explanation_cn),
        };
      }),
    };
  });

  const analysed = result.response_analysis?.by_question_type || [];
  const layer = Object.fromEntries((result.weaknesses || []).map((w) => [w.question_type, w.layer2]));
  const typeName = (t) => named(groups.find((g) => g.qtype === t)?.type ?? t).name;
  // 总评：后端按题型写的作答观察；不止一种题型时各自标上题型名。
  const observed = (k, sep, colon) => analysed
    .map((t) => (analysed.length > 1 ? `${typeName(t.question_type)[k]}${colon}` : '') + t[k ? 'observed_pattern_cn' : 'observed_pattern_en'])
    .join(sep);
  return {
    n,
    title: groups[0].title,
    lines,
    groups,
    figures,
    review: {
      band: null, // 现行日常练习不估分
      right: result.score.correct_count,
      total: result.score.item_count,
      ...(analysed.length ? { text: pair(observed(0, ' ', ': '), observed(1, '', '：')) } : {}),
      // 薄弱项：没全对的题型；中文名用后端的薄弱点名称，配这一类题的做题策略。
      weak: analysed.filter((t) => t.correct < t.attempted).map((t) => ({
        label: pair(typeName(t.question_type)[0], layer[t.question_type] || typeName(t.question_type)[1]),
        text: pair(t.strategy_en, t.strategy_cn),
      })),
    },
  };
}

function mockSession(id, learner) {
  const s = one(
    `select jsonb_build_object(
      'score', r.section_score, 'correct', r.score_detail->'correct_count',
      'sections', (select jsonb_agg(jsonb_build_object(
          'instructions', x.public_content->>'instructions',
          'transcript', (select k.marking_key->>'listening_transcript' from ielts_mock_exam_items i join ielts_mock_exam_marking_keys k on k.item_id = i.id
                         where i.section_id = x.id and k.marking_key ? 'listening_transcript' limit 1),
          'items', (select jsonb_agg(jsonb_build_object(
                'type', i.public_content->>'type', 'prompt', i.public_content->>'prompt', 'options', i.public_content->'options',
                'accepted', k.marking_key->'accepted_responses', 'quote', k.marking_key->>'source_support', 'answer', p.response->>'answer') order by i.ordinal)
              from ielts_mock_exam_items i join ielts_mock_exam_marking_keys k on k.item_id = i.id
              left join ielts_mock_exam_responses p on p.item_id = i.id where i.section_id = x.id)) order by x.ordinal)
        from ielts_mock_exam_sections x where x.session_id = s.id))
     from ielts_mock_exam_sessions s join ielts_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and s.module = 'listening' and s.status = 'completed' and s.user_id::text like ${lit(`${learner}%`)}`,
    `mock listening session ${id}`,
  );
  let no = 0;
  let right = 0;
  const parts = s.sections.map((sec, i) => {
    const questions = sec.items.map((it) => {
      no += 1;
      const options = it.options?.length ? it.options : null;
      const find = (id2) => options?.find((o) => norm(o.id) === norm(id2));
      const accepted = [].concat(it.accepted).map(String);
      const given = String(it.answer ?? '').trim();
      const ok = accepted.some((x) => norm(x) === norm(given));
      if (ok) right += 1;
      named(it.type);
      return {
        n: no,
        type: it.type,
        text: it.prompt,
        options,
        given: options ? (find(given) ? show(find(given)) : '') : given,
        ok,
        answer: options ? show(find(accepted[0])) : accepted[0],
        quote: it.quote,
      };
    });
    return { n: i + 1, title: null, instruction: sec.instructions, lines: (sec.transcript || '').split('\n').filter(Boolean), questions };
  });
  // 后端只存了总对题数，没有逐题对错；这里按答案键逐题比对，必须和它对得上。
  if (right !== Number(s.correct)) throw new Error(`mock listening: ${right} correct by key, backend stored ${s.correct}`);
  return { parts, review: { band: band(s.score), right, total: no, weak: [] } };
}

// ---------- 写成页面认的格式 ----------

/** 回顾页的一个 Part：原文（依据句按页面认的 span 标出题号和对错）+ 每道题。 */
function feedback(base, part, questions) {
  const hits = part.lines.map(() => []);
  for (const q of questions) {
    if (!q.quote) continue;
    // 依据句在原文哪一行：后端给了位置就用位置，否则找第一处逐字相同的。
    let line = q.at && part.lines[q.at.line].startsWith(q.quote, q.at.start) ? q.at.line : -1;
    let start = line < 0 ? -1 : q.at.start;
    if (line < 0) {
      line = part.lines.findIndex((l) => l.includes(q.quote));
      start = line < 0 ? -1 : part.lines[line].indexOf(q.quote);
    }
    const end = start + q.quote.length;
    if (line >= 0 && !hits[line].some((h) => start < h.end && h.start < end)) hits[line].push({ start, end, q });
  }
  const tHtml = part.lines.map((text, i) => {
    let out = '';
    let pos = 0;
    for (const h of hits[i].sort((a, b) => a.start - b.start)) {
      const cls = h.q.ok ? 'ok' : 'bad';
      out += `${text.slice(pos, h.start)}<span class="hit ${cls}">${text.slice(h.start, h.end)}</span><span class="qn ${cls}">${h.q.n}</span>`;
      pos = h.end;
    }
    return `<div>${out}${text.slice(pos)}</div>`;
  }).join('');
  return replace(base, {
    title: part.title ? [`Transcript — ${part.title}`, `听力原文 · ${part.title}`] : null,
    tag: tag(questions.map((q) => q.type)),
    tHtml,
    qs: questions.map((q) => ({
      n: q.n,
      ok: q.ok,
      typeLbl: named(q.type).name,
      kind: q.options ? 'rows' : 'chips',
      q: q.text.replace(/_{2,}/g, '______'),
      ...(q.options ? { opts: q.options.map(show) } : {}),
      mine: q.options ? q.given : q.given || BLANK,
      ans: q.answer,
      ...(q.quote ? { evi: q.quote } : {}),
      ...(q.why ? { why: q.why } : {}),
    })),
    ...(part.review ? { review: part.review } : {}),
  });
}

const flat = (part) => part.groups.flatMap((g) => g.questions.map((q) => ({ ...q, type: g.type, options: g.options })));

/** 日常做题页的一个 Part。页面：第一组可以是填空或选项题，后面的组只能是选项题（带组标题）。 */
function dailyPage(base, part) {
  const all = flat(part);
  const main = part.groups.reduce((m, g) => (g.questions.length > m.questions.length ? g : m));
  const range = (g) => label(g.questions[0].n, g.questions[g.questions.length - 1].n);
  const qs = part.groups.flatMap((g, gi) => g.questions.map((q, i) => {
    if (!g.options) {
      if (gi) throw new Error(`listening part ${part.n}: the page cannot show a completion group after the first group`);
      if (g.figure) throw new Error(`listening part ${part.n}: the page only shows a figure on an option group`);
      const [head, ...tail] = q.text.split(/_{2,}/);
      return { kind: 'gap', type: named(g.type).main, num: q.n, q: [`${q.n}. ${head.trimEnd()}`, tail.join('______').trimStart()] };
    }
    return {
      kind: 'mc',
      type: 'mc',
      q: q.stem === false ? `${q.n}` : `${q.n}. ${q.text}`,
      opts: g.options.map(show),
      ...(gi && !i ? { groupStart: [range(g), g.title].filter(Boolean).join(' · '), groupInstr: g.instruction } : {}),
      ...(g.figure && !i ? { figure: g.figure } : {}),
    };
  }));
  const [en, zh] = named(main.type).name;
  const [from, to] = [all[0].n, all[all.length - 1].n];
  return replace(base, {
    part: `Part ${part.n}`,
    ctx: part.title,
    section: `Part ${part.n}`,
    audioDur: base.audioDur, // 播放器是模拟的，时长沿用原型
    mainType: named(main.type).main,
    brief: [
      `Part ${part.n}, mostly ${en.toLowerCase()}. Listen first, then answer questions ${from}-${to}.`,
      `Part ${part.n} · ${zh}为主，先听录音再作答第 ${from}-${to} 题。`,
    ],
    groupLabel: range(part.groups[0]),
    groupInstr: part.groups[0].instruction,
    qs,
  });
}

exports.build = ({ learner }) => {
  const daily = proto('ielts_listening.json');
  const parts = {};
  const reviews = {};
  const figures = {};
  for (const [n, from] of Object.entries(DAILY)) {
    const part = from.attempt ? legacyPart(Number(n), from.attempt, learner) : sessionPart(Number(n), from.session, learner);
    Object.assign(figures, part.figures);
    parts[`s${n}`] = dailyPage(daily.parts[`s${n}`], part);
    reviews[n] = feedback(daily.feedback[n], part, flat(part));
  }

  const m = mockSession(MOCK, learner);
  const mockReviews = { review: m.review };
  const exam = proto('ielts_mock_listening.json').parts.map((p) => {
    const part = m.parts.find((x) => x.n === p.no);
    const questions = part.questions;
    mockReviews[p.no] = feedback({}, part, questions);
    // 考试页：真实模考每个 Part 是一组混排的题，播放条那几项是模拟的，沿用原型。
    return {
      no: p.no,
      audioTitle: p.audioTitle,
      audioBarPct: p.audioBarPct,
      audioTime: p.audioTime,
      ...(p.tip ? { tip: p.tip } : {}),
      dotFrom: questions[0].n,
      next: p.next,
      groups: [{ label: label(questions[0].n, questions[questions.length - 1].n), sub: part.instruction }],
      items: questions.map((q) => ({ n: q.n, q: q.text, ...(q.options ? { opts: q.options.map((o) => o.text) } : {}) })),
    };
  });

  return {
    ...figures,
    'ielts_listening.json': { parts, feedback: reviews, mockFeedback: mockReviews },
    'ielts_mock_listening.json': { parts: exam },
  };
};
