# 发音课程/讲解/听辨：线上对照修正

## 参考与范围

参考 https://surgo-mobile.vercel.app/ 实际页面；`pronCourse`、`pronLesson`、`pronListen` 三路由。源码四核心hash已确认与只读H5一致。此批只修改显示层，`pron_listen_controller.dart`、PL_PAIRS、阶段解锁规则未改。

## 具体修正

- 固定24px Home导航，`.read-scroll`独立滚动；去掉听辨页多余SURGO logo。
- 课程卡恢复354px内容宽度、白底及外部阴影；纠正阴影画在Material内部造成卡片灰底。锁图标18px靠右，不再让Spacer挤压英文标签换行。
- 讲解页按实际语言自然行高排步骤条；词对三行各11px上下padding、两条分隔线、16px喇叭及原10px列间距。
- 听辨操作恢复原Wrap与胶囊：中文三枚同行，英文第三枚换到第二行；播放状态、选中状态、错误文字颜色依原CSS。
- 原播放中忽略选择、四组词对、答对1200ms进下一题保持。没有新增音轨/评分。

## 证据

- 线上原图：`artifacts/online/{zh,en}/{pronCourse,pronLesson,pronListen}.png`。
- 三页已资源就绪配对截图：`artifacts/flutter-pron5/{zh,en}/{route}.png`。
- 合成对照：`artifacts/visual_audit/pron5-{route}.png`。
- 最后课程阴影/锁布局修正后的英文图：`artifacts/flutter-pron6/en/pronCourse.png`。
- 最后课程中文重截图未完成：90秒后同一10.56MB Noto Sans SC远程字体仍未下载完成。记录为待重验，不用缺字图判通过。此前pron5中文完整图存在，但早于最后阴影/锁细节修正。

## 采集问题与已验证改进

旧采集器逐页禁用缓存，反复下载大字体。现改为每批新隔离Chrome上下文、批内复用字体缓存、绕过ServiceWorker。pron5首张耗时16.28秒，后续5张约2秒，网络台账确认fromDiskCache=true，六张全部fontsSettled且无JS异常。新批次首次远程下载仍受网络影响；不能据此认定业务失败或放宽资源完整条件。

## 回归结果

2026-09-22T21:23:56+08:00：`python tool/verify_handover.py`30项全部通过；analyze零问题、276测试通过、生产Web release成功。原始日志 `docs/verification/`。

4项新增中英Widget测试覆盖24px导航固定不随内文滚动、三对词/两分隔线、使用实际VioletSans验证换行、选中错误态颜色。原25项课程/听辨规则与交互测试保持通过。测试需加载实际字体；Ahem测试字体不能用于判定英语换行。全量282初始双语渲染亦通过。

## 未完成

三页仍有平台字体字重/细微行高差异；全部同状态交互截图尚未完成，不能标记整页像素完全一致。截图与专项通过不是整个141路由保真验收通过。
