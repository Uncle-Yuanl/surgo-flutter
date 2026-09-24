# 发音练习8页：线上逐页修正记录

参考：https://surgo-mobile.vercel.app/ 。2026-09-22核对4核心文件哈希与只读H5一致，相关水獭、Home、状态栏素材亦一致。

## 已落地范围

`pronRepeat`、`pronSentence`、`pronDone`、`pronCongrats`、`pron2Lesson`、`pron2Repeat`、`pron2Done`、`pronCongrats2`。

- 原固定24px Home导航、内层独立滚动；去掉这些页面原本没有的SURGO logo。
- 复原来源CSS的标签/步骤条、圆角白卡、40px圆形播放与麦克风、胶囊按钮、横排页尾按钮。
- 完成页恢复180px完整插图（显式contain避免Flutter默认不放大）、分段翻译标题、无额外外框的三列统计和分隔线、同行返回按钮。
- 英语Self-assessment列宽按最长词计算，修正转义错误，避免额外拆成3行。
- 页尾相邻CSS margin折叠14px与Flutter相加22px的差异已纠正。
- 原模拟录音/计秒/停止/诚实自评和跨页session键保持，未增加真实录音/评分。

## 图像证据

8页×中英的线上截图：`artifacts/online/{zh,en}/{route}.png`。

Flutter修正版：`artifacts/flutter-pron2/{zh,en}/{route}.png`，最终英语列宽与footer代表重截图为 `artifacts/flutter-pron3/{zh,en}/{pronCongrats,pronSentence}.png`。

捕获台账：`artifacts/visual_audit/online-{route}-capture.json` 与对应Flutter台账。

线上截图必须先等原render的20ms定时器形成active页面，再等待当前页图片decode和字体。此前仅等待两帧会间歇漏图，已纠正，不能拿漏图判设计差异。

## 实际验收结果

- 所列8页均已有双语同390×844初始真实截图。代表页面的布局、图标和按钮已从原来明显不同收敛到接近；不宣称像素级或全交互状态完成。
- 仍有字体渲染字重、文字行宽、细小行高/按钮高度差异。播放器激活、自评结果、全部滚动后内容尚无完整双方同状态截图；这些仍待验。
- `pronCourse`、`pronLesson`、`pronListen`未包含在该8页修改中，需要下一小批处理。

## 回归

2026-09-22T19:33:27+08:00，`python tool/verify_handover.py`：30项全部通过；flutter analyze零问题；272测试通过；生产Web release完成。H5四源SHA256不变。

4项新增中英交互测试覆盖固定导航/40px控件、录音计秒/停止/自评、完成页分段翻译/插图宽度/同行返回；既有规则测试继续通过。原日志：`docs/verification/`。

这是一批已验证修改记录，不是整个141路由的视觉验收通过声明。用户另行确认的完整首页插图、金刚区13px和全部消息功能保持不变。
