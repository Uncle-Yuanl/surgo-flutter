# 词汇测试与完成页：线上逐页修正（2026-09-22）

参考 https://surgo-mobile.vercel.app/ 。范围：vocabTest、vocabTestQ、vocabTestPass、vocabTestFail、vocabDone。完成本轮实施、回归、双语真实截图和人工对照；不是这五页或整站的完全保真验收。

## 实施内容

- 拆分显示到 `vocab_test_views.dart` / `vocab_done_view.dart`，保留 `vocab_quiz_module.dart` 公共入口、固定数据和四个已修study视图。
- 测试说明：源24px Home SVG、24px卡顶距、38×26内距、64px圆形尺子底座/30px原SVG、22px标题、280px上限胶囊CTA。
- 单题：32px词、26px原无框喇叭、5px满进度、白底14px圆角选项、12px间距。原喇叭没有onclick，未添加播放。
- 修正选项文本分段：字母与释义不再拼接成不能命中的整串，`SourceText(o.def)`使用已捕获的原DOM映射。英文释义恢复，原中文数据和正确答案不变。
- 结果：40×26卡内距、60px占位/48px原靶心SVG、24px标题、两个同排胶囊按钮；英文返回按钮保持两行。
- 完成：180px完整水獭；原两个标题文本节点（28px正文/26px高亮）；去掉原生版多余的统计白卡；48px统计圆标、分隔线、黄底提示和同排双按钮。保留固定2/1/32数值。
- 采用实际线上运行后字号，而非只抄声明CSS；单题局部行高按线上中英DOM测量，随系统text scale正常缩放。

## 原规则与新测试

`test/vocab_quiz_visual_test.dart`新增10项（5页×双语）。使用390×844 MediaQuery、VioletSans和本地Arimo字体。覆盖：卡片宽度/图标尺寸、英文选项翻译、全4个选项与跳过/退出、结果两个目标、完成页固定统计与两按钮布局和目标。

- A → vocabTier2；B/C/D及跳过 → vocabTier1。
- 测试说明开始 → vocabTestQ；跳过/Home → vocab。
- Pass与Fail开始学习都 → vocabStudy4（原型如此，不擅自改成别的词）。
- 完成页返回 → vocab；待巩固复习 → vocabStudy。
- 未加入评分、持久化、录音、后台或网络业务。
- 原旧测试只将组合文本finder改为选项key，没有改题目预期。

## 实际截图与观察

线上10张：`artifacts/online/{zh,en}/{route}.png`。
台账：`artifacts/visual_audit/online-vocabTest,vocabTestQ,vocabTestPass,vocabTestFail,vocabDone-capture.json`，含源DOM计算样式、图片解码和真实URL。

|路由|最新Flutter图|人工观察，仍非完全通过|
|---|---|---|
|vocabTest|artifacts/flutter-vquiz3/{zh,en}/vocabTest.png|卡片/尺子/标题/说明与胶囊布局恢复；中文字形及轻微行高/卡底差仍存在。|
|vocabTestQ|artifacts/flutter-vquiz4/{zh,en}/vocabTestQ.png|双语释义正确、题目居中、选项尺寸/间距接近源；中文约数px下移，英文选项字重仍较源轻，边框渲染略有差异。|
|vocabTestPass|artifacts/flutter-vquiz3/{zh,en}/vocabTestPass.png|靶心/卡片/同排CTA恢复；英文换行和卡片高度接近源，字重仍不同，中文CTA略下移。|
|vocabTestFail|artifacts/flutter-vquiz3/{zh,en}/vocabTestFail.png|与Pass同布局，Tier1/0分固定文案正确；保留相同字形/字重及数px偏移差。|
|vocabDone|artifacts/flutter-vquiz3/{zh,en}/vocabDone.png|完整图片、统计分隔、提示与双CTA恢复；原蓝色书本字符在Flutter仍呈单色符号、勾形状/字重不同。中文标题及统计有细微位置差。|

人工双语并排图：`artifacts/visual_audit/vquiz3-{route}.png`；答题页以更新的 `vquiz4-vocabTestQ.png`为准。旧vquiz1/vquiz2为修正过程证据，未伪装成最终图。

截图真实Chrome/CanvasKit、390×844 DPR1，等待字体完成。仅对原Noto字体URL使用已验证完全相同字节的传输缓存（见VOCAB_STUDY_VISUAL_BATCH），未用截图替代页面，也未改线上内容。所有新采集台账errors为空。源全局图标覆盖进度文字的问题仍存在，本轮未擅改全局设计。

## 可交付按钮字体

源DOM证明button默认Arial，与正文VioletSans不同。没有复制系统专有字体；新增OFL许可、Arial字宽兼容的Arimo，仅用于这五页的QuizPill及选项。仍不声称字体完全相同。

- 来源说明：https://raw.githubusercontent.com/google/fonts/main/ofl/arimo/DESCRIPTION.en_us.html
- 静态字体：https://raw.githubusercontent.com/googlefonts/Arimo/main/fonts/ttf/Arimo-Bold.ttf
- `assets/fonts/Arimo-Bold.ttf`，485872字节，SHA256 `d7a8b187cf8444d4cfee102e8eae9e3043682fd5106d5d33ed677fe268a0e2ba`。
- 许可：`assets/fonts/Arimo-static-OFL.txt`，OFL正文作为应用asset附带，团队再分发须保留。
- 最初可变字体试验已被静态700字重取代，不用于发布。此替代改善字宽/换行，实际截图仍有字重差，留作后续精修，未伪称问题完全消除。

## 最终本地验证

2026-09-22T22:25:02+08:00，`python tool/verify_handover.py`：30项检查全部通过；analyze零问题；294项测试通过；生产Web release成功；141源路由映射保持。

原H5四文件SHA256与基线一致。没有Git提交/推送/远程部署。SDK/依赖未升级（工具提示64项受版本约束的依赖更新，已告知）。

未验：真机、放大字体下全部分支、逐像素一致、完成页原彩色字符与本地字体完全匹配、所有按压/焦点状态。基线282项表保留历史状态，本批只新增更新证据，不把测试通过计作全页面视觉通过。
