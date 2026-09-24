# 词汇释义四页：首屏及底部状态复核（2026-09-22）

参考 https://surgo-mobile.vercel.app/ 。范围 vocabDetail、vocabDetail2、vocabDetail3、vocabDetail4。仅修改Flutter项目，H5只读。完成一轮修正、全量回归、4页×2语言×首屏/底部真实截图对照；不是完全视觉通过。

## 实施

- `vocab_details_module.dart`保留原固定数据、词序、占位内容与公共入口；28px词、10px标签、18px无框speaker、13px IPA、20px卡内距、18px圆角/原阴影，去额外边框。
- 黄色释义块保留3px左线、14×16内距（实际文本起点额外计入左线），15px释义/11.5px英文说明；灰色例句容器12px/1.55与10.5px译文；10.5px搭配chips。
- Adapt/Analyse/Context的待提供例句仍在灰块中，待提供搭配仍是灰色chip，没有编造材料。修正其原生版过度紧凑问题。
- 侧边信息卡16×17内距、12px标题、11px正文、9px间隔、12px外间距；源字符图标保留，但Flutter彩色字体表现仍不一致。
- 新`vocab_detail_top.dart`恢复一行退出/演示数据/进度/计数，使用实际源字号与中英行高。大字号宽度不足时横向滚动，不挤压隐藏文本。
- 只给这四个路由接入源`.read-page/.read-scroll`等价容器：固定18/8/18/0外距、内滚动，不再继承普通页面30px底留白。其他路由不变。
- 自评三按钮同排，源红/黄/绿边框，保留原三个字符图标；修复英文标题未翻译。原因：源映射含前导空格，通用Translator trim后失配，使用经线上DOM验证的三个固定局部映射，不修改全站字典。
- Quiz批次已有OFL Arimo-Bold用于自评主标签；副标签仍有字体/换行差异。

## 行为与测试

新增`test/vocab_detail_visual_test.dart` 8项（4页×2语言），真实VioletSans/Arimo、390×844 MediaQuery。

验证卡片样式/原词/18px非交互speaker、进度同行、黄色释义内距、当前route session、全部三个自评按钮的原目标、退出目标、英文标题、同排尺寸、实际滚动底部贴齐844（没有30px额外底距）。原10项vocab_details_test不改规则，全部通过。

- Identify/Adapt所有自评分支 → vocabStudy3。
- Analyse/Context所有自评分支 → vocabDone。
- 退出 → vocab。
- 不写新复习数据库；原型提示文字不代表后台调度已实现。
- 不添加speaker播放行为，不改变题目或反馈数据。

## 真实证据

源截图：`artifacts/online/{zh,en}/{route}.png`及`{route}-bottom.png`。
原生最终：`artifacts/flutter-vdetail3/{zh,en}/{route}.png`及`{route}-bottom.png`。
并排人工图：`artifacts/visual_audit/vdetail3-{route}.png`及`vdetail3-{route}-bottom.png`，共8张；均已检查。

32张原图、16对状态记录及SHA256：`artifacts/visual_audit/vocab_detail_reviewed.json`。
采集台账：
- `online-vocabDetail,vocabDetail2,vocabDetail3,vocabDetail4-capture.json`
- `online-vdetail2-vocabDetail,vocabDetail2,vocabDetail3,vocabDetail4-bottom-capture.json`
- `flutter-vdetail3-vocabDetail,vocabDetail2,vocabDetail3,vocabDetail4-capture.json`
- 同名`-bottom-capture.json`
四份各8条，errors为空。

`tool/visual_capture.cjs`新增可选`--bottom`，仅影响指定采集：H5滚到实际`.read-scroll`末尾记录scrollTop/scrollHeight/clientHeight；Flutter对CanvasKit发实际wheel，截图另存`-bottom.png`、独立台账。没有改线上文件/伪造页面。首屏和底部差异不混算。源layout数据仍是首屏抓取，bottom的scrollState另外记录。

## 人工结论与未验

- 四页首屏：原卡块、标签换行、释义与例句/搭配结构恢复。英文卡片与信息块高度接近线上；中文仍有约数px累计偏移、字形与粗细差异。
- 四页底部：多余留白已去掉，自评三按钮英文已正确，侧卡/末端位置接近源。英文副标签换行和字重仍不同。
- 源彩色字符图标在Flutter多为单色：链接、禁止、词族、发音、自评表情，尚未完全还原，不能标全页通过。
- 字体替代/IPA字形、系统放大字、真机滚动/触摸、所有按压态未全面验证。
- 旧vdetail1/vdetail2保留为修正过程，不当成最终结果。历史整站282项基线状态不被本轮测试“通过”覆盖。

## 验证

2026-09-22T22:57:54+08:00，`python tool/verify_handover.py`：30检查全通过、302测试全通过、analyze零问题、141路由映射、生产Web release成功，原H5四hash一致。

中间一次analyze因新增shell if无花括号报info，补齐后全量重跑通过，无lint屏蔽。没有commit/push/远程部署，未升级SDK或依赖。
