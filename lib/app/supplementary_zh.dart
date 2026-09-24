/// 全局中文补充词典（用户 2026-09-24）。
///
/// 规则：中文模式下除考试题干与选项外全部中文；英文模式保持源站英文原文。
/// 这些字符串在源站里就是硬编码英文，`i18n.json` 只有「中文→英文」方向，
/// 因此中文模式查不到译文、一直露英文。这里按英文原文索引补中文，
/// 由 [Translator] 在中文分支末尾查询，全站生效。
///
/// 只覆盖界面文案（任务名称、说明、标签、提示、按钮），
/// 不含阅读文章、听力原文、题目问句与 A/B/C 选项 —— 那些按用户要求保持英文。
library;

const supplementaryZh = <String, String>{
  // ---- 页面标题与副标题 ----
  'Reading (Mock Exam)': '阅读（模拟考）',
  'Academic Reading (Mock Exam)': '学术阅读（模拟考）',
  'Listening (Mock Exam)': '听力（模拟考）',
  'Academic Writing (Mock Exam)': '学术写作（模拟考）',
  'Speaking (Mock Exam)': '口语（模拟考）',
  'Ready to start Speaking?': '准备开始口语了吗？',
  'Three passages, one clock. The timer covers all three passages, so pace yourself.':
      '三篇文章共用一个计时。计时覆盖全部三篇，请自行分配节奏。',
  'Four task types across two modules. Every recording plays once, so listen closely and use the notes panel as you go.':
      '两个模块共四种任务类型。每段录音只播放一次，请仔细听，并随时使用笔记区。',
  'Two tasks share a single sixty-minute clock. Task 2 carries twice the marks of Task 1, so most candidates spend about twenty minutes on Task 1 and forty on Task 2.':
      '两个任务共用一个 60 分钟计时。任务 2 的分值是任务 1 的两倍，多数考生在任务 1 上用约 20 分钟，在任务 2 上用 40 分钟。',
  'The examiner asks the questions and recording starts automatically after each one. The exam runs through Part 1, Part 2 and Part 3 in order.':
      '考官提问，每题结束后自动开始录音。考试按 Part 1、Part 2、Part 3 顺序进行。',
  'A short introduction plays first. It explains that the recording plays once only, and that you may take notes while listening.':
      '开始前会播放一段简短说明，告知录音只播放一次，且听的过程中可以做笔记。',

  // ---- 托福阅读任务 ----
  'Complete the Words': '补全单词',
  'Fill in the missing letters in a short paragraph.': '在一小段文字中填入缺失的字母。',
  'Letter counts shown': '显示字母数',
  'Read in Daily Life': '日常阅读',
  'Answer questions about everyday material such as notices and emails.':
      '回答有关通知、邮件等日常材料的问题。',
  'Shorter texts': '较短篇幅',
  'Read an Academic Passage': '学术阅读',
  'Answer questions about a longer academic text.': '回答有关一篇较长学术文章的问题。',
  'Longest task': '篇幅最长',

  // ---- 雅思阅读篇章 ----
  'Passage 1': '篇章 1',
  'Passage 2': '篇章 2',
  'Passage 3': '篇章 3',
  'A general-interest text, usually the most accessible of the three.':
      '大众题材文章，通常是三篇中最易读的一篇。',
  'A work or study related text carrying more detail.': '与工作或学习相关的文章，细节更多。',
  'A longer academic argument, usually the most demanding.':
      '较长的学术论述，通常难度最高。',
  'About 13 questions': '约 13 题',
  'About 14 questions': '约 14 题',

  // ---- 托福听力任务 ----
  'Listen and Choose a Response': '听后选择回应',
  'Pick the best reply to a short question or statement.': '为简短的问题或陈述选出最佳回复。',
  'Short audio': '短音频',
  'Listen to a Conversation': '听对话',
  'Answer questions about a short everyday conversation.': '回答有关一段简短日常对话的问题。',
  'Listen to an Announcement': '听通知',
  'Answer questions about a campus announcement.': '回答有关校园通知的问题。',
  'Listen to an Academic Talk': '听学术讲座',
  'Answer questions about a short academic talk.': '回答有关一段简短学术讲座的问题。',
  '2-3 questions': '2-3 题',
  '3-4 questions': '3-4 题',

  // ---- 雅思听力部分 ----
  'Part 1 · Everyday conversation': 'Part 1 · 日常对话',
  'Part 2 · Everyday monologue': 'Part 2 · 日常独白',
  'Part 3 · Academic discussion': 'Part 3 · 学术讨论',
  'Part 4 · Academic lecture': 'Part 4 · 学术讲座',
  'A conversation between two people in a social context.': '两人在社交场景中的对话。',
  'One speaker on a familiar everyday topic.': '一位说话者谈论熟悉的日常话题。',
  'Up to four speakers in an educational context.': '教育场景中最多四位说话者。',
  'One speaker on an academic subject.': '一位说话者讲述学术主题。',
  '10 questions': '10 题',

  // ---- 口语任务 ----
  'Listen and Repeat': '听读复述',
  'Listen to a sentence and repeat it exactly as you heard it.':
      '听一句话，然后原样复述。',
  'Plays once': '只播一次',
  'Take an Interview': '参加访谈',
  'Answer a few short interview questions in your own words.':
      '用自己的话回答几个简短的访谈问题。',

  // 'Task 1' / 'Task 2' 故意不收：它们同时是写作批改页的评分维度标签，
  // 全局翻译会把那里的标签一起改掉。模考页的任务名由页面自己给中文。

  // ---- 标签与按钮 ----
  'MOCK EXAM · REAL TIMING': '模拟考 · 真实计时',
  'MOCK EXAM · ONE SHARED CLOCK': '模拟考 · 共用计时',
  // 科目标签：源站的 IELTS/TOEFL 前缀在中文模式下保留品牌名。
  'TOEFL READING': '托福阅读',
  'TOEFL LISTENING': '托福听力',
  'IELTS ACADEMIC READING': '雅思学术阅读',
  'IELTS LISTENING': '雅思听力',
  'IELTS ACADEMIC WRITING': '雅思学术写作',
  'IELTS SPEAKING': '雅思口语',
  // 规格标签
  '2 MODULES · UP TO 50 QUESTIONS': '2 个模块 · 最多 50 题',
  '2 MODULES · UP TO 47 QUESTIONS': '2 个模块 · 最多 47 题',
  '3 PASSAGES · 40 QUESTIONS · 60 MIN': '3 篇文章 · 40 题 · 60 分钟',
  '4 PARTS · 40 QUESTIONS · ABOUT 30 MIN': '4 个部分 · 40 题 · 约 30 分钟',
  '2 TASKS · 60 MIN': '2 个任务 · 60 分钟',
  '2 TASK TYPES · MICROPHONE NEEDED': '2 种任务类型 · 需要麦克风',
  '3 PARTS · 11-14 MIN · MICROPHONE NEEDED': '3 个部分 · 11-14 分钟 · 需要麦克风',
  'TASK 1 OF 2': '第 1 / 2 题',
  'I am ready, start module 1': '我准备好了，开始模块 1',
  'I confirm, start Passage 1': '确认开始，进入篇章 1',
  'I confirm, start Part 1': '确认开始，进入 Part 1',
  'I confirm, start the 60-minute clock': '确认开始 60 分钟计时',
  'I am ready, check my microphone': '我准备好了，检查麦克风',
  'I confirm, check my microphone': '确认开始，检查麦克风',
  'Start Part 1': '开始 Part 1',
  'Back': '返回',
  'One minute of preparation is given in Part 2 only, and it is timed.':
      '仅 Part 2 提供 1 分钟准备时间，并且计时。',

  // ---- 其它页面的界面文案 ----
  'Welcome back, Nafis!': '欢迎回来，Nafis！',
  'Continue Writing': '继续写作',
  'Everyday English': '日常英语',
  'Exam Prep': '考试备考',
  'Select one that applies to you': '请选择适合你的一项',
  'Which one do you want to continue ?': '你想继续哪一项？',
  'What do you mock the exam first?': '先模考哪一科？',
  'Listen: same word or different words?': '听一听：是同一个词还是不同的词？',
  'Completed paragraph': '补全后的段落',
  'Data/chart description': '数据/图表描述',
  'TOEFL SPEAKING': '托福口语',
  'TOEFL WRITING': '托福写作',
  'TASK 2 OF 2': '第 2 / 2 题',
  // 口语任务指令属于界面引导，不是题干本身。
  'The question is spoken aloud. Listen and answer.': '题目会朗读出来，请听后作答。',
  'You should say:': '你需要谈到：',
  'You have volunteered for a research study at your university about work experience. You will have a short online interview with a researcher. The researcher will ask you some questions.':
      '你报名参加了学校一项关于工作经历的研究。你将与研究员进行一次简短的线上访谈，研究员会向你提问。',
};
