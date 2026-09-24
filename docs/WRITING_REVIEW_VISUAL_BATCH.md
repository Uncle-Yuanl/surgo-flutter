# 写作批改页：首轮四分支已对照，字体仍需精修

## 2026-09-23 03:42 后续字体校准（优先于下方历史记录）

已将作文及上标局部接入OFL Inter变量字体，assets/fonts/Inter-opsz-wght.ttf + Inter-OFL.txt；SHA256 29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031。未复制Apple SF字库。光学尺寸14最终保留：15/16改善个别短句但Task2整段少一行，未采用。注释恢复2px两端占位、700/900变量字重，保持L1长span可换行。

新增1项真实字体组件尺寸测试，四作文高度偏差控制在一行约23px内（并非像素验收）。字体校准时完整395tests/30checks通过；后续四写作子页修改后完整405tests/30checks/analyze/release于03:42:40全部通过，H5哈希不变。

wreview8已重新捕获全部40状态；8张作文+底部双语并排图人工复核（16对）。其余24对已捕获但没有重新逐张审阅；wreview4原40对已阅记录继续保留，不能伪称wreview8全量视觉通过。Inter比原Roboto更接近，但字重/个别换行/上标行盒及彩色字符仍差异。历史记录中“尚未接入Inter”“当前Roboto”已被本段取代。

## 实施与验证

writingFeedback 原生实现拆为 page/header/content/widgets/annotations，保留固定 writing_review.json；总体6.5、T1 6.0、T2 6.5及原题目/作文/批注不随用户草稿改变。

恢复圆Home、总体分数小分母、同排任务chips、黄色弱项标签及灰证据块、Task tabs、原先漏掉的题目紫卡、分项分数、黄建议卡、灰作文、黄/紫高亮及上标、删除线/更正、原因绿/紫背景及末端Home。题目读取当前exam的writing.daily.task1/task2，TOEFL缺字段保持空。

Task/tab采用源go重建回顶；active mark/l1无handler，Task按钮包括active仍有handler。练习按钮强制IELTS→writingDaily；两Home→ielts。18项新增专项测试检验上述规则、prompt、注释颜色、几何及两语言；完整394tests、30checks、analyze零问题、生产Web release通过，verification/summary.json时间2026-09-23T03:11:31.862328+08:00。四个H5源哈希不变。

第二轮额外修正：nav运行时11px、英文大写、弱项说明色、源折叠margin、按钮阴影、源隐藏滚动条、提示内嵌span实际10px。Task1总评“精准”纠正为源“精确”，否则英语词典不命中。L1大标题在源英文态仍中文，已保留源行为。源标题/末端按钮/提示中的字符已恢复，但当前Flutter呈单色，与源彩色仍不同。

## 真实图像证据

40个同状态对，共80张390×844原始图：online/{zh,en}/writingFeedback-{task}-{tab}*.png 与 flutter-wreview4/{zh,en}/同名；对应20组online-wreview3及20组flutter-wreview4 capture.json。Task1/2 mark各初始、scroll760/1500/2200/2900、bottom；Task1/2 l1各初始、scroll760/1400、bottom。字体等待完成、资产预检、标题/路由检查、runtime异常检查通过。

16张按比例并排审阅图在 artifacts/visual_audit/wreview4_grids/，全部已人工查看。writing_review_reviewed.json记录每张原图SHA256及状态。wreview1/2仅初始；wreview3发现的翻译/标题/scrollbar问题已在wreview4修正，不能混用为最终图。

## 仍有差异，不是全页视觉通过

- 初始卡片位置已接近源，但字体字重、CJK行度、任务/tab宽度和若干小偏移仍不同。
- 作文长文行宽显著不同并造成后续批注垂直错位。线上CDP CSS.getPlatformFontsForNode实测为 macOS .SF NS（SF Pro），Flutter sans-serif加载Roboto；不能仅归因于抗锯齿，也不能靠减padding伪装。长文原12px/22.2px，高亮因源嵌套缩字为10px/18.5px。
- 尚未把SF Pro拷入可交付工程（授权和跨平台需考虑）。只在 artifacts/visual_audit/font_trials/ 下载Inter OFL试验字体，未接入pubspec/生产。高精度量宽的两样本接近SF，但仍需实际换行与截图验证，不能称已解决。
- 彩色字符在Flutter仍单色；注释高亮圆角/内距/上标排版仍有差别。
- 此批是1条路由的四分支首轮修正与抽查，不代表该页完整保真，更不代表全站完成。

## 环境与边界

审计8955，固定绝对输出artifacts/visual_audit/builds/compose4；8954缺资源不可用。测试/构建必须为子进程设置NO_PROXY=localhost,127.0.0.1,::1，防本机VM通信被代理截断；不改系统代理。测试大资产加载应允许runAsync完成再推进fake time。原H5只读，无commit/push/部署。
