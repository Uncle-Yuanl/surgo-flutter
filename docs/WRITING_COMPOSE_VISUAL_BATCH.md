# 写作作答页：26个双语状态对照（2026-09-23）

范围writingCompose，参考https://surgo-mobile.vercel.app/，390×844 DPR1。完成一轮实现、实际输入/滚动截图与回归，不标全状态完全保真。

## 实现

writing_compose_view/widgets：固定40px Home/两个局部黄色高亮tab，底部56px CTA固定；题目卡、规划折叠/四子模块共用已校正的WritingPlanPanel；白色有界编辑器、粉色时钟和右下字数胶囊。题目/草稿/规划选择/提交目标都保留。

输入框明确VioletSans14px、1.7行高、400字重、0字距、0内距，避免Material默认字距导致换行提前；深色1px光标。原题目正文HTML空白折叠仅作用于展示，JSON未变。

### 必须保留的实际原型行为

1. 实际在线essay时钟为00:00:00，cdTimer=null，直接进入等待2.2秒以及topics→essay等待2.5秒分别核实。render先进入if(id!=='tfDailyInterview')，后面的else-if writingCompose startCountdown(20*60)不可达。原生旧版自行运行20min不符合当前原型，已移除。不可将源码中孤立存在的计时意图当成实际规则。没有修H5。
2. 中文初次render字数是“0 词 / 150 词”；真实输入后源weCount直接赋textContent、不applyLang，变为“5 words / 150words”。切换tab重render才恢复中文。原生用局部countChanged保留这个源行为，用户内容从不翻译。
3. 无字数门槛，空白也进入固定marking与writingFeedback；无新评分或后台提交。邮件原题库无plan数据，因此展开论点没有选项，未编造。
4. inline arg选择源go()重render；vocab只就地切换；草稿跨tab保留。Home回ielts与源相同（包括TOEFL选择）。

## 测试与验证

新增writing_compose_visual_test.dart12项：4题型×双语8、空白提交2、1203秒后仍静止无弹窗2。验证模块/固定Nav和CTA、draft词数/英文动态显示与中文重新显示、tab/inline选择生命周期、编辑器字体/内距/光标、退出和反馈目标。

2026-09-23T02:28:22+08:00，verify_handover：376 tests、30 checks全过；analyze零、141路由、生产Web release、H5四hash不变。完整回归后审计8955的字体manifest、题库、翻译表再次HTTP200。

## 截图证据

最终源/原生共52张、26对语言状态：
- Task2 topics/essay/open/analysis/arg/para/vocab七态×2语言。
- para/vocab底部两态×2。
- 真实Input.insertText录入10词英文示例一态×2（源weCount与原生均显示10words）。
- Task1图表题、letter、TOEFL email题目页三态×2。

原生非essay：artifacts/flutter-wcompose4/{zh,en}/writingCompose-{fixture}-{state}.png；essay空白和真实输入：flutter-wcompose5，同名及-input后缀。源同名在artifacts/online。原先wcompose2用于对照问题定位，wcompose3全26条作废，不能使用。

最终SHA与逐状态台账：artifacts/visual_audit/writing_compose_reviewed.json。
人工六张保持比例的对照网格wcompose-final-{0,1,2}-{zh,en}.png均已看，essay空态单图另已看；输入图能看到相同内容/实际字数。并排大图wcompose4-*保留。

## 本轮采集白屏故障（已恢复）

wcompose3实际全部白屏；虽原采集器写captured-not-reviewed，JSON内有runtime异常。未被算为通过。独立读取错误得Unable to load asset: assets/data/source_dom_translations.json。8954目录缺题库/翻译/FontManifest，均404；生产build/web资源完整。

SDK build_system源码会删除previousOutputs/currentOutputs差集；本项目存在相对和绝对两套同输出目录记录，与相同实际文件被清理吻合。未动SDK/服务/用户应用：新绝对路径artifacts/visual_audit/builds/compose4独立审计，8955独立日志server8955.log。资产逐字节比对源后启动；后续同绝对输出路径构建和生产回归后文件仍齐全。8954旧目录保留错误证据，不再用于当前截图。

采集器现在先检查必需asset HTTP及JSON非空；runtime异常/非预期审计title直接判error、非零退出。已用缺资源8954实测预检失败；新8955截图全台账无运行异常。旧26条invalid记录在wcompose3_invalidated.json，原错误/图未删除。没有假称单测通过能证明浏览器实际启动。

## 仍有差异/未验

字体粗细/字形、警告字符彩色、题目正文与Source SF Pro替代差、约数px行高/模块累计偏移仍存在；Task1图表卡因题目折行略上移。输入光标截图时相位可能不同。完整所有滚动点、编辑器IME/键盘/真机/全字号/提交弹窗逐帧尚未验。其它题型全部editor测试过，但真实输入截图只Task2。当前完成一个修正轮，不是整站完全还原。

原H5只读，未Git提交/推送/远程部署。
