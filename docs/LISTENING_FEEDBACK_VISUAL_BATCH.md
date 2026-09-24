# 听力批改 listeningFeedback — 实现与取证进行中

## 实现

- 恢复四部分原文、证据高亮与题号、三种题卡、紫色40根波形音频条、倍速菜单。
- Part2标题修为Transcript — Leisure centre tour；Part3为Transcript — Tutorial on a research project，均按源lfBody取值。
- 题型标签宽度改成390px源截图布局台账测量值，而非一律80px；中文标签30.906/41.203px，英文Matching46.1875/Multiple choice74.5625/其他80px。
- 顶部仍固定2/4、50%、6.5，即使四Part演示题合计11题也不据此重算。源固定原型行为，不按用户答案真评分。
- 日常只显示本次lisPart；mock显示四个Part。源setLfPart在当前项点击时无动作，切换只换下半页/保留滚动，不app.go。
- 标签立即替换为原始英文Part，13px；下半页180ms后替换，24px滑出/滑入。源只shrinkFonts不applyLang，因此英文界面切换后下半页仍出现源中文，保留。
- 同步保留源快速连续点击的多个180ms回调，不取消前一回调；离页dispose才取消所有计时器。标签状态与body显示状态分离。
- 音频播放按钮在源laAudioBar没有onclick，仍无实际播放；倍速只更新当前标签和lisSpeed，切换Part重建后显示1X，不清全局lisSpeed。
- 分享阅读批改的样式组件时新增ReviewTextScope路由/raw参数及summary文案参数，默认保持阅读页行为。5项新测试+原阅读测试通过。

## 回归

2026-09-23T14:49:25.893168+08:00：445 tests、31 checks全部通过，analyze零问题，生产Web release成功、原H5核心哈希不变。独立审计listenreview4 release成功。

新增5测试覆盖中英四个日常Part题数/固定分数、局部180ms切换/不增revision/滚动保持/跳过翻译、点击原样Part、倍速标签重建复位及播放不动作。真实截图仍独立于Widget通过。

## 取证与已审边界

本轮继续使用哈希一致的本地只读H58931，并非本轮线上加载成功。

- listenreview1：d1/d2/d3/d4/m1五fixture，初始/scroll850/bottom×双语共30对已捕获。人工已看d1初始/d1scroll850/d2scroll850/d3bottom/d4scroll850五张四列图；发现播放三角字体渲染方块、题型标签80px过宽、顶栏英文大小写差，已修。
- listenreview2：switch2/speed各双语。switch2英文中文备用字体未加载完成出现方块，speed英文点击坐标偏差未打开菜单，均不用于通过结论。
- listenreview3：补动作后字体等待及英文菜单点击坐标；菜单去Material默认padding/行高，播放图标改9×10三角CustomPainter。34语言状态对（上述30+动作4）全部捕获无错误。switch2与speed两张四列图已人工看：双语确实切到Part2/菜单打开，无中文缺字；剩余普通30对尚未逐张完成本版人工复审。
- listenreview4：最后把tab立即刷新/body180ms刷新与快速点击回调修正后重拍两个动作。switch2/speed四个双语状态均已与已审listenreview3逐字节相同。证据：`artifacts/visual_audit/listenreview4_action_identity.json`。

## 未验/差异

听力批改本轮暂不新增到首轮完成计数，仍为58路由；不能把34对捕获成功当34对视觉验收。
字体字重/高亮圆角和基线、原文换行、菜单阴影/横向位置及部分累计卡片高度仍有差。菜单原型为按钮内DOM下拉，当前Flutter是phone内PopupMenu，目标视觉接近但键盘/外点关闭/连续Part快速点击的每帧动画未完整同态对照。所有普通最终图需逐张复审，补真实快速切换及端到端交卷复核。移动端设备尚未验收。

未修改H5，未commit/push/部署，未加入真实录音/播放/评分服务。
