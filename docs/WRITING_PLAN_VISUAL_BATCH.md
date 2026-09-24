# 作文规划页：四步骤与选中状态复核（2026-09-23）

范围writingPlan；真实截图以Task2，中英analysis/arg/arg-picked/para/vocab/vocab-picked六态及para/vocab-picked底部，共16状态对。四题型组件均有测试。完成一轮修正，不标完全保真。

## 原生实现

新增writing_plan_view.dart、writing_plan_panel.dart、writing_plan_widgets.dart；固定Home/19px步骤条，原26px白卡、粉色警告、灰/黄/锁定折叠行、下半带黄色划线标题、带原因的论点卡、段落标签和黄色笔记、96px词列/例句/选中勾，按源布局实现。

原状态行为：论点单选后源整页重渲染并回顶；词汇多选只局部更新，不回顶；上一/下一步、无论点的锁提示、最后进入topics保持。加入生词本仍只原型alert，不写入数据库。

修正两个既有迁移缺陷：
- Task1的parasByArg是数组，Task2是对象。旧getter固定字符串键导致Task1段落崩溃；现按真实类型读取并保留源回退0规则，题库不改。新增数组/对象两分支测试。
- 初始DOM翻译表不含非初始规划状态。论点/原因/段落语句改走原Translator精确规则，中文恢复源已有翻译，原题库字符串不改。词汇卡例句在源中仍是英文，未一概翻译。

底部52px双/三按钮按源flex-basis分配：选词时next比add宽16px，避免中文字拆行；prev47px。源码CSS边距折叠与子元素多次缩字号均从实测处理。

## 验证

新增writing_plan_visual_test.dart 9项：中英状态交互各1、其他三题型×双语6、数组/对象oracle1。覆盖门槛alert、重渲染revision、词汇选择不刷新route、数据分支、prev/home、开始写作、中文翻译、按钮单行/高度/宽度。

2026-09-23T01:47:52+08:00，verify_handover 364 tests、30 checks全过，analyze零、生产release、141路由、H5四hash保持。中间analyze弃用Color.value已改colorFilter，未屏蔽lint。无commit/push/部署。

## 证据

源首屏台账online-wplan1-writingPlan-t2-{state}-capture.json；源底部online-wplan2-…-{state}-bottom-capture.json。
最终原生artifacts/flutter-wplan3/{zh,en}/writingPlan-t2-{state}.png及-bottom.png共16；对应台账均保存。
人工8张双语并排artifacts/visual_audit/wplan3-{state}.png（含两个-bottom）均已检查。
16状态对/32原图SHA：writing_plan_reviewed.json。

## 仍有差异

字号/骨架/黄粉灰卡与选中态基本恢复，仍有字体粗细/中文轮廓、警告字符、少量行高/几px偏移；表内部分英文文字仍保留源中文并非漏翻。英文动态选词后原refreshPlanFoot未调用applyLang的行为尚未单独录制，当前fixture是选好后完整渲染，不冒充动态完全等价。

Task1/letter/email所有步骤组件与规则测试过，但实际线上截图本批只Task2；其他题型视觉、两个论点的所有长段落、中间滚动点、真机/无障碍未全验。原Task1规划含animal-testing内容的源题库矛盾不擅改。作答writingCompose仍是下一批待改。
