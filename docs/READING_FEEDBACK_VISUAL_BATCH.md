# 阅读批改 readingFeedback — 日常/模考分支补齐（2026-09-23）

## 本轮实现

- 原生页补齐原H5 `sessionMode==='mock'` 分支，三篇Passage/9道固定演示题，opts/pills/input三种题卡。此前只实现日常版。
- `tool/export_reading_feedback.cjs`只抽取/隔离求值RF_DEMO对象，输出`assets/data/reading_feedback_mock.json`，支持`--check`。不执行整份app.js、不改H5。
- 模考固定三篇共5/9、56%、估分6.5；日常原QB固定1/3、33%、6.5。均不是对用户实际答案评分。模考答题40题与批改演示9题不一致是原行为，保留。
- Passage按钮（含当前项）均通过app.go重新渲染，保留raPas、重置滚动；不改sessionMode。练习按钮强制IELTS、清selReadType→readingDaily。Home仅去ielts，不改examType。已有mock_selector入口设置mock，日常生成入口设置daily。
- 恢复日常四段原文精确三个证据高亮、模考各题ev高亮/题号圆标、原文/我的作答标题、题型标签、解释双文本节点、选项对错、输入答案对照。
- 专用阅读批改滚动区padding18/8/18/30、Home44圆钮内20图标；首页按钮不沿用阅读训练的24px无底版。
- 评分卡40px主分、嵌套14px比率，原文10px/1.85，题目12px/1.4，证据10px，解释10.5px/1.5。按实际渲染缩字后的字号实现，不按CSS声明字号直接复制。
- Web/原生均Dart Widgets/TextSpan，不用WebView。无后端/真评分/上传新增。

## 证据来源与视觉范围

本轮线上https://surgo-mobile.vercel.app/加载失败（Preview与Chrome取证均失败）。改用本地只读H5（8931）继续，四个核心文件SHA256仍与此前已验证的线上版本一致。这是**本地源渲染对照**，不能称为最新线上复核成功。

`readreview2`本地H5 × `readreview3`原生：daily、mock1/2/3，每个初始/scroll600/bottom ×中英，共24对48图。12张四列图已人工审阅。

readreview4/5先修pills宽度及输入label半角冒号；readreview6通过pill局部scaleDown修复文字另起一行，中英底部/scroll600四对已审。readreview7试验删除两个间距，但源DOM证明并未折叠：ra-h-wrap英文实际29px后另有8px字幕间距，rf-weak bottom11后另有6px按钮间距。已恢复原值，不将这次试验标作修复。最终统一取证版本为readreview8；逐张比对SHA与已人工审阅的readreview3/4/6，字节一致的图片沿用该人工结论，不将重复拍摄虚报为新增状态。详细索引`artifacts/visual_audit/reading_feedback_reviewed.json`。

初轮readreview1没有加入图片文件名fixture后缀，后续脚本已修正；readreview2起不同fixture不会覆盖同一文件。原始捕获台账保留captured-not-reviewed，人工记录单独维护。

## 当前回归

2026-09-23T14:14:36.629495+08:00：440 tests、31 checks全部通过，analyze零问题，生产Web release成功，H5哈希不变。新增7项测试：固定3篇/9题/5对数据，双语日常几何，高亮来源，双语Passage切换含当前项重渲染/滚动归零，pills宽度，输入原节点label，练习/Home目标及状态。审计readreview8 release另行构建成功。本次完整回归已经包含pill局部scaleDown、最终宽度及恢复经DOM测量确认的8px/6px间距。

## 明确剩余差异（不宣称完成保真）

- 字重/抗锯齿、正文/高亮的行框和题号基线仍不同；部分中英题型标签换行不同。整体弱项卡使mock中部位置累计约10–20px偏差。
- mock Passage2第6题pills原断行差已修：390px截图为准，将129.266/126.383微调到129/126保持同行，局部FittedBox.scaleDown避免文字另起一行。readreview6双语底部实图已确认同行且文字单行。字体略有缩放，不宣称字形像素完全一致。较大Preview视口测出的断行与390px截图不一致，保留记录而不覆盖真实目标截图结论。
- 原文高亮仍是方形TextSpan背景，H5有圆角；标签字符在Flutter可能单色。
- 英文模式部分模考中文解释/我的作答label保留源未翻译内容，不自行补译。
- bottom快照对齐底边，会隐藏上部累计高度差；不能只看按钮对齐判整页一致。
- 尚未补全逐题中部scroll与真实模考交卷→批改端到端截图，也未移动端设备验收。

本路由为已实施首轮修正/抽查，可计入58路由首轮覆盖，不能计为完整视觉通过。原H5只读，未commit/push/deploy。
