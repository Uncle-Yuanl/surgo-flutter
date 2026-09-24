# SURGO 页面视觉复核报告（进行中）

## 结论
141个源路由的中英282个初始视口已审阅。冻结基线中 279 项可见设计差异、3 项入口/时态不一致需重验，0项可据此认定全页面保真通过。
这不是最终验收通过报告。差异覆盖布局、按钮、字体、翻译、图表、卡片样式，不仅是平台字体抗锯齿。

## 学情报告功能扩展（2026-09-23 17:10）
按用户HTML确认图增原生学情概览、估分规则、四科证据/雷达联动、目标设置、建议/点评展开与8周趋势。保留现有圆卡/黄紫雷达/插画风格，三概览指标按用户确认竖排。5状态×2考试×双语有测试；最终481tests/31checks通过，26状态/滚动真实图已检查；仍为演示数据不是后端真实估分。详见`LEARNING_REPORT_EXTENSION.md`，H5102文件哈希未改。此扩展不提升全站逐像素验收数。

## 用户后续指定Banner与Part2（2026-09-23 16:11）
首页banner覆盖之前完整插画要求：用户确认按图2，纯白/高140px/IP右侧由CTA遮住下半身。雅思Part2补60秒准备且无录音控件，点击进入考试后才显示录音界面，准备笔记保留/重录不清空。451tests/31checks通过，真实填写笔记→进入→录音已操作验证。详见`BANNER_PART2_20260923.md`，其他四项保持。

## 用户指定四项最新改动（2026-09-23 15:30，覆盖旧保真参考）
已完成：阅读计时26px/Home同行；阅读超时手机内居中且底色与最终视频#FBFBFB一致；全部Flutter装饰背景渐变/渐变底图改纯色（保留雷达图数据shader）；首页IP120×148完整放大。用户主动指定偏离原H5，不可按旧截图回退。最终447tests/31checks通过，282初始状态0失败，34核心/主要页面回归图已检查，H5全102文件哈希不变。详见`FOUR_VISUAL_CHANGES_20260923.md`。以下历史渐变/28px等记录属于旧检查点，不代表当前值。

## 证据与方法
- H5只读，Chrome CDP真实渲染；去掉桌面外手机装饰框，保持内部390×844。Flutter使用独立审计target真实CanvasKit渲染，不用结构测试代替截图。
- Flutter截图等待字体网络完成；282项fontsSettled=true、捕获无JS异常。H5路由实际值与请求相符。
- `artifacts/visual_audit/baseline_image_manifest.json`保存564张PNG的SHA256。
- `artifacts/visual_audit/manual_reviews*.json`为逐页人工观察；`reviewed_baseline.json`为语言级记录；`review_sheets/`为双语并排证据；`artifacts/diff/`为像素辅助图。
- 原型初始视口有内容在屏下，长文与反馈滚动后区域、选中/禁用/提交/错误/弹窗状态尚未逐一验完。初始图有差异不等于题库不同；计时差异不能直接判为规则错误。

## 已落实且有回归的修正
- 公共默认行高/字距及嵌套卡片继承；AnimatedSwitcher紧约束避免短页垂直居中；TopBar额外Home字样、尺寸修正。
- 考试入口双层边距、底部logo、非选中灰度；若干向导字号、卡图标、选中勾；已有r1/r2/r3双语重截图。
- 报告r4仅旧检查点；report10已恢复专属渐变、完整英文点评、雷达描边/动画和源订阅行为，8态对已审，字体和图标仍差，见REPORT_VISUAL_BATCH.md。
- 用户新要求：首页完整插图、字号、全部消息页已通过专项与真实点击；金刚区最新13px，不能按旧H5回退。见 `HOME_NOTIFICATIONS_20260922.md`。

## 后续修正批次（2026-09-23 13:01 完整回归）

- 发音练习8页：`PRON_PRACTICE_VISUAL_BATCH.md`；课程/讲解/听辨3页：`PRON_COURSE_VISUAL_BATCH.md`。原圆控件、导航/内滚动、词对分隔、卡片及完成页布局已修，仍保留字体/状态待验。
- 词汇学习4页：`VOCAB_STUDY_VISUAL_BATCH.md`；44px标题、30px原SVG、同排进度、原内距/胶囊按钮/提示图已修并逐页检查8张双语新图。
- 词汇测试/完成5页：`VOCAB_QUIZ_VISUAL_BATCH.md`；卡片/原SVG、选项分段翻译、结果与完成页同排CTA恢复，10张新双语图已对照；仍有字重、数px偏移、彩色书本字符差异。
- 词汇释义4页：`VOCAB_DETAIL_VISUAL_BATCH.md`；首屏/底部32张新截图已对照；原词/释义/例句/chips/侧卡及滚动末端布局修复，英文自评修正，仍有单色图标/字体差异。
- Tier四页/空状态1页：`VOCAB_TIER_VISUAL_BATCH.md`；固定Home、原SVG、左侧统计、完整进度轨、推荐按钮换行、预览chips与链接换行修复，10张新图已核验；仍保留字体/细微位置差异。
- 词汇发音复习7页：`VOCAB_PRON_VISUAL_BATCH.md`；44px词/原麦克风及自评SVG/卡片高度/完成页修复，中英14态已对照，保持纯模拟录音，仍有字形/边框/单色字符差异。
- 单词本/发音本列表2页：`VOCAB_BOOK_VISUAL_BATCH.md`；固定导航、2×2统计、原工具栏/单列卡片与绿色状态、原英文裁切CTA恢复，双语首屏/底部已核对；字体与小幅位置差仍存在。
- 词本详情6页：`VOCAB_WORD_VISUAL_BATCH.md`；黄释义/灰例句/chips/原SVG侧卡/固定返回及边框内距已修，中英首屏与末端24态已核对；字体/行高/细微位置仍不同。
- 词汇主页1页：`VOCAB_HOME_VISUAL_BATCH.md`；固定Home/统计/复习中栏分段翻译/原图标/完整Tier轨已修，中英首尾4态已核对，TOEFL实际截图及字体细节仍待。
- 写作确认1页：`WRITING_SESSION_VISUAL_BATCH.md`；四题型双语+图表放大10态核对，源柱坐标/固定导航/确认规则恢复，关闭符号可见；仍有SF Pro替代字形和细微位置差。
- 作文规划1页：`WRITING_PLAN_VISUAL_BATCH.md`；四步骤/论点与词汇选择/16个中英状态对照，修Task1数组索引崩溃和中文动态文案，仍有字形/少量布局差。
- 作答1页：`WRITING_COMPOSE_VISUAL_BATCH.md`；26中英状态对（四题型/折叠/输入/底部）已核对，保持实际静止时钟与原字数翻译生命周期。wcompose3白屏26图已作废；独立8955目录重采正常，新增必需资源和runtime失败预检。字体/行高差仍存在。
- 写作批改1页：`WRITING_REVIEW_VISUAL_BATCH.md`；Task1/2×mark/l1共40双语状态对/80图，16张对照图已阅，修题目遗漏、标签换行、翻译字误、源回顶/静态tab、注释/原因卡与隐藏滚动条。长作文SF Pro/Roboto换行与单色字符仍不同，不能标全页通过。
- 批改作文新增OFL Inter局部字体与四分支尺寸验证；wreview8重捕40状态，16对作文/底部已复阅，其余仍保留未复阅状态。并非SF Pro完全等价。
- 四写作子页writingImprove/Bands/L1Error/L1Detail首轮完成：导航字号、折叠间距、标题下划线、原星形、嵌套粗体、按钮、隐藏滚动条；14新增测试已过，wlegacy4共24截图对已审（有scroll夹底重复，不是24不同状态），字重与少量位置仍差。见WRITING_LEGACY_VISUAL_BATCH.md及writing_legacy_reviewed.json。合计53路由首轮记录，不等完整视觉通过。
- 能力报告1页：REPORT_VISUAL_BATCH.md；双语初始/scroll550/底部/已订阅8对真实图，report10与已审report9完全相同。修背景/点评/306px比较卡/850ms雷达/底部留白与按钮原型文字。新增5项专项，合计54路由首轮修正/抽查，不等完整视觉通过。
- 个人中心1页：PROFILE_VISUAL_BATCH.md；透明头像边框/外阴影、CSS折叠margin、原型alert和120px底部规则恢复；4状态对已审，5新增测试通过。prep5已补中文统计卡至源124px（英文115px不变），仍有字体/基线细微差，合计55路由首轮修正/抽查。
- 阅读2路由：`READING_VISUAL_BATCH.md`；11题型及整篇/选中/题号/独立滚动/拖动/输入/超时共40语言状态对80图已人工对照。保留用户28px Home同行顶栏，Web视频同帧取证与返回继续计时已验证。仍有字重/行框/个别位置差，未穷尽题号状态，合计57路由首轮修正/抽查。
- 阅读批改1路由：`READING_FEEDBACK_VISUAL_BATCH.md`；补齐mock三Passage/9演示题/固定5对6.5、标签切换重渲染，日常与mock共24语言状态对已审。线上加载失败，使用哈希一致的本地只读H5对照。pill同行/文字单行已修并经真实截图复验，仍有字体/高亮/部分行框差，合计58路由首轮抽查，不等完整验收。
- 听力批改进行中：`LISTENING_FEEDBACK_VISUAL_BATCH.md`；四Part原文高亮/音频条/倍速/局部切换已恢复；34状态对捕获，最终动作4对已审且listenreview4同字节，普通态新版尚待完整复审，暂不增加58路由计数。
- 最近完整本地回归为445 tests、31 checks通过（2026-09-23T14:49:25.893168+08:00），analyze零问题、release成功，原H5哈希不变。已包含最后pill局部scaleDown及原间距恢复；机器检查通过不等于逐像素一致。这不是全站最终视觉验收。
- 基线表保持历史发现，不将旧截图的结论伪装成修后结果；最新图与残余以各批次文档为准。

## 已通过页面
暂无页面可标记为完整视觉验收通过。已通过专项测试/局部改动，不等于整页所有状态通过。

## 待同状态重验
- tfReadModLoad / zh：英文加载页插图更大，字号加大，原粗胶囊进度条变细黄紫线且百分比移到下方；中文Flutter截图已自动跳到模块2说明，不能算同状态证据。 初始截图已越过加载状态，需固定原流程同一时刻重新采集。 证据：`artifacts/h5/zh/tfReadModLoad.png`、`artifacts/flutter/zh/tfReadModLoad.png`。
- examTimer / zh：截图状态不一致：H5默认显示听力30分钟四部分，Flutter默认写作60分钟两任务，不能据这对图判计时规则错误；需统一subject入口后重采。仍可确认FlutterHome附带返回字，外卡描边/阴影和CTA颜色不同。  证据：`artifacts/h5/zh/examTimer.png`、`artifacts/flutter/zh/examTimer.png`。
- examTimer / en：截图状态不一致：H5默认显示听力30分钟四部分，Flutter默认写作60分钟两任务，不能据这对图判计时规则错误；需统一subject入口后重采。仍可确认FlutterHome附带返回字，外卡描边/阴影和CTA颜色不同。  证据：`artifacts/h5/en/examTimer.png`、`artifacts/flutter/en/examTimer.png`。

## 仍有差异的基线页面（逐路由×语言）
|路由|语言|差异|证据|
|---|---|---|---|
|workspace|zh|Flutter多出Home顶栏、整组卡片下移，入口图标变为空心且位置不同，副标题重复，卡片高度和禁用卡样式不同。 |`artifacts/h5/zh/workspace.png` / `artifacts/flutter/zh/workspace.png`|
|workspace|en|Flutter多出Home顶栏、整组卡片下移，入口图标变为空心且位置不同，副标题重复，卡片高度和禁用卡样式不同。 H5快照带淡化状态，需在同一稳定状态重验；Flutter仍有独立可见布局差异。|`artifacts/h5/en/workspace.png` / `artifacts/flutter/en/workspace.png`|
|exam|zh|Flutter选择卡比H5更宽且更靠下；下方logo上移，TOEFL非选中插图仍带颜色。r1已修边距/灰度，须以修正版另验。 |`artifacts/h5/zh/exam.png` / `artifacts/flutter/zh/exam.png`|
|exam|en|Flutter选择卡比H5更宽且更靠下；下方logo上移，TOEFL非选中插图仍带颜色。r1已修边距/灰度，须以修正版另验。 |`artifacts/h5/en/exam.png` / `artifacts/flutter/en/exam.png`|
|report|zh|Flutter在页面中间叠了第二层背景，分数黄色高亮覆盖全字块；水獭偏右下、顶栏与卡片间距不同。r4已调整，不能用此基线图认定修后通过。 |`artifacts/h5/zh/report.png` / `artifacts/flutter/zh/report.png`|
|report|en|Flutter在页面中间叠了第二层背景，分数黄色高亮覆盖全字块；水獭偏右下、顶栏与卡片间距不同。r4已调整，不能用此基线图认定修后通过。 说明段落在Flutter分成3行、H5为2行，导致下方雷达卡下移。|`artifacts/h5/en/report.png` / `artifacts/flutter/en/report.png`|
|ielts|zh|Flutter首页黄/黑训练卡高度和上下间距偏大，背景装饰环形状不同、波形占宽不同。用户随后明确改完整插图和放大文字，该部分按新要求验收，不按H5基线回退。 |`artifacts/h5/zh/ielts.png` / `artifacts/flutter/zh/ielts.png`|
|ielts|en|Flutter首页黄/黑训练卡高度和上下间距偏大，背景装饰环形状不同、波形占宽不同。用户随后明确改完整插图和放大文字，该部分按新要求验收，不按H5基线回退。 |`artifacts/h5/en/ielts.png` / `artifacts/flutter/en/ielts.png`|
|writingDaily|zh|基线多出Home文字，步骤条/任务卡更高，按钮更低；选中卡右上显示推荐而非勾。共享排版和向导已修，须引用新截图验收。 |`artifacts/h5/zh/writingDaily.png` / `artifacts/flutter/zh/writingDaily.png`|
|writingDaily|en|基线多出Home文字，步骤条/任务卡更高，按钮更低；选中卡右上显示推荐而非勾。共享排版和向导已修，须引用新截图验收。 推荐标签覆盖任务标题；原步骤条本身右侧溢出，不能以压字代替对照。|`artifacts/h5/en/writingDaily.png` / `artifacts/flutter/en/writingDaily.png`|
|writingSession|zh|Flutter多出居中logo和空白顶区，四步骤条从横排文字变为垂直标记；题目正文段落/换行与原显示不同，按钮下移。需核对源布局及文本节点而非只字号。 |`artifacts/h5/zh/writingSession.png` / `artifacts/flutter/zh/writingSession.png`|
|writingSession|en|Flutter多出居中logo和空白顶区，四步骤条从横排文字变为垂直标记；题目正文段落/换行与原显示不同，按钮下移。需核对源布局及文本节点而非只字号。 |`artifacts/h5/en/writingSession.png` / `artifacts/flutter/en/writingSession.png`|
|writingPlan|zh|Flutter多logo、整体下移；原粉红警告块变成灰色普通文字，黄色论点选择块变白，下一步宽度和底部留白不同。 |`artifacts/h5/zh/writingPlan.png` / `artifacts/flutter/zh/writingPlan.png`|
|writingPlan|en|Flutter多logo、整体下移；原粉红警告块变成灰色普通文字，黄色论点选择块变白，下一步宽度和底部留白不同。 |`artifacts/h5/en/writingPlan.png` / `artifacts/flutter/en/writingPlan.png`|
|writingCompose|zh|Flutter顶部题目/作文tabs由小字下划线变成按钮，多logo；规划卡高度、提示段落及底部开始写作按钮位置不同。 |`artifacts/h5/zh/writingCompose.png` / `artifacts/flutter/zh/writingCompose.png`|
|writingCompose|en|Flutter顶部题目/作文tabs由小字下划线变成按钮，多logo；规划卡高度、提示段落及底部开始写作按钮位置不同。 |`artifacts/h5/en/writingCompose.png` / `artifacts/flutter/en/writingCompose.png`|
|readingSession|zh|顶部字体/徽章位置不同；原计时使用斜体计时字形，Flutter普通数字；答题片初始高度接近，题目至选项间距及页尾提示宽度不同。计时两秒差只记时刻差异。 |`artifacts/h5/zh/readingSession.png` / `artifacts/flutter/zh/readingSession.png`|
|readingSession|en|顶部字体/徽章位置不同；原计时使用斜体计时字形，Flutter普通数字；答题片初始高度接近，题目至选项间距及页尾提示宽度不同。计时两秒差只记时刻差异。 已答标签在Flutter仍为中文；原H5为英文。|`artifacts/h5/en/readingSession.png` / `artifacts/flutter/en/readingSession.png`|
|readingFeedback|zh|Flutter头部回顾标题居中而非紧邻圆形Home；评分卡更高、弱项卡去掉黄色标签/灰底例句样式；原文卡标题与段落高度不符。 |`artifacts/h5/zh/readingFeedback.png` / `artifacts/flutter/zh/readingFeedback.png`|
|readingFeedback|en|Flutter头部回顾标题居中而非紧邻圆形Home；评分卡更高、弱项卡去掉黄色标签/灰底例句样式；原文卡标题与段落高度不符。 |`artifacts/h5/en/readingFeedback.png` / `artifacts/flutter/en/readingFeedback.png`|
|listeningFeedback|zh|评分卡数字分组、比率字号/排布不同；弱项卡缺原黄色分类标签和灰色示例块；Home圆底/标题位置及模块标签样式不同。 |`artifacts/h5/zh/listeningFeedback.png` / `artifacts/flutter/zh/listeningFeedback.png`|
|listeningFeedback|en|评分卡数字分组、比率字号/排布不同；弱项卡缺原黄色分类标签和灰色示例块；Home圆底/标题位置及模块标签样式不同。 |`artifacts/h5/en/listeningFeedback.png` / `artifacts/flutter/en/listeningFeedback.png`|
|listeningSession|zh|Flutter多logo，计时与做题时间并排而非上下；播放按钮缺黄圆底、音频卡和问题片下移；选项字母独立框缺失。 |`artifacts/h5/zh/listeningSession.png` / `artifacts/flutter/zh/listeningSession.png`|
|listeningSession|en|Flutter多logo，计时与做题时间并排而非上下；播放按钮缺黄圆底、音频卡和问题片下移；选项字母独立框缺失。 Flutter题目说明仍中文，原H5为英文。|`artifacts/h5/en/listeningSession.png` / `artifacts/flutter/en/listeningSession.png`|
|speakingSession|zh|Flutter多logo、计时说明并排；提示区结构不同，底部原黄色可拖面板变成普通白卡；正文换行/徽章样式不同。 Flutter日常训练/口语标签变成细小纯文字，原为彩色胶囊。|`artifacts/h5/zh/speakingSession.png` / `artifacts/flutter/zh/speakingSession.png`|
|speakingSession|en|Flutter多logo、计时说明并排；提示区结构不同，底部原黄色可拖面板变成普通白卡；正文换行/徽章样式不同。 |`artifacts/h5/en/speakingSession.png` / `artifacts/flutter/en/speakingSession.png`|
|oralExam|zh|整体骨架接近，但播放按钮缺原灰色底，卡片阴影和笔记区高度不同；截图中H5提交按钮淡黄禁用，Flutter亮黄，须同phase复验不能据一张图断言状态逻辑。 |`artifacts/h5/zh/oralExam.png` / `artifacts/flutter/zh/oralExam.png`|
|oralExam|en|整体骨架接近，但播放按钮缺原灰色底，卡片阴影和笔记区高度不同；截图中H5提交按钮淡黄禁用，Flutter亮黄，须同phase复验不能据一张图断言状态逻辑。 |`artifacts/h5/en/oralExam.png` / `artifacts/flutter/en/oralExam.png`|
|speakingReview|zh|整体卡片层次接近，评分/弱项卡段落行高与高度更大，后续弱项下移；中文回顾标签与英文Completed说明的换行不同。 |`artifacts/h5/zh/speakingReview.png` / `artifacts/flutter/zh/speakingReview.png`|
|speakingReview|en|整体卡片层次接近，评分/弱项卡段落行高与高度更大，后续弱项下移；中文回顾标签与英文Completed说明的换行不同。 |`artifacts/h5/en/speakingReview.png` / `artifacts/flutter/en/speakingReview.png`|
|oralDiscuss|zh|整体背景、球和说明位置接近；Flutter球有更强渐变，计时略上移、底部提示字位置不同；仅此快照不足以验10轮状态。 |`artifacts/h5/zh/oralDiscuss.png` / `artifacts/flutter/zh/oralDiscuss.png`|
|oralDiscuss|en|整体背景、球和说明位置接近；Flutter球有更强渐变，计时略上移、底部提示字位置不同；仅此快照不足以验10轮状态。 |`artifacts/h5/en/oralDiscuss.png` / `artifacts/flutter/en/oralDiscuss.png`|
|pronCourse|zh|Flutter页头和两阶段内容整体下移；卡片更窄且高度/背景层次不同；阶段副说明与标签字体/排布不同。 |`artifacts/h5/zh/pronCourse.png` / `artifacts/flutter/zh/pronCourse.png`|
|pronCourse|en|Flutter页头和两阶段内容整体下移；卡片更窄且高度/背景层次不同；阶段副说明与标签字体/排布不同。 |`artifacts/h5/en/pronCourse.png` / `artifacts/flutter/en/pronCourse.png`|
|pronLesson|zh|大结构接近但Flutter顶栏Home尺寸与位置不同；讲解/提示/对比卡间距及高度略大，底部主按钮更低，英语底部按钮部分落出初始视口。 |`artifacts/h5/zh/pronLesson.png` / `artifacts/flutter/zh/pronLesson.png`|
|pronLesson|en|大结构接近但Flutter顶栏Home尺寸与位置不同；讲解/提示/对比卡间距及高度略大，底部主按钮更低，英语底部按钮部分落出初始视口。 |`artifacts/h5/en/pronLesson.png` / `artifacts/flutter/en/pronLesson.png`|
|pronListen|zh|Flutter多出居中SURGO logo，页头纵向偏移；三项音频/相同/不同按钮由原同行圆角胶囊变成两行矩形块；底部按钮圆角、留白、尺寸不符。 |`artifacts/h5/zh/pronListen.png` / `artifacts/flutter/zh/pronListen.png`|
|pronListen|en|Flutter多出居中SURGO logo，页头纵向偏移；三项音频/相同/不同按钮由原同行圆角胶囊变成两行矩形块；底部按钮圆角、留白、尺寸不符。 |`artifacts/h5/en/pronListen.png` / `artifacts/flutter/en/pronListen.png`|
|pronRepeat|zh|Flutter多出SURGO logo，顶部标签、进度步骤样式不同；示例词卡高度更大，播放/麦克风的黄色圆底缺失；底部按钮由胶囊变成小圆角矩形。 |`artifacts/h5/zh/pronRepeat.png` / `artifacts/flutter/zh/pronRepeat.png`|
|pronRepeat|en|Flutter多出SURGO logo，顶部标签、进度步骤样式不同；示例词卡高度更大，播放/麦克风的黄色圆底缺失；底部按钮由胶囊变成小圆角矩形。 |`artifacts/h5/en/pronRepeat.png` / `artifacts/flutter/en/pronRepeat.png`|
|pronSentence|zh|Flutter多出logo且主内容向下居中；标题卡更高，播放/麦克风圆底缺失；页尾按钮样式和宽度不符。 |`artifacts/h5/zh/pronSentence.png` / `artifacts/flutter/zh/pronSentence.png`|
|pronSentence|en|Flutter多出logo且主内容向下居中；标题卡更高，播放/麦克风圆底缺失；页尾按钮样式和宽度不符。 |`artifacts/h5/en/pronSentence.png` / `artifacts/flutter/en/pronSentence.png`|
|pronDone|zh|Flutter多出logo、主卡垂直位置明显偏低；标记完成按钮从原左侧自适应宽胶囊变全宽矩形；步骤条与底部上一步样式不符。 |`artifacts/h5/zh/pronDone.png` / `artifacts/flutter/zh/pronDone.png`|
|pronDone|en|Flutter多出logo、主卡垂直位置明显偏低；标记完成按钮从原左侧自适应宽胶囊变全宽矩形；步骤条与底部上一步样式不符。 |`artifacts/h5/en/pronDone.png` / `artifacts/flutter/en/pronDone.png`|
|pronCongrats|zh|Flutter成功页整体更靠下，水獭变小；三列指标新增了原图没有的白色卡容器；返回按钮从同行两枚改为上下全宽。 |`artifacts/h5/zh/pronCongrats.png` / `artifacts/flutter/zh/pronCongrats.png`|
|pronCongrats|en|Flutter成功页整体更靠下，水獭变小；三列指标新增了原图没有的白色卡容器；返回按钮从同行两枚改为上下全宽。 Flutter主标题仍显示中文，H5为英文并有黄色完成词；须补原节点翻译而非只调字号。|`artifacts/h5/en/pronCongrats.png` / `artifacts/flutter/en/pronCongrats.png`|
|pron2Lesson|zh|Flutter多出logo，标签/标题/讲解组下移；解释卡高度和间隔增加，按钮矩形而非原胶囊。 |`artifacts/h5/zh/pron2Lesson.png` / `artifacts/flutter/zh/pron2Lesson.png`|
|pron2Lesson|en|Flutter多出logo，标签/标题/讲解组下移；解释卡高度和间隔增加，按钮矩形而非原胶囊。 |`artifacts/h5/en/pron2Lesson.png` / `artifacts/flutter/en/pron2Lesson.png`|
|pron2Repeat|zh|Flutter多出logo；示例词卡更高，音频/麦克风无黄色圆底；步骤条及底部按钮样式不同。 |`artifacts/h5/zh/pron2Repeat.png` / `artifacts/flutter/zh/pron2Repeat.png`|
|pron2Repeat|en|Flutter多出logo；示例词卡更高，音频/麦克风无黄色圆底；步骤条及底部按钮样式不同。 |`artifacts/h5/en/pron2Repeat.png` / `artifacts/flutter/en/pron2Repeat.png`|
|pron2Done|zh|Flutter多出logo，内容明显居中下移；完成动作从自适应宽胶囊变成全宽矩形；上一步按钮位置/圆角不符。 |`artifacts/h5/zh/pron2Done.png` / `artifacts/flutter/zh/pron2Done.png`|
|pron2Done|en|Flutter多出logo，内容明显居中下移；完成动作从自适应宽胶囊变成全宽矩形；上一步按钮位置/圆角不符。 |`artifacts/h5/en/pron2Done.png` / `artifacts/flutter/en/pron2Done.png`|
|pronCongrats2|zh|Flutter成功页插图缩小下移，新增白色统计卡，底部双按钮变纵向；原黄色成功强调丢失。 |`artifacts/h5/zh/pronCongrats2.png` / `artifacts/flutter/zh/pronCongrats2.png`|
|pronCongrats2|en|Flutter成功页插图缩小下移，新增白色统计卡，底部双按钮变纵向；原黄色成功强调丢失。 Flutter完成标题仍为中文，英文H5已翻译。|`artifacts/h5/en/pronCongrats2.png` / `artifacts/flutter/en/pronCongrats2.png`|
|typeSession|zh|Flutter计时顶部靠上、正文卡留白/行高不同，问题文字到选项的垂直间距压缩。计时09:00/08:58是截图时刻差异，不据此判规则错误；两个按钮组与原间距不同。 |`artifacts/h5/zh/typeSession.png` / `artifacts/flutter/zh/typeSession.png`|
|typeSession|en|Flutter计时顶部靠上、正文卡留白/行高不同，问题文字到选项的垂直间距压缩。计时09:00/08:58是截图时刻差异，不据此判规则错误；两个按钮组与原间距不同。 |`artifacts/h5/en/typeSession.png` / `artifacts/flutter/en/typeSession.png`|
|writingFeedback|zh|评分卡任务分/比率布局不同；弱项细分卡和黄色标签缺失；Task/评分作文tabs由紧凑胶囊变为全宽大按钮，显著改变首屏内容量。 |`artifacts/h5/zh/writingFeedback.png` / `artifacts/flutter/zh/writingFeedback.png`|
|writingFeedback|en|评分卡任务分/比率布局不同；弱项细分卡和黄色标签缺失；Task/评分作文tabs由紧凑胶囊变为全宽大按钮，显著改变首屏内容量。 |`artifacts/h5/en/writingFeedback.png` / `artifacts/flutter/en/writingFeedback.png`|
|writingImprove|zh|Flutter标题黄色下划线铺满整行而非贴字；批注段落缩进、编号、灰色删除文字与批注区间隔不同，后续正文纵向错位。 |`artifacts/h5/zh/writingImprove.png` / `artifacts/flutter/zh/writingImprove.png`|
|writingImprove|en|Flutter标题黄色下划线铺满整行而非贴字；批注段落缩进、编号、灰色删除文字与批注区间隔不同，后续正文纵向错位。 |`artifacts/h5/en/writingImprove.png` / `artifacts/flutter/en/writingImprove.png`|
|writingBands|zh|Flutter标题黄色底纹/星标距离及段落卡高度不同，Band8卡更高导致Band6首屏可见区域减少；导航tabs靠右拥挤。 |`artifacts/h5/zh/writingBands.png` / `artifacts/flutter/zh/writingBands.png`|
|writingBands|en|Flutter标题黄色底纹/星标距离及段落卡高度不同，Band8卡更高导致Band6首屏可见区域减少；导航tabs靠右拥挤。 |`artifacts/h5/en/writingBands.png` / `artifacts/flutter/en/writingBands.png`|
|writingL1Error|zh|Flutter主列向下偏移，统计条高度/间距更大；总评正文换行更多、查看详情按钮更低；需去除额外字体追踪/高度来源。 |`artifacts/h5/zh/writingL1Error.png` / `artifacts/flutter/zh/writingL1Error.png`|
|writingL1Error|en|Flutter主列向下偏移，统计条高度/间距更大；总评正文换行更多、查看详情按钮更低；需去除额外字体追踪/高度来源。 |`artifacts/h5/en/writingL1Error.png` / `artifacts/flutter/en/writingL1Error.png`|
|writingL1Detail|zh|顶栏及彩色筛选标签大小接近；错误示例卡的正文行高/边距更大，第二条下移；部分原删除线、彩色下划线与段落间距不一致。 |`artifacts/h5/zh/writingL1Detail.png` / `artifacts/flutter/zh/writingL1Detail.png`|
|writingL1Detail|en|顶栏及彩色筛选标签大小接近；错误示例卡的正文行高/边距更大，第二条下移；部分原删除线、彩色下划线与段落间距不一致。 |`artifacts/h5/en/writingL1Detail.png` / `artifacts/flutter/en/writingL1Detail.png`|
|listeningDaily|zh|基线多Home文字，步骤条和任务卡更高、卡图标更大；推荐覆盖选中勾，底部按钮首屏被挤出。此向导已有修正，基线保留差异记录。 |`artifacts/h5/zh/listeningDaily.png` / `artifacts/flutter/zh/listeningDaily.png`|
|listeningDaily|en|基线多Home文字，步骤条和任务卡更高、卡图标更大；推荐覆盖选中勾，底部按钮首屏被挤出。此向导已有修正，基线保留差异记录。 |`artifacts/h5/en/listeningDaily.png` / `artifacts/flutter/en/listeningDaily.png`|
|readingDaily|zh|基线多Home文字，步骤/选择卡/输入间距扩大；卡插图偏大、生成按钮下移。后续已修部分字号和公共布局，仍需新图验收。 |`artifacts/h5/zh/readingDaily.png` / `artifacts/flutter/zh/readingDaily.png`|
|readingDaily|en|基线多Home文字，步骤/选择卡/输入间距扩大；卡插图偏大、生成按钮下移。后续已修部分字号和公共布局，仍需新图验收。 |`artifacts/h5/en/readingDaily.png` / `artifacts/flutter/en/readingDaily.png`|
|tfDailyWords|zh|Flutter将原一段内联带空格文章拆成多个大间距行，初始屏幕只显示部分段落，题目空格/编号相对位置不同；不属于字体栅格化小差异。 |`artifacts/h5/zh/tfDailyWords.png` / `artifacts/flutter/zh/tfDailyWords.png`|
|tfDailyWords|en|Flutter将原一段内联带空格文章拆成多个大间距行，初始屏幕只显示部分段落，题目空格/编号相对位置不同；不属于字体栅格化小差异。 |`artifacts/h5/en/tfDailyWords.png` / `artifacts/flutter/en/tfDailyWords.png`|
|tfDwFb|zh|Flutter弱项大卡高度显著增加，按钮从小自适应宽变全宽，原文反馈首屏被挤出；头部下划线和评分块数字位置不同。 |`artifacts/h5/zh/tfDwFb.png` / `artifacts/flutter/zh/tfDwFb.png`|
|tfDwFb|en|Flutter弱项大卡高度显著增加，按钮从小自适应宽变全宽，原文反馈首屏被挤出；头部下划线和评分块数字位置不同。 |`artifacts/h5/en/tfDwFb.png` / `artifacts/flutter/en/tfDwFb.png`|
|tfDailyLife|zh|Flutter原文区占据远多于原H5高度，黄色问题片从屏中下移至接近屏底；文章行距和换行不同。问题片初始高度/布局需实修。 |`artifacts/h5/zh/tfDailyLife.png` / `artifacts/flutter/zh/tfDailyLife.png`|
|tfDailyLife|en|Flutter原文区占据远多于原H5高度，黄色问题片从屏中下移至接近屏底；文章行距和换行不同。问题片初始高度/布局需实修。 |`artifacts/h5/en/tfDailyLife.png` / `artifacts/flutter/en/tfDailyLife.png`|
|tfDlFb|zh|与补词反馈同类：弱项卡行高和内容块高度更大、CTA全宽，原文卡首屏缺失；需要保留源内嵌批注样式。 |`artifacts/h5/zh/tfDlFb.png` / `artifacts/flutter/zh/tfDlFb.png`|
|tfDlFb|en|与补词反馈同类：弱项卡行高和内容块高度更大、CTA全宽，原文卡首屏缺失；需要保留源内嵌批注样式。 |`artifacts/h5/en/tfDlFb.png` / `artifacts/flutter/en/tfDlFb.png`|
|tfDailyAcad|zh|Flutter文章占满初始视口，原H5中部可见的问题片/选项完全不可见；固定可拖问答区布局不符。 |`artifacts/h5/zh/tfDailyAcad.png` / `artifacts/flutter/zh/tfDailyAcad.png`|
|tfDailyAcad|en|Flutter文章占满初始视口，原H5中部可见的问题片/选项完全不可见；固定可拖问答区布局不符。 |`artifacts/h5/en/tfDailyAcad.png` / `artifacts/flutter/en/tfDailyAcad.png`|
|tfDaFb|zh|Flutter弱项卡和按钮明显拉高，首屏没有原文反馈卡；评分数字字号/横向间距及回顾标签下划线不一致。 |`artifacts/h5/zh/tfDaFb.png` / `artifacts/flutter/zh/tfDaFb.png`|
|tfDaFb|en|Flutter弱项卡和按钮明显拉高，首屏没有原文反馈卡；评分数字字号/横向间距及回顾标签下划线不一致。 |`artifacts/h5/en/tfDaFb.png` / `artifacts/flutter/en/tfDaFb.png`|
|tfDailyResp|zh|Flutter多logo，播放卡使用不同黄色面板和紫色倍速按钮、倍速控件换两行；下一题全宽亮黄而原图为右侧禁用灰按钮；须同播放状态核对禁用样式和逻辑。 |`artifacts/h5/zh/tfDailyResp.png` / `artifacts/flutter/zh/tfDailyResp.png`|
|tfDailyResp|en|Flutter多logo，播放卡使用不同黄色面板和紫色倍速按钮、倍速控件换两行；下一题全宽亮黄而原图为右侧禁用灰按钮；须同播放状态核对禁用样式和逻辑。 |`artifacts/h5/en/tfDailyResp.png` / `artifacts/flutter/en/tfDailyResp.png`|
|tfDailyRetell|zh|Flutter多logo且计时下移；球更大，音频卡黄底嵌套白卡与源单层不同；倍速紫色胶囊而非原白/黄，播放中按钮从屏底短灰变为全宽黄。 |`artifacts/h5/zh/tfDailyRetell.png` / `artifacts/flutter/zh/tfDailyRetell.png`|
|tfDailyRetell|en|Flutter多logo且计时下移；球更大，音频卡黄底嵌套白卡与源单层不同；倍速紫色胶囊而非原白/黄，播放中按钮从屏底短灰变为全宽黄。 |`artifacts/h5/en/tfDailyRetell.png` / `artifacts/flutter/en/tfDailyRetell.png`|
|tfDailyInterview|zh|Flutter多logo且球/计时上部布局不同，播放卡层次/倍速按钮颜色和播放中禁用按钮样式不符；截图时刻1-2秒不同单独视为时态差异。 |`artifacts/h5/zh/tfDailyInterview.png` / `artifacts/flutter/zh/tfDailyInterview.png`|
|tfDailyInterview|en|Flutter多logo且球/计时上部布局不同，播放卡层次/倍速按钮颜色和播放中禁用按钮样式不符；截图时刻1-2秒不同单独视为时态差异。 |`artifacts/h5/en/tfDailyInterview.png` / `artifacts/flutter/en/tfDailyInterview.png`|
|tfRetellFb|zh|回顾评分区、弱项模块和CTA高度不同；音频/示例区排列及按钮圆角需进一步放大核对，不以此总览图判通过。 |`artifacts/h5/zh/tfRetellFb.png` / `artifacts/flutter/zh/tfRetellFb.png`|
|tfRetellFb|en|回顾评分区、弱项模块和CTA高度不同；音频/示例区排列及按钮圆角需进一步放大核对，不以此总览图判通过。 |`artifacts/h5/en/tfRetellFb.png` / `artifacts/flutter/en/tfRetellFb.png`|
|tfInterviewFb|zh|反馈卡正文行高、模块间距和CTA宽度不同，首屏可见内容量不一致；评分/示例的细节样式仍需单页验收。 |`artifacts/h5/zh/tfInterviewFb.png` / `artifacts/flutter/zh/tfInterviewFb.png`|
|tfInterviewFb|en|反馈卡正文行高、模块间距和CTA宽度不同，首屏可见内容量不一致；评分/示例的细节样式仍需单页验收。 |`artifacts/h5/en/tfInterviewFb.png` / `artifacts/flutter/en/tfInterviewFb.png`|
|tfDrFb|zh|与听力反馈共用差异：总分比率大字拼成同一行，弱项卡的标签和灰色例句形式不同、CTA全宽，听力原文下移。 |`artifacts/h5/zh/tfDrFb.png` / `artifacts/flutter/zh/tfDrFb.png`|
|tfDrFb|en|与听力反馈共用差异：总分比率大字拼成同一行，弱项卡的标签和灰色例句形式不同、CTA全宽，听力原文下移。 |`artifacts/h5/en/tfDrFb.png` / `artifacts/flutter/en/tfDrFb.png`|
|tfDailyConvo|zh|多出logo和顶部留白；播放卡嵌套黄底、倍速紫色/分两行，与原单层白卡不同；提示文字颜色和笔记占位符需对照。 |`artifacts/h5/zh/tfDailyConvo.png` / `artifacts/flutter/zh/tfDailyConvo.png`|
|tfDailyConvo|en|多出logo和顶部留白；播放卡嵌套黄底、倍速紫色/分两行，与原单层白卡不同；提示文字颜色和笔记占位符需对照。 |`artifacts/h5/en/tfDailyConvo.png` / `artifacts/flutter/en/tfDailyConvo.png`|
|tfDcFb|zh|评分80/6布局不符，弱项卡分类蓝紫标签合成纯字，灰色例句变大；CTA全宽导致听力原文卡下移。 |`artifacts/h5/zh/tfDcFb.png` / `artifacts/flutter/zh/tfDcFb.png`|
|tfDcFb|en|评分80/6布局不符，弱项卡分类蓝紫标签合成纯字，灰色例句变大；CTA全宽导致听力原文卡下移。 |`artifacts/h5/en/tfDcFb.png` / `artifacts/flutter/en/tfDcFb.png`|
|tfDailyAnn|zh|多logo/计时下移，播放卡新增黄底和紫色倍速按钮；原金色小字提示变黑粗字。 |`artifacts/h5/zh/tfDailyAnn.png` / `artifacts/flutter/zh/tfDailyAnn.png`|
|tfDailyAnn|en|多logo/计时下移，播放卡新增黄底和紫色倍速按钮；原金色小字提示变黑粗字。 笔记占位仍中文，原H5为英文；需修原文本翻译。|`artifacts/h5/en/tfDailyAnn.png` / `artifacts/flutter/en/tfDailyAnn.png`|
|tfAnFb|zh|弱项卡行高和例句块变高、分类标签样式缺失，CTA全宽，原文与逐题分析首屏位置均下移。 |`artifacts/h5/zh/tfAnFb.png` / `artifacts/flutter/zh/tfAnFb.png`|
|tfAnFb|en|弱项卡行高和例句块变高、分类标签样式缺失，CTA全宽，原文与逐题分析首屏位置均下移。 |`artifacts/h5/en/tfAnFb.png` / `artifacts/flutter/en/tfAnFb.png`|
|tfDailyLect|zh|多logo，计时播放卡下移且倍速颜色/换行不符；提示段落加粗改黑，笔记卡更高。 |`artifacts/h5/zh/tfDailyLect.png` / `artifacts/flutter/zh/tfDailyLect.png`|
|tfDailyLect|en|多logo，计时播放卡下移且倍速颜色/换行不符；提示段落加粗改黑，笔记卡更高。 笔记输入占位仍中文。|`artifacts/h5/en/tfDailyLect.png` / `artifacts/flutter/en/tfDailyLect.png`|
|tfLcFb|zh|同听力反馈模板：评分比率字体、弱项标签与例句样式不同；按钮扩宽和卡片行高使原文/逐题分析下移。 |`artifacts/h5/zh/tfLcFb.png` / `artifacts/flutter/zh/tfLcFb.png`|
|tfLcFb|en|同听力反馈模板：评分比率字体、弱项标签与例句样式不同；按钮扩宽和卡片行高使原文/逐题分析下移。 |`artifacts/h5/en/tfLcFb.png` / `artifacts/flutter/en/tfLcFb.png`|
|speakingDaily|zh|多Home文字，任务卡字号/图标更大，选中卡应显示勾而非推荐；第四张卡首屏被挤出。已有向导/公共修正，需按新图验。 |`artifacts/h5/zh/speakingDaily.png` / `artifacts/flutter/zh/speakingDaily.png`|
|speakingDaily|en|多Home文字，任务卡字号/图标更大，选中卡应显示勾而非推荐；第四张卡首屏被挤出。已有向导/公共修正，需按新图验。 |`artifacts/h5/en/speakingDaily.png` / `artifacts/flutter/en/speakingDaily.png`|
|vocabDaily|zh|内容被垂直居中下移，多Home字样，卡内字号、标签、图标和步骤条更大；卡宽/高度和首屏CTA位置不同。 |`artifacts/h5/zh/vocabDaily.png` / `artifacts/flutter/zh/vocabDaily.png`|
|vocabDaily|en|内容被垂直居中下移，多Home字样，卡内字号、标签、图标和步骤条更大；卡宽/高度和首屏CTA位置不同。 |`artifacts/h5/en/vocabDaily.png` / `artifacts/flutter/en/vocabDaily.png`|
|vocab|zh|多居中logo，标题及统计卡下移；今日任务卡字号与布局不同，两个书本入口高度与背景不同。 |`artifacts/h5/zh/vocab.png` / `artifacts/flutter/zh/vocab.png`|
|vocab|en|多居中logo，标题及统计卡下移；今日任务卡字号与布局不同，两个书本入口高度与背景不同。 Flutter今日复习的标题片段仍中文，原H5为英文。|`artifacts/h5/en/vocab.png` / `artifacts/flutter/en/vocab.png`|
|vocabBook|zh|原两行2×2统计变成一排四块；页头新增黄底卡，筛选/搜索/排序控件消失成纯文本；单词卡丢状态黄色徽章/外框。 |`artifacts/h5/zh/vocabBook.png` / `artifacts/flutter/zh/vocabBook.png`|
|vocabBook|en|原两行2×2统计变成一排四块；页头新增黄底卡，筛选/搜索/排序控件消失成纯文本；单词卡丢状态黄色徽章/外框。 |`artifacts/h5/en/vocabBook.png` / `artifacts/flutter/en/vocabBook.png`|
|vocabWord|zh|单词标题和标签挤为一行，字体变小；黄底释义框消失、例句灰底消失，搭配配色与卡片间距不同；原错误提示/同义词图标被去掉。 |`artifacts/h5/zh/vocabWord.png` / `artifacts/flutter/zh/vocabWord.png`|
|vocabWord|en|单词标题和标签挤为一行，字体变小；黄底释义框消失、例句灰底消失，搭配配色与卡片间距不同；原错误提示/同义词图标被去掉。 |`artifacts/h5/en/vocabWord.png` / `artifacts/flutter/en/vocabWord.png`|
|vocabWord2|zh|同单词详情模板：大标题缩小，释义/示例/搭配背景消失，内容更紧凑导致更多卡片挤入首屏，图标和徽章不符。 |`artifacts/h5/zh/vocabWord2.png` / `artifacts/flutter/zh/vocabWord2.png`|
|vocabWord2|en|同单词详情模板：大标题缩小，释义/示例/搭配背景消失，内容更紧凑导致更多卡片挤入首屏，图标和徽章不符。 |`artifacts/h5/en/vocabWord2.png` / `artifacts/flutter/en/vocabWord2.png`|
|vocabWord3|zh|黄底释义和灰底空态被简化为纯文字；首卡高度明显变小，原错误提示与同义词/反义词图标缺失。 |`artifacts/h5/zh/vocabWord3.png` / `artifacts/flutter/zh/vocabWord3.png`|
|vocabWord3|en|黄底释义和灰底空态被简化为纯文字；首卡高度明显变小，原错误提示与同义词/反义词图标缺失。 |`artifacts/h5/en/vocabWord3.png` / `artifacts/flutter/en/vocabWord3.png`|
|vocabWord4|zh|同详情模板简化：标题更小、释义与例句块背景缺失、卡片大幅压缩；不只是字体平台差异。 |`artifacts/h5/zh/vocabWord4.png` / `artifacts/flutter/zh/vocabWord4.png`|
|vocabWord4|en|同详情模板简化：标题更小、释义与例句块背景缺失、卡片大幅压缩；不只是字体平台差异。 |`artifacts/h5/en/vocabWord4.png` / `artifacts/flutter/en/vocabWord4.png`|
|vocabPron|zh|页头被包进白卡，统计块增高，筛选/搜索/排序控件变成单行说明；单词列表纵向偏移。 |`artifacts/h5/zh/vocabPron.png` / `artifacts/flutter/zh/vocabPron.png`|
|vocabPron|en|页头被包进白卡，统计块增高，筛选/搜索/排序控件变成单行说明；单词列表纵向偏移。 原H5开始发音复习按钮本身右溢出，Flutter改换行按钮；需记录源差异/可用性取舍，不能擅称像素一致。|`artifacts/h5/en/vocabPron.png` / `artifacts/flutter/en/vocabPron.png`|
|vocabPronWord|zh|主体结构较接近，Flutter首卡和例句高度更多，搭配标签/音标行间距不同；整体卡片下移。 |`artifacts/h5/zh/vocabPronWord.png` / `artifacts/flutter/zh/vocabPronWord.png`|
|vocabPronWord|en|主体结构较接近，Flutter首卡和例句高度更多，搭配标签/音标行间距不同；整体卡片下移。 |`artifacts/h5/en/vocabPronWord.png` / `artifacts/flutter/en/vocabPronWord.png`|
|vocabPronWord2|zh|大结构接近，标题/音标/空例句的纵向间距增大，首卡比H5高，后续卡片下移；仍需检查原阴影与圆角。 |`artifacts/h5/zh/vocabPronWord2.png` / `artifacts/flutter/zh/vocabPronWord2.png`|
|vocabPronWord2|en|大结构接近，标题/音标/空例句的纵向间距增大，首卡比H5高，后续卡片下移；仍需检查原阴影与圆角。 |`artifacts/h5/en/vocabPronWord2.png` / `artifacts/flutter/en/vocabPronWord2.png`|
|vocabPronStudy|zh|内容从H5顶部移到中部；主单词字号明显缩小，麦克风圆按钮变小且失去阴影；原无边白卡增加细边框。 |`artifacts/h5/zh/vocabPronStudy.png` / `artifacts/flutter/zh/vocabPronStudy.png`|
|vocabPronStudy|en|内容从H5顶部移到中部；主单词字号明显缩小，麦克风圆按钮变小且失去阴影；原无边白卡增加细边框。 |`artifacts/h5/en/vocabPronStudy.png` / `artifacts/flutter/en/vocabPronStudy.png`|
|vocabPronStudy2|zh|录音态主卡向下居中、单词和停止圆按钮缩小，阴影被去掉，说明文字换行/间距不同。 |`artifacts/h5/zh/vocabPronStudy2.png` / `artifacts/flutter/zh/vocabPronStudy2.png`|
|vocabPronStudy2|en|录音态主卡向下居中、单词和停止圆按钮缩小，阴影被去掉，说明文字换行/间距不同。 |`artifacts/h5/en/vocabPronStudy2.png` / `artifacts/flutter/en/vocabPronStudy2.png`|
|vocabPronStudy3|zh|自评态主卡更靠下，单词缩小，说明段变为多行并增加高度；进度和退出栏下移。 |`artifacts/h5/zh/vocabPronStudy3.png` / `artifacts/flutter/zh/vocabPronStudy3.png`|
|vocabPronStudy3|en|自评态主卡更靠下，单词缩小，说明段变为多行并增加高度；进度和退出栏下移。 |`artifacts/h5/en/vocabPronStudy3.png` / `artifacts/flutter/en/vocabPronStudy3.png`|
|vocabPronStudyB|zh|第二词准备态整体下移到屏中，单词字号与麦克风圆按钮缩小，卡高/阴影/留白不同。 |`artifacts/h5/zh/vocabPronStudyB.png` / `artifacts/flutter/zh/vocabPronStudyB.png`|
|vocabPronStudyB|en|第二词准备态整体下移到屏中，单词字号与麦克风圆按钮缩小，卡高/阴影/留白不同。 |`artifacts/h5/en/vocabPronStudyB.png` / `artifacts/flutter/en/vocabPronStudyB.png`|
|vocabPronStudyB2|zh|第二词录音态卡整体下移，停止按钮缩小无阴影，单词更小；状态栏下方空白显著增加。 |`artifacts/h5/zh/vocabPronStudyB2.png` / `artifacts/flutter/zh/vocabPronStudyB2.png`|
|vocabPronStudyB2|en|第二词录音态卡整体下移，停止按钮缩小无阴影，单词更小；状态栏下方空白显著增加。 |`artifacts/h5/en/vocabPronStudyB2.png` / `artifacts/flutter/en/vocabPronStudyB2.png`|
|vocabPronStudyB3|zh|第二词自评态整体居中下移，单词缩小，说明行数和卡高增加；原紧凑同排进度标签被折行。 |`artifacts/h5/zh/vocabPronStudyB3.png` / `artifacts/flutter/zh/vocabPronStudyB3.png`|
|vocabPronStudyB3|en|第二词自评态整体居中下移，单词缩小，说明行数和卡高增加；原紧凑同排进度标签被折行。 |`artifacts/h5/en/vocabPronStudyB3.png` / `artifacts/flutter/en/vocabPronStudyB3.png`|
|vocabPronDone|zh|水獭变小，整体内容下移；新增白色统计卡，原三列轻分隔层次消失；底部返回与巩固词按钮从并排变上下。 |`artifacts/h5/zh/vocabPronDone.png` / `artifacts/flutter/zh/vocabPronDone.png`|
|vocabPronDone|en|水獭变小，整体内容下移；新增白色统计卡，原三列轻分隔层次消失；底部返回与巩固词按钮从并排变上下。 All done黄色强调和前句拼接缺少间隔，文本换行不符。|`artifacts/h5/en/vocabPronDone.png` / `artifacts/flutter/en/vocabPronDone.png`|
|vocabTier1|zh|Tier标题耳朵图标不同；推荐区由左上插图/下方按钮改成三列挤压，CTA右置，标题与词汇chips折行；进度指标和留白不符。 |`artifacts/h5/zh/vocabTier1.png` / `artifacts/flutter/zh/vocabTier1.png`|
|vocabTier1|en|Tier标题耳朵图标不同；推荐区由左上插图/下方按钮改成三列挤压，CTA右置，标题与词汇chips折行；进度指标和留白不符。 |`artifacts/h5/en/vocabTier1.png` / `artifacts/flutter/en/vocabTier1.png`|
|vocabTier2|zh|零进度灰底条缺失，指标居中而原靠左；推荐区三列排版导致内容挤压，CTA移到右侧，卡片高度增加。 |`artifacts/h5/zh/vocabTier2.png` / `artifacts/flutter/zh/vocabTier2.png`|
|vocabTier2|en|零进度灰底条缺失，指标居中而原靠左；推荐区三列排版导致内容挤压，CTA移到右侧，卡片高度增加。 |`artifacts/h5/en/vocabTier2.png` / `artifacts/flutter/en/vocabTier2.png`|
|vocabNoNew|zh|空态整体垂直居中而原位于顶部区域；原绿色空心勾圆变成实心勾圆，按钮和间距不同。 |`artifacts/h5/zh/vocabNoNew.png` / `artifacts/flutter/zh/vocabNoNew.png`|
|vocabNoNew|en|空态整体垂直居中而原位于顶部区域；原绿色空心勾圆变成实心勾圆，按钮和间距不同。 |`artifacts/h5/en/vocabNoNew.png` / `artifacts/flutter/en/vocabNoNew.png`|
|vocabTier3|zh|原进度灰条消失，三项指标和推荐区布局不同；推荐标题/占位词多次折行、卡片变高、CTA右置。 |`artifacts/h5/zh/vocabTier3.png` / `artifacts/flutter/zh/vocabTier3.png`|
|vocabTier3|en|原进度灰条消失，三项指标和推荐区布局不同；推荐标题/占位词多次折行、卡片变高、CTA右置。 |`artifacts/h5/en/vocabTier3.png` / `artifacts/flutter/en/vocabTier3.png`|
|vocabTier4|zh|同Tier公共布局差异：零进度条缺失，推荐区横排挤压而非原两行；文字折行/卡片高度增加，CTA位置不符。 |`artifacts/h5/zh/vocabTier4.png` / `artifacts/flutter/zh/vocabTier4.png`|
|vocabTier4|en|同Tier公共布局差异：零进度条缺失，推荐区横排挤压而非原两行；文字折行/卡片高度增加，CTA位置不符。 |`artifacts/h5/en/vocabTier4.png` / `artifacts/flutter/en/vocabTier4.png`|
|mockReading|zh|Flutter多logo，黄色说明块被拆成白底标题和灰色说明；Part卡片编号圆底变淡、题量灰badge移到卡片下方金色字；确认和返回从同行变上下。 |`artifacts/h5/zh/mockReading.png` / `artifacts/flutter/zh/mockReading.png`|
|mockReading|en|Flutter多logo，黄色说明块被拆成白底标题和灰色说明；Part卡片编号圆底变淡、题量灰badge移到卡片下方金色字；确认和返回从同行变上下。 |`artifacts/h5/en/mockReading.png` / `artifacts/flutter/en/mockReading.png`|
|mockReadingIntro|zh|Flutter多logo且整页垂直居中，开始和返回按钮从同行变上下全宽；任务标签变小，黄色提示块高度不同。 |`artifacts/h5/zh/mockReadingIntro.png` / `artifacts/flutter/zh/mockReadingIntro.png`|
|mockReadingIntro|en|Flutter多logo且整页垂直居中，开始和返回按钮从同行变上下全宽；任务标签变小，黄色提示块高度不同。 |`artifacts/h5/en/mockReadingIntro.png` / `artifacts/flutter/en/mockReadingIntro.png`|
|mockWritingIntro|zh|多logo，说明黄底块消失，Task字数/时长灰badge移到卡内金色字；开始与返回按钮变两行全宽，版式不同。 |`artifacts/h5/zh/mockWritingIntro.png` / `artifacts/flutter/zh/mockWritingIntro.png`|
|mockWritingIntro|en|多logo，说明黄底块消失，Task字数/时长灰badge移到卡内金色字；开始与返回按钮变两行全宽，版式不同。 |`artifacts/h5/en/mockWritingIntro.png` / `artifacts/flutter/en/mockWritingIntro.png`|
|mockWritingTf|zh|Flutter页头任务徽章合成普通文字，Task卡片数字圆底丢失、图标位置从左移到标题内；计时灰badge改为黄字，开始/返回变两行。 |`artifacts/h5/zh/mockWritingTf.png` / `artifacts/flutter/zh/mockWritingTf.png`|
|mockWritingTf|en|Flutter页头任务徽章合成普通文字，Task卡片数字圆底丢失、图标位置从左移到标题内；计时灰badge改为黄字，开始/返回变两行。 |`artifacts/h5/en/mockWritingTf.png` / `artifacts/flutter/en/mockWritingTf.png`|
|tfBrief|zh|Flutter卡片少阴影、多细边框，内容向下累积偏移；任务预览chips/提示块高度增加，开始按钮从带播放图标的胶囊改成矩形且缺图标。 |`artifacts/h5/zh/tfBrief.png` / `artifacts/flutter/zh/tfBrief.png`|
|tfBrief|en|Flutter卡片少阴影、多细边框，内容向下累积偏移；任务预览chips/提示块高度增加，开始按钮从带播放图标的胶囊改成矩形且缺图标。 |`artifacts/h5/en/tfBrief.png` / `artifacts/flutter/en/tfBrief.png`|
|tfWr1Intro|zh|Flutter多logo并居中下移；黄色任务标签变成小字，三项说明被加入白色卡片；开始/返回从同行变上下全宽。 |`artifacts/h5/zh/tfWr1Intro.png` / `artifacts/flutter/zh/tfWr1Intro.png`|
|tfWr1Intro|en|Flutter多logo并居中下移；黄色任务标签变成小字，三项说明被加入白色卡片；开始/返回从同行变上下全宽。 三条说明Flutter仍中文，原H5已英文。|`artifacts/h5/en/tfWr1Intro.png` / `artifacts/flutter/en/tfWr1Intro.png`|
|tfWr1Q|zh|Flutter多logo，顶栏计时下移；题目未居中，输入空格从内联下划线改为高矩形；词库词块换为黄底，下一题按钮不再固定底部且宽度不同。 |`artifacts/h5/zh/tfWr1Q.png` / `artifacts/flutter/zh/tfWr1Q.png`|
|tfWr1Q|en|Flutter多logo，顶栏计时下移；题目未居中，输入空格从内联下划线改为高矩形；词库词块换为黄底，下一题按钮不再固定底部且宽度不同。 |`artifacts/h5/en/tfWr1Q.png` / `artifacts/flutter/en/tfWr1Q.png`|
|tfSentFb|zh|回顾标题位置不同，总分分母被放大；弱项彩色chips/灰例句容器丢失，按钮全宽；逐题分析的外白卡标题/标记形式不同。 |`artifacts/h5/zh/tfSentFb.png` / `artifacts/flutter/zh/tfSentFb.png`|
|tfSentFb|en|回顾标题位置不同，总分分母被放大；弱项彩色chips/灰例句容器丢失，按钮全宽；逐题分析的外白卡标题/标记形式不同。 弱项分类仍有中文，H5为英文chips。|`artifacts/h5/en/tfSentFb.png` / `artifacts/flutter/en/tfSentFb.png`|
|tfEmailFb|zh|总分布局、弱项标签和例句背景不同；CTA全宽，分项得分标签及逐题分析外卡布局不同，正文首屏量不一致。 |`artifacts/h5/zh/tfEmailFb.png` / `artifacts/flutter/zh/tfEmailFb.png`|
|tfEmailFb|en|总分布局、弱项标签和例句背景不同；CTA全宽，分项得分标签及逐题分析外卡布局不同，正文首屏量不一致。 薄弱分类行中文残留。|`artifacts/h5/en/tfEmailFb.png` / `artifacts/flutter/en/tfEmailFb.png`|
|tfDiscFb|zh|反馈公共模板差异：分母被放大，弱项多色标签消失，灰例句卡去掉；分项标签/题目区位置不同。 |`artifacts/h5/zh/tfDiscFb.png` / `artifacts/flutter/zh/tfDiscFb.png`|
|tfDiscFb|en|反馈公共模板差异：分母被放大，弱项多色标签消失，灰例句卡去掉；分项标签/题目区位置不同。 薄弱分类行中文残留。|`artifacts/h5/en/tfDiscFb.png` / `artifacts/flutter/en/tfDiscFb.png`|
|tfWr2Intro|zh|Flutter多logo、整体居中下移；原多个任务徽章压成多行小字；开始与返回由并排变成两行全宽。 |`artifacts/h5/zh/tfWr2Intro.png` / `artifacts/flutter/zh/tfWr2Intro.png`|
|tfWr2Intro|en|Flutter多logo、整体居中下移；原多个任务徽章压成多行小字；开始与返回由并排变成两行全宽。 |`artifacts/h5/en/tfWr2Intro.png` / `artifacts/flutter/en/tfWr2Intro.png`|
|tfWr2Q|zh|原题目/写作下划线tabs变全宽按钮；多logo和下移计时。身份/收件人/语气三列背景卡变纯文字行，要求列表灰底圆点变Checkbox，底部去写作首屏不可见。 |`artifacts/h5/zh/tfWr2Q.png` / `artifacts/flutter/zh/tfWr2Q.png`|
|tfWr2Q|en|原题目/写作下划线tabs变全宽按钮；多logo和下移计时。身份/收件人/语气三列背景卡变纯文字行，要求列表灰底圆点变Checkbox，底部去写作首屏不可见。 |`artifacts/h5/en/tfWr2Q.png` / `artifacts/flutter/en/tfWr2Q.png`|
|tfWr3Intro|zh|多logo和大块顶部空白，说明/任务标签的形态不同；开始与返回改成两行而非原并排，黄色计时提示位置不同。 |`artifacts/h5/zh/tfWr3Intro.png` / `artifacts/flutter/zh/tfWr3Intro.png`|
|tfWr3Intro|en|多logo和大块顶部空白，说明/任务标签的形态不同；开始与返回改成两行而非原并排，黄色计时提示位置不同。 |`artifacts/h5/en/tfWr3Intro.png` / `artifacts/flutter/en/tfWr3Intro.png`|
|tfWr3Q|zh|题目/写作tabs样式不符；Flutter讨论题全文加粗并放大，原教授发言灰底缺失，人物圆标颜色不同；底部CTA仍固定但前文可见量明显减少。 |`artifacts/h5/zh/tfWr3Q.png` / `artifacts/flutter/zh/tfWr3Q.png`|
|tfWr3Q|en|题目/写作tabs样式不符；Flutter讨论题全文加粗并放大，原教授发言灰底缺失，人物圆标颜色不同；底部CTA仍固定但前文可见量明显减少。 |`artifacts/h5/en/tfWr3Q.png` / `artifacts/flutter/en/tfWr3Q.png`|
|tfWriteFb|zh|各题型得分原粗灰/黄进度条变成细紫/黄线；总分分母过大，弱项chips和灰例句样式丢失，筛选胶囊紫底与源白/黄不符。 |`artifacts/h5/zh/tfWriteFb.png` / `artifacts/flutter/zh/tfWriteFb.png`|
|tfWriteFb|en|各题型得分原粗灰/黄进度条变成细紫/黄线；总分分母过大，弱项chips和灰例句样式丢失，筛选胶囊紫底与源白/黄不符。 |`artifacts/h5/en/tfWriteFb.png` / `artifacts/flutter/en/tfWriteFb.png`|
|mockWritingQ|zh|Task tabs变宽，计时黑胶囊被白按钮替代、交卷按钮变大；图表完全不同版式，缺坐标网格/纵轴刻度而加数值标记，图高过大使答案框首屏不可见。 |`artifacts/h5/zh/mockWritingQ.png` / `artifacts/flutter/zh/mockWritingQ.png`|
|mockWritingQ|en|Task tabs变宽，计时黑胶囊被白按钮替代、交卷按钮变大；图表完全不同版式，缺坐标网格/纵轴刻度而加数值标记，图高过大使答案框首屏不可见。 |`artifacts/h5/en/mockWritingQ.png` / `artifacts/flutter/en/mockWritingQ.png`|
|mockReadingQ|zh|Flutter缺原文白色卡片框和黄色题片顶栏，计时黑胶囊变纯数字；选项字母框消失，答题卡圆点变方框，交卷按钮从白底描边变亮黄。 |`artifacts/h5/zh/mockReadingQ.png` / `artifacts/flutter/zh/mockReadingQ.png`|
|mockReadingQ|en|Flutter缺原文白色卡片框和黄色题片顶栏，计时黑胶囊变纯数字；选项字母框消失，答题卡圆点变方框，交卷按钮从白底描边变亮黄。 |`artifacts/h5/en/mockReadingQ.png` / `artifacts/flutter/en/mockReadingQ.png`|
|mockSpeaking|zh|多logo，原黄底提示卡变无背景大字；Part时长由右侧灰badge移到底部金色文字；开始按钮全宽、返回掉出首屏。 |`artifacts/h5/zh/mockSpeaking.png` / `artifacts/flutter/zh/mockSpeaking.png`|
|mockSpeaking|en|多logo，原黄底提示卡变无背景大字；Part时长由右侧灰badge移到底部金色文字；开始按钮全宽、返回掉出首屏。 |`artifacts/h5/en/mockSpeaking.png` / `artifacts/flutter/en/mockSpeaking.png`|
|mockSpeakingIntro|zh|多logo、整体居中下移；任务标签样式变小，开始与返回由同行变成上下两行。 |`artifacts/h5/zh/mockSpeakingIntro.png` / `artifacts/flutter/zh/mockSpeakingIntro.png`|
|mockSpeakingIntro|en|多logo、整体居中下移；任务标签样式变小，开始与返回由同行变成上下两行。 |`artifacts/h5/en/mockSpeakingIntro.png` / `artifacts/flutter/en/mockSpeakingIntro.png`|
|mockSpeakingQ|zh|总体全高聊天卡/黑footer已接近；Home缺圆底，音频气泡的播放圆底缺失、宽度不同。计时、录音波形及提示差异受采集时刻/TTS影响，需同phase重验，不据此修改计时规则。 |`artifacts/h5/zh/mockSpeakingQ.png` / `artifacts/flutter/zh/mockSpeakingQ.png`|
|mockSpeakingQ|en|总体全高聊天卡/黑footer已接近；Home缺圆底，音频气泡的播放圆底缺失、宽度不同。计时、录音波形及提示差异受采集时刻/TTS影响，需同phase重验，不据此修改计时规则。 进度/Part仍有中文，源英文快照为Question和Part。|`artifacts/h5/en/mockSpeakingQ.png` / `artifacts/flutter/en/mockSpeakingQ.png`|
|mockListening|zh|多logo、黄色提示背景消失，Part计数从右侧灰标签移到底部金色字；卡片高度增加，确认和返回首屏不可见。 |`artifacts/h5/zh/mockListening.png` / `artifacts/flutter/zh/mockListening.png`|
|mockListening|en|多logo、黄色提示背景消失，Part计数从右侧灰标签移到底部金色字；卡片高度增加，确认和返回首屏不可见。 |`artifacts/h5/en/mockListening.png` / `artifacts/flutter/en/mockListening.png`|
|mockListeningIntro|zh|多logo和顶部空白、整体居中；开始/返回改上下全宽，原黄任务badge变小字。 |`artifacts/h5/zh/mockListeningIntro.png` / `artifacts/flutter/zh/mockListeningIntro.png`|
|mockListeningIntro|en|多logo和顶部空白、整体居中；开始/返回改上下全宽，原黄任务badge变小字。 |`artifacts/h5/en/mockListeningIntro.png` / `artifacts/flutter/en/mockListeningIntro.png`|
|tfListenQ|zh|多logo、计时下移，选项圆角变大且没有原字母小框；原卡内右侧禁用灰下一段按钮变卡外全宽黄按钮；原笔记输入灰底框缺失。 |`artifacts/h5/zh/tfListenQ.png` / `artifacts/flutter/zh/tfListenQ.png`|
|tfListenQ|en|多logo、计时下移，选项圆角变大且没有原字母小框；原卡内右侧禁用灰下一段按钮变卡外全宽黄按钮；原笔记输入灰底框缺失。 笔记占位仍中文。|`artifacts/h5/en/tfListenQ.png` / `artifacts/flutter/en/tfListenQ.png`|
|tfConvQ|zh|多logo、整页下移；播放中黄色音频柱图丢失，音频条外框/背景消失；笔记变空白白卡，缺灰底可编辑区域。 |`artifacts/h5/zh/tfConvQ.png` / `artifacts/flutter/zh/tfConvQ.png`|
|tfConvQ|en|多logo、整页下移；播放中黄色音频柱图丢失，音频条外框/背景消失；笔记变空白白卡，缺灰底可编辑区域。 笔记标题/占位仍中文。|`artifacts/h5/en/tfConvQ.png` / `artifacts/flutter/en/tfConvQ.png`|
|tfAnnQ|zh|多logo/居中下移；播放中柱形图丢失，情境提示从金色小字变黑粗字，播放卡高度缩短；笔记输入灰框缺失。 |`artifacts/h5/zh/tfAnnQ.png` / `artifacts/flutter/zh/tfAnnQ.png`|
|tfAnnQ|en|多logo/居中下移；播放中柱形图丢失，情境提示从金色小字变黑粗字，播放卡高度缩短；笔记输入灰框缺失。 笔记标题/占位仍中文。|`artifacts/h5/en/tfAnnQ.png` / `artifacts/flutter/en/tfAnnQ.png`|
|tfTalkQ|zh|与公告同样多logo、播放图标和音频条边框缺失；情境说明更粗、笔记输入框背景丢失、整页下移。 |`artifacts/h5/zh/tfTalkQ.png` / `artifacts/flutter/zh/tfTalkQ.png`|
|tfTalkQ|en|与公告同样多logo、播放图标和音频条边框缺失；情境说明更粗、笔记输入框背景丢失、整页下移。 笔记标题/占位仍中文。|`artifacts/h5/en/tfTalkQ.png` / `artifacts/flutter/en/tfTalkQ.png`|
|tfModEnd|zh|Flutter多logo并把模块结束卡居中；源为上方白卡，Flutter黄底；继续按钮矩形而非胶囊，内容行高不同。 |`artifacts/h5/zh/tfModEnd.png` / `artifacts/flutter/zh/tfModEnd.png`|
|tfModEnd|en|Flutter多logo并把模块结束卡居中；源为上方白卡，Flutter黄底；继续按钮矩形而非胶囊，内容行高不同。 |`artifacts/h5/en/tfModEnd.png` / `artifacts/flutter/en/tfModEnd.png`|
|tfModLoad|zh|加载图用的插图不同、尺寸缩小；进度条从粗胶囊改成细线，数字移到线下方。进度百分比差只是采样时间差，应另测加载时长。 |`artifacts/h5/zh/tfModLoad.png` / `artifacts/flutter/zh/tfModLoad.png`|
|tfModLoad|en|加载图用的插图不同、尺寸缩小；进度条从粗胶囊改成细线，数字移到线下方。进度百分比差只是采样时间差，应另测加载时长。 |`artifacts/h5/en/tfModLoad.png` / `artifacts/flutter/en/tfModLoad.png`|
|tfMod2Intro|zh|Flutter多出Home/logo整行并垂直居中，源卡片在顶部；原内容分隔线消失，继续按钮由胶囊变小圆角矩形，标题与说明的纵向留白不同。 |`artifacts/h5/zh/tfMod2Intro.png` / `artifacts/flutter/zh/tfMod2Intro.png`|
|tfMod2Intro|en|Flutter多出Home/logo整行并垂直居中，源卡片在顶部；原内容分隔线消失，继续按钮由胶囊变小圆角矩形，标题与说明的纵向留白不同。 |`artifacts/h5/en/tfMod2Intro.png` / `artifacts/flutter/en/tfMod2Intro.png`|
|tfM2P1Q|zh|Flutter多logo，计时下移；音频条少外框并新增播放中文字行；选项字母小框缺失，下一段原右侧灰色禁用胶囊变成底部全宽黄按钮；笔记灰底输入区丢失。 |`artifacts/h5/zh/tfM2P1Q.png` / `artifacts/flutter/zh/tfM2P1Q.png`|
|tfM2P1Q|en|Flutter多logo，计时下移；音频条少外框并新增播放中文字行；选项字母小框缺失，下一段原右侧灰色禁用胶囊变成底部全宽黄按钮；笔记灰底输入区丢失。 笔记占位仍是中文，源为英文。|`artifacts/h5/en/tfM2P1Q.png` / `artifacts/flutter/en/tfM2P1Q.png`|
|tfM2P2Q|zh|Flutter主内容居中下移，多logo；原金黄色细小说明变黑粗字，播放柱形图消失；笔记区的灰底输入框变成普通文字卡。 |`artifacts/h5/zh/tfM2P2Q.png` / `artifacts/flutter/zh/tfM2P2Q.png`|
|tfM2P2Q|en|Flutter主内容居中下移，多logo；原金黄色细小说明变黑粗字，播放柱形图消失；笔记区的灰底输入框变成普通文字卡。 笔记占位仍中文。|`artifacts/h5/en/tfM2P2Q.png` / `artifacts/flutter/en/tfM2P2Q.png`|
|tfM2P3Q|zh|Flutter多logo且整体下移，原播放中柱形图丢失；播放卡更矮，黄色情境小字变黑粗字，笔记编辑框灰底缺失。 |`artifacts/h5/zh/tfM2P3Q.png` / `artifacts/flutter/zh/tfM2P3Q.png`|
|tfM2P3Q|en|Flutter多logo且整体下移，原播放中柱形图丢失；播放卡更矮，黄色情境小字变黑粗字，笔记编辑框灰底缺失。 笔记占位仍中文。|`artifacts/h5/en/tfM2P3Q.png` / `artifacts/flutter/en/tfM2P3Q.png`|
|tfListenFb|zh|源头部/总分两卡为黄色，Flutter头卡黑色/总分白色；模块tab源黄白胶囊，Flutter黑白矩形；题型得分条从粗灰底黄色进度变细线，弱项区向下偏移。 |`artifacts/h5/zh/tfListenFb.png` / `artifacts/flutter/zh/tfListenFb.png`|
|tfListenFb|en|源头部/总分两卡为黄色，Flutter头卡黑色/总分白色；模块tab源黄白胶囊，Flutter黑白矩形；题型得分条从粗灰底黄色进度变细线，弱项区向下偏移。 |`artifacts/h5/en/tfListenFb.png` / `artifacts/flutter/en/tfListenFb.png`|
|tfSpk1Q|zh|原说明白卡贯穿剩余页面，Flutter仅包住短文字且全页居中；顶栏计时从黑胶囊变纯文字并下移，说明字体更大。需在同instruction阶段修布局，计时值本身不作问题判断。 |`artifacts/h5/zh/tfSpk1Q.png` / `artifacts/flutter/zh/tfSpk1Q.png`|
|tfSpk1Q|en|原说明白卡贯穿剩余页面，Flutter仅包住短文字且全页居中；顶栏计时从黑胶囊变纯文字并下移，说明字体更大。需在同instruction阶段修布局，计时值本身不作问题判断。 |`artifacts/h5/en/tfSpk1Q.png` / `artifacts/flutter/en/tfSpk1Q.png`|
|tfSpk2Intro|zh|多出SURGO logo并整页居中下移；任务三徽章变成小段文字，黄提示卡变白；开始/返回从同行变成上下全宽。 |`artifacts/h5/zh/tfSpk2Intro.png` / `artifacts/flutter/zh/tfSpk2Intro.png`|
|tfSpk2Intro|en|多出SURGO logo并整页居中下移；任务三徽章变成小段文字，黄提示卡变白；开始/返回从同行变成上下全宽。 |`artifacts/h5/en/tfSpk2Intro.png` / `artifacts/flutter/en/tfSpk2Intro.png`|
|tfSpk2Brief|zh|多logo并垂直居中下移；徽章样式简化为多行字，标题/说明/按钮间距不同；开始和返回按钮由并排变两行。 |`artifacts/h5/zh/tfSpk2Brief.png` / `artifacts/flutter/zh/tfSpk2Brief.png`|
|tfSpk2Brief|en|多logo并垂直居中下移；徽章样式简化为多行字，标题/说明/按钮间距不同；开始和返回按钮由并排变两行。 |`artifacts/h5/en/tfSpk2Brief.png` / `artifacts/flutter/en/tfSpk2Brief.png`|
|tfSpk2Q|zh|源白色答题面板铺满剩余高度，Flutter只给音频块白底导致黄背景暴露；球和文字更大且整体上移，计时胶囊丢失，音频条背景/边框/提示布局不符。 |`artifacts/h5/zh/tfSpk2Q.png` / `artifacts/flutter/zh/tfSpk2Q.png`|
|tfSpk2Q|en|源白色答题面板铺满剩余高度，Flutter只给音频块白底导致黄背景暴露；球和文字更大且整体上移，计时胶囊丢失，音频条背景/边框/提示布局不符。 |`artifacts/h5/en/tfSpk2Q.png` / `artifacts/flutter/en/tfSpk2Q.png`|
|tfSpeakFb|zh|总分分母被同字号放大，技能进度原粗灰底变细线；弱项彩色小标签/灰例句层次丢失，句子加粗和卡高增加导致后文下移。 |`artifacts/h5/zh/tfSpeakFb.png` / `artifacts/flutter/zh/tfSpeakFb.png`|
|tfSpeakFb|en|总分分母被同字号放大，技能进度原粗灰底变细线；弱项彩色小标签/灰例句层次丢失，句子加粗和卡高增加导致后文下移。 |`artifacts/h5/en/tfSpeakFb.png` / `artifacts/flutter/en/tfSpeakFb.png`|
|tfRead1Q|zh|原黑色计时胶囊变纯数字，任务小胶囊改整行下划线tabs；带空原文从紧凑内联变分散多行、题片黄顶栏消失；答题圆点变方块且面板初始高度减小。 |`artifacts/h5/zh/tfRead1Q.png` / `artifacts/flutter/zh/tfRead1Q.png`|
|tfRead1Q|en|原黑色计时胶囊变纯数字，任务小胶囊改整行下划线tabs；带空原文从紧凑内联变分散多行、题片黄顶栏消失；答题圆点变方块且面板初始高度减小。 Flutter填空说明第二句仍中文，H5已英文。|`artifacts/h5/en/tfRead1Q.png` / `artifacts/flutter/en/tfRead1Q.png`|
|tfRead2Q|zh|计时胶囊/任务tabs样式不符；黄色可拖栏变白并折行；选项字母框缺失，选项卡高度不同；上一题/下一题宽度和位置变化。 |`artifacts/h5/zh/tfRead2Q.png` / `artifacts/flutter/zh/tfRead2Q.png`|
|tfRead2Q|en|计时胶囊/任务tabs样式不符；黄色可拖栏变白并折行；选项字母框缺失，选项卡高度不同；上一题/下一题宽度和位置变化。 |`artifacts/h5/en/tfRead2Q.png` / `artifacts/flutter/en/tfRead2Q.png`|
|tfReadModEnd|zh|Flutter结束卡垂直居中下移，原H5顶部排列；按钮由胶囊变矩形，原阴影减弱、卡片新增细边框，正文更小更淡。 |`artifacts/h5/zh/tfReadModEnd.png` / `artifacts/flutter/zh/tfReadModEnd.png`|
|tfReadModEnd|en|Flutter结束卡垂直居中下移，原H5顶部排列；按钮由胶囊变矩形，原阴影减弱、卡片新增细边框，正文更小更淡。 |`artifacts/h5/en/tfReadModEnd.png` / `artifacts/flutter/en/tfReadModEnd.png`|
|tfReadModLoad|en|英文加载页插图更大，字号加大，原粗胶囊进度条变细黄紫线且百分比移到下方；中文Flutter截图已自动跳到模块2说明，不能算同状态证据。 |`artifacts/h5/en/tfReadModLoad.png` / `artifacts/flutter/en/tfReadModLoad.png`|
|tfReadMod2Intro|zh|Flutter说明卡垂直居中下移；正文部分句子加粗而原为普通字，按钮圆角更小，原阴影和内边距不同。 |`artifacts/h5/zh/tfReadMod2Intro.png` / `artifacts/flutter/zh/tfReadMod2Intro.png`|
|tfReadMod2Intro|en|Flutter说明卡垂直居中下移；正文部分句子加粗而原为普通字，按钮圆角更小，原阴影和内边距不同。 |`artifacts/h5/en/tfReadMod2Intro.png` / `artifacts/flutter/en/tfReadMod2Intro.png`|
|tfRead3Q|zh|计时黑胶囊缺失，任务pill变成整行下划线；源正文暖灰背景消失，内联填空变大间距行，底部黄色拖动条变白，答题圆点变方块。 |`artifacts/h5/zh/tfRead3Q.png` / `artifacts/flutter/zh/tfRead3Q.png`|
|tfRead3Q|en|计时黑胶囊缺失，任务pill变成整行下划线；源正文暖灰背景消失，内联填空变大间距行，底部黄色拖动条变白，答题圆点变方块。 Flutter补词第二句提示仍中文，原H5已英文。|`artifacts/h5/en/tfRead3Q.png` / `artifacts/flutter/en/tfRead3Q.png`|
|tfRead4Q|zh|计时黑胶囊变纯数字、任务pill变下划线；题片黄色拖动栏变白，选项字母徽章缺失、选项卡高度压缩，前后按钮尺寸和位置不同。 |`artifacts/h5/zh/tfRead4Q.png` / `artifacts/flutter/zh/tfRead4Q.png`|
|tfRead4Q|en|计时黑胶囊变纯数字、任务pill变下划线；题片黄色拖动栏变白，选项字母徽章缺失、选项卡高度压缩，前后按钮尺寸和位置不同。 |`artifacts/h5/en/tfRead4Q.png` / `artifacts/flutter/en/tfRead4Q.png`|
|tfReadFb|zh|源最终成绩/总估分均黄卡，Flutter总估分白卡且分母过大；源模块pill变下划线；技能粗进度条变细黄紫线，弱项模块层次/字号不符。 |`artifacts/h5/zh/tfReadFb.png` / `artifacts/flutter/zh/tfReadFb.png`|
|tfReadFb|en|源最终成绩/总估分均黄卡，Flutter总估分白卡且分母过大；源模块pill变下划线；技能粗进度条变细黄紫线，弱项模块层次/字号不符。 最终成绩和Upper标题混用中文，源H5为英文。|`artifacts/h5/en/tfReadFb.png` / `artifacts/flutter/en/tfReadFb.png`|
|mockListeningQ|zh|整体白卡/黑计时/固定答题片已接近；Flutter选择行缺原圆形radio，仅保留字母框；当前Part答题点折行且标签换行，非当前Part三个pill高度变高；题目文字额外换行。两秒计时差不作规则错误。 |`artifacts/h5/zh/mockListeningQ.png` / `artifacts/flutter/zh/mockListeningQ.png`|
|mockListeningQ|en|整体白卡/黑计时/固定答题片已接近；Flutter选择行缺原圆形radio，仅保留字母框；当前Part答题点折行且标签换行，非当前Part三个pill高度变高；题目文字额外换行。两秒计时差不作规则错误。 |`artifacts/h5/en/mockListeningQ.png` / `artifacts/flutter/en/mockListeningQ.png`|
|mockListeningQ2|zh|源失踪人员描述是紧凑两列表格，Flutter每条变独立圆角卡片，表格高度增大；答题片初始高度及Part标签不同。源横排圆点在Flutter折成两行，英语顶栏提示折行。 |`artifacts/h5/zh/mockListeningQ2.png` / `artifacts/flutter/zh/mockListeningQ2.png`|
|mockListeningQ2|en|源失踪人员描述是紧凑两列表格，Flutter每条变独立圆角卡片，表格高度增大；答题片初始高度及Part标签不同。源横排圆点在Flutter折成两行，英语顶栏提示折行。 |`artifacts/h5/en/mockListeningQ2.png` / `artifacts/flutter/en/mockListeningQ2.png`|
|mockListeningQ3|zh|Flutter答案表原横排10个圆点折成两行，当前Part标签折行；底部面板把手和标题行更高，英语提示折行。匹配选项框原灰底粗字变成纯字灰小字。两秒计时差只作采样差记录。 |`artifacts/h5/zh/mockListeningQ3.png` / `artifacts/flutter/zh/mockListeningQ3.png`|
|mockListeningQ3|en|Flutter答案表原横排10个圆点折成两行，当前Part标签折行；底部面板把手和标题行更高，英语提示折行。匹配选项框原灰底粗字变成纯字灰小字。两秒计时差只作采样差记录。 |`artifacts/h5/en/mockListeningQ3.png` / `artifacts/flutter/en/mockListeningQ3.png`|
|mockListeningQ4|zh|原内联下划线填空变成大块矩形输入，句子被拆分导致首屏内容更少；答题卡圆点换行，面板标题/把手更高，当前Part折行。 |`artifacts/h5/zh/mockListeningQ4.png` / `artifacts/flutter/zh/mockListeningQ4.png`|
|mockListeningQ4|en|原内联下划线填空变成大块矩形输入，句子被拆分导致首屏内容更少；答题卡圆点换行，面板标题/把手更高，当前Part折行。 |`artifacts/h5/en/mockListeningQ4.png` / `artifacts/flutter/en/mockListeningQ4.png`|
|vocabTest|zh|基线整页向下居中，原居中圆底尺子图标变成圆角方块；开始按钮变矩形全宽，外卡多描边少阴影；Home位置下移。 |`artifacts/h5/zh/vocabTest.png` / `artifacts/flutter/zh/vocabTest.png`|
|vocabTest|en|基线整页向下居中，原居中圆底尺子图标变成圆角方块；开始按钮变矩形全宽，外卡多描边少阴影；Home位置下移。 |`artifacts/h5/en/vocabTest.png` / `artifacts/flutter/en/vocabTest.png`|
|vocabTestQ|zh|基线整体下移，单词从大标题居中变成靠左小字并加扬声器黄底；原说明小灰字变黑粗字；中英选项行高/样式不同。 |`artifacts/h5/zh/vocabTestQ.png` / `artifacts/flutter/zh/vocabTestQ.png`|
|vocabTestQ|en|基线整体下移，单词从大标题居中变成靠左小字并加扬声器黄底；原说明小灰字变黑粗字；中英选项行高/样式不同。 英文模式Flutter选项仍为中文释义，原H5选项是英文。需针对同一个源节点检查翻译，不改变题库。|`artifacts/h5/en/vocabTestQ.png` / `artifacts/flutter/en/vocabTestQ.png`|
|vocabTestPass|zh|推荐结果从顶部移到中部，红色靶心图标被换形并加方框；原两枚并排胶囊按钮改为纵向全宽矩形。 |`artifacts/h5/zh/vocabTestPass.png` / `artifacts/flutter/zh/vocabTestPass.png`|
|vocabTestPass|en|推荐结果从顶部移到中部，红色靶心图标被换形并加方框；原两枚并排胶囊按钮改为纵向全宽矩形。 |`artifacts/h5/en/vocabTestPass.png` / `artifacts/flutter/en/vocabTestPass.png`|
|vocabTestFail|zh|未通过结果同模板差异：靶心图标、卡片阴影/描边和按钮布局不符，整卡下移。 |`artifacts/h5/zh/vocabTestFail.png` / `artifacts/flutter/zh/vocabTestFail.png`|
|vocabTestFail|en|未通过结果同模板差异：靶心图标、卡片阴影/描边和按钮布局不符，整卡下移。 |`artifacts/h5/en/vocabTestFail.png` / `artifacts/flutter/en/vocabTestFail.png`|
|vocabStudy|zh|原大字居中单词变小，speaker加方框；退出/进度/示例标记从同行变为多行；卡片垂直下移，查看释义按钮从自适应胶囊改全宽矩形，提示卡插图缩小。 |`artifacts/h5/zh/vocabStudy.png` / `artifacts/flutter/zh/vocabStudy.png`|
|vocabStudy|en|原大字居中单词变小，speaker加方框；退出/进度/示例标记从同行变为多行；卡片垂直下移，查看释义按钮从自适应胶囊改全宽矩形，提示卡插图缩小。 |`artifacts/h5/en/vocabStudy.png` / `artifacts/flutter/en/vocabStudy.png`|
|vocabStudy2|zh|单词/按钮尺寸与位置、进度区换行及提示卡图不符；原提示卡含水獭，Flutter第二词提示缺图。 |`artifacts/h5/zh/vocabStudy2.png` / `artifacts/flutter/zh/vocabStudy2.png`|
|vocabStudy2|en|单词/按钮尺寸与位置、进度区换行及提示卡图不符；原提示卡含水獭，Flutter第二词提示缺图。 |`artifacts/h5/en/vocabStudy2.png` / `artifacts/flutter/en/vocabStudy2.png`|
|vocabStudy3|zh|主卡下移且大字缩小，speaker多方框，查看释义按钮扩为全宽；进度状态字换到下一行、提示水獭缩小。 |`artifacts/h5/zh/vocabStudy3.png` / `artifacts/flutter/zh/vocabStudy3.png`|
|vocabStudy3|en|主卡下移且大字缩小，speaker多方框，查看释义按钮扩为全宽；进度状态字换到下一行、提示水獭缩小。 |`artifacts/h5/en/vocabStudy3.png` / `artifacts/flutter/en/vocabStudy3.png`|
|vocabStudy4|zh|与学习模板一致：卡片居中下移、单词字号更小、释义按钮全宽；顶部示例数据/计数排布不同，提示卡插图缩小。 |`artifacts/h5/zh/vocabStudy4.png` / `artifacts/flutter/zh/vocabStudy4.png`|
|vocabStudy4|en|与学习模板一致：卡片居中下移、单词字号更小、释义按钮全宽；顶部示例数据/计数排布不同，提示卡插图缩小。 |`artifacts/h5/en/vocabStudy4.png` / `artifacts/flutter/en/vocabStudy4.png`|
|vocabDetail|zh|原整体大标题和徽章紧贴，Flutter字号较小而徽章更多换行；释义与例句卡行距加大，首个详情卡变高，下方错误/同反义词卡下移；空态/段落图标丢失。 |`artifacts/h5/zh/vocabDetail.png` / `artifacts/flutter/zh/vocabDetail.png`|
|vocabDetail|en|原整体大标题和徽章紧贴，Flutter字号较小而徽章更多换行；释义与例句卡行距加大，首个详情卡变高，下方错误/同反义词卡下移；空态/段落图标丢失。 |`artifacts/h5/en/vocabDetail.png` / `artifacts/flutter/en/vocabDetail.png`|
|vocabDetail2|zh|原搭配空态为灰色chip，Flutter变纯文字；标题区换行、释义块和例句高度增加，后续卡片下移，标题旁图标缺失。 |`artifacts/h5/zh/vocabDetail2.png` / `artifacts/flutter/zh/vocabDetail2.png`|
|vocabDetail2|en|原搭配空态为灰色chip，Flutter变纯文字；标题区换行、释义块和例句高度增加，后续卡片下移，标题旁图标缺失。 |`artifacts/h5/en/vocabDetail2.png` / `artifacts/flutter/en/vocabDetail2.png`|
|vocabDetail3|zh|原搭配空态胶囊背景丢失，主体首卡更高；同义词/反义词/词族的小图标缺失，后续卡片位置下移。 |`artifacts/h5/zh/vocabDetail3.png` / `artifacts/flutter/zh/vocabDetail3.png`|
|vocabDetail3|en|原搭配空态胶囊背景丢失，主体首卡更高；同义词/反义词/词族的小图标缺失，后续卡片位置下移。 |`artifacts/h5/en/vocabDetail3.png` / `artifacts/flutter/en/vocabDetail3.png`|
|vocabDetail4|zh|标题和徽章更多换行，原搭配空态灰badge被纯文本代替；卡片加描边，阴影与段落间距不符。 |`artifacts/h5/zh/vocabDetail4.png` / `artifacts/flutter/zh/vocabDetail4.png`|
|vocabDetail4|en|标题和徽章更多换行，原搭配空态灰badge被纯文本代替；卡片加描边，阴影与段落间距不符。 |`artifacts/h5/en/vocabDetail4.png` / `artifacts/flutter/en/vocabDetail4.png`|
|vocabDone|zh|完成插图縮小下移，三项统计原轻分隔无外框变成白色大卡；黄色强调与前句粘连，底部并排胶囊改纵向全宽按钮。 |`artifacts/h5/zh/vocabDone.png` / `artifacts/flutter/zh/vocabDone.png`|
|vocabDone|en|完成插图縮小下移，三项统计原轻分隔无外框变成白色大卡；黄色强调与前句粘连，底部并排胶囊改纵向全宽按钮。 |`artifacts/h5/en/vocabDone.png` / `artifacts/flutter/en/vocabDone.png`|
|prep|zh|头像应黄底/白边，Flutter白底；顶部标题/头像/姓名总体接近但统计卡下移，原统计阴影减弱；统计文字粗细、分隔线高度、设置条目图标与原SVG不同，列表向下累积偏移。 |`artifacts/h5/zh/prep.png` / `artifacts/flutter/zh/prep.png`|
|prep|en|头像应黄底/白边，Flutter白底；顶部标题/头像/姓名总体接近但统计卡下移，原统计阴影减弱；统计文字粗细、分隔线高度、设置条目图标与原SVG不同，列表向下累积偏移。 |`artifacts/h5/en/prep.png` / `artifacts/flutter/en/prep.png`|

## 最终回归状态
最终修复未完成，因此不能把此前268测试/30校验全通过当作本轮最终验收。最近完整日志见docs/verification；后续代码每批测试并在收尾时重新完整analyze/test/release/hash。
iOS/Android真机、TTS/输入法/键盘/后台计时等仍未全验。未做远程部署或Git推送。
