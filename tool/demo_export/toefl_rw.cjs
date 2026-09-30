// 托福（2026 版）阅读与写作：日常训练六个题型 + 阅读、写作两场模考。
// 数据全部来自后端已存的结果（只读）：
//   日常  toefl_daily_training_items（题目、私有答案键）+ ..._attempts（作答、得分、评语）
//   模考  toefl_mock_exam_sections / items / responses / marking_keys / results
//   薄弱项 assessment_analysis_runs → assessment_observations（取法同后端的 weaknesses 接口）
// 解析、评语、批注、薄弱项后端存了中英两份，输出 [英文, 中文]；题目、原文、选项只有英文，保持原文。
const { rows, one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');
// 模考的写邮件 / 学术讨论另存一份题目（见 writing()），界面文案（标签、占位提示）沿用原型的。
const prototype = require('../../assets/data/tf_writing.json');

// 演示学员的哪几次作答：日常训练一题型一场（toefl_daily_training_sessions.id），模考一科一场
// （toefl_mock_exam_sessions.id）。这位学员不少场次是乱敲键盘的测试作答，挑的是认真作答、结果完整的。
const DAILY = {
  words: 'b92bccd5-cbe3-444e-959b-76a4071e0f36', // Complete the Words
  life: '556e957d-2bc8-4c2a-9ecc-6f7b89c726f8', // Read in Daily Life
  acad: 'd364b9a1-eda4-4780-bbbe-9ceb674f7aea', // Read an Academic Passage
  sentence: 'c5f574c0-db35-4c56-8a86-a8b8be13a66a', // Build a Sentence
  email: '14ae98af-adb5-4430-a6f2-ae9858382d59', // Write an Email
  discussion: '554e973c-2eeb-4912-b7b4-e8a66fb80b8a', // Academic Discussion
};
const MOCK = {
  reading: 'c811b3b1-fbaa-4cbd-b531-6bd616705f95',
  writing: '43922b7e-0c4d-4004-b24d-faf24925df81',
};

// 题型名是后端 examReviewBundle.LABELS 的英文官方名（页面的词典里有对应中文）。
const NAMES = {
  complete_the_words: 'Complete the Words',
  read_in_daily_life: 'Read in Daily Life',
  read_an_academic_passage: 'Read an Academic Passage',
  build_a_sentence: 'Build a Sentence',
  write_an_email: 'Write an Email',
  academic_discussion: 'Academic Discussion',
};
const CRITERIA = {
  fulfilment: 'Fulfilment', organisation: 'Organisation', register: 'Register', language_control: 'Language control',
  contribution: 'Contribution', development: 'Development', interaction: 'Interaction',
};
const READING = ['Reading', '阅读'];
const WRITING = ['Writing', '写作'];

// ---- 分数 ----------------------------------------------------------------------------------
// 后端 toefl2026Primitives：题目分 0–5，线性换到 2026 版的 1–6 分并取半分（bandFieldsFromTaskScore）；
// 一场日常训练先对各题分取平均再换算一次（sessionBandFromTaskScores）；模考客观题按答对率
// halfPoint(1 + 5 × 比例)（estimateObjectiveSection），和前一条是同一个换算。
const taskBand = (score) => Math.max(1, Math.min(6, Math.round((1 + Number(score)) * 2) / 2));
const sessionBand = (items) => band(taskBand(items.reduce((s, it) => s + Number(it.score), 0) / items.length));
const ratioBand = (correct, total) => taskBand((5 * correct) / total);
// 写作四项（0–5）和整题分：4 分起是评分标准里的「基本达成」，页面上算「表现良好」。
const GOOD = 4;

// ---- 读库 ----------------------------------------------------------------------------------
const mine = (config, alias) => `${alias}.user_id::text like ${lit(`${config.learner}%`)}`;
const FINDING = `'tag', o.error_tag_uid, 'label', t.labels, 'area', o.evidence->'layer1'->'label',
  'explanation', o.evidence->'explanation', 'activity', t.suggested_activities`;
const IS_FINDING = `o.direction = 'negative'
  and o.detector in ('weakness_v1_rule', 'weakness_v1_llm', 'weakness_v2_rule', 'weakness_v2_llm')`;

function dailyItems(config, id, type) {
  const items = rows(
    `select jsonb_build_object('ordinal', i.ordinal, 'pub', i.public_content, 'key', i.marking_key,
       'response', a.response, 'score', a.task_score, 'detail', a.result_detail)
     from toefl_daily_training_sessions s
     join toefl_daily_training_items i on i.session_id = s.id
     join toefl_daily_training_attempts a on a.session_id = s.id and a.item_id = i.id
     where s.id = ${lit(id)} and ${mine(config, 's')} and s.status = 'completed' and s.task_type = ${lit(type)}
     order by i.ordinal`,
  );
  if (!items.length) throw new Error(`toefl daily ${type} ${id}: no completed session with scored items`);
  return items;
}

/** 日常：每题一次分析，取当前分析器版本最新的一次（后端 toeflDailySessionWeaknesses）。 */
function dailyFindings(config, id) {
  return rows(
    `select jsonb_build_object(${FINDING}, 'ordinal', i.ordinal)
     from toefl_daily_training_attempts a
     join toefl_daily_training_items i on i.id = a.item_id
     join lateral (
       select r.id, r.status from assessment_analysis_runs r
       where r.user_id = a.user_id and r.source_type = 'toefl_daily' and r.source_result_id = a.id
         and r.analyzer_version = 'structured-evidence-v8'
         and r.ontology_version_id = (select v.id from assessment_ontology_versions v where v.status = 'active'
                                      order by v.published_at desc nulls last, v.created_at desc limit 1)
       order by r.created_at desc, r.id desc limit 1
     ) run on run.status not in ('failed', 'queued', 'processing')
     join assessment_observations o on o.analysis_run_id = run.id and ${IS_FINDING}
     left join assessment_error_tags t on t.uid = o.error_tag_uid
     where a.session_id = ${lit(id)} and ${mine(config, 'a')}
     order by i.ordinal, o.observed_at, o.id`,
  );
}

/** 模考：整场一次分析，取最新的一次（后端 analysisForSource）。 */
function mockFindings(config, id) {
  return rows(
    `select jsonb_build_object(${FINDING})
     from (select r.id, r.status from assessment_analysis_runs r
           where r.source_type = 'toefl_mock' and r.source_result_id = ${lit(id)} and ${mine(config, 'r')}
           order by r.created_at desc limit 1) run
     join assessment_observations o on o.analysis_run_id = run.id and ${IS_FINDING}
     left join assessment_error_tags t on t.uid = o.error_tag_uid
     where run.status not in ('failed', 'queued', 'processing')
     order by o.observed_at, o.id`,
  );
}

/** 一场模考：成绩、自适应分到的分支、各模块的原文和题目（带作答和答案键）。 */
function mockSession(config, id, module) {
  return one(
    `select jsonb_build_object('score', r.section_score, 'detail', r.score_detail,
       'branch', (select b.branch_code from toefl_mock_exam_adaptive_decisions d
                  join toefl_mock_exam_adaptive_branches b on b.id = d.selected_branch_id where d.session_id = s.id),
       'sections', (select jsonb_agg(jsonb_build_object('units', x.public_content->'content',
           'items', (select jsonb_agg(jsonb_build_object('ordinal', i.ordinal, 'pub', i.public_content,
                       'key', k.marking_key, 'response', p.response) order by i.ordinal)
                     from toefl_mock_exam_items i
                     join toefl_mock_exam_marking_keys k on k.item_id = i.id
                     left join toefl_mock_exam_responses p on p.item_id = i.id
                     where i.section_id = x.id)) order by x.ordinal)
         from toefl_mock_exam_sections x where x.session_id = s.id))
     from toefl_mock_exam_sessions s join toefl_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and ${mine(config, 's')} and s.status = 'completed' and s.module = ${lit(module)}`,
    `toefl mock ${module} ${id}`,
  );
}

// ---- 薄弱项 --------------------------------------------------------------------------------
/**
 * 原型的薄弱项卡：三个标签（科目 / 能力 / 错误类型）、问题、建议。同一个错误标签只留第一条
 * （后端按标签合并）；`numbered` 时在问题前标上是第几题。
 */
function weakCards(findings, module, numbered) {
  const seen = new Set();
  return findings
    .filter((f) => {
      const k = f.tag || JSON.stringify(f.explanation);
      return !seen.has(k) && seen.add(k);
    })
    .map((f) => ({
      tags: [module, pair(f.area?.en, f.area?.zh), pair(f.label?.en, f.label?.zh)],
      q: numbered
        ? pair(`Q${f.ordinal}: ${f.explanation?.en || ''}`, `第 ${f.ordinal} 题：${f.explanation?.zh || ''}`)
        : pair(f.explanation?.en, f.explanation?.zh),
      a: pair(f.activity?.en, f.activity?.zh),
    }));
}
/** 写作评分页的标签是一行字：三个标签用「 · 」连起来。 */
const tagLine = (cards) => cards.map((c) => ({ ...c, tags: [0, 1].map((l) => c.tags.map((t) => t[l]).join(' · ')) }));

// ---- 文本 ----------------------------------------------------------------------------------
const paragraphs = (text) => text.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
/** 原型的「原文行」：一段一行，段与段之间放一个空串。 */
const lines = (text) => paragraphs(text).flatMap((p, i) => (i ? ['', p] : [p]));
/** 选项按字母排：页面按位置标 A/B/C/D，题库里个别题的顺序和字母不一致。 */
const options = (pub) => [...(pub.options || [])].sort((a, b) => a.id.localeCompare(b.id));
const optionLine = (pub, id) => {
  const o = options(pub).find((x) => x.id === id);
  return o ? `${o.id}. ${o.text}` : id;
};
const given = (it) => String(it.response?.choice ?? it.response?.answer ?? '').trim();
const accepted = (it) => String((it.key.accepted_responses || [])[0] ?? '');
const support = (it) => String(it.key.source_support?.quote ?? it.key.source_support ?? '');
const isRight = (it) => (it.key.accepted_responses || []).some((a) => String(a).toLowerCase() === given(it).toLowerCase());

/** 在原文里找一段引文：先原样找，找不到再放宽空白和引号。 */
function locate(text, quote) {
  const q = quote.trim();
  if (!q) return null;
  const at = text.indexOf(q);
  if (at >= 0) return { start: at, end: at + q.length };
  const relaxed = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/['’‘]/g, "['’‘]").replace(/["“”]/g, '["“”]').replace(/\s+/g, '\\s+');
  const m = new RegExp(relaxed).exec(text);
  return m ? { start: m.index, end: m.index + m[0].length } : null;
}
/** 多段引文在原文里的位置：按出现先后排，和已占的片段重叠的不要；n 是引文在传入数组里的序号。 */
function hits(text, quotes) {
  const out = [];
  quotes.forEach((quote, i) => {
    const at = locate(text, quote);
    if (at && !out.some((h) => at.start < h.end && h.start < at.end)) out.push({ ...at, n: i + 1 });
  });
  return out.sort((a, b) => a.start - b.start);
}

// ---- 阅读：讲解 ----------------------------------------------------------------------------
/**
 * 后端 examReviewBundle.toeflReadingFeedback 的照搬：复盘里每题的讲解是读的时候用答案键里的中英解析
 * 拼出来的，库里不存成品。模考每题都这样拼（always）；日常的老题没有解析，后端用评分时存的那句评语。
 */
function readingFeedback(it, always) {
  const rationale = it.key.review_rationale;
  if (!rationale && !always) return pair(it.detail?.feedback_en, it.detail?.feedback_cn);
  const answer = given(it);
  const key = accepted(it);
  const correct = rationale?.correct || {};
  const evidence = support(it);
  if (it.pub.type === 'complete_the_words') {
    const word = evidence || key;
    return [
      [
        answer ? `The submitted letters were “${answer}”.` : 'No response was submitted for this blank.',
        key ? `The missing letters are “${key}”, completing the word “${word}”.` : '',
        correct.en || (word ? 'Read the completed word in its surrounding sentence to confirm the spelling and meaning.' : ''),
      ].filter(Boolean).join(' '),
      [
        answer ? `你填写的字母是“${answer}”。` : '本题未作答。',
        key ? `缺失字母应为“${key}”，补全后的单词是“${word}”。` : '',
        correct.zh || (word ? '请把完整单词放回原句，结合拼写和上下文核对。' : ''),
      ].filter(Boolean).join(''),
    ];
  }
  const label = (id) => {
    const o = options(it.pub).find((x) => x.id === id);
    return o ? `${o.id} (“${o.text}”)` : id;
  };
  const picked = rationale?.options?.[answer] || {};
  return [
    [
      !answer ? 'No response was submitted for this question.' : `You selected ${label(answer)}.${picked.en ? ` ${picked.en}` : ''}`,
      key ? `The accepted answer is ${label(key)}.` : '',
      correct.en || (evidence ? `The source evidence states: “${evidence}”.` : ''),
    ].filter(Boolean).join(' '),
    [
      !answer ? '本题未作答。' : `你选择了 ${label(answer)}。${picked.zh || ''}`,
      key ? `正确答案是 ${label(key)}。` : '',
      correct.zh || (evidence ? `原文依据是：“${evidence}”。` : ''),
    ].filter(Boolean).join(''),
  ];
}

// ---- 阅读：选择题（日常生活 / 学术文章）------------------------------------------------------
const question = (it) => ({ q: it.pub.prompt, opts: options(it.pub).map((o) => o.text) });
/** 逐题卡：答对只列作答；答错或没答再列正确答案、讲解和原文依据。 */
function choiceCard(it, n, always) {
  const ok = isRight(it);
  return {
    n,
    ok,
    q: it.pub.prompt,
    mine: given(it) ? optionLine(it.pub, given(it)) : '—',
    ...(ok ? {} : { ans: optionLine(it.pub, accepted(it)), why: readingFeedback(it, always), evi: `"${support(it)}"` }),
  };
}
/** 原文回看：各题的原文依据在原文里标出来，[前文, 命中片段, 题号, 后文]；`tail` 是最后一处之后的原文。 */
function evidenceRows(passage, items, first = 1) {
  const out = [];
  let pos = 0;
  for (const h of hits(passage, items.map(support))) {
    out.push([passage.slice(pos, h.start), passage.slice(h.start, h.end), h.n + first - 1, '']);
    pos = h.end;
  }
  return { out, tail: passage.slice(pos) };
}
/** 库里存的每题得分（5 / 0）要和按答案键重算的对错一致，不一致就是映射写错了。 */
function sameAsStored(items, what) {
  if (items.some((it) => isRight(it) !== Number(it.score) > 0)) throw new Error(`${what}: marking differs from the stored scores`);
}

function dailyChoice(config, id, type) {
  const items = dailyItems(config, id, type);
  sameAsStored(items, `toefl daily ${type}`);
  const passage = items[0].pub.passage;
  if (items.some((it) => it.pub.passage !== passage)) throw new Error(`toefl daily ${type} ${id}: more than one passage`);
  const { out, tail } = evidenceRows(passage, items);
  return {
    passage,
    questions: items.map(question),
    // 日常生活 / 学术的反馈页把「只有一项的行」当纯文本。
    src: [...out, ...(tail ? [[tail]] : [])],
    cards: items.map((it, i) => choiceCard(it, i + 1, false)),
    weak: weakCards(dailyFindings(config, id), READING, true),
    score: sessionBand(items),
  };
}

// ---- 阅读：补全单词 ------------------------------------------------------------------------
/** 题库里一个空是「前缀 + 下划线」（Loc__）：页面要 [前缀, 缺几个字母, 后缀]。 */
function blank(text) {
  const m = /^(.*?)(_+)(.*)$/.exec(text);
  if (!m) throw new Error(`toefl complete the words: unexpected blank ${text}`);
  return [m[1], m[2].length, m[3]];
}
const segments = (items) => items[0].pub.content.segments;
const tokens = (items) => segments(items).map((s) => (s.type === 'blank' ? blank(s.text) : s.text));
const blankText = (it) => segments([it]).find((s) => s.id === it.key.blank_id).text;
/** 把字母放回单词里：Loc + al。 */
const filled = (it, letters) => {
  const [prefix, , suffix] = blank(blankText(it));
  return `${prefix}${letters}${suffix}`;
};

function wordCard(it, n, always) {
  const ok = isRight(it);
  return {
    n,
    ok,
    q: pair(`Blank ${n} — "${blankText(it)}"`, `第 ${n} 空 — "${blankText(it)}"`),
    mine: given(it) ? filled(it, given(it)) : '—',
    ...(ok ? {} : { ans: filled(it, accepted(it)), why: readingFeedback(it, always), evi: `"${support(it)}"` }),
  };
}
/** 补全后的段落：每个空填上正确答案并标题号，`first` 是这一段第一个空的题号。 */
function completedRows(items, first = 1) {
  const out = [];
  let before = '';
  let n = first;
  for (const s of segments(items)) {
    if (s.type !== 'blank') {
      before += s.text;
      continue;
    }
    const it = items.find((x) => x.key.blank_id === s.id);
    out.push([before, filled(it, accepted(it)), n++, '']);
    before = '';
  }
  return { out, tail: before };
}

// ---- 写作 ----------------------------------------------------------------------------------
/** 排列成句：固定的词块原样摆在句子里，其余位置是空格，没固定的词块进词库。 */
function sentenceTask(it) {
  const fixed = new Map((it.pub.fixed_tokens || []).map((f) => [f.position, f.id]));
  const text = (id) => it.pub.tokens.find((t) => t.id === id).text;
  return {
    q: it.pub.prompt,
    parts: it.pub.tokens.map((_, i) => (fixed.has(i) ? text(fixed.get(i)) : '_')),
    tail: it.pub.terminal_punctuation || '',
    bank: it.pub.tokens.filter((t) => ![...fixed.values()].includes(t.id)).map((t) => t.text),
  };
}
const context = (pub, label) => (pub.context || []).find((c) => c.label === label)?.text;

function emailTask(pub) {
  // 页面拿来信的主题当标题、发件人当收件人，缺了会直接画不出来。
  if (!context(pub, 'Subject') || !context(pub, 'From')) throw new Error('toefl write an email: task context has no From / Subject');
  return {
    title: context(pub, 'Subject'),
    ctx: pub.scenario,
    meta: (pub.context || []).map((c) => [c.label, c.text]),
    reqs: [pub.prompt],
    to: context(pub, 'From'),
    subjPh: context(pub, 'Subject'),
    min: pub.recommended_minimum_words,
  };
}

/** 讨论帖：日常题把三段发言写在 scenario 里（「Professor: …」），模考题放在 context 里。 */
function posts(pub) {
  const inContext = (pub.context || []).filter((c) => /^(Professor|Classmate)/.test(c.label));
  const list = inContext.length
    ? inContext.map((c) => [(/\(([^)]+)\)/.exec(c.label) || [])[1] || c.label, c.text])
    : paragraphs(pub.scenario).map((p) => /^([^:\n]{1,40}):\s*([\s\S]+)$/.exec(p)).filter(Boolean).map((m) => [m[1], m[2]]);
  if (list.length < 2) throw new Error('toefl academic discussion: no posts found');
  return list.map(([name, txt], i) => ({ ini: name[0], cls: ['p', 'k', 'u'][i] || 'u', name, txt }));
}
const discussionTask = (pub) => ({ prompt: pub.prompt, posts: posts(pub), min: pub.recommended_minimum_words });

/** 排列成句的逐题卡：学员排出来的句子（`wrong` 的词块标红）、正确句子、评语（有才放）。 */
function sentenceCard(it, n, { ok, words, wrong, fb }) {
  return {
    n,
    ok,
    q: `"${it.pub.prompt}"`,
    chips: words.map((w, i) => [w, wrong(i) ? 1 : 0]),
    ans: accepted(it),
    ...(fb ? { fb } : {}),
  };
}

/** 作文里标批注：[plain, 文字] / [hl, 原文, ok|bad, 序号]；在作文里找不到原文的批注不标。 */
function essay(text, annotations) {
  const found = hits(text, annotations.map((a) => a.quote));
  const tone = (h) => (annotations[h.n - 1].polarity === 'strength' ? 'ok' : 'bad');
  const seg = [];
  let pos = 0;
  found.forEach((h, i) => {
    if (h.start > pos) seg.push(['plain', text.slice(pos, h.start)]);
    seg.push(['hl', text.slice(h.start, h.end), tone(h), i + 1]);
    pos = h.end;
  });
  if (pos < text.length) seg.push(['plain', text.slice(pos)]);
  return {
    seg,
    notes: found.map((h, i) => [i + 1, tone(h), pair(annotations[h.n - 1].message_en, annotations[h.n - 1].message_cn)]),
  };
}

/** 写邮件 / 学术讨论的评分卡：四项分、题目、作文（带批注）、评语。`result` 是后端存的这道题的评分。 */
function constructedCard(it, result) {
  const email = it.pub.type === 'write_an_email';
  return {
    n: 1,
    ok: Number(result.task_score) >= GOOD,
    q: email ? `"${NAMES.write_an_email} — ${context(it.pub, 'Subject')}"` : `"${NAMES.academic_discussion}"`,
    subs: it.key.criteria.map((k) => [CRITERIA[k], band(result.criteria[k]), Number(result.criteria[k]) >= GOOD ? 'ok' : 'bad']),
    task: email ? it.pub.scenario : posts(it.pub)[0].txt,
    ...essay(it.response?.text || '', result.annotations || []),
    fb: pair(result.feedback_en, result.feedback_cn),
  };
}

// ---- 各页 ----------------------------------------------------------------------------------
function dailyReading(config) {
  const life = dailyChoice(config, DAILY.life, 'read_in_daily_life');
  const acad = dailyChoice(config, DAILY.acad, 'read_an_academic_passage');
  const words = dailyItems(config, DAILY.words, 'complete_the_words');
  sameAsStored(words, 'toefl daily complete_the_words');
  const completed = completedRows(words);
  return {
    'toefl_life.json': {
      TFDL_AD: lines(life.passage),
      TFDL_POST: [],
      // 日常题的原文没有标题，用题型名。
      TFDL_QS: life.questions.map((q, i) => (i ? q : { src: 'ad', title: NAMES.read_in_daily_life, ...q })),
      TFDL_TOTAL: life.questions.length,
      TFDLFB_WEAK: life.weak,
      TFDLFB_SRC: life.src,
      TFDLFB_QS: life.cards,
      TFDLFB_SCORE: life.score,
    },
    'tf_acad.json': {
      TFDA_TITLE: NAMES.read_an_academic_passage,
      TFDA_PARAS: paragraphs(acad.passage),
      TFDA_TITLE2: '',
      TFDA_PARAS2: [],
      TFDA_QS: acad.questions,
      TFDA_TOTAL: acad.questions.length,
      TFDAFB_WEAK: acad.weak,
      TFDAFB_SRC: acad.src,
      TFDAFB_QS: acad.cards,
      TFDAFB_SCORE: acad.score,
    },
    'toefl_words.json': {
      _source: 'tool/demo_export/toefl_rw.cjs',
      TFDW_PARAS: [tokens(words)],
      TFDWFB_WEAK: weakCards(dailyFindings(config, DAILY.words), READING, true),
      // 补全单词的反馈页每一行都要四项，纯文本行的命中片段留空。
      TFDWFB_SRC: [...completed.out, ...(completed.tail ? [[completed.tail, '', 0, '']] : [])],
      TFDWFB_QS: words.map((it, i) => wordCard(it, i + 1, false)),
      // 后端不出整场的评语，d 留空（页面不画这一行）。
      TFDWFB_SCORE: { n: sessionBand(words), d: '' },
    },
  };
}

function mockReading(config) {
  const s = mockSession(config, MOCK.reading, 'reading');
  // 模块 1 是 35 道计分题（两段补全单词、一篇日常、一篇学术）；模块 2 按模块 1 的表现分到
  // foundation / advanced，15 道题不计分（后端 score_detail：Unscored trial items）。
  const [router, second] = s.sections;
  /** 一个模块里某题型的题，按材料分组。 */
  const sets = (section, type) => {
    const map = new Map();
    for (const it of section.items.filter((x) => x.pub.type === type)) {
      map.set(it.pub.source_id, [...(map.get(it.pub.source_id) || []), it]);
    }
    return [...map.entries()].map(([id, items]) => ({ unit: section.units.find((u) => u.id === id), items }));
  };
  const wordPart = (section) => {
    const paras = sets(section, 'complete_the_words').map((g) => tokens(g.items));
    return { paras, total: paras.length };
  };
  /** 选择题一页：每篇材料的第一题带标题和原文，后面的题沿用；题号是整个模块里的序号。 */
  const choicePart = (section) => {
    const qs = ['read_in_daily_life', 'read_an_academic_passage'].flatMap((type) => sets(section, type).flatMap((g) =>
      g.items.map((it, i) => ({
        no: it.ordinal,
        ...(i ? {} : { title: g.unit.title, ad: lines(g.unit.passage) }),
        ...question(it),
      }))));
    return { qs, total: section.items.length, ad: qs[0].ad, title: qs[0].title };
  };
  /** 复盘里一个模块：各题型的原文回看和逐题卡；题型分只有计分的模块 1 有（用库里存的答对数算）。 */
  const review = (section, counts) => {
    const out = { types: [], src: {}, qs: {} };
    for (const [key, type] of [['w', 'complete_the_words'], ['d', 'read_in_daily_life'], ['p', 'read_an_academic_passage']]) {
      const groups = sets(section, type);
      const items = groups.flatMap((g) => g.items);
      if (!items.length) continue;
      const words = type === 'complete_the_words';
      if (counts && items.filter(isRight).length !== counts[type].correct_count) {
        throw new Error(`toefl mock reading ${type}: marking differs from the stored result`);
      }
      out.types.push({
        key,
        name: NAMES[type],
        ...(counts ? { score: ratioBand(counts[type].correct_count, counts[type].item_count) } : {}),
      });
      // 复盘页每一行都要带题号：一篇材料开头的文字并进第一行的前文，结尾并进最后一行的后文。
      const rowsOut = [];
      let n = 1;
      for (const g of groups) {
        const part = words ? completedRows(g.items, n) : evidenceRows(g.unit.passage, g.items, n);
        n += g.items.length;
        if (!part.out.length) continue;
        if (rowsOut.length) part.out[0][0] = `\n\n${part.out[0][0]}`;
        part.out[part.out.length - 1][3] = part.tail;
        rowsOut.push(...part.out);
      }
      out.src[key] = { label: words ? 'Completed paragraph' : 'Passage', rows: rowsOut };
      out.qs[key] = items.map((it, i) => (words ? wordCard(it, i + 1, true) : choiceCard(it, i + 1, true)));
    }
    return out;
  };
  const weak = weakCards(mockFindings(config, MOCK.reading), READING, false);
  return {
    'tf_reading_mock.json': {
      parts: { 1: wordPart(router), 2: choicePart(router), 3: wordPart(second), 4: choicePart(second) },
      feedback: {
        result: { band: band(s.score), branch: s.branch === 'advanced' ? 'Upper' : 'Lower' },
        m1: { ...review(router, s.detail.task_counts), score: band(s.score), weak },
        m2: { ...review(second, null), weak },
      },
    },
  };
}

function writing(config) {
  const sentences = dailyItems(config, DAILY.sentence, 'build_a_sentence');
  const [email] = dailyItems(config, DAILY.email, 'write_an_email');
  const [discussion] = dailyItems(config, DAILY.discussion, 'academic_discussion');
  const mock = mockSession(config, MOCK.writing, 'writing');
  const items = mock.sections.flatMap((x) => x.items);
  const of = (type) => items.filter((it) => it.pub.type === type);
  const result = (type) => mock.detail.constructed_tasks.find((t) => t.task_type === type);
  const mockSentences = of('build_a_sentence');
  const [mockEmail] = of('write_an_email');
  const [mockDiscussion] = of('academic_discussion');

  // 日常：后端存了词块顺序、哪些词块放错了、中英评语。
  const dailySentence = (it, i) => sentenceCard(it, i + 1, {
    ok: it.detail.outcome === 'matched',
    words: it.response.token_ids.map((id) => it.pub.tokens.find((t) => t.id === id).text),
    wrong: (at) => (it.detail.arrangement_analysis?.out_of_order_token_ids || []).includes(it.response.token_ids[at]),
    fb: pair(it.detail.feedback_en, it.detail.feedback_cn),
  });
  // 模考：只存整句和全场答对几句，没有逐题评语；对错和放错的词块按正确句子逐位比
  // （不计大小写和句末标点，同后端的判分口径），再和库里存的答对数对一遍。
  const plain = (w) => w.toLowerCase().replace(/[.?!]$/, '');
  const mockSentence = (it, i) => {
    const words = given(it).split(/\s+/).filter(Boolean);
    const right = accepted(it).split(/\s+/);
    const wrong = (at) => plain(words[at]) !== plain(right[at] || '');
    return sentenceCard(it, i + 1, { ok: words.length === right.length && !words.some((_, at) => wrong(at)), words, wrong });
  };
  const sentenceCount = mock.detail.build_sentence;
  if (mockSentences.map(mockSentence).filter((c) => c.ok).length !== sentenceCount.correct_count) {
    throw new Error('toefl mock writing: sentence marking differs from the stored result');
  }

  return {
    'tf_writing.json': {
      TFW1_QS: sentences.map(sentenceTask),
      TFW1_TOTAL: sentences.length,
      TFW2: emailTask(email.pub),
      TFW3: discussionTask(discussion.pub),
      // 模考那一场的题目：页面在模考流程里读这三个键（原型数据没有，日常和模考共用一套题）。
      TFW1_QS_MOCK: mockSentences.map(sentenceTask),
      TFW2_MOCK: { ...prototype.TFW2, ...emailTask(mockEmail.pub) },
      TFW3_MOCK: { ...prototype.TFW3, ...discussionTask(mockDiscussion.pub) },
    },
    'tf_writing_feedback.json': {
      SCORE: {
        sent: sessionBand(sentences),
        email: sessionBand([email]),
        disc: sessionBand([discussion]),
        mock: band(mock.score),
      },
      WEAK: {
        sent: tagLine(weakCards(dailyFindings(config, DAILY.sentence), WRITING, true)),
        email: tagLine(weakCards(dailyFindings(config, DAILY.email), WRITING, false)),
        disc: tagLine(weakCards(dailyFindings(config, DAILY.discussion), WRITING, false)),
        mock: tagLine(weakCards(mockFindings(config, MOCK.writing), WRITING, false)),
      },
      // 原型的薄弱项文案（TFWFB_WEAK、两张卡的 weak）页面在有 WEAK 时不读，清掉免得假数据留在文件里。
      TFWFB_WEAK: [],
      TFSENT_FB: sentences.map(dailySentence),
      tfEmailFbView: { ...constructedCard(email, email.detail), weak: '' },
      tfDiscFbView: { ...constructedCard(discussion, discussion.detail), weak: '' },
      TFWFB_TYPES: [
        { key: 's', name: NAMES.build_a_sentence, score: ratioBand(sentenceCount.correct_count, sentenceCount.item_count) },
        { key: 'e', name: NAMES.write_an_email, score: taskBand(result('write_an_email').task_score) },
        { key: 'd', name: NAMES.academic_discussion, score: taskBand(result('academic_discussion').task_score) },
      ],
      TFWFB_QS: {
        s: mockSentences.map(mockSentence),
        e: [constructedCard(mockEmail, result('write_an_email'))],
        d: [constructedCard(mockDiscussion, result('academic_discussion'))],
      },
    },
  };
}

exports.build = (config) => ({ ...dailyReading(config), ...mockReading(config), ...writing(config) });
