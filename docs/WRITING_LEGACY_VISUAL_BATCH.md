# 四个写作固定示例子页：首轮修正与抽查完成，仍有字体差异

路由writingImprove、writingBands、writingL1Error、writingL1Detail。原writing_legacy.json固定文本/顺序/统计不变，NEXT/返回/只读tab路由不变。

## 本次修改

- 原导航实际11px（父子缩字叠加）及悬出4px的下划线。
- writingImprove源wi-wrap左右2px；修CSS相邻14px margin重复累加；嵌套高亮10px、改写文本中粗体额外缩2px，箭头仍为父字号；旧文子span10px。
- 原始批注标题下划线从误铺满改为贴标题。wlegacy2发现该问题，wlegacy3修正，最新两初始截图已确认。
- Band星形改源SVG，去掉最后一颗后的多余5px；保留5/4/3星与7.0/8.0/6.0的源固定组合。
- 返回胶囊内部Material继承源字体；统计卡后margin不重复加；按钮样式同源ra-next；四路由滚动条隐藏、源全页滚动仍保留。
- lib/app/shell.dart仅增加四路由专用scroll wrapper，没有改变其他页。

## 验证

14新增专项测试：四路由的惰性tab点击不改revision，返回胶囊/WRITING MARK/Home目标；四路由两语言Home位置/导航字号/末端路径，原星形排布及无末尾空隙，嵌套粗体实际字号。既有8项页面测试通过。完整409tests/30checks/analyze/release于2026-09-23T03:50:26.553107+08:00通过，四个H5哈希不变。

源图online-wlegacy1（initial）、online-wlegacy2（bottom）、online-wlegacy4（scroll550）；最终native-wlegacy4共4路由×2语言×3采样位置=24组截图对、48图。全部已审：12张与已审wlegacy3像素相同，其余12对通过10张wlegacy4并排图复核。writing_legacy_reviewed.json记录每张原图SHA256和reviewed-differences-remain状态。

24是截图对数量，不是24个不同状态：源L1Error本来不滚动，scroll550实际0；Bands实际夹到zh365/en334，L1Detail夹到zh315/en368；这些与bottom重合。Improve scroll550覆盖中段，另有顶部与底部。

本轮另恢复Improve高亮span两端各3px内距，不把长高亮强行做成不能换行的Widget。

## 尚未完成

四页中英顶部/长页底部与550px采样均已审阅。卡片主要结构、导航/星级/固定文字/行为已恢复，但正文笔画粗细、部分数字轮廓、高亮换行及数px行盒/垂直间距仍不同，不是全页像素级通过。源线上VioletSans、本机H5与Flutter三处字体SHA相同(ab03804669e19cb4f522310d1e0957ab3a0e356a858f239a1d880bfb0ff790c9)，不能误说成拿错字体文件；具体渲染差异原因尚未完全证实。系统文字缩放/真机字体与触控仍未验。

四条计入首轮修正/抽查记录，合计53条；不计为53条完整视觉验收。原H5只读，无Git提交/推送/部署。
