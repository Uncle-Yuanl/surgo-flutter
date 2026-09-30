// 雅思阅读：日常整篇（题目 + 回顾）、单一题型练习、模考（考试页 + 回顾）。
// 数据全部来自后端已存的结果：ielts_attempts（作答、判分、解析）、ielts_generated_items（文章和题目）、
// ielts_mock_exam_*（模考的文章、题目、答案键、作答、成绩）。示意图题的图是题目里内嵌的 PNG，原样导出。
const fs = require('fs');
const path = require('path');
const { one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');
const { inline, figure } = require('./media.cjs');

// 日常整篇：13 题（标题匹配 7、选择 1、判断 2、句子填空 2、简答 1），答对 6。
const DAILY = '81afb75d-b1d1-4649-8852-c14d56fe287d';
// 单一题型练习：ielts_reading.json 里每个题型用哪次作答的文章和题目（第二项：整篇作答里只取这一种题型）。
// 句尾匹配（ematch）学员没做过，演示里不出这个题型。示意图标注（diagram）取图上画了题号的那次：另外几次的图
// 要么没画题号，要么题号在手机宽度下小得看不清。
const TYPES_FROM = {
  mc: ['ea308527-66c1-4a11-b31e-f7ae375f72ec'],
  tfng: ['1bcb6cc7-c374-4e51-bc0f-639a63811000'],
  yyng: ['0ccf6182-d240-4756-a07f-e81dfeac81ce', 'yes_no_not_given'],
  imatch: ['0ccf6182-d240-4756-a07f-e81dfeac81ce', 'matching_information'],
  hmatch: ['1723bfb1-df8c-4b61-9f91-7c59d3b2a522'],
  fmatch: ['631344fc-7c82-4a28-917a-3790728ce7e4', 'matching_features'],
  scomplete: ['3cb4c85e-bce0-42c7-8557-39e34f1adc66'],
  summary: ['631344fc-7c82-4a28-917a-3790728ce7e4', 'summary_completion'],
  diagram: ['7a46d728-25a5-40f6-8d35-727d4a986a47'],
  short: ['631344fc-7c82-4a28-917a-3790728ce7e4', 'short_answer'],
};
// 模考（ielts_mock_exam_sessions.id）：三篇 40 题，题目质量最好的一场；学员是点过去的（答对 1 题）。
const MOCK = '17ae1a32-32a1-4803-8f02-ddfadf24c955';

// 题型名：中文用原型 ielts_reading.json 里的叫法。
const NAMES = {
  multiple_choice: ['Multiple choice', '选择题'],
  true_false_not_given: ['True / False / Not Given', '判断信息（正误未提及）'],
  yes_no_not_given: ['Yes / No / Not Given', '判断观点（是否未提及）'],
  matching_headings: ['Matching headings', '标题匹配'],
  matching_information: ['Matching information', '信息匹配'],
  matching_features: ['Matching features', '特征匹配'],
  sentence_completion: ['Sentence completion', '句子填空'],
  summary_completion: ['Summary completion', '摘要/笔记/表格填空'],
  short_answer: ['Short answer', '简答题'],
  diagram_labelling: ['Diagram labelling', '示意图标注填空'],
};
const CHOICES = {
  true_false_not_given: ['TRUE', 'FALSE', 'NOT GIVEN'],
  yes_no_not_given: ['YES', 'NO', 'NOT GIVEN'],
};
const BLANK = '—'; // 没作答

const proto = (file) => JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../assets/data', file), 'utf8'));
const norm = (s) => String(s ?? '').trim().replace(/\s+/g, ' ').toLowerCase();
const letter = (i) => String.fromCharCode(65 + i);
const label = (from, to) => (from === to ? `Question ${from}` : `Questions ${from}-${to}`);
/** 题型标签：这组题里出现过的题型，按出现顺序。 */
const tag = (icon, types) => [0, 1].map((k) => `${icon} ${[...new Set(types)].map((t) => NAMES[t][k]).join(' · ')}`);

/** 文章分段：段首自带 "A\n" 标号的用它，没有的按顺序标 A、B、C…… */
const paragraphs = (text) => text.split(/\n{2,}/).map((p, i) => {
  const m = /^([A-Z])\n/.exec(p);
  return [m ? m[1] : letter(i), (m ? p.slice(m[0].length) : p).trim()];
});

/** "A. xxx" / "A) xxx" / "ii. xxx" → { id, text }。 */
const option = (o) => {
  const m = /^\s*([A-Za-z]+)[.)]\s+([\s\S]*)$/.exec(o);
  return m ? { id: m[1], text: m[2] } : { id: '', text: o };
};

/** 连续同一组（keyOf 相同）的题：每题所在组的首尾下标。 */
function runs(items, keyOf) {
  const out = [];
  items.forEach((it, i) => {
    if (i && keyOf(items[i - 1]) === keyOf(it)) out.push(out[i - 1]);
    else out.push({ start: i, end: i });
    out[i].end = i;
  });
  return out;
}

function attempt(id, learner) {
  return one(
    `select jsonb_build_object('band', a.band, 'detail', a.detail, 'item', g.content)
     from ielts_attempts a join ielts_generated_items g on g.id = a.generated_item_id
     where a.id = ${lit(id)} and a.module = 'reading' and a.user_id::text like ${lit(`${learner}%`)}`,
    `reading attempt ${id}`,
  );
}

// ---------- 日常整篇 ----------

/** 做题页的一道题。页面：判断题用固定三个选项，带 opts 的画成选项卡，其余是行内填空。 */
function dailyQuestion(q) {
  if (CHOICES[q.type]) return { type: q.type === 'yes_no_not_given' ? 'ynng' : 'tfng', q: q.question };
  if (!q.options) return { type: 'gap', q: q.question };
  // 页面给每个选项画 A、B、C 角标并去掉 "A) " 前缀；标题匹配的 "ii. " 编号解析里要用，留着。
  const opts = q.options.map((o) => {
    const x = option(o);
    return /^[A-Z]$/.test(x.id) ? `${x.id}) ${x.text}` : o;
  });
  return { type: 'mchoice', q: q.question, opts };
}

/** 回顾页的一道题：作答、答案、依据句、解析（答错的题用针对这次作答的解析）。 */
function reviewQuestion(q, pq, ex, paras) {
  const quotes = [ex?.source_support, q.source_support].filter(Boolean);
  const anchor = quotes.find((s) => paras.some((p) => p[1].includes(s))) ?? null;
  const base = {
    typeLbl: NAMES[q.type],
    q: q.question,
    ok: pq.correct,
    evidence: anchor ?? quotes[0],
    anchor, // 原文里逐字能找到的依据句，页面据此高亮
    why: pair(ex?.explanation ?? q.explanation, ex?.explanation_cn ?? q.explanation_cn),
  };
  const given = String(pq.given ?? '').trim();
  const choices = CHOICES[q.type];
  if (choices && (!given || choices.includes(given.toUpperCase()))) {
    return { ...base, type: q.type === 'yes_no_not_given' ? 'ynng' : 'tfng', a: q.answer, mine: given };
  }
  const opts = (q.options || []).map(option);
  const find = (id) => opts.find((o) => norm(o.id) === norm(id));
  const show = (o) => `${o.id}. ${o.text}`;
  if (find(q.answer) && (!given || find(given))) {
    return { ...base, type: 'mchoice', opts: opts.map(show), a: show(find(q.answer)), mine: given ? show(find(given)) : '' };
  }
  // 填空 / 简答，或者作答不在选项里：两个标签「我的作答 / 正确答案」。
  return { ...base, type: 'gap', kind: 'input', a: find(q.answer) ? show(find(q.answer)) : String(q.answer), mine: given || BLANK };
}

function daily(a) {
  const { item, detail } = a;
  const paras = paragraphs(item.passage);
  const pq = Object.fromEntries(detail.per_question.map((p) => [p.id, p]));
  const ex = Object.fromEntries((detail.explanations || []).map((e) => [e.question_id, e]));
  const groups = runs(item.questions, (q) => q.type);
  const questions = item.questions.map((q, i) => ({
    ...dailyQuestion(q),
    ...(groups[i].start === i ? { group: label(i + 1, groups[i].end + 1), instr: q.instruction } : {}),
  }));
  // 薄弱项：后端给的薄弱题型，各配这类题里答错的第一道的解析。
  const weak = (detail.student_analysis?.weakness_patterns || []).flatMap((t) => {
    const q = item.questions.find((x) => x.type === t && !pq[x.id].correct);
    const e = q && (ex[q.id] || q);
    return e ? [{ label: NAMES[t], text: pair(e.explanation, e.explanation_cn) }] : [];
  });
  const predicted = detail.student_analysis?.predicted_band;
  return {
    session: { title: item.title, passage: paras, questions },
    review: {
      title: item.title,
      tag: tag('🏷', item.questions.map((q) => q.type)),
      passage: paras.map(([l, text]) => [`Paragraph ${l}: `, text]),
      questions: item.questions.map((q) => reviewQuestion(q, pq[q.id], ex[q.id], paras)),
      review: {
        band: a.band == null ? null : band(a.band),
        ...(predicted ? { text: [`Predicted band: ${predicted}`, `预估分数：${predicted}`] } : {}),
        weak,
      },
    },
  };
}

// ---------- 单一题型练习 ----------

/** 按原型的题型格式（ielts_reading.json 的 types）把真实题目填进去；题号从 1 排（示意图题照用图上的题号）。 */
function practiceType(t, item, only, addFigure) {
  const qs = item.questions.filter((q) => !only || q.type === only);
  if (!qs.length) throw new Error(`reading type ${t.key}: no ${only} question in the chosen item`);
  // 整套题原样用的，计时用这套题自己的时限；只取了其中几道的，沿用原型的时长。
  if (!only && item.time_limit_seconds) t = { ...t, mins: item.time_limit_seconds / 60 };
  const article = { title: item.title, passage: paragraphs(item.passage) };
  const instr = qs[0].instruction;
  const opts = (qs[0].options || []).map(option);
  const gap = (q, i, sep) => {
    const [head, ...tail] = q.question.split(/_{2,}/);
    return [`${i + 1}${sep}${head}`, tail.join('______')];
  };
  switch (t.key) {
    case 'mc':
      // 选项写成 "A) xxx"：页面画 A、B、C 角标，并只认这种前缀把它去掉。
      return { ...t, instr, article, items: qs.map((q, i) => ({ q: `${i + 1}. ${q.question}`, opts: q.options.map(option).map((o) => `${o.id}) ${o.text}`) })) };
    case 'tfng':
    case 'yyng':
      return { ...t, instr, article, items: qs.map((q, i) => `${i + 1}. ${q.question}`) };
    case 'imatch':
      return { ...t, instr, article, options: opts.map((o) => o.id), items: qs.map((q, i) => `${i + 1}. ${q.question}`) };
    case 'hmatch':
    case 'fmatch':
      return { ...t, instr, article, options: opts.map((o) => o.id), optionLabels: opts.map((o) => `${o.id}  ${o.text}`), items: qs.map((q, i) => `${i + 1}. ${q.question}`) };
    case 'scomplete':
      return { ...t, instr, article, items: qs.map((q, i) => gap(q, i, '. ')) };
    case 'summary': {
      // 页面把 "(n) ______" 标成题号；真实题没有摘要标题。
      const { summaryTitle, ...rest } = t;
      return { ...rest, instr, article, summaryText: qs.map((q, i) => q.question.replace(/_{2,}/, `(${i + 1}) ______`)).join(' '), items: qs.map((q, i) => [`${i + 1}. `, '']) };
    }
    case 'diagram': {
      // 真实图代替原型自带的示意图（diagramSvg）；图上标的是原题号。
      const { diagramSvg, ...rest } = t;
      const image = (item.media || []).find((x) => x.id === qs[0].media_id)?.image;
      if (!image?.base64) throw new Error(`reading type ${t.key}: the chosen item has no stored figure`);
      const n = (q) => q.question_number ?? q.id;
      return {
        ...rest,
        instr,
        article,
        groupLabel: label(n(qs[0]), n(qs[qs.length - 1])),
        figure: addFigure('fig_reading_diagram.jpg', image, 'reading diagram figure'),
        items: qs.map((q) => [`${n(q)}. ${q.question} `, '']),
      };
    }
    case 'short':
      return { ...t, instr, article, groupLabel: label(1, qs.length), items: qs.map((q, i) => [`${i + 1}  ${q.question} `, '']) };
    default:
      throw new Error(`reading type ${t.key}: no mapping`);
  }
}

// ---------- 模考 ----------

function mockSession(id, learner) {
  return one(
    `select jsonb_build_object(
      'score', r.section_score, 'correct', r.score_detail->'correct_count',
      'sections', (select jsonb_agg(jsonb_build_object(
          'title', x.public_content->>'title', 'passage', x.public_content->>'passage', 'media', x.public_content->'media',
          'items', (select jsonb_agg(jsonb_build_object('pc', i.public_content, 'key', k.marking_key, 'answer', p.response->>'answer') order by i.ordinal)
                    from ielts_mock_exam_items i join ielts_mock_exam_marking_keys k on k.item_id = i.id
                    left join ielts_mock_exam_responses p on p.item_id = i.id where i.section_id = x.id)) order by x.ordinal)
        from ielts_mock_exam_sections x where x.session_id = s.id))
     from ielts_mock_exam_sessions s join ielts_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and s.module = 'reading' and s.status = 'completed' and s.user_id::text like ${lit(`${learner}%`)}`,
    `mock reading session ${id}`,
  );
}

/** 选项怎么显示：段落题的选项就是 "Paragraph A"，其余带上字母。 */
const showOption = (o) => (o.text.startsWith('Paragraph ') || o.text === o.id ? o.text : `${o.id}. ${o.text}`);

function mock(s, addFigure) {
  let no = 0;
  let right = 0;
  const pages = [];
  const passages = {};
  s.sections.forEach((sec, si) => {
    const paras = paragraphs(sec.passage);
    const groups = runs(sec.items, (it) => `${it.pc.type}|${it.pc.instruction}`);
    const base = no;
    const exam = [];
    const review = [];
    let figureShown = false;
    sec.items.forEach((it, i) => {
      no += 1;
      const { pc, key } = it;
      const opts = pc.options || [];
      const accepted = [].concat(...[].concat(key.accepted_responses)).map(String);
      const given = String(it.answer ?? '').trim();
      const ok = accepted.some((x) => norm(x) === norm(given));
      if (ok) right += 1;

      // 考试页：判断题固定三个选项，选择题画选项卡，配对题是下拉，其余是输入框。
      const first = groups[i].start === i;
      const head = first ? { group: label(base + i + 1, base + groups[i].end + 1), instr: pc.instruction } : {};
      let q;
      if (CHOICES[pc.type]) q = { type: pc.type === 'yes_no_not_given' ? 'ynng' : 'tfng' };
      else if (pc.type === 'multiple_choice') q = { type: 'mchoice', opts: opts.map((o) => o.text) };
      else if (opts.length) {
        const plain = opts.every((o) => o.text.startsWith('Paragraph ') || o.text === o.id);
        q = { type: 'match', ...(first ? { letters: opts.map((o) => o.id), ...(plain ? { nobox: true } : { box: opts.map((o) => o.text) }) } : {}) };
      } else if (pc.type === 'diagram_labelling' && first && !figureShown) {
        // 一篇的几组标注题共用一张图，只在第一组画。真实图是 PNG，和题目一起导出；
        // 这篇没存图的话页面画它自带的示意图。
        figureShown = true;
        const image = (Array.isArray(sec.media) ? sec.media : []).find((x) => x.id === pc.media_id)?.image;
        q = { type: 'diagram', ...(image?.base64 ? { figure: addFigure(`fig_mock_reading_p${si + 1}.jpg`, image, `mock reading passage ${si + 1} figure`) } : {}) };
      } else q = { type: pc.type === 'short_answer' ? 'shortans' : 'gap' };
      exam.push({ ...q, ...head, q: pc.prompt });

      // 回顾页。
      const choices = CHOICES[pc.type];
      const find = (id) => opts.find((o) => norm(o.id) === norm(id));
      // 依据句从段首起时会带上段落标号那一行，去掉才能在原文里找到。
      const r = { no, typeLbl: NAMES[pc.type], q: pc.prompt, ok, ev: key.source_support.replace(/^[A-Z]\n/, '') };
      if (choices && (!given || choices.includes(given.toUpperCase()))) {
        review.push({ ...r, kind: 'opts', opts: choices, correct: accepted[0], mine: given.toUpperCase() });
      } else if (find(accepted[0]) && (!given || find(given))) {
        review.push({ ...r, kind: 'opts', opts: opts.map(showOption), correct: showOption(find(accepted[0])), mine: given ? showOption(find(given)) : '' });
      } else {
        review.push({ ...r, kind: 'input', correct: find(accepted[0]) ? showOption(find(accepted[0])) : accepted[0], mine: given || BLANK });
      }
    });
    pages.push({ title: sec.title, paras, qs: exam });
    passages[si + 1] = {
      title: sec.title,
      tag: tag('⚖', sec.items.map((it) => it.pc.type)),
      paras: paras.map(([l, text]) => [`Paragraph ${l}: `, text]),
      qs: review,
    };
  });
  // 后端只存了总对题数，没有逐题对错；这里按答案键逐题比对，必须和它对得上。
  if (right !== Number(s.correct)) throw new Error(`mock reading: ${right} correct by key, backend stored ${s.correct}`);
  return { pages, passages, review: { band: band(s.score), weak: [] } };
}

exports.build = ({ learner }) => {
  // 题图：{ 文件名: PNG 字节 }，和 JSON 一起交给 export.cjs 写出；JSON 里记文件位置和原图宽高。
  const figures = {};
  const addFigure = (name, image, what) => {
    figures[name] = inline(image, what);
    return figure(name, { width: image.width, height: image.height, alt: image.alt_text });
  };
  const d = daily(attempt(DAILY, learner));
  const attempts = {};
  // 只出有真实作答的题型：没做过的留着原型内容就成了假数据。
  const types = proto('ielts_reading.json').types.filter((t) => TYPES_FROM[t.key]).map((t) => {
    const from = TYPES_FROM[t.key];
    attempts[from[0]] ??= attempt(from[0], learner);
    return practiceType(t, attempts[from[0]].item, from[1], addFigure);
  });
  const m = mock(mockSession(MOCK, learner), addFigure);
  return {
    ...figures,
    // passages.monarch：回顾页按这个键取日常那篇（原型是帝王蝶那篇，键名沿用）。
    'questions.json': { ielts: { reading: { daily: d.session, passages: { monarch: d.review } } } },
    'ielts_reading.json': { types },
    'reading_wizard.json': { RTYPES: types },
    'ielts_mock_reading.json': m.pages,
    'reading_feedback_mock.json': { passages: m.passages, review: m.review },
  };
};
