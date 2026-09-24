# 白底Banner与口语Part2准备流程（用户新增要求）

## 首页Banner

用户确认“按第二张还原”，覆盖此前IP全身无遮挡要求。首页banner纯白，高140px；文字左上；IP右14/top14，88×109；底部CTA42px、左右/底18px，前景遮住IP下半身。说明采用10px/重点12px单行，文字过长时局部缩放。未改CTA跳转、其他金刚区字号或阅读26px等已完成要求。

## 雅思口语Part2

- speakingSession且IELTS cue任务直接呈现准备阶段；oralExam cue入口同样兼容。
- 准备倒计时取题库prep60秒，显示01:00→00:00；不显示麦克风、重录、提交或录音波形。
- 底部“进入口语考试”明确进入待录界面；可提前进入，60秒到期仍等待用户点击，不自动录音。
- 笔记实时写入同一个OralController及session oralNote；进入oralExam重建TextEditingController仍读取原笔记；开始录音后保持可见但禁用编辑，重录不清空。
- 进入录音界面后保留点击麦克风开始/停止、2分钟陈述上限、原型固定批改。未新增真实麦克风上传、评分服务。
- Part1/Part3/TOEFL其他入口保持原逻辑。原cue2500ms自动就绪已被用户明确要求替代，因此冻结source oracle只继续验证其他场景；新增5项cue准备/笔记专项测试覆盖两入口×双语及提前进入。
- 默认cue入口的顶栏标为Part2，不再在未指定card时显示Part1。新准备提示提供中英文本；题库原文及原有矛盾问题内容不修改。

## 核验

最终2026-09-23T16:11:28.984832+08:00：451tests、31checks通过，analyze零问题，生产release与独立审计release成功。H5全102文件与四项改动前哈希相同、git status干净；未commit/push/deploy。

`artifacts/flutter-banner-part2-3/{zh,en}/`为最终首页、speakingSession、oralExam的390×844截图。测试包含banner纯白/高140/IP尺寸/CTA明确相交，以及60秒后不出现录音按钮、点击进入保持笔记、真实2秒计时和重录保持笔记。

Preview实际填写“Health habits — walk every morning.\n准备时填写的笔记。”，点击进入考试后截图可见同样文字；点击麦克风后进入录音中且2秒进度，模拟120秒结束后重录返回00:00。此真实交互验证基于banner-part2-2，最终3仅修准备提示双语，控制器/笔记逻辑相同。无障碍隐藏textarea未聚焦时value为空，但CanvasKit显示文字完整；不能拿隐藏DOM空值误判笔记丢失。

最新本地构建`artifacts/visual_audit/builds/banner-part2-3`，端口8973。原H5线上链接未同步。本轮只完成这两项，不代表全站视觉等同或移动端真机验收。
