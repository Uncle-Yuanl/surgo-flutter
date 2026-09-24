# 单词本与发音本列表2页：逐页复核（2026-09-23）

参考 https://surgo-mobile.vercel.app/，范围 vocabBook / vocabPron，390×844。完成双语首屏及底部对照的一轮修正，未标完全保真。

## 实施

- 新 `book_list_view.dart` / `book_list_widgets.dart`：共享源wb-*布局，数据仍由两个原模块适配，未造新词/分数。
- 固定Home/返回导航与独立read-scroll，18/8/18/0外距；普通单词本保留4卡，发音本保留2卡。
- 恢复2×2统计、171×76块、44×44图标底座/22px源SVG、24px数值。
- 26px标题、开始复习胶囊、原搜索/过滤/排序/视图白底边框；原控件是静态span，未新增搜索或过滤行为。
- 单列354px词卡、16px圆角、黄/绿边框、17px词、15pxspeaker、原标签/释义/分隔线/Tier或固定分数。Adapt绿色掌握卡不再被旧选择状态错误染黄。
- speaker没有独立处理，点击仍随整卡进入详情，未新增语音。
- 原英文发音本CTA不收缩，约208px宽，超过read-scroll右边；使用局部OverflowBox和ClipRect保留原单行裁切，没有自作两行改版。完整文字仍在Widget中。
- 删除原列表专用的旧私有组件与不再用的SVG常量；六个词详情实现和数据尚未在本批重做。
- 禁止列表卡的Material悬停灰色，避免真实wheel采集后指针下的卡出现原型没有的灰底。

## 测试与证据

新增 `test/book_list_visual_test.dart`4项：2路由×2语言。核对统计几何、固定导航、静态工具栏、354px卡/15pxspeaker、全部卡目标与session、绿色状态、复习和返回路径，英文溢出CTA原尺寸。

原22项词本/发音本测试继续通过。全路由Ahem测试暴露英文工具栏44px溢出；按实际文字宽度选择Wrap回退，未缩小字体或跳过测试。

2026-09-23T00:09:06+08:00，verify_handover：330 tests、30 checks全过；analyze零问题、141路由、生产Web release、H5四hash保持。无commit/push/远程部署。

源：`artifacts/online/{zh,en}/{vocabBook,vocabPron}.png`与`-bottom.png`。
最终原生：`artifacts/flutter-vbook5/{zh,en}/{route}.png`与`-bottom.png`。
人工4张并排：`artifacts/visual_audit/vbook5-{route}[ -bottom].png`（无空格），均已检查。
16个源/原生图SHA和8个语言状态：`artifacts/visual_audit/vocab_book_reviewed.json`。

## 仍有差异

- 部分英文字重、中文/IPA字形、放大镜与星号形状、边框抗锯齿、数px位置/卡高累计差。
- 英文工具栏搜索小字行高与原站仍略有区别；没有声称逐像素相同。
- 发音本两张卡短于视口，bottom截图与首屏相同，不能算额外页面覆盖。
- 原站英文CTA裁切是原已有缺陷，按还原要求保留；系统大字号与真机全部状态未验。
- 详情6页虽已采集线上参考，尚未在本批完成还原，不能算已完成。
