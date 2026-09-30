// 雅思模考写作：一场已完成的模考的两道题（Task 1 是表格题，页面按数据原生画表）和它的评分页。
// 数据来自 ielts_mock_exam_sections / items（题目）、marking_keys 里的 visual_spec（表格的数据，与考生看到的图
// 同一份）、responses（作文）、results（分数、分项、批注，中英两份）。
// 评分页的形状与日常写作相同，直接复用 writing.cjs 的映射。
const { one, lit } = require('./db.cjs');
const { band } = require('./text.cjs');
const { review, weakest } = require('./writing.cjs');

// 演示学员的哪一场模考写作（ielts_mock_exam_sessions.id）：最近一场，两篇都写完，评语中英齐全。
// Task 1 要表格题：答题页只会原生画表格（其余几场是折线图）。
const SESSION = 'c5feac82-c276-4046-93d3-434086ce7c62';

/** 只认演示学员自己的场次：号主同意公开的是这一位，id 写成别人的就查不到、直接报错。 */
function session(id, learner) {
  return one(
    `select jsonb_build_object(
      'score', r.section_score, 'detail', r.score_detail,
      'tasks', (select jsonb_agg(jsonb_build_object('item', i.public_content - 'media', 'essay', x.response->>'text',
                  'spec', k.marking_key->'visual_ground_truth'->'visual_spec') order by sc.ordinal)
                from ielts_mock_exam_sections sc join ielts_mock_exam_items i on i.section_id = sc.id
                left join ielts_mock_exam_responses x on x.item_id = i.id
                left join ielts_mock_exam_marking_keys k on k.item_id = i.id where sc.session_id = s.id))
     from ielts_mock_exam_sessions s join ielts_mock_exam_results r on r.session_id = s.id
     where s.id = ${lit(id)} and s.module = 'writing' and s.status = 'completed'
       and s.user_id::text like ${lit(`${learner}%`)}`,
    `mock writing session ${id}`,
  );
}

/** 模考答题页的一道题；Task 1 带表格（首行表头、首列行名）。 */
function question(task, n) {
  const q = { prompt: task.item.prompt, minWords: task.item.recommended_minimum_words };
  if (n !== 1) return q;
  const fig = (task.spec?.figures || []).find((f) => f.visual_type === 'table');
  if (!fig) throw new Error('mock writing task1: pick a session whose Task 1 is a table (the page draws tables natively)');
  const p = fig.payload;
  return {
    ...q,
    table: {
      title: fig.title,
      head: [p.corner_label, ...p.columns.map((c) => c.label)],
      rows: p.row_headings.map((heading, i) => [heading, ...p.cells[i]]),
    },
  };
}

/** 模考一道题的结果，换成日常写作评分的形状（writing.cjs 的 review / weakest 认的那种）。 */
function scored(m, n) {
  const r = m.detail.task_reviews.find((x) => x.task === n);
  return {
    band: m.detail.task_scores.find((x) => x.task === n).band,
    essay: m.tasks[n - 1].essay,
    detail: {
      criteria: r.criteria,
      overall_feedback: r.feedback_en,
      overall_feedback_cn: r.feedback_cn,
      academic_upgrades: r.annotations.map((x) => ({
        original: x.quote, improved: x.replacement, reason: x.message_en, reason_cn: x.message_cn,
      })),
    },
  };
}

exports.build = ({ learner }) => {
  const m = session(SESSION, learner);
  const t1 = scored(m, 1);
  const t2 = scored(m, 2);
  const r1 = review(t1);
  const r2 = review(t2);
  return {
    'questions.json': {
      ielts: {
        writing: {
          mock: {
            task1: question(m.tasks[0], 1),
            task2: question(m.tasks[1], 2),
            // 这场模考的评分页：从模考写作进评分页时看这一块（页面按 sessionMode 取），形状同 writing_review.json。
            // 放在题库里而不是 writing_review.json 里：那个文件再大就过 50 KB，flutter test 里改由 isolate 解码，
            // 路由审计等不到它，会停在转圈上。
            review: {
              overall: band(m.score), // 后端存的整场分数（Task 1 : Task 2 = 1 : 2）
              weak: [weakest(t1, 1), weakest(t2, 2)],
              task1: { ...r1.block, essay: r1.essay, notes: r1.notes },
              WF_T2: r2.block,
              WF_T2_ESSAY: r2.essay,
              WF_T2_NOTES: r2.notes,
              hasL1: false, // 模考不做母语负迁移检查，页面不出那个页签
            },
          },
        },
      },
    },
  };
};
