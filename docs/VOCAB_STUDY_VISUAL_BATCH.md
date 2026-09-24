# 词汇学习四页：线上逐页修正记录

参考 https://surgo-mobile.vercel.app/ ，范围仅 `vocabStudy`、`vocabStudy2`、`vocabStudy3`、`vocabStudy4`。这是一轮已实施并验证的修改，不是整站视觉完全一致声明。

## 已实现

- 保留四个原单词/音标、50%/66.6%/100%/100%进度、各自查看释义目标、退出到vocab；原喇叭没有onclick，仍为装饰，未擅自添加播放。
- 顶部退出、演示数据、6px进度条、计数恢复同一行；正常390px实际字体下无需滚动，超大字体下允许横向滚动，避免溢出或缩字。
- 单词恢复44px、800字重、-.5字距；喇叭换成原30px无边框SVG。白卡44px上下/24px左右内距、20px圆角、原阴影。
- 恢复音标/回忆提示/副提示间距与字号；查看释义按钮为自适应宽胶囊，不再全宽矩形。
- 提示图片48×48 cover及12px圆角，黄底提示卡16px圆角；第二词原无图片，保持无图片。

## 证据与逐页结论

每页已分别查看中文和英文线上/Flutter图。均仍标为“已修一轮，存在细微差异”，未标完全通过。

|路由|线上双语图|Flutter双语图|本轮观察|
|---|---|---|---|
|vocabStudy|artifacts/online/{zh,en}/vocabStudy.png|artifacts/flutter-vstudy1/{zh,en}/vocabStudy.png|顶栏和大词/胶囊结构恢复；字重/音标字形略不同，卡底和提示块相对线上约数像素偏下。|
|vocabStudy2|artifacts/online/{zh,en}/vocabStudy2.png|artifacts/flutter-vstudy1/{zh,en}/vocabStudy2.png|保持原无提示插图；结构与单词/进度一致，仍有字形、细小行高/按钮宽度差。|
|vocabStudy3|artifacts/online/{zh,en}/vocabStudy3.png|artifacts/flutter-vstudy1/{zh,en}/vocabStudy3.png|100%进度、Analyse与详情3路径保持；布局接近，中文卡片略高、英文阴影与字重不完全一致。|
|vocabStudy4|artifacts/online/{zh,en}/vocabStudy4.png|artifacts/flutter-vstudy1/{zh,en}/vocabStudy4.png|Context及详情4路径保持；线上该音标自然行高更短，Flutter卡底约多出数像素，需要后续字体度量细化。|

合成对照图：`artifacts/visual_audit/vstudy1-{route}.png`。

原站右上全局图标与进度文字有遮挡，这轮没有改变全局按钮或隐藏进度；若要调整须单独处理，不能假称是像素一致。

## 字体采集说明

首张中文图曾因10.56MB远程Noto字体下载超时缺图；其余7张真实下载/缓存就绪。已单独补齐首张：只对该字体URL使用此前从原URL下载的完全相同字节作为传输缓存，未替换字形、未修改应用字体或截图DOM。

- 字体SHA256：`ae82f4e2a55e1316a55bcc1d05e9555ce08d8bda07e893b486896b626fd852ff`
- 清单：`artifacts/visual_audit/font_cache/manifest.json`
- 补图台账：`artifacts/visual_audit/flutter-vstudy1-vocabStudy-zh-capture.json`，含exactFontTransportCache。
- 其他图台账：`artifacts/visual_audit/flutter-vstudy1-vocabStudy,vocabStudy2,vocabStudy3,vocabStudy4-capture.json`，首张旧error记录保留，补图台账为新证据。

## 验证

`test/vocab_study_visual_test.dart`新增8项：四页×双语，检查词内容、44px标题、30pxSVG、顶栏同行、卡片padding、按钮非全宽、图像规则以及查看释义/退出目标。全部通过；原词汇题库/路由测试继续通过。

2026-09-22T21:43:56+08:00，`python tool/verify_handover.py`：30项全部通过；analyze零问题；284项测试通过；生产Web release完成。原H5只读未改，未Git提交/推送/远程部署。

下一轮细化点：中文PingFang与Flutter Noto回退的度量差、音标字体和按钮细微字宽。其余词汇测试/完成页不属于本四页修正，仍保留原验收清单的差异状态。
