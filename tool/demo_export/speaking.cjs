// 雅思口语：日常 Part 1–3 的题目与练习回顾页，模考口语的题目与计时。
// 数据全部来自后端已存的结果：ielts_attempts（逐题的题目与转写、评分、语法问题）、ielts_generated_items（题目）、
// 能力分析的弱项（assessment_observations + assessment_error_tags，中英两份）、
// ielts_mock_exam_sessions（模考的计时方案）。
const { one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');
const { spoken, audio, clip } = require('./media.cjs');

// 演示学员的哪三次日常作答（ielts_attempts.id），每个 Part 一次：挑质量检查通过、没有质量警告、
// 转写最完整的一次。回顾页按 Part 显示对应那一次的分数、分项、弱项和逐题。
// 模考口语问的也是这三次作答的题（2026-09-30 定）：模考走完进的就是这张回顾页，看到、听到的每道题
// 回顾页上都得有。
const ATTEMPTS = {
  p1: '88213563-b7af-4744-a989-1aba8928a120',
  p2: 'de733c07-a358-4358-8268-3a2fee9da835',
  p3: '3da0783a-9216-4239-a016-fcaaae72e79b',
};
// 模考口语各 Part 的计时取这一场的方案（ielts_mock_exam_sessions.id，唯一一场已完成的）。它按时交卷但一题
// 都没录上（0/14 题，整场 0 分），题目和成绩都不用它。
const MOCK_SESSION = '12f6e3bb-00fe-4f72-a2f5-a81d3a18b70b';

// 考官的原音频：Part 1 / Part 3 的提问当时是后端用这个音色读的，读完留在朗读缓存里（media.cjs 的 spoken）。
// 练习页和模考页问这些题时放的就是它（lib/features/oral_daily/controller.dart 的 NativeOralSpeech）；
// Part 2 的题卡没有音频，页面上本来就有文字。
const EXAMINER_VOICE = 'en-GB-RyanNeural';

// 回顾页四张分项卡（中文名是原型的，英文界面由词典译）；发音只有测评指标，后端不折算成分数。
const CRITERIA = [
  ['fluency_and_coherence', '流利度与连贯性'],
  ['lexical_resource', '词汇资源'],
  ['grammatical_range_and_accuracy', '语法多样性与准确性'],
];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** 只认演示学员自己的作答：号主同意公开的是这一位，id 写成别人的就查不到、直接报错。 */
function attempt(id, learner) {
  return one(
    `select jsonb_build_object(
      'at', a.attempted_at, 'item', g.content, 'response', a.response_text,
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
     where a.id = ${lit(id)} and a.module = 'speaking' and a.user_id::text like ${lit(`${learner}%`)}`,
    `speaking attempt ${id}`,
  );
}

/** 那场模考的计时方案：各阶段的 id 和时长。 */
function mockPlan(id, learner) {
  return one(
    `select s.exam_plan_snapshot->'groups'
     from ielts_mock_exam_sessions s where s.id = ${lit(id)} and s.module = 'speaking' and s.status = 'completed'
       and s.user_id::text like ${lit(`${learner}%`)}`,
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
  // Part 2 回顾页只有一张卡：放整段 Part 2 的作答（长陈述加追问的回答）。评分、引文、弱项看的都是这一整段，
  // 只放长陈述那一轮的话，一半引文在页面上找不到出处。考官那一栏相应地列出题卡和后面的追问，一句一行。
  const turns = part === 'p2'
    ? [{ q: a.turns.map((t) => t.q).join('\n'), a: a.response, ms: Number(a.seconds) * 1000 }]
    : a.turns;
  // 没有转写的那一轮在页面上是一张空卡：换一次作答，别悄悄导出去。
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
        q: t.q, // 考官问的原话；回顾页每张卡都写出来（原型只有 Part 3 写）
        dur: duration(t.ms),
        ans: t.a,
        tags: grammarIn(t.a, a.grammar).map((g) => ['语法多样性与准确性', `"${g.original}" → "${g.correction}"`, g.explanation, 'warn']),
      })),
    },
  };
}

const seconds = (groups, id) => groups.find((g) => g.id === id).timing_policy.duration_seconds;

/**
 * 练习页和模考页上看到、听到的题，必须就是回顾页上讲的那几题：Part 1 / 3 的题目表要和那次作答里逐轮问出去的
 * 一字不差，Part 2 的题卡（话题加要点）要都在当时问出去的原话里。对不上（比如挑了追问是现场生成的作答）就报错。
 */
function askedQuestions(a) {
  const asked = Object.fromEntries(['p1', 'p3'].map((part) => [part, a[part].turns.map((t) => t.q)]));
  for (const [part, list] of Object.entries(asked)) {
    const task = a[part].item.questions.map((q) => q.question);
    if (JSON.stringify(task) !== JSON.stringify(list)) {
      throw new Error(`speaking ${part}: the task's questions are not the ones asked in the attempt, pick another attempt`);
    }
  }
  const cue = a.p2.item.cue_card;
  const cueAsked = a.p2.turns[0].q;
  if (![cue.topic, ...cue.points].every((line) => words(cueAsked).includes(words(line)))) {
    throw new Error('speaking p2: the cue card is not what the attempt was asked, pick another attempt');
  }
  return { ...asked, cue, cueAsked };
}

exports.build = ({ learner }) => {
  const a = Object.fromEntries(Object.entries(ATTEMPTS).map(([part, id]) => [part, attempt(id, learner)]));
  const { p1, p3, cue, cueAsked } = askedQuestions(a);
  const plan = mockPlan(MOCK_SESSION, learner);
  const examiner = {}; // 题目原文 → { asset, sec }
  const sounds = {};
  for (const [part, questions] of [['p1', p1], ['p3', p3]]) {
    questions.forEach((q, i) => {
      const name = `aud_examiner_${part}_${i + 1}.mp3`;
      const sound = audio(spoken(q, [EXAMINER_VOICE], `examiner audio ${part} question ${i + 1}`), name);
      sounds[name] = sound.bytes;
      examiner[q] = clip(name, sound.sec);
    });
  }
  return {
    ...sounds,
    'questions.json': {
      ielts: {
        speaking: {
          examinerAudio: examiner,
          daily: {
            part1: { topic: a.p1.item.topic, questions: p1 },
            part2: { cue: cue.topic, points: cue.points, pointsZh: [] },
            // rounds：那次作答实际问了几轮（原型固定 10 轮、题目循环着问），练习页和回顾页的轮数才对得上。
            part3: { topic: a.p3.item.topic, questions: p3, rounds: p3.length },
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
      // 题目是上面三次日常作答的题，计时是那场真实模考的方案。
      SPQ: {
        p1: { n: p1.length, sec: seconds(plan, 'speaking_part_1'), qs: p1 },
        // 题卡：话题加要点（原型那行「你应该谈到:」不动）；念出来的是当时问出去的原话。
        p2: { card: { title: cue.topic, bullets: cue.points }, qs: [cueAsked] },
        p3: { n: p3.length, sec: seconds(plan, 'speaking_part_3'), qs: p3 },
      },
      SP3_TOTAL: seconds(plan, 'speaking_part_3'),
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
  // 练习页 / 模考页的题必须是回顾页讲的题：题目表和问出去的对不上、题卡不在问出去的原话里，都要报错。
  const task = (qs) => ({ item: { questions: qs.map((question) => ({ question })) }, turns: qs.map((q) => ({ q })) });
  const cueCard = { topic: 'Describe a trip.', points: ['where you went', 'and explain why you remember it.'] };
  const part2 = (q) => ({ item: { cue_card: cueCard }, turns: [{ q }, { q: 'Anything else?' }] });
  const ok = { p1: task(['A?', 'B?']), p2: part2('Describe a trip. — where you went — and explain why you remember it.'), p3: task(['C?']) };
  assert.deepStrictEqual(askedQuestions(ok).p1, ['A?', 'B?']);
  assert.throws(() => askedQuestions({ ...ok, p3: { ...task(['C?']), turns: [{ q: 'C?' }, { q: 'a follow-up made up on the spot' }] } }), /p3/);
  assert.throws(() => askedQuestions({ ...ok, p2: part2('Describe a trip. — where you went') }), /p2/);
  // 逐题转写是小写、无标点、撇号前带空格的；整篇里摘的原句带标点。找不到的（转写写法不同）不挂。
  const answer = "then makes makes sound like everything 's mostly and on two time";
  assert.deepStrictEqual(
    grammarIn(answer, [{ original: "Then makes makes sound like everything's mostly." }, { original: 'a plan of 1/2 of day' }]),
    [{ original: "Then makes makes sound like everything's mostly." }],
  );
  console.log('speaking.cjs self-check ok');
}
