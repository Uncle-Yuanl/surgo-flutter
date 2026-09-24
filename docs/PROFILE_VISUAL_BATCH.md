# 个人中心 prep：首轮修正与抽查

源为线上V.prep（本地只读app.js1114行起），保持演示Miki Jin/miki.jin@example.com、6.3/9、目标7.0、20天；日期仍按当前本地日期+20天，中英格式不变，不是登录账户资料。

## 已实施

- 头像104px白色4px边框，透明中心而非白色填充，保留原otter_glasses.png（H5/Flutter SHA相同4f559261983d62e5309c578a560deb44494a72ff90e151866d3092bbce93f9db）。
- 头像外阴影：原BoxDecoration阴影画入透明图内部，移到独立图层模糊绘制，再以BlendMode.clear清掉圆形内部，避免把背景染灰。不是简单移除阴影。
- CSS相邻垂直margin折叠：成绩卡前2px被上段18px吸收，Settings前4px被成绩卡下24px吸收。初始头像y120、成绩卡y293恢复。
- prep5修正成绩卡中文行盒：数字单位继承line-height1，标签18px、次行14px（英文13/10不变），中文卡高124px、英文115px由组件几何验证，消除先前约8px矮卡。
- 源返回箭头12px；去掉源没有的列表hover灰底/Material按钮最小高度，logout保留相同目标exam。
- prep专用隐藏scrollbar和源has-nav底部120px；不改其他页。
- 四设置仍只弹原型alert，无新设置页/登录/持久化。英文模式原JS alert也直接写中文，因此这里保留中文内容；原生AlertDialog限制在手机内部导航。

## 验证

原4项测试及5项新增专项通过：两语言头像位置/透明中心/边框/成绩卡坐标/底部scroll设置；四个alert开关不改revision且不越出手机；像素测试确认独立shadow内部保持原背景。完整419tests/30checks/analyze/release全通过，时间2026-09-23T05:07:15.800647+08:00。原H5hash不变。

真实390×844：online-prep1 zh/en顶部/底部，与flutter-prep5同名4对8图。prep5中文初始/底部已复阅；英文两图与已阅prep4逐字节相同。profile_reviewed_prep5.json记最新SHA，profile_reviewed.json保留旧prep4记录。头像透明区域三采样点(190,139)/(195,155)/(200,160)在线与最终Flutter分别完全同RGB(251,236,194)/(250,237,197)/(250,237,198)。该局部像素检查不等整个头像或页面像素一致。

## 试验记录与仍有差异

prep1白底；prep2透明底但阴影透入；prep3先尝试difference-path clip，VM像素测试通过而实际CanvasKit截图与prep2完全相同，不能当修复。prepshadow0临时关闭阴影后三点匹配，证实灰层来自阴影不是缓存；服务main.dart.js与磁盘SHA也相同。最终prep4用saveLayer+clear实际图验证匹配，诊断代码不留在生产。

英文字体字重/数字造型与小图标边缘仍有差别；prep5已补中文统计卡高度，仍有部分中文文字基线和滚动末端数px偏移；头像线条采样也非完全一致。alert内容/关闭行为已测，但浏览器原生alert与Flutter原生对话框不能称视觉一致，本轮未做真实弹窗截图；真机/缩放未验。此页计入第55条首轮修正记录，不计为55条完整视觉验收。