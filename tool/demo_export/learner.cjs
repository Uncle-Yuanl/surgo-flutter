// 学员总览：首页、个人中心、消息通知、继续学习、模考选科、学情分析。
// 写 learner_profile.json（原型数据里是空表，页面用各自写死的原型值；键在而值是 null = 真实数据里
// 没有，那一行 / 那一块不画）和 continue.json。
//
// 分数照后端学情内核的口径从库里的作答记录现算（learningInsightSnapshot.loadScoreRecords +
// learningInsightEstimate，后端的首页、学情页、家长端都读它）：同样的记录、同样的就绪规则与加权、
// 半分取整。后端给家长月报存过完整快照（progress 表 parent_overall_assessment:…，含 estimate），
// verify() 每次先按快照自己的截止时刻重算一遍，对不上就不导出。
const { rows, one, lit } = require('./db.cjs');
const { band, pair } = require('./text.cjs');

// 演示的时刻：这之后的记录不算；倒计时、近 7/30 天、本周、八周趋势都按这一刻、学员的
// study_timezone 算。要换成更新的数据就改这里。（能力画像和未完成的练习没有历史可回放，读的是现状。）
const AS_OF = '2026-09-30T07:00:00Z';

const MODULES = ['listening', 'reading', 'writing', 'speaking'];
const DAY = 86400000;
const SCALE = { ielts: { min: 0.5, max: 9, low: 0 }, toefl: { min: 1, max: 6, low: 1 } };
const TASKS = {
  ielts: {
    listening: ['section1', 'section2', 'section3', 'section4'],
    reading: ['multiple_choice', 'true_false_not_given', 'yes_no_not_given', 'matching_information',
      'matching_headings', 'matching_features', 'matching_sentence_endings', 'sentence_completion',
      'summary_completion', 'diagram_labelling', 'short_answer'],
    writing: ['task1', 'task2'],
    speaking: ['part1', 'part2', 'part3'],
  },
  toefl: {
    listening: ['listen_choose_response', 'listen_conversation', 'listen_announcement', 'listen_academic_talk'],
    reading: ['complete_the_words', 'read_in_daily_life', 'read_an_academic_passage'],
    writing: ['build_a_sentence', 'write_an_email', 'academic_discussion'],
    speaking: ['listen_and_repeat', 'take_an_interview'],
  },
};
const READING_ALIASES = {
  mcq: 'multiple_choice', multiple_choices: 'multiple_choice', multiple_choice_questions: 'multiple_choice',
  tfng: 'true_false_not_given', true_false_ng: 'true_false_not_given', ynng: 'yes_no_not_given',
  yes_no_ng: 'yes_no_not_given', matching_paragraphs: 'matching_information',
  paragraph_matching: 'matching_information', heading_matching: 'matching_headings',
  feature_matching: 'matching_features', sentence_endings: 'matching_sentence_endings',
  diagram_labeling: 'diagram_labelling', diagram_labels: 'diagram_labelling', short_answer_questions: 'short_answer',
};

// ---------------------------------------------------------------- 记录（loadScoreRecords）

const num = (v) => (v == null || v === '' || !Number.isFinite(Number(v)) ? null : Number(v));
const task = (v, exam, module) => {
  const id = String(v || '').trim().toLowerCase().replace(/^(task|part|section)_([1-4])$/, '$1$2');
  return TASKS[exam][module]?.includes(id) ? id : null;
};
const readingType = (v) => {
  const key = String(v || '').trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  const id = READING_ALIASES[key] || key;
  return TASKS.ielts.reading.includes(id) ? id : null;
};
function validity(d = {}) {
  const value = d.attempt_validity || d.validity || d.validation?.attempt_validity;
  if (d.validation_code || d.invalid === true) return 'invalid';
  return ['valid', 'questionable', 'invalid'].includes(value) ? value : 'valid';
}
/** 口语只认 homeSkillScores.speakingRange 信得过的估分（真音频、只估分），取中点。 */
function speakingScore(d) {
  const m = d?.meta, r = d?.estimated_band_range;
  const ok = (x) => typeof x === 'number' && x >= 0 && x <= 9 && Number.isInteger(x * 2);
  if (!m || !r || m.realAudioAnalysis !== true || m.transcriptOnly !== false || m.providerMode !== 'live'
    || m.officialScoreClaim !== false || m.estimateOnly !== true || m.pronunciationOnly !== false
    || typeof m.qualityCheckPassed !== 'boolean' || !/^part[1-3]$/.test(m.taskPart)
    || !['azure_pron', 'azure_pron+llm_language'].includes(r.basis) || typeof r.caveat !== 'string' || !r.caveat.trim()
    || !ok(r.low) || !ok(r.high) || r.low > r.high) return null;
  return (r.low + r.high) / 2;
}
/** 听力 / 阅读没存分的练习：按 ieltsMockBandConversion.practiceBandEstimate 从对题数换算。 */
function practiceBand(module, correct, total) {
  const anchors = module === 'reading'
    ? [[0, 0], [15, 5], [23, 6], [30, 7], [35, 8], [40, 9]]
    : [[0, 0], [16, 5], [23, 6], [30, 7], [35, 8], [40, 9]];
  if (!Number.isInteger(correct) || !Number.isInteger(total) || total < 0 || correct < 0 || correct > total) return null;
  if (total === 0) return 1;
  const raw = (correct * 40) / total;
  const exact = anchors.find(([v]) => v === raw);
  if (exact) return Math.max(1, exact[1]);
  for (let i = 1; i < anchors.length; i++) {
    const [hr, hb] = anchors[i], [lr, lb] = anchors[i - 1];
    if (raw < hr) return Math.max(1, Math.round((lb + ((raw - lr) / (hr - lr)) * (hb - lb)) * 2) / 2);
  }
  return 9;
}
/** 托福日常一场：各题 0–5 分取平均再换 1–6 分（toefl2026Primitives.sessionBandFromTaskScores）。 */
function sessionBand(scores) {
  if (!scores?.length || scores.some((s) => typeof s !== 'number' || s < 0 || s > 5)) return null;
  const mean = scores.reduce((a, b) => a + b, 0) / scores.length;
  return Math.max(1, Math.min(6, Math.round((1 + mean) * 2) / 2));
}
function record(exam, module, id, mock, score, date, detail, types = [null]) {
  const n = num(score), t = Date.parse(date);
  if (!MODULES.includes(module) || !Number.isFinite(t)) return null;
  return { id, module, mock, date: Math.floor(t / 1000) * 1000, types, validity: validity(detail),
    score: n != null && n >= SCALE[exam].low && n <= SCALE[exam].max ? n : null };
}

// 模考只有真作答过（至少五分之一的题有答案；口语要有录到音的一段）才算分（mockScoreEvidence）。
const answeredMockScore = (exam) => `case when (case when s.module = 'speaking'
    then (select count(*) from ${exam}_mock_exam_recording_capture_attempts c
          where c.session_id = s.id and c.user_id = s.user_id and c.recording_sha256 is not null)
    else (select count(*) from ${exam}_mock_exam_responses a where a.session_id = s.id and a.user_id = s.user_id) end)
  >= greatest(1, ceil(0.2 * (select count(*) from ${exam}_mock_exam_items i where i.session_id = s.id and i.user_id = s.user_id)))
  then r.section_score end`;

/** 一门考试截至 cutoff 的全部记分记录：练习 + 托福日常整场 + 真作答过的模考，一次作答一条。 */
function loadRecords(user, exam, cutoff) {
  const u = lit(user), at = `${lit(cutoff)}::timestamptz`;
  const out = [];
  const mocks = rows(`select jsonb_build_object('id', s.id, 'module', s.module, 'score', ${answeredMockScore(exam)},
      'detail', r.score_detail, 'at', r.completed_at)
    from ${exam}_mock_exam_results r join ${exam}_mock_exam_sessions s on s.id = r.session_id and s.user_id = r.user_id
    where r.user_id = ${u} and r.completed_at <= ${at} and s.status = 'completed'`);
  for (const m of mocks) out.push(record(exam, m.module, `mock:${m.id}`, true, m.score, m.at, m.detail));
  if (exam === 'ielts') {
    const practice = rows(`select jsonb_build_object('id', a.id, 'module', a.module, 'task_type', a.task_type,
        'band', a.band, 'detail', a.detail, 'correct', a.correct_count, 'total', a.total_count, 'at', a.attempted_at,
        'mode', a.exam_mode, 'mock', a.mock_exam_session_id, 'gen_type', g.task_type, 'gen_qt', g.content->'question_type')
      from ielts_attempts a left join ielts_generated_items g on g.id = a.generated_item_id and g.user_id = a.user_id
      where a.user_id = ${u} and a.attempted_at <= ${at} and coalesce(a.exam_mode, 'practice') <> 'mock'`);
    for (const a of practice) {
      if (a.mode === 'mock' || a.mock || /^(dictation|level[1-9]|daily_challenge|vocabulary)/.test(a.task_type || '')) continue;
      const d = a.detail && typeof a.detail === 'object' && !Array.isArray(a.detail) ? a.detail : {};
      let types = [task(a.task_type, exam, a.module) || task(d.task_type, exam, a.module) || task(a.gen_type, exam, a.module)];
      if (a.module === 'reading') {
        const q = Array.isArray(d.per_question) ? d.per_question : [];
        const marked = q.filter((x) => typeof x.correct === 'boolean').map((x) => readingType(x.type)).filter(Boolean);
        types = marked.length ? [...new Set(marked)]
          : [types[0] || readingType(d.question_type) || readingType(d.content?.question_type) || readingType(a.gen_qt)];
      }
      const derived = ['listening', 'reading'].includes(a.module) ? practiceBand(a.module, num(a.correct), num(a.total)) : null;
      const score = a.module === 'speaking' ? speakingScore(d)
        : (a.band ?? d.band_estimate?.band ?? d.band_estimate?.midpoint ?? derived);
      out.push(record(exam, a.module, `ielts:${a.id}`, false, score, a.at, d, types));
    }
  } else {
    const sessions = rows(`select jsonb_build_object('id', s.id, 'module', s.module, 'task_type', s.task_type,
        'at', s.completed_at, 'items', count(i.id), 'scored', count(a.task_score),
        'scores', jsonb_agg(a.task_score order by i.ordinal),
        'validity', case when bool_or(a.result_detail->>'attempt_validity' = 'invalid') then 'invalid'
          when bool_or(a.result_detail->>'attempt_validity' = 'questionable') then 'questionable' else 'valid' end)
      from toefl_daily_training_sessions s join toefl_daily_training_items i on i.session_id = s.id and i.user_id = s.user_id
      left join lateral (select task_score, result_detail from toefl_daily_training_attempts a
        where a.item_id = i.id and a.session_id = s.id and a.user_id = s.user_id and a.completed_at <= ${at}
        order by a.completed_at desc, a.id desc limit 1) a on true
      where s.user_id = ${u} and s.status = 'completed' and s.completed_at <= ${at} group by s.id`);
    for (const s of sessions) {
      if (s.items < 1) continue;
      const score = s.scored === s.items ? sessionBand(s.scores.map(num)) : null;
      out.push(record(exam, s.module, `toefl:${s.id}`, false, score, s.at, { validity: s.validity }, [task(s.task_type, exam, s.module)]));
    }
  }
  return out.filter((r) => r && r.date <= Date.parse(cutoff));
}

// ---------------------------------------------------------------- 估分（learningInsightEstimate）

function zoned(ms, tz) {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' }).formatToParts(new Date(ms));
  return Object.fromEntries(parts.filter((p) => p.type !== 'literal').map((p) => [p.type, Number(p.value)]));
}
/** 学员日历上的那一天（那天 UTC 零点的毫秒数）。 */
const localDay = (ms, tz) => { const p = zoned(ms, tz); return Date.UTC(p.year, p.month - 1, p.day); };
function localMidnight(dayUtc, tz) {
  let guess = dayUtc;
  for (let i = 0; i < 3; i++) {
    const p = zoned(guess, tz);
    guess += dayUtc - Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  }
  return guess;
}
/** 本周（周一零点起）的 [开始, 结束)，ieltsRecommendations.weekBounds。 */
function week(ms, tz) {
  const day = localDay(ms, tz);
  const monday = day - ((new Date(day).getUTCDay() + 6) % 7) * DAY;
  return [localMidnight(monday, tz), localMidnight(monday + 7 * DAY, tz)];
}

function estimate(records, exam, now, tz) {
  const s = SCALE[exam];
  const round = (v) => Math.round(Math.min(s.max, Math.max(s.min, v)) * 2) / 2;
  const credible = (r) => r.validity === 'valid' && r.score != null && r.score >= s.low && r.score <= s.max;
  const weight = (r, asOf) => {
    const d = (localDay(asOf, tz) - localDay(r.date, tz)) / DAY;
    return d < 0 ? 0 : d <= 7 ? 3 : d <= 14 ? 2 : d <= 30 ? 1 : 0;
  };
  // 一科：够五次有效练习或 90 天内有一次模考才出分；近 30 天练习按 3/2/1 加权 × 0.4 + 最近一次模考 × 0.6，
  // 没模考 × 0.9，只有模考就用模考；取半分。
  function subject(module, asOf) {
    const scored = records.filter((r) => r.module === module && credible(r) && r.date <= asOf);
    const practices = scored.filter((r) => !r.mock);
    const mocks = scored.filter((r) => r.mock && asOf - r.date <= 90 * DAY);
    if (!mocks.length && practices.length < 5) return null;
    let sum = 0, total = 0;
    for (const r of practices) { const w = weight(r, asOf); sum += r.score * w; total += w; }
    const avg = total ? sum / total : null;
    const mock = mocks.reduce((m, r) => (m == null || r.date > m.date ? r : m), null)?.score ?? null;
    const v = avg != null && mock != null ? avg * 0.4 + mock * 0.6 : avg != null ? avg * 0.9 : mock;
    return v == null ? null : round(v);
  }
  function overall(asOf) {
    const all = MODULES.map((m) => subject(m, asOf));
    return all.includes(null) ? null : round(all.reduce((a, b) => a + b, 0) / 4);
  }
  const counted = records.filter((r) => r.validity !== 'invalid' && r.date <= now);
  const count = (from, to) => counted.filter((r) => r.date > now - from * DAY && r.date <= now - to * DAY).length;
  const weeks = [];
  for (let span = week(now, tz); weeks.length < 8; span = week(span[0] - 1, tz)) weeks.unshift(span);
  return {
    subjects: Object.fromEntries(MODULES.map((m) => [m, subject(m, now)])),
    total: overall(now),
    trend: weeks.map(([start, end]) => ({
      start,
      predicted: overall(end > now ? now : end - 1),
      attempts: counted.filter((r) => r.date >= start && r.date < end).length,
    })),
    last7: count(7, 0),
    last30: count(30, 0),
    prior30: count(60, 30),
  };
}

/**
 * 拿后端自己存的快照核对移植：取最近生成的一份家长月报快照，按它的截止时刻从库里重建记录再估分，
 * 四科、总分、八周趋势、近 7/30 天次数必须和快照里的 estimate 一样，否则不导出。
 * （09-24 生成的那份用的是 09-25 前的换算——低正确率可以是 0 分——所以只认最近生成的。）
 */
function verify(user, exam, tz) {
  const saved = rows(`select value->'insightSnapshot' from progress
    where user_id = ${lit(user)} and key like ${lit(`parent_overall_assessment:%:${exam}`)}
    order by value->>'generatedAt' desc limit 1`)[0];
  if (!saved) return console.warn(`learner: no stored ${exam} snapshot to check the estimate against`);
  const e = saved.estimate;
  const mine = estimate(loadRecords(user, exam, saved.generatedAt), exam, Date.parse(saved.generatedAt), tz);
  const got = JSON.stringify([mine.subjects, mine.total, mine.trend.map((w) => [w.start, w.predicted, w.attempts]), mine.last7, mine.last30]);
  const want = JSON.stringify([
    Object.fromEntries(MODULES.map((m) => [m, e.prediction.subjects.find((x) => x.module === m).predicted])),
    e.prediction.total,
    e.trend.map((w) => [Date.parse(w.weekStart), w.predicted, w.attemptCount]),
    e.activity.last7DaysAttempts,
    e.activity.last30DaysAttempts,
  ]);
  if (got !== want) throw new Error(`learner: ${exam} estimate differs from the backend's stored snapshot; got ${got}, want ${want}`);
}

// ---------------------------------------------------------------- 页面用的块

const NAMES = { listening: ['Listening', '听力'], reading: ['Reading', '阅读'], writing: ['Writing', '写作'], speaking: ['Speaking', '口语'] };
const EXAMS = { ielts: ['IELTS', '雅思'], toefl: ['TOEFL', '托福'] };
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
// 题型名：雅思阅读的中文照后端学情 catalog，托福照 examReviewBundle.LABELS（全站一套）。
const TASK_LABELS = {
  multiple_choice: ['Multiple choice', '选择题'], true_false_not_given: ['True/False/Not given', '判断正误题'],
  yes_no_not_given: ['Yes/No/Not given', '观点判断题'], matching_information: ['Matching information', '信息匹配'],
  matching_headings: ['Matching headings', '标题匹配'], matching_features: ['Matching features', '特征匹配'],
  matching_sentence_endings: ['Matching sentence endings', '句尾匹配'], sentence_completion: ['Sentence completion', '句子填空'],
  summary_completion: ['Summary completion', '摘要填空'], diagram_labelling: ['Diagram labelling', '图表标注'],
  short_answer: ['Short answer', '简答题'],
  complete_the_words: ['Complete the Words', '补全单词'], read_in_daily_life: ['Read in Daily Life', '日常生活阅读'],
  read_an_academic_passage: ['Read an Academic Passage', '学术文章阅读'],
  listen_choose_response: ['Listen and Choose a Response', '听句选答'], listen_conversation: ['Listen to a Conversation', '听对话'],
  listen_announcement: ['Listen to an Announcement', '听通知'], listen_academic_talk: ['Listen to an Academic Talk', '听学术讲座'],
  build_a_sentence: ['Build a Sentence', '排列成句'], write_an_email: ['Write an Email', '撰写邮件'],
  academic_discussion: ['Academic Discussion', '学术讨论写作'], listen_and_repeat: ['Listen and Repeat', '听后复述'],
  take_an_interview: ['Take an Interview', '访谈'],
};
const numbered = (id) => /^(task|part|section)_?([1-4])$/.exec(String(id || ''));
/** task1 → Task 1，part2 / section2 → Part 2（界面上听力也叫 Part），其余查表；认不出的返回 null。 */
function taskLabel(id) {
  const m = numbered(id);
  if (!m) return TASK_LABELS[id] || null;
  const name = `${m[1] === 'task' ? 'Task' : 'Part'} ${m[2]}`;
  return [name, name];
}
/** 训练页预选的卡：写作 t1 / t2、口语 p1–p3、听力 s1–s4。 */
const wizardCard = (id) => { const m = numbered(id); return m ? `${m[1][0]}${m[2]}` : null; };
/** 「IELTS Writing · Task 2」/「雅思写作 · Task 2」，和正式客户端「继续学习」列表同一种叫法。 */
function practiceLabel(exam, module, taskId) {
  const t = taskLabel(taskId);
  return [`${EXAMS[exam][0]} ${NAMES[module][0]}${t ? ` · ${t[0]}` : ''}`, `${EXAMS[exam][1]}${NAMES[module][1]}${t ? ` · ${t[1]}` : ''}`];
}

/** 每日挑战连胜：连续完成的天数，到今天为止；今天还没做就从昨天往前数（ieltsDaily.streak）。 */
function streak(user, exam, at, today) {
  const done = new Set(rows(`select to_jsonb(challenge_date::text) from ${exam}_daily_challenges
    where user_id = ${lit(user)} and completed_at <= ${at}`));
  const iso = (ms) => new Date(ms).toISOString().slice(0, 10);
  let day = today, n = 0;
  if (!done.has(iso(day))) day -= DAY;
  for (; done.has(iso(day)); day -= DAY) n++;
  return n;
}

/**
 * 首页「每日挑战」卡：学员最近一次出了题的每日挑战——科目、预计用时、标题（库里存了中英两份）、做没做完。
 * 这门考试一次都没有就是 null，整张卡不画。
 */
function dailyChallenge(user, exam, at) {
  const c = rows(`select jsonb_build_object('date', challenge_date::text,
      'module', ${exam === 'toefl' ? 'module' : "coalesce(content->>'module_targeted', task_type)"},
      'title', jsonb_build_array(content->>'title_en', content->>'title_cn'), 'minutes', content->'estimated_minutes',
      'done', coalesce(completed_at <= ${at}, false))
    from ${exam}_daily_challenges where user_id = ${lit(user)} and content is not null and created_at <= ${at}
    order by challenge_date desc limit 1`)[0];
  if (!c) return null;
  const [, month, day] = c.date.split('-').map(Number);
  const name = NAMES[c.module] || (c.module === 'vocabulary' ? ['Vocabulary', '词汇'] : [c.module, c.module]);
  const minutes = Number.isInteger(c.minutes) ? ` · ${c.minutes} min` : '';
  const title = pair(c.title[0], c.title[1]);
  const state = c.done
    ? [`completed ${MONTHS[month - 1]} ${day}`, `${month}月${day}日已完成`]
    : [`${MONTHS[month - 1]} ${day}, not finished`, `${month}月${day}日未完成`];
  return {
    // 点卡片去哪：该科的日常训练页（词汇去词汇页）。
    go: NAMES[c.module] ? `${c.module}Daily` : 'vocab',
    sub: [`${name[0]}${minutes}`, `${name[1]}${minutes}`],
    status: title[0] ? [`${title[0]} · ${state[0]}`, `${title[1]} · ${state[1]}`] : state,
  };
}

/**
 * 首页三张卡 = 推荐计划的三项（每项目标 5 次，完成数是记到该项的练习）：取这门考试最近的一份计划——
 * 本周有就是本周的，本周还没生成就用上一份（后端是学员打开首页时才生成当周计划）。一份都没有才是 null。
 */
function weeklyFocus(user, exam, at) {
  const items = rows(`select jsonb_build_object('module', i.module, 'title', jsonb_build_array(i.title_en, i.title_zh),
      'selector', i.task_selector, 'of', i.target_count, 'done', (select count(*) from ielts_recommendation_credits c
        where c.item_id = i.id and c.user_id = i.user_id and c.credited_at <= ${at}))
    from ielts_weekly_recommendation_items i
    where i.user_id = ${lit(user)} and i.plan_id = (select p.id from ielts_weekly_recommendation_plans p
      where p.user_id = ${lit(user)} and p.exam = ${lit(exam)} and p.week_start_at <= ${at}
        and exists (select 1 from ielts_weekly_recommendation_items x where x.plan_id = p.id)
      order by p.week_start_at desc limit 1)
    order by i.rank`);
  if (!items.length) return null;
  return items.map((i) => {
    const sel = i.selector || {};
    const id = sel.task_type || sel.question_type || (sel.section ? `section${sel.section}` : sel.part ? `part${sel.part}` : null);
    const label = taskLabel(id);
    return {
      module: i.module,
      kicker: [`${NAMES[i.module][0]}${label ? ` · ${label[0]}` : ''}`.toUpperCase(), `${NAMES[i.module][1]}${label ? ` · ${label[1]}` : ''}`],
      head: i.title,
      done: i.done,
      of: i.of,
      card: wizardCard(id),
    };
  });
}

/**
 * 继续学习：还能接着做的练习和模考（题目已生成没开始，或做到一半），最近动过的排前面，每门考试取 5 条。
 * 雅思写作 / 阅读的草稿只存在学员设备上，库里没有进度，没交卷的是 0%。
 */
function continueItems(user, exam, at) {
  const u = lit(user);
  const sessions = (table, kind) => rows(`select jsonb_build_object('kind', ${lit(kind)}, 'module', s.module,
      'task', ${kind === 'daily' ? 's.task_type' : 'null'}, 'status', s.status, 'at', s.updated_at,
      'total', (select count(*) from ${table}_items i where i.session_id = s.id and i.user_id = s.user_id),
      'answered', (select count(distinct r.item_id) from ${table}_responses r where r.session_id = s.id and r.user_id = s.user_id))
    from ${table}_sessions s where s.user_id = ${u} and s.status in ('ready', 'in_progress') and s.updated_at <= ${at}`);
  const found = sessions(`${exam}_mock_exam`, 'mock');
  if (exam === 'toefl') found.push(...sessions('toefl_daily_training', 'daily'));
  else {
    // 生成了还没交卷的题；口语对话练习答过几轮库里有（ielts_speaking_dialogue_turns），其余科目没有进度。
    found.push(...rows(`select jsonb_build_object('kind', 'daily', 'module', g.module, 'task', g.task_type,
        'status', case when d.answered > 0 then 'in_progress' else 'ready' end, 'at', coalesce(d.updated_at, g.created_at),
        'total', coalesce(d.total_turns, 1), 'answered', coalesce(d.answered, 0))
      from ielts_generated_items g left join lateral (select s.updated_at, s.total_turns,
          (select count(*) from ielts_speaking_dialogue_turns t where t.session_id = s.id and t.answered_at <= ${at}) as answered
        from ielts_speaking_dialogue_sessions s where s.item_id = g.id and s.user_id = g.user_id and s.status = 'active'
        order by s.updated_at desc limit 1) d on true
      where g.user_id = ${u} and g.module in ('listening', 'reading', 'writing', 'speaking') and g.created_at <= ${at}
        and not exists (select 1 from ielts_attempts a where a.generated_item_id = g.id and a.user_id = g.user_id)`));
    found.push(...rows(`select jsonb_build_object('kind', 'daily', 'module', 'listening', 'task', 'section' || s.part,
        'status', s.status, 'at', s.updated_at, 'total', jsonb_array_length(s.public_content->'answer_units'),
        'answered', (select count(*) from ielts_listening_daily_responses r where r.session_id = s.id and r.user_id = s.user_id))
      from ielts_listening_daily_sessions s where s.user_id = ${u} and s.status in ('ready', 'in_progress') and s.updated_at <= ${at}`));
  }
  return found.sort((a, b) => Date.parse(b.at) - Date.parse(a.at)).slice(0, 5).map((f) => {
    const mock = f.kind === 'mock';
    const card = wizardCard(f.task);
    const [en, zh] = practiceLabel(exam, f.module, mock ? null : f.task);
    return {
      exam,
      tab: f.kind,
      ic: `assets/ic3_${f.module}.png`,
      name: mock ? [`${en} Mock Exam`, `${zh}模拟考试`] : [en, zh],
      kicker: f.status === 'ready' ? ['Not started', '未开始']
        : f.answered ? [`In progress · ${f.answered}/${f.total} answered`, `进行中 · 已作答 ${f.answered}/${f.total}`]
          : ['In progress', '进行中'],
      pct: f.total ? Math.round((100 * f.answered) / f.total) : 0,
      module: f.module,
      // 点进去落在哪页、带什么状态（原型的页面键）：模考进该科模考入口，托福练习进任务说明页，雅思进日常训练。
      go: mock ? (f.module === 'writing' ? (exam === 'toefl' ? 'mockWritingTf' : 'mockWritingIntro') : `mock${NAMES[f.module][0]}`)
        : exam === 'toefl' ? 'tfBrief' : `${f.module}Daily`,
      session: mock ? { sessionMode: 'mock' } : exam === 'toefl' ? { tfBriefMod: f.module }
        : !card ? {} : f.module === 'listening' ? { lisPart: card } : { selWizCard: card },
    };
  });
}

// 「可以进步的地方」照正式客户端学情页的取法：有弱项证据的能力项，每科取最细一层里掌握度最低的三项，
// 其余（含上一层的大类）收在后面。
const STAGE_RANK = { generalised_weakness: 5, persistent_weakness_candidate: 4, context_specific_weakness: 4,
  emerging_concern: 3, isolated_slip: 2, resolved_monitoring: 1 };
function improvementAreas(user, exam) {
  const areas = rows(`select jsonb_build_object('uid', st.skill_uid, 'parent', sk.parent_uid, 'module', sk.module,
      'label', jsonb_build_array(sk.labels->>'en', sk.labels->>'zh'), 'mastery', st.mastery_mean,
      'stage', st.evidence_stage, 'count', st.opportunity_count, 'trend', st.trend)
    from learner_skill_states st join assessment_skills sk on sk.uid = st.skill_uid
    where st.user_id = ${lit(user)} and sk.exam = ${lit(exam)} and sk.level <= st.visible_level
      and st.ontology_version_id = (select id from assessment_ontology_versions where status = 'active'
        order by published_at desc nulls last, created_at desc limit 1)`).filter((a) => STAGE_RANK[a.stage]);
  const urgency = (a, b) => a.mastery - b.mastery || STAGE_RANK[b.stage] - STAGE_RANK[a.stage] || b.count - a.count
    || (a.label[1] < b.label[1] ? -1 : a.label[1] > b.label[1] ? 1 : 0);
  return Object.fromEntries(MODULES.map((m) => {
    const own = areas.filter((a) => a.module === m).sort(urgency);
    const top = own.filter((a) => a.stage !== 'resolved_monitoring' && !own.some((c) => c.parent === a.uid)).slice(0, 3);
    return [m, {
      top: top.map((a) => ({
        title: a.label,
        trend: ['improving', 'declining', 'stable'].includes(a.trend) ? a.trend : null,
        count: a.count,
        progress: Math.round(a.mastery * 100) / 100,
      })),
      more: own.filter((a) => !top.includes(a)).slice(0, 15).map((a) => a.label),
    }];
  }));
}

/** 「老师给你的点评」= 后端存的能力点评（学员自己生成过才有）；收起时只显示第一句。 */
function abilitySummary(user, exam, at) {
  const s = rows(`select value->'summary' from progress where user_id = ${lit(user)}
    and key = ${lit(`learning_insight_summary:all-tasks-v1:${exam}`)} and (value->'summary'->>'generated_at')::timestamptz <= ${at}`)[0];
  if (!s) return null;
  return {
    summary: pair(s.en?.split(/(?<=[.!?])\s+/)[0], s.zh?.split(/(?<=[。！？])/)[0]),
    full: pair(s.en, s.zh),
    tags: (s.referenced_labels_en || []).map((en, i) => pair(en, (s.referenced_labels_zh || [])[i])),
  };
}

/** 学情页「今日能力点评」：只写数字能说明的三句（总分、最高与最低的一科、离目标多远）。 */
function review(scores, total, target) {
  const order = ['writing', 'reading', 'listening', 'speaking'];
  const top = order.reduce((a, b) => (scores[b] > scores[a] ? b : a));
  const low = order.reduce((a, b) => (scores[b] < scores[a] ? b : a));
  const gap = target == null ? 0 : Math.max(0, target - total);
  return [
    { text: [`Your current overall level is Band ${band(total)}. `, `你目前的综合水平为 Band ${band(total)}。`] },
    { bold: true, text: [`${NAMES[top][0]} (${band(scores[top])}) is your strength`, `${NAMES[top][1]}（${band(scores[top])}）是你的强项`] },
    { text: [', and ', '，'] },
    { bold: true, text: [`${NAMES[low][0]} (${band(scores[low])}) is the area that most needs a breakthrough`, `${NAMES[low][1]}（${band(scores[low])}）是当前最需要突破的一项`] },
    { text: gap > 0 ? [`. You are ${band(gap)} short of your ${band(target)} target.`, `。距离目标 ${band(target)} 还差 ${band(gap)} 分。`] : ['.', '。'] },
  ];
}

/** 每种通知取最近一条：模考出分、练习题目就绪、能力档案更新。标题和正文库里就是「英文 / 中文」。 */
function notifications(user, at, tz) {
  const KINDS = { mock_exam_scoring_completed: 'mock', daily_training_ready: 'daily', capability_analysis_completed: 'report' };
  const both = (text) => { const [en, ...zh] = String(text || '').split(' / '); return pair(en, zh.join(' / ')); };
  return rows(`select distinct on (type) jsonb_build_object('type', type, 'title', title, 'body', body, 'at', created_at)
    from notifications where user_id = ${lit(user)} and created_at <= ${at} and type in (${Object.keys(KINDS).map(lit).join(', ')})
    order by type, created_at desc`)
    .sort((a, b) => Date.parse(b.at) - Date.parse(a.at))
    .map((n) => {
      const d = zoned(Date.parse(n.at), tz), body = both(n.body);
      return { id: n.type, kind: KINDS[n.type], title: both(n.title),
        detail: [`${body[0]} · ${MONTHS[d.month - 1]} ${d.day}`, `${body[1]} · ${d.month}月${d.day}日`] };
    });
}

exports.build = (config) => {
  const user = one(`select to_jsonb(id::text) from users where id::text like ${lit(`${config.learner}%`)}`, 'learner');
  const profile = one(`select jsonb_build_object('ielts', target_band, 'toefl', toefl_target_band, 'examDate', exam_date::text,
    'tz', study_timezone) from user_profiles where user_id = ${lit(user)}`, 'learner profile');
  const tz = profile.tz || 'Asia/Shanghai';
  const now = Date.parse(AS_OF), at = `${lit(AS_OF)}::timestamptz`, today = localDay(now, tz);
  // 只用「还剩几天」，不出具体日期；考试日已到或已过就不显示倒计时（「还剩 0 天」只在导出当天成立）。
  const days = profile.examDate ? (Date.parse(`${profile.examDate}T00:00:00Z`) - today) / DAY : null;

  const learner = {
    daysToExam: days != null && days > 0 ? days : null,
    profile: { name: 'Nafis', email: null },
    notifications: notifications(user, at, tz),
  };
  const items = [];
  for (const exam of ['ielts', 'toefl']) {
    verify(user, exam, tz);
    const records = loadRecords(user, exam, AS_OF);
    const e = estimate(records, exam, now, tz);
    const target = num(profile[exam]);
    const valid = records.filter((r) => r.validity === 'valid' && r.score != null);
    const practices = (m) => valid.filter((r) => r.module === m && !r.mock);
    const lastMock = (m) => valid.filter((r) => r.module === m && r.mock).sort((a, b) => b.date - a.date)[0];
    const resume = continueItems(user, exam, at);
    items.push(...resume.map(({ module, ...item }) => item));
    learner[exam] = {
      target: target == null ? null : band(target),
      score: e.total == null ? null : band(e.total),
      streak: streak(user, exam, at, today),
      challenge: dailyChallenge(user, exam, at),
      continue: resume.length ? [`Continue ${NAMES[resume[0].module][0]}`, `继续${NAMES[resume[0].module][1]}`] : ['Continue', '继续'],
      weekly: weeklyFocus(user, exam, at),
      // 模考选科：每科最近一次真作答过的模考分 / 满分；没有就不显示。
      mocks: Object.fromEntries(MODULES.map((m) => [m, lastMock(m) ? `${band(lastMock(m).score)}/${SCALE[exam].max}` : null])),
      report: {
        target,
        scores: Object.fromEntries(Object.entries(e.subjects).filter(([, v]) => v != null)),
        overall: e.total,
        // 八周趋势：每周（周一起）的练习次数、那一周结束时的总分估计、周一的日期。
        weeklyPractice: e.trend.map((w) => w.attempts),
        weeklyScores: e.trend.map((w) => w.predicted),
        weekLabels: e.trend.map((w) => { const d = zoned(w.start, tz); return `${d.month}/${d.day}`; }),
        last30: e.last30,
        prior30: e.prior30,
        // 「评分依据」里按题型数的有效评分练习（累计），顺序同页面上的题型表；practices 是该科的练习次数。
        done: Object.fromEntries(MODULES.map((m) => [m, TASKS[exam][m].map((t) => practices(m).filter((r) => r.types.includes(t)).length)])),
        practices: Object.fromEntries(MODULES.map((m) => [m, practices(m).length])),
        review: exam === 'ielts' && e.total != null ? review(e.subjects, e.total, target) : null,
        teacher: abilitySummary(user, exam, at),
        advice: improvementAreas(user, exam),
      },
    };
  }
  return { 'learner_profile.json': learner, 'continue.json': { items } };
};
