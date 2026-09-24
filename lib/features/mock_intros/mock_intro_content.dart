import '../../app/app_state.dart';
import '../../app/routes.dart';

/// 全局模拟考「介绍 / 准备」七页的**源常量端口**。
///
/// 归属（own）：`lib/features/mock_intros/**` + `test/mock_intros*.dart`。
///
/// 逐字对应原型 `app.js` 的七个视图函数（见 `_extract/logic/fns/`）：
///   * mockReadingView / mockReadingIntroView
///   * mockListeningView / mockListeningIntroView
///   * mockSpeakingView / mockSpeakingIntroView
///   * mockWritingIntroView
///
/// 以及它们 onclick 里串起来的动作函数：
///   mockReadConfirmStart / mockReadStartReady / mlConfirmStart /
///   mockSpkIntroStart / mwStartReady，和被它们调用的
///   openMockReadySheet / mrStart / mwStart / spqSetPart /
///   startTfRead1 / startTfListen / startTfSpk1。
///
/// 这里只保留**文案 + 分支 + 下一步状态重置**，不发明任何新内容。
/// TOEFL/IELTS 分支、时长、准备弹窗、以及跳下一页时的状态重置都一字照抄。
/// 页面 body 为自然高度，纵向滚动由外层 shell 的 SingleChildScrollView 承担。

/// 模拟考流程里的一「行」题型条：编号 / 标题 / 说明 / 时长或题量标签。
/// 对应原型 IELTS 的 `.ml-bar` 与 TOEFL 的 `tfMlCard` 所承载的四个字段。
class MockPart {
  const MockPart(this.num, this.title, this.desc, this.chip, [this.icon]);
  final String num;
  final String title;
  final String desc;
  final String chip;

  /// 仅 TOEFL 分支带图标键（wordfill / respond ...）；IELTS 为 null。
  final String? icon;
}

/// 一段「加粗前缀 + 普通说明」的 tip / note 行。
class MockTip {
  const MockTip(this.bold, this.rest);
  final String bold;
  final String rest;
}

/// openMockReadySheet 用的三段文案，源 `const MOCK_READY`（app.js 2026-2046）。
class MockReadyCopy {
  const MockReadyCopy(this.title, this.sub, this.note);
  final String title;
  final String sub;
  final String note;
}

/// 源 `MOCK_READY` 对象，四科各一份，文案一字不改。
const kMockReady = <String, MockReadyCopy>{
  'reading': MockReadyCopy(
    '准备好了吗？',
    '你有六十分钟，完成三篇文章、共四十道题。',
    '开始作答即开始计时。',
  ),
  'listening': MockReadyCopy(
    '准备好了吗？',
    '先播放一段简短说明，告知录音仅播放一次，随后从第 1 题开始考试。',
    '录音仅播放一次，不能暂停、后退或重播。',
  ),
  'speaking': MockReadyCopy(
    '准备好了吗？',
    '考官提问，每问结束后自动开始录音。考试按 Part 1、Part 2、Part 3 的顺序进行。',
    '仅 Part 2 提供 1 分钟准备时间，且会计时。',
  ),
  'writing': MockReadyCopy(
    '准备好了吗？',
    '两个任务共用六十分钟，提交前可随时在 Task 1 与 Task 2 之间切换。',
    '开始作答即开始计时。',
  ),
};

// ---------------------------------------------------------------- 题型条数据
// 源 mockReadingView.js / mockListeningView.js / mockSpeakingView.js /
// mockWritingIntroView.js 的 parts / tasks 数组，TOEFL 与 IELTS 各一套。

const kReadingPartsToefl = <MockPart>[
  MockPart('1', 'Complete the Words',
      'Fill in the missing letters in a short paragraph.', 'Letter counts shown', 'wordfill'),
  MockPart('2', 'Read in Daily Life',
      'Answer questions about everyday material such as notices and emails.', 'Shorter texts', 'liferead'),
  MockPart('3', 'Read an Academic Passage',
      'Answer questions about a longer academic text.', 'Longest task', 'acadread'),
];
const kReadingPartsIelts = <MockPart>[
  MockPart('1', 'Passage 1',
      'A general-interest text, usually the most accessible of the three.', 'About 13 questions'),
  MockPart('2', 'Passage 2',
      'A work or study related text carrying more detail.', 'About 13 questions'),
  MockPart('3', 'Passage 3',
      'A longer academic argument, usually the most demanding.', 'About 14 questions'),
];

const kListeningPartsToefl = <MockPart>[
  MockPart('1', 'Listen and Choose a Response',
      'Pick the best reply to a short question or statement.', 'Short audio', 'respond'),
  MockPart('2', 'Listen to a Conversation',
      'Answer questions about a short everyday conversation.', '2-3 questions', 'convo'),
  MockPart('3', 'Listen to an Announcement',
      'Answer questions about a campus announcement.', '2-3 questions', 'announce'),
  MockPart('4', 'Listen to an Academic Talk',
      'Answer questions about a short academic talk.', '3-4 questions', 'lecture'),
];
const kListeningPartsIelts = <MockPart>[
  MockPart('1', 'Part 1 · Everyday conversation',
      'A conversation between two people in a social context.', '10 questions'),
  MockPart('2', 'Part 2 · Everyday monologue',
      'One speaker on a familiar everyday topic.', '10 questions'),
  MockPart('3', 'Part 3 · Academic discussion',
      'Up to four speakers in an educational context.', '10 questions'),
  MockPart('4', 'Part 4 · Academic lecture',
      'One speaker on an academic subject.', '10 questions'),
];

const kSpeakingPartsToefl = <MockPart>[
  MockPart('1', 'Listen and Repeat',
      'Listen to a sentence and repeat it exactly as you heard it.', 'Plays once', 'retell'),
  MockPart('2', 'Take an Interview',
      "Answer the interviewer's questions in your own words.", 'No preparation time', 'interview'),
];
const kSpeakingPartsIelts = <MockPart>[
  MockPart('1', 'Part 1 · Interview',
      'Familiar topics such as your home, work, studies and interests.', '4-5 min'),
  MockPart('2', 'Part 2 · Long turn',
      'A cue card with one minute to prepare, then you speak alone.', '3-4 min'),
  MockPart('3', 'Part 3 · Discussion',
      'Broader, more abstract questions linked to the Part 2 topic.', '4-5 min'),
];

const kWritingTasks = <MockPart>[
  MockPart('1', 'Task 1 · Describe visual information',
      'Summarise a chart, table, map or process in your own words.', 'At least 150 words · about 20 min'),
  MockPart('2', 'Task 2 · Essay',
      'Respond to a point of view, argument or problem with a structured essay.', 'At least 250 words · about 40 min'),
];

// ---------------------------------------------------------------- tips / notes

const kReadingTipsIelts = <MockTip>[
  MockTip('每篇单独计时', '三篇各 20 分钟，当前这篇用完之后才进入下一篇。'),
  MockTip('篇内自由切换', '同一篇里可以任意顺序作答，随时回到前面的题目。'),
  MockTip('批改前可核对', '三篇都完成后统一提交，提交前都能回头检查。'),
];
const kListeningTipsIelts = <MockTip>[
  MockTip('录音只播一次', '不能暂停、后退或重播，请集中注意力。'),
  MockTip('题目顺序与录音一致', '答案会在录音中依次出现。'),
  MockTip('拼写计入评分', '答案按你实际拼写判分。'),
];
const kSpeakingTipsToefl = <MockTip>[
  MockTip('提示音后自动开录', '本部分不提供准备时间。'),
  MockTip('不能回到上一题', '每段音频只播放一次。'),
  MockTip('现在就检查麦克风', '下一屏会出现音量条。'),
];
const kSpeakingTipsIelts = <MockTip>[
  MockTip('仅 Part 2 提供准备时间', '1 分钟，且会计时。'),
  MockTip('每题只播一次', '提示音后自动开始录音。'),
  MockTip('现在就检查麦克风', '下一屏会出现音量条。'),
];
const kWritingNote = <MockTip>[
  MockTip('两个任务共用一个计时，', '六十分钟由你自行分配。'),
  MockTip('可自由切换，', '提交前在 Task 1 与 Task 2 之间随时来回。'),
  MockTip('低于词数下限会被扣分，', '提交前实时字数会提醒你。'),
];

// ---------------------------------------------------------------- 下一步状态重置
// 每个 apply* 把原型跳下一页前对全局变量做的重置，逐条写入 AppState.session
// （沿用原始变量名作为键），随后跳向既有 enum 页。不新增内容、不改数值。

/// mrStart()：mrPas=1; mrAns={}; mrLeft=60*60; go('mockReadingQ')。
void applyReadingIelts(AppState s) {
  s.session['mrPas'] = 1;
  s.session['mrAns'] = <String, dynamic>{};
  s.session['mrLeft'] = 60 * 60;
  s.go(SurgoPage.mockReadingQ);
}

/// startTfRead1()：tfR1Para=0; tfR1Vals={}; tfR1Left=TFRD1_SEC(30*60); go('tfRead1Q')。
void applyReadingToefl(AppState s) {
  s.session['tfR1Para'] = 0;
  s.session['tfR1Vals'] = <String, dynamic>{};
  s.session['tfR1Left'] = 30 * 60;
  s.go(SurgoPage.tfRead1Q);
}

/// mlConfirmStart() 的雅思分支：done=()=>go('mockListeningQ')（无状态重置）。
void applyListeningIelts(AppState s) {
  s.go(SurgoPage.mockListeningQ);
}

/// startTfListen()：tfSeg=0; tfPicks={}; tfNotes={}; tfPhase='play';
/// tfAudio=0; tfLeft=TF_ANSWER_SEC(20); go('tfListenQ')。
void applyListeningToefl(AppState s) {
  s.session['tfSeg'] = 0;
  s.session['tfPicks'] = <String, dynamic>{};
  s.session['tfNotes'] = <String, dynamic>{};
  s.session['tfPhase'] = 'play';
  s.session['tfAudio'] = 0;
  s.session['tfLeft'] = 20;
  s.go(SurgoPage.tfListenQ);
}

/// spqSetPart('p1')：spqPart='p1'; spqIdx=0; spqLeft=SPQ.p1.sec(5*60);
/// spqTurns=[]; spqBusy=false; spqRec=false; spqRecSec=0; go('mockSpeakingQ')。
/// （原型还会清理 spq/sp2/sp3 计时器与语音合成；那些在对应作答页控制器里承接。）
void applySpeakingIelts(AppState s) {
  s.session['spqPart'] = 'p1';
  s.session['spqIdx'] = 0;
  s.session['spqLeft'] = 5 * 60;
  s.session['spqTurns'] = <dynamic>[];
  s.session['spqBusy'] = false;
  s.session['spqRec'] = false;
  s.session['spqRecSec'] = 0;
  s.go(SurgoPage.mockSpeakingQ);
}

/// startTfSpk1()：tfS1Seg=0; tfS1Phase='instruct'; tfS1Audio=0;
/// tfS1Left=TFSPK1_INSTR_SEC(5); go('tfSpk1Q')。
void applySpeakingToefl(AppState s) {
  s.session['tfS1Seg'] = 0;
  s.session['tfS1Phase'] = 'instruct';
  s.session['tfS1Audio'] = 0;
  s.session['tfS1Left'] = 5;
  s.go(SurgoPage.tfSpk1Q);
}

/// mwStart()：mwTask=1; mwText={1:'',2:''}; mwLeft=60*60; mwWarnCount=0;
/// go('mockWritingQ')。
void applyWriting(AppState s) {
  s.session['mwTask'] = 1;
  s.session['mwText'] = <String, String>{'1': '', '2': ''};
  s.session['mwLeft'] = 60 * 60;
  s.session['mwWarnCount'] = 0;
  s.go(SurgoPage.mockWritingQ);
}
