// 托福听力 / 口语：日常训练（四种听力题型、听后复述、访谈）和模考（听力两阶段、口语两部分）的题目与批改页。
// 数据全部来自后端已存的结果：toefl_daily_training_*、toefl_mock_exam_*（题目、作答、判分、答案键里的
// 听力原文和原文依据、口语的音频分析），薄弱项来自能力分析（assessment_observations 的负向发现）。
// 后端存了中英两份的（口语反馈、薄弱项解释）输出 [英文, 中文]；只有英文的（题目、选项、原文）照原文。
const { rows, one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');

// 演示学员的哪几次作答：日常训练是 toefl_daily_training_sessions.id，模考是 toefl_mock_exam_sessions.id。
const DAILY = {
  respond: 'e8e4129c-b9e6-4378-a731-e85fa32305ca', // listen_choose_response，8 题
  convo: '23332d60-bd34-44e4-b2c4-ce15ee9fac06', // listen_conversation，1 段 2 题
  announce: 'b476ede3-6f07-4e9c-831f-b7c7087c9b64', // listen_announcement，1 段 3 题
  lecture: '90fc0ead-f131-4070-aefc-28c8924338a2', // listen_academic_talk，1 段 4 题
  retell: '51c77ae4-3120-4dcf-8aa8-b09d1827292e', // listen_and_repeat，7 句
  interview: '7536c3af-80c9-44fb-b758-147db834f4ab', // take_an_interview，4 问
};
const MOCK = {
  listening: '26047304-a7d6-4b57-b00d-f48b147a4296', // 两阶段 47 题；学员只答了 7 题，时间到自动交卷
  speaking: 'bfc74c71-0ff3-41fd-abf5-4efbbad4e593', // 7 句复述 + 4 问访谈，全部有录音
};

// 页面的七个听力模考模块 ← 阶段 + 题型。阶段 1 是定级卷（32 题），阶段 2 是按定级结果选中的分支卷（15 题）。
const MOCK_MODULES = {
  listen: [1, 'listen_choose_response'],
  conv: [1, 'listen_conversation'],
  ann: [1, 'listen_announcement'],
  talk: [1, 'listen_academic_talk'],
  m2p1: [2, 'listen_choose_response'],
  m2p2: [2, 'listen_conversation'],
  m2p3: [2, 'listen_announcement'],
};
const LISTENING_TYPES = {
  listen_choose_response: ['r', 'Listen and Choose a Response'],
  listen_conversation: ['c', 'Listen to a Conversation'],
  listen_announcement: ['a', 'Listen to an Announcement'],
  listen_academic_talk: ['t', 'Listen to an Academic Talk'],
};
const BRANCH_LEVEL = { foundation: ['Lower', '低阶'], advanced: ['Upper', '高阶'] };
// 口语四项（后端 CONSTRUCTED_CRITERIA 的顺序）。英文名是键名；中文名前五个照正式客户端，
// 访谈的后三项正式客户端没有译名，用后端中文反馈里自己的叫法（「相关性和内容展开都不及格，语言控制也很弱」）。
const CRITERIA = {
  listen_and_repeat: ['accuracy', 'completeness', 'intelligibility', 'prosody'],
  take_an_interview: ['delivery', 'language_control', 'relevance', 'development'],
};
const CRITERION_ZH = {
  accuracy: '准确度', completeness: '复述完整度', intelligibility: '可懂度', prosody: '韵律', delivery: '表达',
  language_control: '语言控制', relevance: '相关性', development: '内容展开',
};

const mean = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;
/** 0–5 的题目分 → 2026 版 1–6 分（半分）。后端 toefl2026Primitives.bandFieldsFromTaskScore 的同一公式。 */
const toeflBand = (taskScore) => band(Math.max(1, Math.min(6, Math.round((1 + Number(taskScore)) * 2) / 2)));
const secs = (ms) => Math.max(1, Math.round(Number(ms) / 1000));
const clock = (ms) => `${String(Math.floor(secs(ms) / 60)).padStart(2, '0')}:${String(secs(ms) % 60).padStart(2, '0')}`;
const option = (x, id) => {
  const o = x.options.find((v) => v.id === id);
  return o ? `${o.id}. ${o.text}` : id;
};

/**
 * 一次作答最新一轮已完成分析里的负向发现：错误标签、三层能力和解释（中英）。
 * structured-evidence-v8 是后端当前的分析版本（src/db/assessment.js 的 DEFAULT_ANALYZER_VERSION）。
 */
const findingsOf = (sourceType, sourceId) => `coalesce((select jsonb_agg(jsonb_build_object(
      'tag', t.labels, 'area', o.evidence#>'{layer0,label}', 'skill', o.evidence#>'{layer1,label}',
      'can', o.evidence#>'{layer2,label}', 'why', o.evidence->'explanation') order by o.observed_at, o.id)
    from assessment_observations o left join assessment_error_tags t on t.uid = o.error_tag_uid
    where o.direction = 'negative'
      and o.detector in ('weakness_v1_rule', 'weakness_v1_llm', 'weakness_v2_rule', 'weakness_v2_llm')
      and o.analysis_run_id = (select r.id from assessment_analysis_runs r
        where r.source_type = ${lit(sourceType)} and r.source_result_id = ${sourceId}
          and r.analyzer_version = 'structured-evidence-v8' and r.status = 'completed'
        order by r.created_at desc, r.id desc limit 1)), '[]'::jsonb)`;

/**
 * 薄弱项卡片，写法同正式客户端的发现卡：「上一层能力 → 错误标签」加解释。同一个标签只留一张
 * （后端按标签合并，解释取第一条）；知道是哪几题的（日常听力按题分析）在前面标题号。
 */
function weakCards(moduleZh, found) {
  const cards = new Map();
  for (const { f, n } of found) {
    const primary = f.tag || f.can || f.skill;
    const parent = f.tag || f.can ? f.skill : f.area;
    if (!primary || !parent || !f.why) continue;
    const card = cards.get(primary.en) || { f, primary, parent, ns: [] };
    if (n) card.ns.push(n);
    cards.set(primary.en, card);
  }
  return [...cards.values()].map(({ f, primary, parent, ns }) => ({
    tags: [moduleZh, ...(f.area ? [pair(f.area.en, f.area.zh)] : [])],
    q: pair(
      `${ns.length ? `Q${ns.join(', Q')} · ` : ''}${parent.en} → ${primary.en}`,
      `${ns.length ? `第 ${ns.join('、')} 题 · ` : ''}${parent.zh} → ${primary.zh}`,
    ),
    a: pair(f.why.en, f.why.zh),
  }));
}

/**
 * 听力原文：每段录音一段，每题的原文依据标上题号（页面按这题对错着色）。
 * 行的格式是页面认的 [前文, 依据, 题号, 后文]；原文里找不到依据或与已标的重叠的题不标。
 */
function transcriptRows(passages) {
  const out = [];
  passages.forEach(({ text, marks }, i) => {
    let pos = 0;
    let pre = i ? '\n\n' : '';
    const hits = marks
      .map((m) => ({ ...m, at: m.span ? text.indexOf(m.span) : -1 }))
      .filter((h) => h.at >= 0)
      .sort((a, b) => a.at - b.at);
    for (const h of hits) {
      if (h.at < pos) continue;
      out.push([pre + text.slice(pos, h.at), h.span, h.n, '']);
      pre = '';
      pos = h.at + h.span.length;
    }
    if (pos < text.length) out.push([pre + text.slice(pos)]);
  });
  return out;
}

/** 按录音分段：同一段录音的题排在一起。 */
const passagesOf = (list, nOf) => [...new Set(list.map((x) => x.audio))].map((audio) => {
  const own = list.filter((x) => x.audio === audio);
  return { text: own[0].transcript, marks: own.map((x) => ({ n: nOf(x), span: x.support })) };
});

// 听力的录音文件（文件名 → MP3 字节）：dailyListening / mockListening 读出来先收在这里，build 一起交出去。
const LISTENING_AUDIO = {};

/**
 * 给每道题挂上它那段录音（页面认的 clip：{ asset, sec }），做题页和批改页就真的放它。录音是后端存档里
 * 挂在这道题上的那一份（x.stored：*_media_assets 里 purpose = 'listening_prompt'、state = 'attached' 的对象），
 * 读出来按库里记的 sha256 / 大小核对。同一段录音的几道题共用一个文件；文件名按出场顺序编号，不带库里的 id。
 * 没挂上录音的题不带 clip，页面那一段照旧走原型的模拟播放。
 */
function attachClips(list, prefix) {
  // media.cjs 只有这里用，就在这里 require：文件头那几行，口语那半边同时在改。
  const { object, audio, clip } = require('./media.cjs');
  const clips = new Map(); // 录音（media asset）→ clip
  for (const x of list) {
    if (!x.stored) continue;
    if (!clips.has(x.audio)) {
      const name = `${prefix}_${clips.size + 1}.mp3`;
      const sound = audio(object(x.stored, name), name);
      LISTENING_AUDIO[name] = sound.bytes;
      clips.set(x.audio, clip(name, sound.sec));
    }
    x.clip = clips.get(x.audio);
  }
}

/** 这道题的录音多长（毫秒）：带了录音就是成品量出来的时长（页面的时间和进度才对得上真的在放的那段），否则是库里记的。 */
const heardMs = (x) => (x.clip ? x.clip.sec * 1000 : x.ms);

/** 做题页的一段：录音时长（秒）、同一段录音的序号、情境说明（每段录音的第一题带）、题干和选项、录音文件。 */
function segments(list, audioKey, grouped) {
  const audios = [...new Set(list.map((x) => x.audio))];
  return list.map((x, i) => ({
    sec: secs(heardMs(x)),
    ...(grouped ? { [audioKey]: audios.indexOf(x.audio) } : {}),
    ...(grouped && x.context && list.findIndex((y) => y.audio === x.audio) === i ? { lead: x.context } : {}),
    ...(x.clip ? { clip: x.clip } : {}),
    q: x.prompt,
    opts: x.options.map((o) => [o.id, o.text]),
  }));
}

/** 逐题分析的一张卡。听后选择回应的题干都是同一句指令，题目栏放听到的那句话。 */
function questionCard(x, n, ok) {
  const why = x.findings?.[0]?.why;
  return {
    n,
    ok,
    dur: clock(heardMs(x)),
    ...(x.clip ? { clip: x.clip } : {}),
    q: x.type === 'listen_choose_response' ? `"${x.transcript}"` : x.prompt,
    mine: x.choice ? option(x, x.choice) : '—',
    ...(ok ? {} : { ans: option(x, x.answer) }),
    ...(why ? { why: pair(why.en, why.zh), evi: `"${x.support}"` } : {}),
  };
}

function dailyListening(kind, learner) {
  const id = DAILY[kind];
  const items = rows(
    `select jsonb_build_object(
      'n', i.ordinal, 'type', i.item_type, 'prompt', i.public_content->>'prompt', 'options', i.public_content->'options',
      'context', i.public_content#>>'{context,0,text}', 'audio', i.marking_key->>'media_asset_id', 'ms', m.duration_ms,
      'stored', case when m.purpose = 'listening_prompt' and m.state = 'attached' and m.user_id = s.user_id
        then jsonb_build_object('scope', 'user', 'key', m.object_key, 'sha256', m.sha256, 'size', m.size_bytes) end,
      'answer', i.marking_key#>>'{accepted_responses,0}', 'transcript', i.marking_key->>'listening_transcript',
      'support', i.marking_key->>'source_support', 'choice', r.response->>'choice',
      'score', a.task_score, 'outcome', a.result_detail->>'outcome', 'findings', ${findingsOf('toefl_daily', 'a.id')})
     from toefl_daily_training_items i
     join toefl_daily_training_sessions s on s.id = i.session_id
     join toefl_daily_training_attempts a on a.item_id = i.id
     left join toefl_daily_training_responses r on r.item_id = i.id
     left join toefl_daily_training_media_assets m on m.id::text = i.marking_key->>'media_asset_id'
     where s.id = ${lit(id)} and s.status = 'completed' and s.user_id::text like ${lit(`${learner}%`)}
     order by i.ordinal`,
  );
  if (!items.length) throw new Error(`toefl daily ${kind} ${id}: no scored items for this learner`);
  attachClips(items, `aud_tf_listening_${kind}`);
  const right = items.filter((x) => x.outcome === 'matched').length;
  return {
    total: items.length,
    segments: segments(items, 'aud', kind !== 'respond'),
    weak: weakCards('听力', items.flatMap((x) => x.findings.map((f) => ({ f, n: x.n })))),
    questions: items.map((x) => questionCard(x, x.n, x.outcome === 'matched')),
    // 「听后选择回应」听到的那句话已经在每张题卡的题目栏里，不再另放原文（原型也没有）。
    source: kind === 'respond' ? [] : transcriptRows(passagesOf(items, (x) => x.n)),
    // 一次日常训练的分：题目分先平均再换算（后端 sessionBandFromTaskScores）。
    score: toeflBand(mean(items.map((x) => Number(x.score)))),
    description: pair(`${right} of ${items.length} correct`, `答对 ${right} / ${items.length} 题`),
  };
}

/** 口语四项的分（各题平均后换算成 1–6），平均分最高的一项标绿、最低的标红。 */
function criterionScores(type, results) {
  const scored = CRITERIA[type].map((key) => {
    const en = key.split('_').map((p) => p[0].toUpperCase() + p.slice(1)).join(' ');
    return { label: [en, CRITERION_ZH[key]], raw: mean(results.map((r) => Number(r.criteria[key]))) };
  });
  const lo = Math.min(...scored.map((s) => s.raw));
  const hi = Math.max(...scored.map((s) => s.raw));
  return scored.map((s) => ({
    label: s.label,
    v: toeflBand(s.raw),
    c: lo === hi ? '' : s.raw === hi ? 'ok' : s.raw === lo ? 'bad' : '',
  }));
}

/** 口语逐题卡：考官说的原句、两段录音的时长、这一题的分和反馈；复述题带完整度（语音评测的 0–100）。 */
function speakingCard(n, x, result, completeness) {
  return {
    n,
    score: toeflBand(result.task_score),
    dur: `00:00 / ${clock(x.ms)}`,
    myDur: `00:00 / ${clock(x.recMs)}`,
    ...(completeness == null ? {} : { pct: Math.round(Number(completeness)) }),
    fb: pair(result.feedback_en, result.feedback_cn),
  };
}

function dailySpeaking(kind, learner) {
  const id = DAILY[kind];
  const items = rows(
    `select jsonb_build_object(
      'n', i.ordinal, 'type', i.item_type, 'text', i.marking_key->>'source_text',
      'ansSec', (i.public_content->>'response_seconds')::int, 'ms', m.duration_ms, 'recMs', rc.duration_ms,
      'result', a.result_detail - 'training_context')
     from toefl_daily_training_items i
     join toefl_daily_training_sessions s on s.id = i.session_id
     join toefl_daily_training_attempts a on a.item_id = i.id
     left join toefl_daily_training_recordings rc on rc.id = a.recording_id
     left join toefl_daily_training_media_assets m on m.id::text = i.marking_key->>'media_asset_id'
     where s.id = ${lit(id)} and s.status = 'completed' and s.user_id::text like ${lit(`${learner}%`)}
     order by i.ordinal`,
  );
  if (!items.length) throw new Error(`toefl daily ${kind} ${id}: no scored items for this learner`);
  // 口语整场只分析一次，分析挂在场次上。
  const found = one(`select ${findingsOf('toefl_daily', lit(id))}`, `toefl daily ${kind} findings`);
  const results = items.map((x) => x.result);
  return {
    total: items.length,
    segments: items.map((x) => ({ sec: secs(x.ms), ansSec: x.ansSec })),
    feedback: {
      score: toeflBand(mean(results.map((r) => Number(r.task_score)))),
      description: null,
      subs: criterionScores(items[0].type, results).map((s) => [s.label, s.v, s.c]),
      weak: weakCards('口语', found.map((f) => ({ f }))),
      questions: items.map((x) => ({
        ...speakingCard(x.n, x, x.result, kind === 'retell' ? x.result.speech_metrics?.pronunciation?.completeness : null),
        q: `"${x.text}"`,
      })),
    },
  };
}

function mockListening(learner) {
  const id = MOCK.listening;
  const result = one(
    `select jsonb_build_object('score', r.section_score, 'reason', s.submit_reason,
      'correct', r.score_detail->'correct_count', 'scored', r.score_detail->'scored_item_count',
      'branch', (select b.branch_code from toefl_mock_exam_adaptive_decisions d
                 join toefl_mock_exam_adaptive_branches b on b.id = d.selected_branch_id where d.session_id = s.id))
     from toefl_mock_exam_sessions s join toefl_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and s.module = 'listening' and s.status = 'completed'
       and s.user_id::text like ${lit(`${learner}%`)}`,
    `toefl mock listening ${id}`,
  );
  const items = rows(
    `select jsonb_build_object(
      'stage', sec.ordinal, 'type', i.public_content->>'type', 'prompt', i.public_content->>'prompt',
      'options', i.public_content->'options',
      'context', (select c->>'text' from jsonb_array_elements(sec.public_content->'content') u
                  cross join jsonb_array_elements(u->'context') c
                  where u->>'id' = i.public_content->>'source_id' and c->>'label' = 'Context' limit 1),
      'audio', k.marking_key->>'media_asset_id', 'ms', m.duration_ms,
      'stored', case when m.purpose = 'listening_prompt' and m.state = 'attached' and m.session_id = i.session_id
          and m.user_id::text like ${lit(`${learner}%`)}
        then jsonb_build_object('scope', m.storage_scope, 'key', m.object_key, 'sha256', m.sha256, 'size', m.size_bytes) end,
      'answer', k.marking_key#>>'{accepted_responses,0}', 'transcript', k.marking_key->>'listening_transcript',
      'support', k.marking_key->>'source_support', 'choice', x.response->>'choice')
     from toefl_mock_exam_items i
     join toefl_mock_exam_sections sec on sec.id = i.section_id
     join toefl_mock_exam_marking_keys k on k.item_id = i.id
     left join toefl_mock_exam_responses x on x.item_id = i.id
     left join toefl_mock_exam_media_assets m on m.id::text = k.marking_key->>'media_asset_id'
     where i.session_id = ${lit(id)}
     order by sec.ordinal, i.ordinal`,
  );
  const of = (stage, type) => items.filter((x) => x.stage === stage && x.type === type);
  const right = (x) => x.choice != null && x.choice === x.answer;
  const [level, levelZh] = BRANCH_LEVEL[result.branch] || [];
  if (!level) throw new Error(`toefl mock listening ${id}: no adaptive branch decision`);

  const modules = {};
  for (const [key, [stage, type]] of Object.entries(MOCK_MODULES)) {
    const list = of(stage, type);
    if (!list.length) throw new Error(`toefl mock listening ${id}: stage ${stage} has no ${type}`);
    attachClips(list, `aud_tf_listening_mock_${key}`);
    // 「听后选择回应」每题单独放一遍录音（页面的 locked 样式），不分组、不带情境说明。
    modules[key] = { total: list.length, segments: segments(list, 'audio', type !== 'listen_choose_response') };
  }

  // 批改页：模块 1 / 模块 2 各自的题型。模块 2 的题型键加 "2"，两个模块的逐题分析和原文才不会串。
  const qs = {};
  const transcripts = {};
  const types = (stage) => Object.entries(LISTENING_TYPES).flatMap(([type, [key, name]]) => {
    const list = of(stage, type);
    if (!list.length) return [];
    const k = stage === 1 ? key : `${key}2`;
    qs[k] = list.map((x, i) => questionCard(x, i + 1, right(x)));
    if (type !== 'listen_choose_response') transcripts[k] = transcriptRows(passagesOf(list, (x) => list.indexOf(x) + 1));
    // 题型分：答对比例换算成 1–6（正式客户端复盘页的同一算法）。
    return [{ key: k, name, score: Number(toeflBand((list.filter(right).length / list.length) * 5)) }];
  });
  const typesM1 = types(1);
  const typesM2 = types(2);
  const second = items.filter((x) => x.stage === 2);
  const answered = second.filter((x) => x.choice != null).length;
  const timeUp = result.reason === 'deadline';
  return {
    modules,
    feedback: {
      typesM1,
      typesM2,
      qs,
      transcripts,
      // 这场的能力分析没有得出薄弱项（证据不足），批改页就不画那一块。
      weak: weakCards('听力', one(`select ${findingsOf('toefl_mock', lit(id))}`, 'toefl mock listening findings').map((f) => ({ f }))),
      final: {
        score: band(result.score),
        level: [level, levelZh],
        summary: pair(`Your final Listening score is based on your ${level} form.`, `最终听力分基于你的 ${level} 卷表现。`),
        m1: pair(
          `Placement: ${result.correct} of ${result.scored} correct — you were routed to the ${level} form.`,
          `定级：${result.scored} 题答对 ${result.correct} 题——你已进入 ${level}（${levelZh}）卷。`,
        ),
        m2: pair(
          `${level} form: ${answered} of ${second.length} questions answered${timeUp ? ' before the time ran out' : ''}.`,
          `${level} 卷：${second.length} 题作答 ${answered} 题${timeUp ? '，时间已到' : ''}。`,
        ),
      },
    },
  };
}

function mockSpeaking(learner) {
  const id = MOCK.speaking;
  const result = one(
    `select jsonb_build_object('score', r.section_score, 'tasks', r.score_detail->'task_scores',
      'findings', ${findingsOf('toefl_mock', 's.id')})
     from toefl_mock_exam_sessions s join toefl_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and s.module = 'speaking' and s.status = 'completed'
       and s.user_id::text like ${lit(`${learner}%`)}`,
    `toefl mock speaking ${id}`,
  );
  const items = rows(
    `select jsonb_build_object(
      'type', i.item_type, 'instruction', i.public_content->>'instruction', 'intro', i.public_content->>'intro_summary',
      'ansSec', (i.public_content->>'response_seconds')::int, 'text', k.marking_key->>'source_text', 'ms', m.duration_ms,
      'recMs', (c.private_payload#>>'{analysis,durationSeconds}')::numeric * 1000,
      'completeness', c.private_payload#>'{analysis,pronunciation,completeness}')
     from toefl_mock_exam_items i
     join toefl_mock_exam_marking_keys k on k.item_id = i.id
     left join toefl_mock_exam_media_assets m on m.id::text = k.marking_key->>'media_asset_id'
     left join toefl_mock_exam_scoring_checkpoints c on c.item_id = i.id and c.phase = 'audio_analysed'
     where i.session_id = ${lit(id)}
     order by i.ordinal`,
  );
  // 结果里的 task_scores 按题型依次对应各题（后端 examReviewBundle.resultForMockItem 的同一规则）。
  const part = (type) => {
    const scores = result.tasks.filter((t) => t.task_type === type);
    const list = items.filter((x) => x.type === type);
    if (!list.length || list.length !== scores.length) throw new Error(`toefl mock speaking ${id}: ${type} turns and scores differ`);
    return list.map((x, i) => ({ ...x, result: scores[i] }));
  };
  const repeat = part('listen_and_repeat');
  const interview = part('take_an_interview');
  const typeScore = (list) => Number(toeflBand(mean(list.map((x) => Number(x.result.task_score)))));
  const cards = (list, withPct) => list.map((x, i) => ({
    ...speakingCard(i + 1, x, x.result, withPct ? x.completeness : null),
    ask: `"${x.text}"`,
  }));
  return {
    task1: {
      total: repeat.length,
      segments: repeat.map((x) => ({ sec: secs(x.ms), ansSec: x.ansSec, instruct: x.instruction })),
    },
    task2: {
      total: interview.length,
      // 访谈开始前学员看到的是第一问的情境简介。
      brief: { sub: interview[0].intro || interview[0].instruction },
      segments: interview.map((x) => ({ sec: secs(x.ms), ansSec: x.ansSec })),
    },
    feedback: {
      score: band(result.score),
      description: null,
      types: [
        { key: 'r', name: 'Listen and Repeat', score: typeScore(repeat) },
        { key: 'i', name: 'Take an Interview', score: typeScore(interview) },
      ],
      subs: Object.fromEntries([['r', repeat], ['i', interview]].map(([key, list]) => [
        key,
        criterionScores(list[0].type, list.map((x) => x.result)).map((s) => ({ n: s.label, v: s.v, c: s.c })),
      ])),
      questions: { r: cards(repeat, true), i: cards(interview, false) },
      weak: weakCards('口语', result.findings.map((f) => ({ f }))),
    },
  };
}

exports.build = ({ learner }) => ({
  'tf_listening_daily.json': Object.fromEntries(
    ['respond', 'convo', 'announce', 'lecture'].map((kind) => [kind, dailyListening(kind, learner)]),
  ),
  'tf_listening_mock.json': mockListening(learner),
  ...LISTENING_AUDIO, // 上面两项读出来的听力录音（aud_tf_listening_*.mp3）
  'tf_speaking_daily.json': Object.fromEntries(
    ['retell', 'interview'].map((kind) => [kind, dailySpeaking(kind, learner)]),
  ),
  'tf_speaking_mock.json': mockSpeaking(learner),
});

// 自检：node tool/demo_export/toefl_listening_speaking.cjs（不连库）。
if (require.main === module) {
  const assert = require('assert');
  assert.deepStrictEqual(
    transcriptRows([
      { text: 'A b c. D e.', marks: [{ n: 2, span: 'D e.' }, { n: 1, span: 'b c' }, { n: 3, span: 'c. D' }, { n: 4, span: 'zzz' }] },
      { text: 'X', marks: [] },
    ]),
    [['A ', 'b c', 1, ''], ['. ', 'D e.', 2, ''], ['\n\nX']],
  );
  assert.strictEqual(toeflBand(20 / 7), '4.0');
  assert.strictEqual(toeflBand(0), '1.0');
  assert.strictEqual(clock(65400), '01:05');
  console.log('ok');
}
