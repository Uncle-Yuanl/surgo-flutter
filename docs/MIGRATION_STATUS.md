# SURGO 原生迁移状态（2026-09-23）

## 当前检查点

- 141 / 141 源路由已接入实际原生 Dart Widget，不再有迁移占位页。
- 141路由×中英2语言=282个初始状态已真实加载渲染，布局审计通过。
- 2026-09-23 05:07完整本地回归：静态分析零问题、419项测试通过、30项交接校验全通过。原始结果见 `verification/summary.json`。
- Web release构建成功。Preview已实际点击首页→阅读→生成→作答，以及考试→口语→准备→mockSpeakingQ。详见 `VISUAL_CHECK.md`。
- 原题库与翻译表由原JS运行导出；2862翻译案例、102正则案例、日常口语33状态快照及模块专项测试保留。
- 新增2026条原DOM逐页面文本映射，遵守源实际翻译行为，不改题库/用户输入。
- 继续学习已恢复固定任务筛选和reading/listening进度，6项回归通过。
- 原H5保持只读；没有本轮git commit/push或远程部署。
- 用户追加的首页完整插图、金刚区及倒计时文字加大、通知小字加大及全部消息页已完成，详见 `HOME_NOTIFICATIONS_20260922.md`。
- 282对390×844真实浏览器基线已审阅，279项有可见差异、3项待同状态重验，不据此标记全页通过。
- 发音11页、词汇学习4页、词汇测试/完成5页、词汇释义4页（含底部状态）、Tier及空状态5页、词汇发音复习7页、单词本/发音本列表2页、词本详情6页、词汇主页1页已按指定线上版本完成一轮修正/回归/重截图；残余及资源记录见 `PRON_PRACTICE_VISUAL_BATCH.md`、`PRON_COURSE_VISUAL_BATCH.md`、`VOCAB_STUDY_VISUAL_BATCH.md`、`VOCAB_QUIZ_VISUAL_BATCH.md`、`VOCAB_DETAIL_VISUAL_BATCH.md`、`VOCAB_TIER_VISUAL_BATCH.md`、`VOCAB_PRON_VISUAL_BATCH.md`、`VOCAB_BOOK_VISUAL_BATCH.md`、`VOCAB_WORD_VISUAL_BATCH.md`、`VOCAB_HOME_VISUAL_BATCH.md`。写作确认页另完成四题型双语及图表zoom核对，见`WRITING_SESSION_VISUAL_BATCH.md`，规划页四步骤/选中态及两底部已完成一轮，见`WRITING_PLAN_VISUAL_BATCH.md`；作答页四题型/折叠/输入/底部26状态对已完成一轮，见`WRITING_COMPOSE_VISUAL_BATCH.md`。原站计时不可达，保持00:00:00而非擅加20min计时；审计白屏26图作废并在独立8955目录重采。

写作批改writingFeedback另完成Task1/2×mark/l1四分支40个双语同状态对照，新增18项测试。作文已局部接入OFL Inter并新增一项尺寸验证，但与源SF Pro仍有换行/字重差，单色字符也未完全还原，见 `WRITING_REVIEW_VISUAL_BATCH.md`。四个固定写作子页另完成24组截图抽查及14专项测试（含只读tab/返回），见`WRITING_LEGACY_VISUAL_BATCH.md`；报告页另恢复专属渐变、完整英文点评、雷达动画和订阅局部文字更新，8状态对已审，见`REPORT_VISUAL_BATCH.md`。个人中心另完成透明头像外阴影、中文卡片行盒、折叠间距、滚动与原型alert修正，4对初始/底部图已审，见`PROFILE_VISUAL_BATCH.md`。总计55路由有首轮修正/抽查记录，不等最终保真。

## 不是全量保真验收完成

上述证明了原生接入、已列出的数据/状态与初始布局，不证明所有题型分支、页面生命周期、错误状态和像素级视觉完全相同。iOS/Android没有真机构建与运行验证，真实录音/后台评分/推送并不存在。

雅思听力gap事件、模考退出/计时重置/答题卡已修并回归；仍需对照全部非默认状态、反馈标注/图表/图示、部分图标及其他跨路由重入计时。全量视觉人工复核尚未完成，清单见 `KNOWN_DIFFS.md` 与 `visual_audit_checklist.md`。

## 团队文件

- `HANDOVER.md`：运行方式、结构、集成约定、移动端未验项。
- `ROUTE_MAPPING.md` / `route_mapping.json`：141实际挂载路由映射。
- `KNOWN_DIFFS.md`：已修、源问题与仍未验证范围。
- `STATE_PARITY_AUDIT.md`：JS→Dart行为对照记录。
- `VISUAL_CHECK.md`：本轮可见路径和截图证据。
- `verification/`：本地验证脚本产生的日志与汇总。

复验：在工程目录执行 `python tool/verify_handover.py`。它仅本地检查、构建与写报告，不提交Git、不部署、不改源H5。
