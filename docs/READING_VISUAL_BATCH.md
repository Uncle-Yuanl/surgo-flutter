# IELTS readingSession/typeSession 首轮修正与抽查（非完整验收）

## 最新结论（2026-09-23 13:01 回归）

两个路由已完成本轮实现、回归及40个语言状态对/80张真实截图人工对照。11种单题型、整篇阅读、选择、题号导航、问答独立滚动、拖动、短答输入及超时视频已抽查。合计首轮记录从55增至57路由，**不是57页完整保真通过**。

全套433 tests、30 checks通过，analyze零问题、生产Web release成功，原H5四个核心文件哈希不变。`docs/verification/summary.json`时间为2026-09-23T13:01:12.927759+08:00。后续独立审计release也已构建成功；iOS/Android尚未设备验收。

证据索引：`artifacts/visual_audit/reading_reviewed_final.json`。捕获台账仍保持captured-not-reviewed，人工审阅结论与每张SHA256在独立索引中，不篡改原捕获记录。

## 用户指定调整：时间与Home同行，再缩小数字

- Home保持(20,66,24,24)。倒计时最终28px、全屏y64，中心x195/y78，与Home同一水平线。
- 说明文字保留在下方，不改变其字号。文章区随顶栏压缩向上43px，初始答题区位置/高度不变；拖动时避让新的顶栏。
- 这是用户授权偏离旧H5，不能在视觉对照时回退。readinghome1是30px中间版本，readinghome2及readingfinal系列是28px。
- 没有改题库、计时长度、作答/跳转规则。3秒递减3秒和Home目标都有测试。

## 实现与原行为

- 文章13px/1.8，段落标记11px黄色粗体和5px间隔；文章标题20px，页面题型标题17px。说明行高由实际翻译文本是否含中文决定。
- 初始整篇答题区为58%；单题按自然内容测量，上限46%。拖动范围保留源20%最小/host-60最大及整数取整；超大面板保留源向手机底外延伸并裁切的行为。
- 选择题15px题目/14.5px选项，54px选项和32px字母框。匹配控件至少64×56。
- summary标题11px、正文12px/1.75、嵌套10px粗体；diagram140px原灰图盒；inline90×20与box200×37，输入容器显式定尺寸，避免TextField默认边框撑高。
- BACK/NEXT按CSS flex加内距计算宽136.15/197.85，不能仅按比例分总宽。
- 题号导航：整篇切index；单题只滚动rq-item，不改变typeIdx。原站实点第3题后仍是idx0，保留此源行为。
- 源refresh不applyLang：刷新后按钮/进度为英文，提示继续中文。原选择在go()/rerender后丢失，answered集合仍在。inline不记完成，box在blur/submit时记完成。
- 生产原时长不变。auditSeconds只供审计入口缩短等待，正常main.dart为null。

## 超时视频与返回作答

`StyledLoopVideo`条件导出：原生仍是LoopVideo加颜色滤镜；Web只把媒体元素用HtmlElementView呈现，以CSS设置brightness(1.033)/radius14。页面与弹窗依然是Dart Widgets，不是HTML页面包装/WebView。直接依赖web1.1.1，版本未升级。

- 视频与原站字节一致：1468207 bytes，SHA256 `976dfc22f2325bf647c0f694be7c536c876eefbe1c600ead619028292067a772`。
- readingmedia4中英均等待视频完整缓冲并可seek，审计暂停至1.000s；暂停前均在播放、muted=true/loop=true，滤镜实际生效。
- 最终视频rect=(89,452.5,212,212)，与线上一致；返回按钮文字linebox21px、总高55px，修复此前1px整体偏移。
- 对应原图视频内部211px高裁剪区域，RGB平均绝对差约0.0108/0.0106/0.0107（0–255），无图像修饰；这不代表整个弹窗像素完全相同。
- 原SimpleHTTP不支持Range，首次seek失败。新增仅本地`tool/audit_range_server.py`提供206，未改生产播放规则或用户其他服务。
- 四项新增测试覆盖两路由×两语言：过期后返回同路由/revision不变，选中颜色与answered集合保留，超时钟继续4秒，不重新弹窗。真实Preview也实点关闭并确认video节点移除。

## 本轮实际图片覆盖

19张四列双语对照图位于`artifacts/visual_audit/readingfinal1_grids/`：

- 11单题型：mc/tfng/yyng/imatch/hmatch/fmatch/ematch/scomplete/summary/diagram/short。
- 整篇：初始、pick、nav、qbottom、abottom、drag。
- 单题：nav、short-input（真实输入sample并blur，两边Answered1/2）。

另外2张超时双列图：`artifacts/visual_audit/readingmedia1_grids/{zh,en}-final.png`，最终原生来自readingmedia4。

readingfinal1是28px顶栏版；readingfinal2只额外修超时按钮1px，普通阅读代码未变。文章底部中文、拖动和两种单题交互来自readingfinal2，其余普通态来自readingfinal1。每对实际文件均在索引列明。

失败证据保留但不用于验收：readingmedia1/2中文seek失败；readingfinal1中文abottom外部symbols字体网络关闭，已单独重拍。审计构建曾因localhost代理截断VM服务失败，用本进程NO_PROXY绕过后成功，未改系统代理。

## 剩余差异与未验证

- VioletSans字重、字形/抗锯齿及部分行框不同；选项文字/输入字形、导航弹窗个别位置仍有数px差。不能靠全局伪粗体掩盖。
- 计时截图取样时刻不同，不能将秒数差当作计时规则差异。
- drag图是指定的一次向上拖动，不是绝对最大；最大边界由Widget测试覆盖。新顶栏下可露更多文章是用户要求产生的布局变化。
- 并非全部题号、每项选择、错误/禁用、跨路由计时、所有滚动位置都已穷尽。
- iOS/Android真实媒体、前后台、键盘、安全区、系统返回、无障碍仍待验。

原H5始终只读；未commit/push或外部部署。
