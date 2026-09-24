# 能力报告页首轮修正与同状态复核

## 已实施

源为用户指定线上surgo-mobile.vercel.app，app.js report模板218行起、index.html的rp-*及phone.rp-bg。只改Flutter，固定Nafis/四科6.5/5.5/7.0/6.0/同龄6.0/6.0/5.8/5.9/62%不变。6.25先toFixed为6.3再计算7.0-6.3=0.7，保持原计算顺序。

- 原遗漏的phone.rp-bg背景恢复为0/52/130/360/620px颜色停点，不再用通用app_bg，也不叠两层渐变。PhoneFrame新增可选backgroundLayer，仅report使用。
- 完整英文点评：恢复源DOM文本分段，纠正拆碎造成的中文残留；保留源连接处没有空格的`range.Listening`/`papers.Reading`。两处破折号前恰好一个空格；内嵌粗体按源12px、外层14px/1.85。
- report-compare强制源306px宽，避免children shrinkwrap收窄；恢复74%列表宽、嵌套10px金色字及原英文`Listeningthan`/`ReadingAhead of only`连字（源缺空格，未美化）。
- 雷达SVG viewBox300到236缩放，所有stroke也按236/300缩放；标签最小52px、左右fractional translation、源48/44 margin，数据多边形阴影和渐变边界。
- 恢复850ms grow动画，只动画得分区域，网格/同龄不动；Cubic(.34,1.4,.5,1)，透明度在55%关键帧到1。动画中间未录视频/逐帧视觉验收，但时长/0/425/850ms状态有专项测试。
- 阅读目标/订阅按钮的14px间隔、目标图标fit、下方120000嵌套10px；report专用滚动隐藏scrollbar。
- 还原底部总留白：report130+末端18+has-nav120；shell原140，report局部补128。没有改其他路由的底部规则。
- 订阅仅本地按钮class/文字，不持久化、不推送。实际在线点击验证：英文初始Subscribe，点击直接写中文已订阅/订阅；go重渲染恢复初始。Flutter按此保留。

## 验证与图像

5新增专项测试（完整译文/背景停点/306px/无scrollbar/源列表文本，两个语言订阅点击与重新渲染，850ms雷达）；既有5测试仍通过。全工程414tests、30checks、analyze零、release通过，最新2026-09-23T04:38:00.826330+08:00。原H5 app.js/index/questions/i18n四个hash保持。

实际390×844：源online-report5初始/底部、online-report8 scroll550/已订阅；最终flutter-report10初始/scroll550/bottom/subscribed，2语言共8对16图。四张report9-*-*.png并排图全部人工审阅；report10全部8张与report9逐字节相同，继承同一视觉结论。report_reviewed.json记录SHA256及reviewed-differences-remain。

## 仍有差异 / 未验证

字体笔画粗细、数字形状、CJK line box与数px的偏移仍不同；bell是单色字形而非源彩色；图片/图标边缘抗锯齿有差；英文订阅后按钮/卡片重排尚有少量高度差。不能据此标全页像素一致。雷达阴影的SVG滤镜与Canvas blur仅近似，瞬间动画曲线虽组件验证但未逐帧比图。真机、安全区、系统缩放仍未验。

注意VioletSans已核实线上/H5/Flutter三处同SHA；CSS.getPlatformFontsForNode线上VioletSans-Regular，Flutter字体manifest请求200。显式FontLoader试验与默认输出逐字节相同，排除了“字体没有加载”的猜测；未全局强行增粗。此report计入第54条首轮修正/抽查记录，不是54页完整视觉验收。
