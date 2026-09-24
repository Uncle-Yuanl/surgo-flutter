# 用户截图四项视觉改动 — 已实现与核验

范围仅限本次明确指定的四项；不继续听力/其他保真审计。H5只读，未commit/push/部署。

## 最终效果

1. 阅读readingSession/typeSession计时28→26px，top4→5，数字与Home中心仍为屏幕y78，水平中心x195。副标题、文章与答题布局/规则不变。
2. 阅读超时由底部sheet改为手机内Navigator的居中Dialog，宽330、全圆角24，保留原212px媒体。视频brightness从1.033撤为1。最终纯色背景#FBFBFB；原始视频解码角点为250，但真实Chromium合成后为251，因此以最终图像而非原始解码值对齐。双语最终截图视频内外4点均为RGB251/251/251。计时和已选答案在关闭后继续保留；桌面缩放phone内居中也有测试。
3. Flutter所有装饰背景渐变改纯色：shell不再使用含渐变的app_bg.png，普通底#F7F3EE、作答暖白保留；报告页#FBF7EF、报告进度黄、考试卡选中黄/未选米色、全局菜单深色、四处麦克风问答态深色/黄色。原高亮渐变实现改为纯色条并保留其文字强调含义。唯一保留的RadialGradient为报告雷达图的数据区域shader（用户指定保留图表语义）。无任何BoxDecoration.gradient，移除无使用的渐变token。
4. 首页完整IP插画88×110→120×148，保持BoxFit.contain、文字左侧/插画右侧、CTA下方，未被裁切或遮挡。保留13px金刚区标签及之前指定的通知字号。

## 验证

- 2026-09-23T15:30:55.968350+08:00完整验证：447 tests、31 checks通过，analyze零问题，生产Web release成功。
- 141路由×2语言=282初始状态，0失败；新增逐路由DecoratedBox无背景渐变断言。
- 针对计时26px/Home中心、弹窗居中/底色/媒体滤镜、保留答案和继续超时计时、IP120×148且卡内/CTA无相交的测试通过。
- 真实Chrome390×844：核心首页/两个阅读页×中英6图，最终居中视频弹窗×中英2图。截图人工确认。
- 13个其余主要路由×中英=26图回归浏览完成（只确认背景替换未破坏排版/空白，不宣称新增全站保真验收）：exam/report/prep/writingPlan/writingCompose/oralDiscuss/mockSpeakingQ/tfDailyRetell/tfSpk1Q/listeningSession/listeningFeedback/vocab/pronListen。
- H5全102文件改动前后SHA256完全一致，H5 git status干净。Flutter先前未提交工作完整保留。

## 证据与显示

`artifacts/four_visual_changes/reviewed.json`列34张核心/回归图路径及SHA256。core/回归图来自fourfix1，其代码与fourfix2仅弹窗底色250→251不同；最终弹窗来自fourfix2。`h5_before.json`/`h5_after.json`记录只读验证。

最新本地审计构建：`artifacts/visual_audit/builds/fourfix2`，本地8970端口。首页：
`http://127.0.0.1:8970/index.html?route=ielts&lang=zh&revision=fourfix2-final`

该本地Flutter页面留在Preview，线上H5链接未修改。页面设计四项已完成；此前全站字体/状态保真差异不在本轮处理范围，不能因447 tests通过推定整站完全一致。
