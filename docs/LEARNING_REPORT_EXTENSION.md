# 学情分析功能扩展（保留现有Flutter报告页风格）

## 参考与范围

用户附件 `SURGO_学情分析页_UI确认.html` 是17张嵌入截图的交互确认图集，不含可接入的评分业务代码。提取后的只读参考位于 `artifacts/report_reference/`，manifest记录A01/B01–B04/C01–C05/D01–D06说明。实现保留原报告页奶油纯色底、圆角白卡、黄紫雷达图、插画、底栏和默认IELTS四科6.5/5.5/7.0/6.0；不用HTML/WebView包裹。

2026-09-23 概览三段布局最终为**横向一行三列**（用户先要求“竖向”，随后明确纠正“错了错了 横着排布，三个排布在一行”，以后者为准，也与参考稿 B01 首屏三段横排一致）：`learning-metric-row` 内三张等宽卡 `learning-metric-level/gap/practice`，间距8、固定行高126、值用 FittedBox.scaleDown 防裁切、标题2行、说明2行；“估分说明 / 设置目标”两个链接移到行下方 Wrap。中文文案保持原表述，英文压缩为 Current level / Goal distance / Recent practice 以适配390宽。测试断言三卡同顶、等高、等宽、左→右不重叠且右边界不超390，概览内无Divider。证据 `artifacts/learning_row/reviewed.json`（learning8，12张：五状态+TOEFL×中英，全部逐张看过）。历史记录：更早的“竖排独立卡”版本（learning4）已被此次纠正取代。

## 新增功能

- 学情概览：当前综合水平、目标差距/考试倒计时、近30天练习量与前30天对比。目标分/日期可编辑，保存于当前AppState演示会话；不接真实账号。
- 估分说明：手机内滚动弹窗，总分/逐科构成和四个说明问题；右上关闭与底部知道了；正式考试成绩免责声明以浅黄色强调。
- 四科现状：各科分数/待积累状态、逐行展开累计有效练习次数/题型覆盖进度。点击雷达顶点或标签只切选中，点击科目行才展开。列表、雷达高亮、建议科目联动。
- 规则与来源：每个必需题型累计5次有效评分练习，或该科近90天有有效模考；出分资格按累计，当前分数参考近30天。四科齐全才显示总分，缺分不算0、不画得分雷达顶点；趋势缺周断开而不连成连续测量。
- 建议：按四科切换前三项优先建议、观察次数、趋势、能力进度、练习入口；老师点评摘要/全文切换；其他四条建议可展开。练习入口进入既有对应科目日常训练选择页，未虚造不存在的细粒度训练路由。
- 近8周：水平折线+每周练习量、目标线、周选择详情；未出分时仍保留练习量。沿用黄/米色，与原报告风格一致。
- 演示状态菜单：完整出分/已有练习未出分/部分科目出分/达标/未设目标。保留分析而非空页。TOEFL报告用6分量表，与IELTS9分区分。

## 数据界限

页面明确标注演示数据。附件没有真实学生记录/评分服务，本次不宣称计算真实考试分数。默认原报告6.25显示6.3的一位小数约定保持；资格/样本时间窗用说明与演示状态表达，不冒充已接入真实测评数据库。示例练习量/建议/趋势由本地模型提供，可由团队后续接入真实数据。官方成绩以考试机构报告为准。

## 实现

`learning_data.dart`是报告本地演示模型；`learning_overview.dart`概览/目标；`learning_details.dart`评分依据/说明；`learning_advice.dart`建议/点评；`learning_trends.dart`趋势；由`report_page.dart`管理选中/展开与目标状态。审计入口支持`reportState=full|early|partial|strong|no_target`与`exam=toefl`，生产入口不依赖URL参数。

## 验证记录

最终learning3于2026-09-23T17:10:38.276064+08:00完成481tests/31checks全通过、analyze零问题、生产/审计release成功。282双语初始路由无异常。额外报告集成测试覆盖5状态×2考试×2语言、三指标竖排、两种关闭、目标编辑、列表/雷达/建议联动和练习跳转。learning2曾因修正文案后旧测试仍查错字失败，已修测试；未把失败构建计为通过。

真实截图：learning3五状态的top/scroll950×中英20张，加TOEFL中部2张；learning3-final建议/趋势×中英4张，共26张最终图已人工检查。初轮learning1另有12张全页滚动采样（其中scroll500未单独细审），不混计最终状态验收。Preview中实点估分说明打开/关闭、写作评分依据展开并联动建议成功。截图索引：`artifacts/learning_final/reviewed.json`。H5全102文件SHA256与改动前一致，git status干净。

H5与附件只读，不commit/push/部署。原有阅读26px、居中超时弹窗、纯色背景、白底紧凑banner和Part2准备笔记流程不回退。本功能扩展不等于全站所有状态视觉验收或移动真机验收。

## 2026-09-23 概览四项修改与全局字体

用户在横排落地后提出四项：去掉「离目标还有多远」的「多远」、去掉演示数据下拉入口、小字放大一档、本页字体与其它页统一。实现：

- 标题改为「离目标还有」（英文 Goal distance 不变），测试文案同步。
- 移除 `learning-scenario` 演示数据 PopupMenu 入口；五种演示状态仍由 `?reportState=` / `session['reportScenario']` 驱动，截图与测试覆盖不减，只是页面上不再有这个开关。
- 三张卡文字整体放大一档：标题 11→12.5、badge 9→10.5、数值 16→18、说明 10→11.5、两个链接 12→13；行高 126→142 容纳。`learning_details / learning_advice / learning_trends` 内 10~12px 一并按 `tool/bump_learning_small_text.py` 升一档，Ahem 下 `learning_advice` 观察次数行改 Flexible 防溢出。
- 字体不再是本页特例，随下述全局改动统一。

## 全局字体：标题 Outfit + 正文苹方

用户 2026-09-23 先要求「标题/副标题 Outfit，题目/正文 SF Pro」，2026-09-24 看到中文出现杂散黑点后改为「题目以及正文都换成 pingfang」。当前实现以后者为准。

- `SurgoFontFamily`：`heading='Outfit'`、`body='PingFang SC'`、`primary=body`、`fallback=['PingFang SC','Heiti SC','Helvetica Neue','Arial']`，`violetSans` 保留给仍沿用源站字形的位置。
- 正文族通过 `shell.dart` 的 `Material.textStyle` 与 `app_theme` 的 textTheme 继承下发。
- 标题/副标题由 `tool/apply_global_fonts.py` 按字重判定：w700/w800/w900/bold 的 `TextStyle` 补 `fontFamily:'Outfit'`，共 85 文件 431 处；已显式指定 VioletSans/Arimo/Inter 的保真位置不动。脚本用 `(?<![A-Za-z0-9_])TextStyle\(` 排除 `DefaultTextStyle`。
- `tool/add_heading_fallback.py` 给全部 90 个含 Outfit 样式的文件补 `fontFamilyFallback: SurgoFontFamily.fallback`。
- 测试新增 `test/support/fonts.dart`，`loadSurgoTestFonts()` 预载 VioletSans 与 Outfit；苹方是系统字体、没有可加载文件，widget 测试量到的是默认测试字体（`tool/preload_test_fonts.py` 改了 19 个测试）。

### 中文黑点的成因与修复

第一版按要求打包了 Apple SF Pro（`assets/fonts/SFPro-*.otf`）。SF Pro 与 Outfit 都不含 CJK 字形，而当时只有 shell 一处声明回退链、标题等显式样式没有；缺字未被静默回退到苹方，渲染出的中文就带上了零散墨点。两步修复均已验证：正文族直接改系统苹方，不再经由无中文的拉丁字体；每一处 Outfit 样式显式带中文回退链。放大 `artifacts/flutter-fonts2/zh/report.png` 与 `readingSession.png` 的中文标题确认墨点消失。

### 字体许可（交接必读）

- Outfit 为 OFL，可随工程分发。
- 苹方（PingFang SC）属 Apple，同 SF Pro 一样不可再分发。这里只按族名引用、由 iOS/macOS 系统解析，与源站 CSS 写法一致，工程内不存放该字体文件；原先复制进来的 `SFPro-*.otf` 已删除。
- Android 无苹方，会落到回退链（思源/Roboto）。若需两端完全一致，需自备有授权的中文字体。

### 保真影响（如实记录）

换字体必然改变字形度量，以下源站几何基线按新字体实测更新，并在测试里写明原因，不是「对齐源站」而是「用户授权的偏离」：

- `profile-stats` top 293→298（上方姓名/副标题走 Outfit）。
- writing legacy 星标行 top 255→265；正文族断言 VioletSans→`PingFang SC`。
- writing review 长文高度容差 23→34px。
- vocab tier「查看全部」不再钉死在某一侧，改为断言不与预览词块重叠；`tier-stats` 宽度由 `closeTo(194)` 改为「不超过 314px 轨道」。
- book list 统计卡英文态高度 76→80。

另需注意：苹方没有可加载的字体文件，widget 测试量到的是默认测试字体而非真实字形，因此正文相关的精确像素断言已按上述方式放宽，真实度量以 390px 实截图为准。

结论：全站像素级还原目标与用户指定字体互斥，当前以用户指定为准；`docs/visual_audit_report.md` 的差异基线需按此理解。
