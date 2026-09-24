import 'package:flutter/foundation.dart';

/// 页面键 —— 与 H5 原型 `app.js` 里 `const V = { ... }` 的键名逐个对应（共 141 个）。
///
/// 用 enum 而不是字符串，是为了让「页面清单」这件事在编译期就受保护：
/// 少一页、拼错一个键，编译器直接报错，而不是运行时静默走到空白页。
///
/// 原型的 `go(id)` 是 `if(!V[id])return; render(id);` ——
/// 注册表里没有的 id 会被静默忽略。这里用枚举把同样的语义表达出来。
enum SurgoPage {
  workspace,
  exam,
  report,
  ielts,
  writingDaily,
  writingSession,
  writingPlan,
  writingCompose,
  readingSession,
  readingFeedback,
  listeningFeedback,
  listeningSession,
  speakingSession,
  oralExam,
  speakingReview,
  oralDiscuss,
  pronCourse,
  pronLesson,
  pronListen,
  pronRepeat,
  pronSentence,
  pronDone,
  pronCongrats,
  pron2Lesson,
  pron2Repeat,
  pron2Done,
  pronCongrats2,
  typeSession,
  writingFeedback,
  writingImprove,
  writingBands,
  writingL1Error,
  writingL1Detail,
  listeningDaily,
  readingDaily,
  tfDailyWords,
  tfDwFb,
  tfDailyLife,
  tfDlFb,
  tfDailyAcad,
  tfDaFb,
  tfDailyResp,
  tfDailyRetell,
  tfDailyInterview,
  tfRetellFb,
  tfInterviewFb,
  tfDrFb,
  tfDailyConvo,
  tfDcFb,
  tfDailyAnn,
  tfAnFb,
  tfDailyLect,
  tfLcFb,
  speakingDaily,
  vocabDaily,
  vocab,
  vocabBook,
  vocabWord,
  vocabWord2,
  vocabWord3,
  vocabWord4,
  vocabPron,
  vocabPronWord,
  vocabPronWord2,
  vocabPronStudy,
  vocabPronStudy2,
  vocabPronStudy3,
  vocabPronStudyB,
  vocabPronStudyB2,
  vocabPronStudyB3,
  vocabPronDone,
  vocabTier1,
  vocabTier2,
  vocabNoNew,
  vocabTier3,
  vocabTier4,
  mockReading,
  mockReadingIntro,
  mockWritingIntro,
  mockWritingTf,
  tfBrief,
  tfWr1Intro,
  tfWr1Q,
  tfSentFb,
  tfEmailFb,
  tfDiscFb,
  tfWr2Intro,
  tfWr2Q,
  tfWr3Intro,
  tfWr3Q,
  tfWriteFb,
  mockWritingQ,
  mockReadingQ,
  mockSpeaking,
  mockSpeakingIntro,
  mockSpeakingQ,
  mockListening,
  mockListeningIntro,
  tfListenQ,
  tfConvQ,
  tfAnnQ,
  tfTalkQ,
  tfModEnd,
  tfModLoad,
  tfMod2Intro,
  tfM2P1Q,
  tfM2P2Q,
  tfM2P3Q,
  tfListenFb,
  tfSpk1Q,
  tfSpk2Intro,
  tfSpk2Brief,
  tfSpk2Q,
  tfSpeakFb,
  tfRead1Q,
  tfRead2Q,
  tfReadModEnd,
  tfReadModLoad,
  tfReadMod2Intro,
  tfRead3Q,
  tfRead4Q,
  tfReadFb,
  mockListeningQ,
  mockListeningQ2,
  mockListeningQ3,
  mockListeningQ4,
  vocabTest,
  vocabTestQ,
  vocabTestPass,
  vocabTestFail,
  vocabStudy,
  vocabStudy2,
  vocabStudy3,
  vocabStudy4,
  vocabDetail,
  vocabDetail2,
  vocabDetail3,
  vocabDetail4,
  vocabDone,
  prep,
  examTimer,
  // 用户 2026-09-25：Figma 文件 gW9DKhEd6UuQQAnv32BlXH 第 5 页的 13 个登录注册页。
  // 这批不属于原型 H5，是新增设计稿；注释里标的是对应 Figma frame。
  authSplash, // 40:363  "80"       黄底启动页
  authSignUp, // 40:388  "81"       注册表单
  authError, // 40:472  "错误页面"    加载失败重试
  authWelcome, // 40:500  "82"       欢迎 + 第三方登录
  authOtp, // 40:1415 "POP UP"   OTP 验证码 + 条款弹窗
  authCongrats, // 40:1485            注册成功 + 选语言
  authForgot, // 40:1648            忘记密码：填邮箱
  authCheckEmail, // 40:1689            去邮箱查收
  authResetEmail, // 40:1729            邮箱验证码
  authResetPhone, // 40:1855            手机验证码
  authNewPassword, // 40:1981            设置新密码
  authSignIn, // 40:2052            登录（邮箱 + 密码）
  authSignInAlt, // 40:2192            登录（另一版）
}

/// 登录注册流程 —— 铺满全屏，没有底部导航、没有右上角全局按钮，
/// 也不吃 shell 的 18px 内边距（各页按设计稿自己的 25px 边距排版）。
const kAuthPages = <SurgoPage>{
  SurgoPage.authSplash,
  SurgoPage.authSignUp,
  SurgoPage.authError,
  SurgoPage.authWelcome,
  SurgoPage.authOtp,
  SurgoPage.authCongrats,
  SurgoPage.authForgot,
  SurgoPage.authCheckEmail,
  SurgoPage.authResetEmail,
  SurgoPage.authResetPhone,
  SurgoPage.authNewPassword,
  SurgoPage.authSignIn,
  SurgoPage.authSignInAlt,
};

/// 页面键 ↔ 字符串互转。路由状态里存字符串，方便与原型日志、深链对齐。
extension SurgoPageX on SurgoPage {
  String get key => name;

  static SurgoPage? fromKey(String key) {
    for (final p in SurgoPage.values) {
      if (p.name == key) return p;
    }
    return null;
  }
}

/// 底部悬浮导航出现的页面 —— 原型：`const NAV_PAGES=['ielts','report','prep'];`
const kNavPages = <SurgoPage>{
  SurgoPage.ielts,
  SurgoPage.report,
  SurgoPage.prep,
};

/// 作答/考试/批改类页面统一暖白底（`SOFT_PAGES`）——
/// 原型 render() 里这一串决定 `.phone.we-bg{background:#FCF8F5}`。
const kSoftPages = <SurgoPage>{
  SurgoPage.tfDailyWords,
  SurgoPage.tfDwFb,
  SurgoPage.tfDailyLife,
  SurgoPage.tfDlFb,
  SurgoPage.tfDailyAcad,
  SurgoPage.tfDaFb,
  SurgoPage.tfDailyResp,
  SurgoPage.tfDailyRetell,
  SurgoPage.tfDailyInterview,
  SurgoPage.tfRetellFb,
  SurgoPage.tfInterviewFb,
  SurgoPage.tfDrFb,
  SurgoPage.tfDailyConvo,
  SurgoPage.tfDcFb,
  SurgoPage.tfDailyAnn,
  SurgoPage.tfAnFb,
  SurgoPage.tfDailyLect,
  SurgoPage.tfLcFb,
  SurgoPage.vocabNoNew,
  SurgoPage.readingSession,
  SurgoPage.typeSession,
  SurgoPage.listeningSession,
  SurgoPage.writingSession,
  SurgoPage.speakingSession,
  SurgoPage.examTimer,
  SurgoPage.readingFeedback,
  SurgoPage.listeningFeedback,
  SurgoPage.writingFeedback,
  SurgoPage.writingImprove,
  SurgoPage.writingBands,
  SurgoPage.writingL1Error,
  SurgoPage.writingL1Detail,
  SurgoPage.writingPlan,
  SurgoPage.writingCompose,
  SurgoPage.oralExam,
  SurgoPage.speakingReview,
  SurgoPage.pronCourse,
  SurgoPage.pronLesson,
  SurgoPage.pronListen,
  SurgoPage.pronRepeat,
  SurgoPage.pronSentence,
  SurgoPage.pronDone,
  SurgoPage.pronCongrats,
  SurgoPage.pron2Lesson,
  SurgoPage.pron2Repeat,
  SurgoPage.pron2Done,
  SurgoPage.pronCongrats2,
  SurgoPage.vocab,
  SurgoPage.vocabBook,
  SurgoPage.vocabWord,
  SurgoPage.vocabWord2,
  SurgoPage.vocabWord3,
  SurgoPage.vocabWord4,
  SurgoPage.vocabPron,
  SurgoPage.vocabPronWord,
  SurgoPage.vocabPronWord2,
  SurgoPage.vocabPronStudy,
  SurgoPage.vocabPronStudy2,
  SurgoPage.vocabPronStudy3,
  SurgoPage.vocabPronStudyB,
  SurgoPage.vocabPronStudyB2,
  SurgoPage.vocabPronStudyB3,
  SurgoPage.vocabPronDone,
  SurgoPage.vocabTier1,
  SurgoPage.vocabTier2,
  SurgoPage.vocabTier3,
  SurgoPage.vocabTier4,
  SurgoPage.mockReading,
  SurgoPage.mockReadingIntro,
  SurgoPage.mockWritingIntro,
  SurgoPage.mockWritingTf,
  SurgoPage.tfWr1Intro,
  SurgoPage.tfWr1Q,
  SurgoPage.tfSentFb,
  SurgoPage.tfEmailFb,
  SurgoPage.tfDiscFb,
  SurgoPage.tfWr2Intro,
  SurgoPage.tfWr2Q,
  SurgoPage.tfWr3Intro,
  SurgoPage.tfWr3Q,
  SurgoPage.mockWritingQ,
  SurgoPage.mockReadingQ,
  SurgoPage.mockSpeaking,
  SurgoPage.mockSpeakingIntro,
  SurgoPage.mockSpeakingQ,
  SurgoPage.mockListening,
  SurgoPage.mockListeningIntro,
  SurgoPage.mockListeningQ,
  SurgoPage.mockListeningQ2,
  SurgoPage.mockListeningQ3,
  SurgoPage.mockListeningQ4,
  SurgoPage.vocabTest,
  SurgoPage.vocabTestQ,
  SurgoPage.vocabTestPass,
  SurgoPage.vocabTestFail,
  SurgoPage.vocabStudy,
  SurgoPage.vocabStudy2,
  SurgoPage.vocabStudy3,
  SurgoPage.vocabStudy4,
  SurgoPage.vocabDetail,
  SurgoPage.vocabDetail2,
  SurgoPage.vocabDetail3,
  SurgoPage.vocabDetail4,
  SurgoPage.vocabDone,
};

/// 雅思模拟考作答页 —— 原型：`const EXAM_PAGES=[...]`。
/// render() 里 `exam-on` 用来隐藏右上角全局按钮，把位置让给计时。
const kExamPages = <SurgoPage>{
  SurgoPage.mockReadingQ,
  SurgoPage.mockListeningQ,
  SurgoPage.mockListeningQ2,
  SurgoPage.mockListeningQ3,
  SurgoPage.mockListeningQ4,
  SurgoPage.mockWritingQ,
  SurgoPage.mockSpeakingQ,
};

/// 考试类型。
///
/// 原型里这是个裸的全局变量 `let examType='ielts'`，到处直接读写；
/// 这里收成枚举，但取值语义完全一致。
enum ExamType {
  ielts,
  toefl;

  String get label => this == ExamType.ielts ? 'IELTS' : 'TOEFL';
}

/// 界面语言 —— 原型：`let uiLang='zh'`。
enum UiLang { zh, en }

/// 只用于 debug 时断言页面清单没漏。
@visibleForTesting
bool debugPageCountMatchesSource() => SurgoPage.values.length == 141;