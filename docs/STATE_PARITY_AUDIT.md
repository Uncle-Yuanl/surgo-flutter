# JS → Dart 状态与数据对照（持续核对，非全量保真结论）

基准：只读 `../surgo-mobile-new/app.js`、`questions.js`、`i18n.js`。所有源码散列由 `tool/export_source.cjs --check`核验。2026-09-22。

|范围|原 JS 实际规则|Dart/证据|状态|
|---|---|---|---|
|题库及翻译|QB；949/62 EN，428/32 ZH；按文本节点命中并按中文字符过滤|export_source +2862翻译/102正则oracle|数据与算法通过；页面分段仍需逐项核对|
|日常口语|startOralExam 400ms播题；cue2500ms解锁；录音p2=120秒else30秒；Part3 ask5s/answer30s×10|oral_daily/controller.dart；export_oral_daily执行JS33状态；8测试|已对照。原提示与实际规则矛盾照留|
|雅思口语模考|Part1 260ms播题→完成自动录音；10轮或300秒→P2；P2准备60秒录音120秒+700ms；手停600ms；P3 270秒，5秒切换无真实TTS|ielts_mock_speaking/controller.dart；4专项测试|已核对这些状态，未真机TTS验证|
|雅思阅读模考|14/13/13=40题；共60min；跨篇保留答案；输入trim仅用于判空，值原样保留|export_ielts_mock_reading，controller/page及2测试|数据/主要路径通过，图示视觉近似待改|
|雅思写作模考|共60min；任务切换保草稿；按空白分词；只检查当前任务；字数不足第一次继续不提交，第二次可提交|ielts_mock_writing/controller/page及2测试|已对照；图表视觉待精细验收|
|托福阅读模考|M1填词1800s；理解360s；返回填词重置；M2填词+日常阅读共540s，返回保留|export_tf_reading_mock，controller及11测试|已核对；原总数35/15与实际15/5不一致，保持源数据|
|托福口语模考|Task1每段instruct5s→play段时长→ready2s→answer7s；Task2 play7s→answer45s；停止弹窗2000ms再推进|tf_speaking_mock/controllers与7测试|已核对主要计时；模块页视觉待比较|
|首页继续学习|固定5项；筛选后第一项推荐；reading按当前daily题数×pct取round；listening按LQS×pct；不改变sessionMode/exam；speakingDaily仍去向导|continue_sheet.dart；实际共享IeltsListeningData；6双语交互测试|已接首页并通过|
|托福日常口语|play/ready顶钟显示pos；answer计时可超时一次提示；next保留left/over/alerted直到answer重置|tf_speaking_daily/module,controller|已修复原96px黑球/静态顶钟/next误重置；tf_speaking_daily_test覆盖实际顶钟推进及next残余状态|
|托福句子写作|计时410s；拖拽与翻题不能回滚时钟|tf_writing/module timer原只写session，controller.save覆写旧值|已改计时调用controller.tick；tf_writing_drag_clock_test实拖拽/翻题后计时不回滚|
|雅思听力日常|主gap值变化后blur/submit计数；未改值不计数；清空已提交输入仍mark；qs2逐输入判空|ListeningSourceGap；listening_gap_event_test两项事件回归|所列事件已核对；四部分完整输入导航组合未穷尽|
|雅思听力模考|Part1每次进入重置1800s；其他Part续走；答案/dots仅当前DOM；非当前部分固定0 of 10；Part4重复提交重启118s、到-1才批改；Home退出而非交卷|ielts_mock_listening；9原专项+5 lifecycle测试；export_mock_listening_oracle.cjs仅静态原文检查|已修所列规则、固定独立滚动/拖动答题卡；退出停双计时、提前交卷批改期间主钟继续、到时替换退出弹窗已测；不声称JS动态oracle或全部边界等价|

## 双语与布局
`test/route_bilingual_audit_test.dart`真实加载141路由×2语言，共282初始状态，修复30条英文路径溢出后282通过。此测试使用假的TTS通道（不是语音成功证据）。详细可见文字记录在`build/audit/bilingual_routes.json`。

`tool/audit_rendered_i18n.cjs`生成候选而非错误列表：需补上原`applyLang`的字符过滤和真实DOM节点分段才能判断。不得批量翻译题目或靠英文页中文残留判断。

## 尚未验证的边界
141有Widget不等于状态全覆盖，更不等于像素保真。跨路由退出重入、所有非默认状态、原图示/SVG、TTS完成事件及iOS/Android插件行为需继续验收。未新增真实录音、真实评分、后台或远程推送。
