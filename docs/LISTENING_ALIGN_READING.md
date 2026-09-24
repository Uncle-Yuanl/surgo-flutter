# 听力页面对齐阅读设计（2026-09-24）

用户要求：「听力日常训练以及考试的页面设计和图2阅读设计一致」。参照 `readingSession` 的版式重写
`listeningSession`，题目内容、题型、计时与批改规则一字不改。

## 改动

新增 `lib/features/ielts_listening/listening_layout.dart`：

- `ListeningHeader`：顶部计时 + 左上 home，与 `ReadingHeader` 同一套（26px Outfit 计时、
  下方「本次练习时长」副标题、超时显示「已超时」）。`contentTop` 与阅读同值（中文 72 / 英文 67）。
- `ListeningBrief`：上半区独立滚动，排版对齐阅读的文章区 —— 胶囊标签（日常训练 / IELTS 听力，
  与阅读 `_tag` 同色同字号）→ 17px 标题 → 14px 说明 → 白色圆角卡（圆角 22、阴影
  `0x143c321e`）。音频播放器搬进这张白卡：Section 标题、倍速菜单、进度条、四个控制键、耳机提示。

重写 `lib/features/ielts_listening/ielts_listening_module.dart` 的作答页：

- 由「整页一条直排滚动」改为阅读那套 `Stack`：上半区 brief + 下半区可拖拽答题面板。
- 面板与阅读完全同款：黄色把手条（44×4 圆角手柄）、`Answered n / total` + 「☰ 题号」按钮、
  圆角 `SurgoRadius.sheetTopAll`、阴影 `0x213c3214`，初始高度 58%、拖拽范围 20% ~ 高度-60。
- 选项改为阅读单选同款：左侧 32×32 字母徽标（A/B/C），选中填黄；文案去掉源串里的 `A)` 前缀。
- 题号导航面板改为白底圆角卡片按钮，和阅读风格一致。
- 底部操作条 74px（阅读只放一个提示胶囊、用 60px；这里要放「返回 / 提交并批改」两个按钮，
  60px 会把按钮裁掉）。

`lib/app/shell.dart`：`listeningSession` 改为与 `readingSession` 同路径直接返回页面。原先它走
通用 builder 列表、被外层 `SingleChildScrollView` 包住；新版是有界布局，套在无界滚动里会
`RenderBox was not laid out`（route_coverage / route_bilingual_audit 已捕获此错）。

## 顺带修正的既有缺陷

说明行的题型名，旧 Flutter 写「单选题」，而源站 app.js 只出现「选择题」（9 处，无「单选题」），
翻译表键也是「Part 1 · 选择题为主，…」。因此英文态这一整句匹配不到翻译、一直显示中文原文。
已按源站改回「选择题」，英文态恢复为
`Part 1, mostly multiple choice. Listen first, then answer questions 1-6.`

## 未改动

题库与题型分支（表格填空、配对、地图、笔记填空、多选）、`done/picks/gap` 作答状态、
计时与到时提示、`showMarking` 批改跳转、听力批改页 `listeningFeedback` 全部保持原样。

## 验证

- analyze 干净；486 项测试、31 项检查通过。
- build `listen3`，端口 8989；中英 `listeningSession` 实截图逐张核对：版式与阅读一致、
  字母徽标正确、底部按钮无裁切、英文说明行已翻译。
- 原 H5 四个核心文件哈希未变、`git status` 为空；未 commit / push / 部署。
