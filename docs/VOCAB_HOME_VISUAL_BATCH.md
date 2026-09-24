# 词汇主页：线上首屏/末端复核（2026-09-23）

范围仅vocab。参考https://surgo-mobile.vercel.app/，390×844中英首屏/底部。原固定统计、Tier词数/百分比/目标、IELTS/TOEFL插值不变。

## 实施

- 新vocab_home_view.dart / vocab_home_widgets.dart，原vocab_home_page.dart保留数据与入口。源24px Home固定在read-scroll上方，去掉原生额外logo；18/8/18/0外距与有界滚动。
- 26px标题、统计354×75(zh)/71(en)、56px完整水獭、64px复习圈、两张354×76词本卡及原bookmark/mic/book SVG。
- 复习卡右侧按钮不再与中栏等分压缩，按源正常390测量宽100.78125/161.921875；保留英文中栏换成三行。英文“words / due today”按原两个DOM文本节点翻译，避免组合串失配。
- 原“发音复习(0)”静态按钮继续无handler，局部还原源英文，未加新复习业务。
- 白卡阴影移外层，避免Material被灰色阴影染色；Tier全部320×5进度轨，46%填充与0%原样，44/40px图标容器和158/144px中文/英文卡片高度。
- 保留原型数字不一致：首页“12词”与单词本4词、发音本0待复习与后续2卡，不擅自“修正”数据。

## 测试

新增vocab_home_visual_test.dart 4项（中英×IELTS/TOEFL），覆盖y112标题、y66 Home、统计/卡/环尺寸、两段翻译、静态按钮点击不跳转、全部9个导航目标、固定导航与滚动、四Tier轨/填充值和高度。原11测试继续通过。没有用Surface尺寸替代MediaQuery。

一次测试误把scroll GestureDetector当按钮handler，改为检查onTap并实际点击确认不跳，没有改业务。

2026-09-23T00:39:14+08:00，完整verify_handover：346 tests、30 checks全过、analyze零、141路由、生产Web release成功、H5四hash保持。

## 截图和已知差异

源中英首屏/末端：artifacts/online/{zh,en}/vocab.png及vocab-bottom.png。
原生首屏：flutter-vhome1/{zh,en}/vocab.png；末端：flutter-vhome2/{zh,en}/vocab-bottom.png。
人工双语对照：artifacts/visual_audit/vhome-vocab.png及vhome-vocab-bottom.png，均已看。
4语言状态对/8图SHA：vocab_home_reviewed.json。

最初末端批次报zh document not ready/en font request failed，错误台账保留。检查server日志及正确FontManifest资源均HTTP200后，以单语言/5000ms新采集成功；未重启服务/替换字体/接受不完整图。一次诊断访问错误的assets/fonts/violet-sans.ttf返回404，与真实assets/assets/fonts/violet-sans.ttf区别已核实。

残余：字体形状/字重、统计插图缩放采样、麦克风字符彩色表现、测试按钮约数px宽差、少量纵向位置差。首屏/末端结构已恢复但未声称像素完全相同。TOEFL插值测试通过但本次线上截图默认IELTS，TOEFL实际截图未单独采集。系统放大字体、真机与所有按压态未全验。

累计词汇34路由完成此轮逐页实施和状态抽查，不等于34路由已全状态视觉通过。冻结282历史审计状态保持，继续以逐批记录补充。无Git提交/推送/远程部署，原H5只读。
