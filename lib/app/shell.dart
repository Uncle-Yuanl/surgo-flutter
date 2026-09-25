import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/reading_wizard/reading_wizard_page.dart';
import '../features/pron_course/pron_course_module.dart';
import '../features/oral_daily/page.dart';
import '../features/legacy_entry/module.dart';
import '../features/ielts_mock_listening/ielts_mock_listening_module.dart';
import '../features/oral_daily/session_page.dart';
import '../features/vocab_words/vocab_words_module.dart';
import '../features/vocab_home/vocab_home_page.dart';
import '../features/vocab_quiz/vocab_quiz_module.dart';
import '../features/vocab_tiers/vocab_tiers_module.dart';
import '../features/vocab_details/vocab_details_module.dart';
import '../features/vocab_pron_book/vocab_pron_book_module.dart';
import '../features/vocab_pron_study/vocab_pron_study_module.dart';
import '../features/training_wizards/training_wizards_module.dart';
import '../features/writing_workspace/writing_workspace_module.dart';
import '../features/writing_review/writing_review_page.dart';
import '../features/speaking_review/speaking_review_page.dart';
import '../features/mock_intros/mock_intro_module.dart';
import '../features/pron_practice/pron_practice_module.dart';
import '../features/pron_listen/pron_listen_page.dart';
import '../features/report/report_page.dart';
import '../features/profile/profile_page.dart';
import '../features/task_brief/task_brief_page.dart';
import '../features/toefl_words/toefl_words_module.dart';
import '../features/toefl_life/toefl_life_module.dart';
import '../features/tf_acad/tf_acad_module.dart';
import '../widgets/mock_selector.dart';
import '../features/ielts_reading/reading_page.dart';
import '../features/ielts_mock_writing/page.dart';
import '../features/ielts_mock_reading/page.dart';
import '../features/ielts_mock_speaking/page.dart';
import '../features/ielts_reading/reading_feedback.dart';
import '../features/ielts_listening/ielts_listening_module.dart';
import '../features/tf_listening_daily/module.dart';
import '../features/tf_writing/module.dart';
import '../features/tf_speaking_daily/module.dart';
import '../features/tf_speaking_mock/module.dart';
import '../features/tf_listening_mock/module.dart';
import '../features/tf_reading_mock/module.dart';
import '../features/tf_reading_mock/page.dart';
import '../features/writing_legacy/writing_legacy_page.dart';
import '../features/tf_writing/feedback.dart';
import '../pages/exam_selection_page.dart';
import '../pages/home_page.dart';
import '../features/auth/auth_routes.dart';
import '../theme/tokens.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/phone_frame.dart';
import '../widgets/global_menu.dart';
import '../widgets/continue_sheet.dart';
import '../widgets/primitives.dart';
import 'app_state.dart';
import 'routes.dart';

/// Rendering stays native. Unimplemented routes remain explicitly identified;
/// a route enum entry is not evidence of a completed migration.
class SurgoShell extends StatelessWidget {
  const SurgoShell({super.key,this.readingAuditSeconds});
  final int? readingAuditSeconds;
  @override
  Widget build(BuildContext context) {
    final page=context.watch<AppState>().current;
    return PhoneFrame(background:kSoftPages.contains(page)?SurgoColors.warmWhite:SurgoColors.bg,
      backgroundLayer:page==SurgoPage.report?const ReportBackground():null,
      fitToScreen:MediaQuery.sizeOf(context).width<520,
      // All modal routes are inside the phone, never over the whole desktop.
      child:Navigator(onGenerateRoute:(_)=>MaterialPageRoute<void>(builder:(_)=>_PhoneBody(readingAuditSeconds:readingAuditSeconds))));
  }
}
class _PhoneBody extends StatefulWidget {
  const _PhoneBody({this.readingAuditSeconds});
  final int? readingAuditSeconds;
  @override
  State<_PhoneBody> createState()=>_PhoneBodyState();
}
class _PhoneBodyState extends State<_PhoneBody> {
  String? menu;
  SurgoPage? previousPage;
  void closeMenu() { if(mounted)setState(()=>menu=null); }
  @override
  Widget build(BuildContext context) {
    final state=context.watch<AppState>();
    final page=state.current;
    if(previousPage!=page) { menu=null; previousPage=page; }
    final hasNav=kNavPages.contains(page);
    return Material(type:MaterialType.transparency,
      // H5 body uses natural font metrics and zero tracking, not Material's
      // bodyMedium height=1.43/letterSpacing=.25. Explicit page styles still win.
      // Body/question family per user request: SF Pro, Chinese via system fallback.
      textStyle:const TextStyle(fontFamily:SurgoFontFamily.body,
        fontFamilyFallback:SurgoFontFamily.fallback,fontSize:14,
        height:kTextHeightNone,letterSpacing:0,color:SurgoColors.ink),
      child:Stack(children:[
      // 用户 2026-09-25：开屏页与欢迎页要铺到状态栏后面
      // （开屏页黄底连状态栏一起满，欢迎页插画透到图标后）。
      // 状态栏图（status_bar.png）是透明 PNG，所以这两页从 top:0 起画，
      // 时间与信号图标浮在内容上。其余登录页顶部是返回键与标题，
      // 上移 52px 会被压住，连同 141 条原型路由仍从 52px 起。
      Positioned.fill(top:const{SurgoPage.authSplash,SurgoPage.authWelcome}.contains(page)?0:SurgoDevice.statusBarHeight,child:AnimatedSwitcher(
        duration:const Duration(milliseconds:300),
        // Default AnimatedSwitcher centers short children. H5 .screen always
        // fills the viewport; retain tight bounds even when a page fits.
        layoutBuilder:(current,previous)=>Stack(fit:StackFit.expand,
          children:[...previous,if(current!=null)current]),
        child:_ScreenSurface(key:ValueKey('${page.name}-${state.revision}'),page:page,hasNav:hasNav,readingAuditSeconds:widget.readingAuditSeconds))),
      const Positioned(top:0,left:0,right:0,child:PhoneStatusBar()),
      const Positioned(top:0,left:0,right:0,child:PhoneNotch()),
      if(hasNav) BottomNav(currentPage:page.name,onHome:()=>state.go(SurgoPage.ielts),
        onExam:()=>showMockSelector(context),onReport:()=>state.go(SurgoPage.report)),
      if(menu!=null) Positioned.fill(child:GestureDetector(behavior:HitTestBehavior.translucent,onTap:closeMenu)),
      GlobalButtons(showSettings:page!=SurgoPage.prep&&!kExamPages.contains(page)&&!kAuthPages.contains(page),
        showNotifications:!kExamPages.contains(page)&&!kAuthPages.contains(page),
        onSettings:()=>setState(()=>menu=menu=='settings'?null:'settings'),
        onNotifications:()=>setState(()=>menu=menu=='notes'?null:'notes')),
      if(menu!=null) Positioned(top:104,right:10,child:GlobalMenu(notifications:menu=='notes',close:closeMenu)),
    ]));
  }
}
class _ScreenSurface extends StatelessWidget {
  const _ScreenSurface({super.key,required this.page,required this.hasNav,this.readingAuditSeconds});
  final int? readingAuditSeconds;
  final SurgoPage page;
  final bool hasNav;
  @override
  Widget build(BuildContext context) {
    // 用户 2026-09-25：登录注册 13 页铺满全屏，自己控制边距（设计稿 25px），
    // 不走 shell 的 18px 内边距与外层滚动容器。
    final auth=buildAuthPage(page);
    if(auth!=null)return auth;
    final pronPractice=buildPronPracticePage(page);
    if(pronPractice!=null)return pronPractice; // Source fixed nav + bounded inner scroll.
    final pronCourse=buildPronCoursePage(page);
    if(pronCourse!=null)return pronCourse;
    if(page==SurgoPage.pronListen)return const PronListenPage();
    if(page==SurgoPage.writingSession||page==SurgoPage.writingPlan||page==SurgoPage.writingCompose) { return WritingWorkspacePage(page:page); }
    if(page==SurgoPage.writingFeedback) { return const WritingReviewPage(); }
    if(page==SurgoPage.readingFeedback) { return ScrollConfiguration(
      behavior:ScrollConfiguration.of(context).copyWith(scrollbars:false),
      child:const SingleChildScrollView(key:ValueKey('reading-feedback-scroll'),
        padding:EdgeInsets.fromLTRB(18,8,18,30),child:ReadingFeedbackPage())); }
    if(page==SurgoPage.prep) { return ScrollConfiguration(
      behavior:ScrollConfiguration.of(context).copyWith(scrollbars:false),
      child:const SingleChildScrollView(key:ValueKey('profile-scroll'),
        padding:EdgeInsets.fromLTRB(18,8,18,120),child:ProfilePage())); }
    if(page==SurgoPage.listeningFeedback) { return ScrollConfiguration(
      behavior:ScrollConfiguration.of(context).copyWith(scrollbars:false),
      child:const SingleChildScrollView(key:ValueKey('listening-feedback-scroll'),
        padding:EdgeInsets.fromLTRB(18,8,18,30),child:IeltsListeningPage(feedback:true))); }
    if(page==SurgoPage.report) { return ScrollConfiguration(
      behavior:ScrollConfiguration.of(context).copyWith(scrollbars:false),
      child:const SingleChildScrollView(key:ValueKey('report-scroll'),
        padding:EdgeInsets.fromLTRB(18,8,18,140),child:ReportPage())); }
    final writingLegacy=buildWritingLegacyPage(page);
    if(writingLegacy!=null) { return ScrollConfiguration(
      behavior:ScrollConfiguration.of(context).copyWith(scrollbars:false),
      child:SingleChildScrollView(key:const ValueKey('writing-legacy-scroll'),
        padding:const EdgeInsets.fromLTRB(18,8,18,30),child:writingLegacy)); }
    if(page==SurgoPage.vocab) { return const VocabHomePage(); }
    if(page==SurgoPage.vocabBook) { return const VocabBookPage(); }
    if(page==SurgoPage.vocabPron) { return const VocabPronPage(); }
    if(kVocabWordData.containsKey(page)) { return VocabWordPage(data:kVocabWordData[page]!); }
    if(kVocabPronWordData.containsKey(page)) { return VocabPronWordPage(data:kVocabPronWordData[page]!); }
    final tier=buildVocabTiersPage(page);
    if(tier!=null) { return tier; }
    if(kVocabDetailData.containsKey(page)) {
      return Padding(padding:const EdgeInsets.fromLTRB(18,8,18,0),
        child:SingleChildScrollView(key:const ValueKey('vocab-detail-scroll'),
          physics:const ClampingScrollPhysics(),child:VocabDetailPage(data:kVocabDetailData[page]!)));
    }
    if(page==SurgoPage.readingSession||page==SurgoPage.typeSession)return IeltsReadingPage(single:page==SurgoPage.typeSession,auditSeconds:readingAuditSeconds);
    // Listening now uses the reading bounded layout (two scroll areas + draggable
    // sheet), so it must not be wrapped in an outer scroll view.
    if(page==SurgoPage.listeningSession)return const IeltsListeningPage(feedback:false);
    if(page==SurgoPage.oralExam||page==SurgoPage.oralDiscuss)return OralDailyPage(discussion:page==SurgoPage.oralDiscuss);
    if(page==SurgoPage.speakingSession && context.read<AppState>().examType==ExamType.ielts &&
      !['p1','p3','pron'].contains(context.read<AppState>().session['selWizCard'])) { return const OralDailyPage(); }
    if(page==SurgoPage.mockReadingQ)return const IeltsMockReadingPage();
    if(page==SurgoPage.mockSpeakingQ)return const IeltsMockSpeakingPage();
    const tfReadPages=[SurgoPage.tfRead1Q,SurgoPage.tfRead2Q,SurgoPage.tfRead3Q,SurgoPage.tfRead4Q];
    if(tfReadPages.contains(page))return TfReadingMockPage(part:tfReadPages.indexOf(page)+1);
    final mockListening=buildIeltsMockListeningPage(page);if(mockListening!=null)return mockListening;
    if(page==SurgoPage.exam) {
      return LayoutBuilder(builder:(_,bounds)=>SingleChildScrollView(
        padding:const EdgeInsets.fromLTRB(18,8,18,30),
        child:SizedBox(height:bounds.maxHeight-38,child:const ExamSelectionPage())));
    }
    // 用户 2026-09-24：托福阅读日常（日常阅读 / 学术阅读）的答题面板要两边贴边，
    // 这些页面自己控制左右内边距，所以和首页一样不吃 shell 的 18px。
    final flush=page==SurgoPage.ielts||const{SurgoPage.tfDailyLife,SurgoPage.tfDailyAcad}.contains(page);
    // Padding belongs to the scroll content, not outside it. Otherwise the
    // bottom navigation removes 120px from the visible viewport on every page.
    return SingleChildScrollView(physics:const ClampingScrollPhysics(),
      padding:EdgeInsets.fromLTRB(flush?0:18,8,flush?0:18,hasNav?140:30),child:_body(context));
  }
  Widget _body(BuildContext context) {
    final state=context.read<AppState>();
    for(final builder in [buildVocabQuizPage,buildVocabTiersPage,buildVocabDetailsPage,buildPronPracticePage,buildToeflLifePage,buildTfAcademicPage,buildVocabPronBookPage,buildVocabPronStudyPage,buildTrainingWizardPage,buildWritingWorkspacePage,buildMockIntroPage,buildIeltsListeningPage,buildTfListeningDailyPage,buildTfWritingPage,buildTfWritingFeedback,buildTfSpeakingDailyPage,buildWritingLegacyPage,buildLegacyEntryPage,buildTfSpeakingMockPage,buildTfListeningMockPage,buildTfReadingMockPage]) { final widget=builder(page);if(widget!=null)return widget; }
    final vocab=buildVocabWordsPage(page); if(vocab!=null)return vocab;
    final pron=buildPronCoursePage(page); if(pron!=null)return pron;
    final words=buildToeflWordsPage(page); if(words!=null)return words;
    switch(page) {
      case SurgoPage.exam:return const ExamSelectionPage();
      case SurgoPage.report:return const ReportPage();
      case SurgoPage.prep:return const ProfilePage();
      case SurgoPage.pronListen:return const PronListenPage();
      case SurgoPage.speakingSession:return const SpeakingSessionPage();
      case SurgoPage.mockWritingQ:return const IeltsMockWritingPage();
      case SurgoPage.vocab:return const VocabHomePage();
      case SurgoPage.readingDaily:return const ReadingWizardPage();
      case SurgoPage.tfBrief:return const TaskBriefPage();
      case SurgoPage.readingFeedback:return const ReadingFeedbackPage();
      case SurgoPage.writingFeedback:return const WritingReviewPage();
      case SurgoPage.speakingReview:return const SpeakingReviewPage();
      case SurgoPage.ielts:return Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:HomePage(
        onOpenModule:()=>surgoPrototypeAlert(context,'原型此入口引用了不存在的 MOD.writing。为避免擅改规则，暂不替换为其他流程。'),
        onContinue:()=>showContinueSheet(context),
        onReading:()=>state.go(SurgoPage.readingDaily),onListening:()=>state.go(SurgoPage.listeningDaily),
        onWriting:()=>state.go(SurgoPage.writingDaily),onSpeaking:()=>state.go(SurgoPage.speakingDaily),
        onVocab:()=>state.go(SurgoPage.vocab),onPrep:()=>state.go(SurgoPage.prep),
        onTrain:(key,card){ final target=SurgoPageX.fromKey(key);if(target==null)return;
          if(card!=null)state.session['selWizCard']=card;state.go(target); },onLogo:()=>state.go(SurgoPage.exam)));
      default:return PlaceholderPage(page:page);
    }
  }
}
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key,required this.page});
  final SurgoPage page;
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const SurgoTopBar(),SurgoCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('此页尚未完成原生迁移',style:TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize:18,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),Text(page.name),const SizedBox(height:10),
      const Text('这是明确的未实现标记，不代表原型功能。原 H5 保留不变。',style:TextStyle(fontSize:13,height:1.5)),
    ])),
  ]);
}
