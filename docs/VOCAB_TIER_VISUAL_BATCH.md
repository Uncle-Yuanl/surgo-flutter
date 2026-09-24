# 词汇Tier四页及空状态：线上逐页复核（2026-09-22）

范围：vocabTier1、vocabTier2、vocabTier3、vocabTier4、vocabNoNew。参考https://surgo-mobile.vercel.app/，首屏390×844，中英双语。完成一轮原生布局修正/测试/真实截图人工对照，仍非完全视觉验收。

## 已修正

- 新`tier_source_widgets.dart`：原Home SVG固定在内滚动区上方；四Tier路由和空状态由shell直接交给有界TierFrame（18/8/18/0），不再把Home与全部内容一起滚动。
- 耳朵、勾、笔、时钟及空状态原SVG路径，不用Material近似图标；26/19/52px尺寸与原型一致。
- 进度卡：三个统计保持左侧194px宽，每列最少56px、36px圆标及44px分隔线；不再均分整卡。进度底轨明确314px宽，fill=314×pct/100，6px圆角，0%也保留整条底轨。
- 推荐卡恢复源flex-wrap：78px图+220px文字一行，开始学习作为下一行独立按钮；不再把文字和按钮挤成三列。
- 预览卡恢复源换行语义：词组作为整体，查看全部在剩余宽度不足时另起一行。正常390下中文同排；英文Tier1/3/4另行，Tier2同排。源码和真实DOM都已核对。
- 22px按钮圆角、源阴影及12×22/13×26padding；继承自然行高，Arial型按钮局部使用已有OFL Arimo；空状态按钮按源继承VioletSans。
- 白卡原阴影/18px圆角，原数据/词汇占位及文字完整保留。

## 未改规则

Tier1/2继续与开始均→vocabStudy4；Tier3/4均→vocabNoNew；四页查看全部→vocabBook；Home及空状态返回→vocab。原计数226/1302/1180/3221、Tier1百分比46及86/18/122、其余零进度原样。未补造Tier3/4缺失材料，未加入后台。

## 验证及修正过程

新增`test/vocab_tier_visual_test.dart`10项，真实VioletSans/Arimo和390×844；验证原SVG、固定Home、314px进度轨和实际百分比fill、194px统计、78px图、推荐按钮换行、预览词组同行/链接换行、所有路由目标、空状态图标y150。

原11项vocab_tiers_test仍通过。

真实截图揭示先前测试未覆盖的缺陷，均追加断言后再修：
- 原先进度轨未给宽度；固定宽度而非只对Fill设比例。
- 单靠TextPainter/IntrinsicWidth仍挤压中文第三个chip，未假称解决；最终词组用非flex收缩Row，外层Wrap负责链接换行。
- 全路由Ahem检查暴露单个英文占位chip超宽51px；单项不用Row，允许文本自身换行。真实字体截图不变。未删/跳过失败测试。
- 曾误把英文Tier3/4链接判为同排，核对真实DOM后纠正为换行；不是为了让测试过而修改源规则。

2026-09-22T23:24:51+08:00，`python tool/verify_handover.py`：312项测试、30项检查全部通过，analyze零问题、141路由映射、生产release成功、H5四文件哈希一致。没有commit/push/部署或SDK升级。

## 截图证据

源：`artifacts/online/{zh,en}/{route}.png`，10张，台账`online-vocabTier1,vocabTier2,vocabTier3,vocabTier4,vocabNoNew-capture.json`。

最终原生：`artifacts/flutter-vtier5/{zh,en}/{route}.png`，10张，台账`flutter-vtier5-vocabTier1,vocabTier2,vocabTier3,vocabTier4,vocabNoNew-capture.json`；errors为空。

并排：`artifacts/visual_audit/vtier5-{route}.png`。

人工检查vtier4的五张双语并排后，vtier5只改变Tier1的进度填充末端圆角（差异矩形zh38,274→183,282；en38,267→183,275），其余8张与已审图像素完全一致。Tier1最终图再次人工检查。20张原图SHA及逐语言状态存`vocab_tier_reviewed.json`。

## 仍有差异 / 未验

- 中文字形、字重和约数px累计纵向位置差；英文按钮局部字重不同。英文整体卡片高度/换行较接近但不是逐像素相同。
- 状态栏/全局按钮颜色/抗锯齿等公共差异仍存在，不在本批扩大修改。
- 5页仅初始截图；已测试固定导航与点击分支，但所有按压/焦点/极端系统字号及真机未逐状态拍图。
- 不将10个新增测试或10张新图记作完全还原，冻结282状态历史清单保持原结论。
