# 词本详情6页：逐页复核（2026-09-23）

范围vocabWord/2/3/4与vocabPronWord/2。参考https://surgo-mobile.vercel.app/。本轮完成共享原生视图、回归、首屏和底部真实截图核对；不是整页完全保真通过。

## 实施与规则

- 共享`word_detail_view.dart`/`word_detail_widgets.dart`。两个原模块仍保留原固定数据/路由/session；发音详情仅适配同结构数据，不改原文或占位材料。
- 32px词、22px原speaker、17px原星形、18px信息卡原SVG；灰色词性/级别/学习状态标签，黄色释义块、灰色例句、chips、五张信息卡。
- 原固定返回导航和18/8/18/0内滚动，不与正文一起滚动。
- 原speaker及“移出单词本”没有onclick，保持不响应；没有添加移除或播放业务。
- 主卡CSS内距22/22/22/26，1px边框由Container自动计入；释义内距17/15，左4px边框同理。修复首版重复计入边框的问题，防止文字偏右/卡片层层偏高。
- 英文标题右侧状态组按源另行右对齐；正常390中文同行。保留所有原词/解释/例句/缺失占位。

## 回归

新增`test/word_detail_visual_test.dart`12项（6路由×2语言），加载实际VioletSans、390×844。

测试除内距常数还断言真实坐标：主卡y106宽354，词x41/y129，黄色释义x41且标题x62、例句宽308。覆盖全部图标尺寸、无新增交互、固定返回/滚动、各本返回目标。原22项单词本/发音本数据与路由测试继续通过。

2026-09-23T00:26:32+08:00：verify_handover 342 tests / 30 checks全过，analyze零问题、141路由映射、生产Web release、H5四hash保持。没有commit/push/远程部署。

## 真实证据

- 源首屏：`online-vocabBook,vocabWord,vocabWord2,vocabWord3,vocabWord4,vocabPron,vocabPronWord,vocabPronWord2-capture.json`中的6条路由×2语言；源底部：`online-vword1-…-bottom-capture.json`。
- 最终原生：`artifacts/flutter-vword2/{zh,en}/{route}.png`及`-bottom.png`，24张，两个capture台账各12条，errors为空。
- 人工并排：`artifacts/visual_audit/vword2-all-{zh,en}[-bottom].png`四张网格，保持原比例，每格同路由源/原生，全部已检查。早期vword1单独双语图用于发现偏移，不当作最终结果。
- 24个路由/语言/状态对、48张源/原生文件SHA：`artifacts/visual_audit/vocab_word_reviewed.json`。

## 仍有差异与未验

- 中文字形/字重、IPA、英文标题及正文粗细、少量行高/数px累计偏差仍可见；侧卡高度和底部位置接近但非逐像素一致。
- Identify的例句与chips较长，累计差比其他占位词略明显；普通/发音两套都已核对，不依靠只看共用代码作验收。
- 检查的是首屏及滚动末端，不代表全部滚动位置/按压焦点/放大字体和真机都验过。
- 原型不响应的移除和speaker不作为待实现功能。字体、布局残余仍在审计范围，不标视觉“通过”。

前批单词本/发音本列表见`VOCAB_BOOK_VISUAL_BATCH.md`。H5保持只读；冻结282基线不因新增测试通过被改成整页通过。
