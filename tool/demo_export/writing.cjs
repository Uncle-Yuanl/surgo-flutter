// 雅思写作：日常 Task 1（柱状图）/ Task 2 的题目、写作规划、评分页（批注 + 母语负迁移）。
// 数据全部来自后端已存的结果：ielts_attempts（作文、评分）、ielts_generated_items（题目）、
// 私有素材里的 visual_spec（图的数据）、ielts_writing_artifacts（plan / l1_check）。
const { one, lit } = require('./db.cjs');
const { band, halfBand, pair, annotate } = require('./text.cjs');

// 演示学员的哪两次作答（ielts_attempts.id）：Task 1 要柱状图题，页面按数列原生画柱。
const ATTEMPTS = {
  task1: '1a0721f0-53c1-487c-98b1-66de239543fe',
  task2: '3cd0354a-b33d-48ea-9876-6d5947a3c288',
};

// 原型四项的中文名（词典里有英文）；后端 criteria 的键，Task 2 第一项可能叫 task_response。
const CRITERIA = [
  { keys: ['task_achievement', 'task_response'], zh: '任务完成情况', en: 'Task achievement' },
  { keys: ['coherence_cohesion'], zh: '连贯与衔接', en: 'Coherence & cohesion' },
  { keys: ['lexical_resource'], zh: '词汇资源', en: 'Lexical resource' },
  { keys: ['grammatical_range', 'grammatical_range_accuracy'], zh: '语法', en: 'Grammatical range & accuracy' },
];
const L1_TYPES = {
  vocabulary: ['Word choice', '用词'],
  syntax: ['Sentence structure', '句式'],
  grammar: ['Grammar', '语法'],
  preposition: ['Preposition', '介词'],
  style: ['Register', '文体'],
};
const COLORS = ['#F5B301', '#7cb518', '#5b8def', '#e4572e']; // 原型的两色 + 备用

function attempt(id) {
  return one(
    `select jsonb_build_object(
      'band', a.band, 'detail', a.detail, 'essay', a.response_text, 'topic', g.topic,
      'item', g.content, 'spec', m.material->'visual_spec',
      'plan', (select w.content from ielts_writing_artifacts w where w.generated_item_id = a.generated_item_id
               and w.user_id = a.user_id and w.kind = 'plan' order by w.created_at desc limit 1),
      'l1', (select w.content from ielts_writing_artifacts w where w.generated_item_id = a.generated_item_id
             and w.user_id = a.user_id and w.kind = 'l1_check' order by w.created_at desc limit 1))
     from ielts_attempts a join ielts_generated_items g on g.id = a.generated_item_id
     left join ielts_generated_item_private_material m on m.generated_item_id = a.generated_item_id
     where a.id = ${lit(id)} and a.module = 'writing'`,
    `writing attempt ${id}`,
  );
}

const crit = (detail, c) => c.keys.map((k) => detail.criteria?.[k]).find(Boolean) || {};
const weakText = (x) => (x.weaknesses || []).join(' ');

/** 评分页一块：总评、四项（✓ 优点 / ↑ 不足或提分方向）、提分建议、批注、母语负迁移。 */
function review(a) {
  const d = a.detail;
  const scored = CRITERIA.map((c) => ({ c, x: crit(d, c) }));
  const withWeak = scored.filter(({ x }) => weakText(x));
  const upgrades = annotate(a.essay, d.academic_upgrades || [], (u) => u.original, 'wf-hl');
  const l1 = annotate(a.essay, a.l1?.errors || [], (e) => e.original_text, 'wf-hl-p');
  return {
    block: {
      band: band(a.band),
      descEn: d.overall_feedback,
      descZh: d.overall_feedback_cn || d.overall_feedback,
      crit: scored.map(({ c, x }) => ({
        name: c.zh,
        sc: band(x.band),
        ok: pair((x.strengths || []).join(' ')),
        up: weakText(x) ? pair(weakText(x)) : pair(x.upgrade_tip, x.upgrade_tip_cn),
      })),
      // 「不足」那行已经用了提分方向的项，这里只放有不足的项的提分方向，避免重复。
      tips: (withWeak.length ? withWeak : scored.slice(0, 2)).map(({ c, x }) => ({
        name: c.zh,
        items: [pair(x.upgrade_tip, x.upgrade_tip_cn)],
      })),
    },
    essay: upgrades.text,
    notes: upgrades.items.map(({ n, item: u }) => ({
      n, old: u.original, neu: u.improved, en: '', zh: '', whyEn: u.reason, whyZh: u.reason_cn || u.reason,
    })),
    l1Essay: l1.text,
    l1Summary: pair(a.l1?.overall_assessment_en, a.l1?.overall_assessment_cn),
    l1Items: l1.items.map(({ n, item: e }) => {
      const [title, zh] = L1_TYPES[e.error_type] || ['Language transfer', '母语迁移'];
      return {
        n, title, zh, old: e.original_text, neu: e.corrected_text,
        en: e.explanation_en, cn: e.explanation_cn || e.explanation_en, whyZh: '', tip: '',
      };
    }),
  };
}

/** 薄弱项：分最低的一项（同分取第一项），配它的提分方向。 */
function weakest(a, task) {
  const { c, x } = CRITERIA.map((cc) => ({ c: cc, x: crit(a.detail, cc) }))
    .reduce((m, e) => (Number(e.x.band) < Number(m.x.band) ? e : m));
  return {
    label: [`Task ${task} · ${c.en} ${band(x.band)}`, `Task ${task} · ${c.zh} ${band(x.band)}`],
    text: pair(x.upgrade_tip, x.upgrade_tip_cn),
  };
}

function chartTask(a) {
  const fig = (a.spec?.figures || []).find((f) => f.visual_type === 'bar_chart');
  if (!fig) throw new Error('writing task1: pick a bar_chart item (the page draws grouped bars natively)');
  const unit = fig.unit && !fig.title.includes(`(${fig.unit})`) ? ` (${fig.unit})` : '';
  return {
    type: 't1chart',
    title: a.topic || fig.title,
    prompt: a.item.prompt,
    minWords: a.item.minimum_words || 150,
    minutes: a.item.time_limit_minutes || 20,
    chartTitle: fig.title + unit,
    chartYears: fig.payload.categories.map((c) => c.label),
    chartSeries: fig.payload.series.map((s, i) => ({ name: s.label, color: COLORS[i % COLORS.length], data: s.values })),
    chartDesc: a.item.data_description || fig.alt_text,
    keyPoints: [],
    hints: a.item.tips || [],
  };
}

function essayTask(a) {
  return {
    type: 't2discuss',
    title: pair(a.plan?.task_analysis?.question_type, a.plan?.task_analysis?.question_type_cn),
    prompt: a.item.prompt,
    minWords: a.item.minimum_words || 250,
    minutes: a.item.time_limit_minutes || 40,
    keyPoints: [],
    hints: a.item.tips || [],
  };
}

function plan(p) {
  return {
    args: p.thesis_options.map((o) => ({ band: '选择理由', text: pair(o.thesis, o.thesis_cn), note: pair(o.reasoning, o.reasoning_cn) })),
    parasByArg: p.thesis_options.map((o) => o.paragraph_plan.map((x) => ({
      tag: pair(x.purpose, x.purpose_cn),
      text: pair(x.topic_sentence, x.topic_sentence_cn),
      bullets: [...(x.supporting_points || []).map((s) => `- ${s}`), ...(x.example ? [`example: ${x.example}`] : [])],
    }))),
    vocab: p.vocabulary.map((v) => ({ en: v.word, zh: v.chinese, ex: v.example })),
  };
}

function analysis(p) {
  const t = p.task_analysis;
  return {
    label: pair(t.question_type, t.question_type_cn),
    requirement: pair(t.key_instruction, t.key_instruction_cn),
    detail: pair(t.analysis, t.analysis_cn),
    pitfall: pair(t.trap_to_avoid, t.trap_to_avoid_cn),
  };
}

exports.build = () => {
  const t1 = attempt(ATTEMPTS.task1);
  const t2 = attempt(ATTEMPTS.task2);
  const r1 = review(t1);
  const r2 = review(t2);
  return {
    'questions.json': {
      ielts: {
        writing: {
          daily: { task1: chartTask(t1), task2: essayTask(t2) },
          plan: { task1: plan(t1.plan), task2: plan(t2.plan) },
          analysis: { t1chart: analysis(t1.plan), t2discuss: analysis(t2.plan) },
        },
      },
    },
    'writing_review.json': {
      // 雅思写作总分：Task 2 权重是 Task 1 的两倍，四舍五入到半分。
      overall: halfBand((Number(t1.band) + 2 * Number(t2.band)) / 3),
      weak: [weakest(t1, 1), weakest(t2, 2)],
      task1: { ...r1.block, essay: r1.essay, notes: r1.notes },
      l1task1: { essay: r1.l1Essay, items: r1.l1Items, summary: r1.l1Summary },
      WF_T2: r2.block,
      WF_T2_ESSAY: r2.essay,
      WF_T2_NOTES: r2.notes,
      WF_T2_L1_ESSAY: r2.l1Essay,
      WF_T2_L1: r2.l1Items,
      WF_T2_L1_SUMMARY: r2.l1Summary,
    },
  };
};

// 模考写作（mock_writing.cjs）的评分页用同一套映射。
exports.review = review;
exports.weakest = weakest;
