// 雅思口语：日常 Part 1–3 的题目与练习回顾页，模考口语的题目与计时。
// 数据全部来自后端已存的结果：ielts_attempts（逐题转写、评分、语法问题）、ielts_generated_items（题目）、
// 能力分析的弱项（assessment_observations + assessment_error_tags，中英两份）、
// ielts_mock_exam_sections / items / sessions（模考题目与计时方案）。
const { one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');

// 演示学员的哪三次日常作答（ielts_attempts.id），每个 Part 一次：挑质量检查通过、没有质量警告、
// 转写最完整的一次。回顾页按 Part 显示对应那一次的分数、分项、弱项和逐题。
const ATTEMPTS = {
  p1: '88213563-b7af-4744-a989-1aba8928a120',
  p2: 'de733c07-a358-4358-8268-3a2fee9da835',
  p3: '3da0783a-9216-4239-a016-fcaaae72e79b',
};
// 模考口语的题目用这一场（ielts_mock_exam_sessions.id，唯一一场已完成的）。它按时交卷但一题都没录上
// （0/14 题，整场 0 分、各项 not_demonstrated），所以成绩页不用它：模考模式的回顾页仍按 Part 显示上面三次日常作答。
const MOCK_SESSION = '12f6e3bb-00fe-4f72-a2f5-a81d3a18b70b';

// 回顾页四张分项卡（中文名是原型的，英文界面由词典译）；发音只有测评指标，后端不折算成分数。
const CRITERIA = [
  ['fluency_and_coherence', '流利度与连贯性'],
  ['lexical_resource', '词汇资源'],
  ['grammatical_range_and_accuracy', '语法多样性与准确性'],
];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function attempt(id) {
  return one(
    `select jsonb_build_object(
      'at', a.attempted_at, 'item', g.content,
      'range', a.detail->'estimated_band_range', 'criteria', a.detail->'criterion_estimates',
      'fixes', a.detail->'priority_fixes', 'grammar', a.detail->'grammar_issues',
      'pron', a.detail->'pronunciation_evidence', 'seconds', a.detail->'speech_metrics'->'durationSeconds',
      'turns', (select jsonb_agg(jsonb_build_object('q', t->>'question_text', 'a', t->>'transcript', 'ms', t->'duration_ms'))
                from jsonb_array_elements(a.detail->'dialogue_turns') t),
      -- 与正式客户端的弱项面板同一来源：这次作答最新一轮能力分析里的负向弱项，按出现顺序。
      'findings', (select coalesce(jsonb_agg(jsonb_build_object(
                     'label', coalesce(t.labels, o.evidence->'layer2'->'label', o.evidence->'layer1'->'label'),
                     'items', o.evidence->'items', 'why', o.evidence->'explanation', 'drill', t.suggested_activities)
                   order by o.observed_at, o.id), '[]')
                   from assessment_observations o left join assessment_error_tags t on t.uid = o.error_tag_uid
                   where o.direction = 'negative'
                     and o.detector in ('weakness_v1_rule', 'weakness_v1_llm', 'weakness_v2_rule', 'weakness_v2_llm')
                     and o.analysis_run_id = (select r.id from assessment_analysis_runs r where r.user_id = a.user_id
                       and r.source_type = 'ielts_practice' and r.source_result_id = a.id order by r.created_at desc limit 1)))
     from ielts_attempts a join ielts_generated_items g on g.id = a.generated_item_id
     where a.id = ${lit(id)} and a.module = 'speaking'`,
    `speaking attempt ${id}`,
  );
}

function mockSession(id) {
  return one(
    `select jsonb_build_object(
      'groups', s.exam_plan_snapshot->'groups',
      'parts', (select jsonb_agg(jsonb_build_object('c', sc.public_content,
                 'qs', (select jsonb_agg(i.public_content->>'prompt' order by i.ordinal)
                        from ielts_mock_exam_items i where i.section_id = sc.id)) order by sc.ordinal)
                from ielts_mock_exam_sections sc where sc.session_id = s.id))
     from ielts_mock_exam_sessions s where s.id = ${lit(id)} and s.module = 'speaking' and s.status = 'completed'`,
    `speaking mock session ${id}`,
  );
}

/** 83072 → "1:23"，18400 → "18s"（原型的写法）。 */
function duration(ms) {
  const s = Math.round(Number(ms) / 1000);
  return s < 60 ? `${s}s` : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

/** 「9 月 16 日 15:42 完成 · 2 min」一对；学员在国内，按北京时间（UTC+8，没有夏令时）。 */
function completed(at, seconds) {
  const t = new Date(Date.parse(at) + 8 * 3600e3);
  const hm = `${String(t.getUTCHours()).padStart(2, '0')}:${String(t.getUTCMinutes()).padStart(2, '0')}`;
  const min = `${Math.max(1, Math.round(Number(seconds) / 60))} min`;
  return [
    `Completed ${t.getUTCDate()} ${MONTHS[t.getUTCMonth()]}, ${hm} · ${min}`,
    `${t.getUTCMonth() + 1}月${t.getUTCDate()}日完成, ${hm} · ${min}`,
  ];
}

const words = (s) => ` ${String(s).toLowerCase().replace(/\s+'/g, "'").replace(/[^a-z0-9']+/g, ' ').trim()} `;

/** 这一题的回答里出现了的语法问题（与正式客户端相同：按词比对原句，找不到的不挂到任何一题上）。 */
const grammarIn = (answer, issues) => (issues || []).filter((g) => words(answer).includes(words(g.original)));

/** 回顾页的一个 Part：总分、分项、弱项、逐题。 */
function review(part, a) {
  const turns = part === 'p2' ? a.turns.slice(0, 1) : a.turns; // Part 2 回顾页只有长陈述一张卡，追问不在这页
  // 早期的 Part 2 作答没有逐题转写，页面上会是一张空卡：换一次作答，别悄悄导出去。
  if (turns.some((t) => !t.a)) throw new Error(`speaking ${part}: a turn has no transcript, pick another attempt`);
  return {
    // 2026-09-25 以前存的是 ±0.5 的区间，后端与正式客户端都取中点作为唯一的练习估分。
    score: band((Number(a.range.low) + Number(a.range.high)) / 2),
    meta: completed(a.at, a.seconds),
    // 正式客户端估分卡下面那句：第一条优先改进项（只有英文）。
    summary: a.fixes?.[0],
    criteria: [
      ...CRITERIA.map(([key, zh]) => {
        const c = a.criteria[key];
        return { zh, sc: band(c.practice_band_estimate), en: c.feedback, quotes: (c.evidence || []).map((q) => `"${q}"`) };
      }),
      { zh: '发音', sc: null, en: [a.criteria.pronunciation?.note, ...(a.pron || [])].filter(Boolean).join(' '), quotes: [] },
    ],
    weaks: a.findings.map((f) => {
      const quote = (f.items || []).find((i) => i.source === 'learner_answer' && i.quote)?.quote;
      return {
        en: pair(f.label.en, f.label.zh),
        ...(quote ? { quote: `"${quote}"` } : {}),
        tip: pair([f.why?.en, f.drill?.en].filter(Boolean).join(' '), [f.why?.zh, f.drill?.zh].filter(Boolean).join('')),
      };
    }),
    items: {
      [part]: turns.map((t) => ({
        ...(part === 'p3' ? { q: t.q } : {}),
        dur: duration(t.ms),
        ans: t.a,
        tags: grammarIn(t.a, a.grammar).map((g) => ['语法多样性与准确性', `"${g.original}" → "${g.correction}"`, g.explanation, 'warn']),
      })),
    },
  };
}

const questions = (item) => item.questions.map((q) => q.question);
const seconds = (groups, id) => groups.find((g) => g.id === id).timing_policy.duration_seconds;

exports.build = () => {
  const a = Object.fromEntries(Object.entries(ATTEMPTS).map(([part, id]) => [part, attempt(id)]));
  const cue = a.p2.item.cue_card;
  const mock = mockSession(MOCK_SESSION);
  const [m1, m2, m3] = mock.parts;
  return {
    'questions.json': {
      ielts: {
        speaking: {
          daily: {
            part1: { topic: a.p1.item.topic, questions: questions(a.p1.item) },
            part2: { cue: cue.topic, points: cue.points, pointsZh: [] },
            // rounds：那次作答实际问了几轮（原型固定 10 轮、题目循环着问），练习页和回顾页的轮数才对得上。
            part3: { topic: a.p3.item.topic, questions: questions(a.p3.item), rounds: a.p3.turns.length },
          },
        },
      },
    },
    'speaking_review.json': {
      daily: Object.fromEntries(Object.entries(a).map(([part, x]) => [part, review(part, x)])),
      // 顶层是原型那份示例评语；三个 Part 都有 daily，页面用不到它，清空，免得示例内容混进演示包。
      score: '', criteria: [], weaks: [], items: { p1: [], p2: [], p3: [] }, cuePoints: [], p3Overall: null,
    },
    'ielts_mock_speaking.json': {
      SPQ: {
        p1: { n: m1.qs.length, sec: seconds(mock.groups, 'speaking_part_1'), qs: m1.qs },
        // 模考的 Part 2 题卡只有话题一句，没有「你应该谈到」的要点；题卡下面放这一节的作答说明。
        // 两道追问（ordinal 2、3）在原型的 Part 2 流程里没有位置，不放。
        p2: { card: { title: m2.c.topic, lead: m2.c.instructions, bullets: [] }, qs: m2.qs.slice(0, 1) },
        p3: { n: m3.qs.length, sec: seconds(mock.groups, 'speaking_part_3'), qs: m3.qs },
      },
      SP3_TOTAL: seconds(mock.groups, 'speaking_part_3'),
    },
  };
};

// 自检：node tool/demo_export/speaking.cjs（不连库）。
if (require.main === module) {
  const assert = require('assert');
  assert.strictEqual(duration(83072), '1:23');
  assert.strictEqual(duration(9400), '9s');
  assert.deepStrictEqual(completed('2026-09-16T07:42:46.98+00:00', 116.2), ['Completed 16 Sep, 15:42 · 2 min', '9月16日完成, 15:42 · 2 min']);
  assert.deepStrictEqual(completed('2026-12-31T16:05:00+00:00', 20), ['Completed 1 Jan, 00:05 · 1 min', '1月1日完成, 00:05 · 1 min']);
  // 逐题转写是小写、无标点、撇号前带空格的；整篇里摘的原句带标点。找不到的（转写写法不同）不挂。
  const answer = "then makes makes sound like everything 's mostly and on two time";
  assert.deepStrictEqual(
    grammarIn(answer, [{ original: "Then makes makes sound like everything's mostly." }, { original: 'a plan of 1/2 of day' }]),
    [{ original: "Then makes makes sound like everything's mostly." }],
  );
  console.log('speaking.cjs self-check ok');
}
