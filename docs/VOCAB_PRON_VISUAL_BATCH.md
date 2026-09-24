# 词汇发音复习7页：线上逐页修正（2026-09-22）

范围 vocabPronStudy/2/3、vocabPronStudyB/B2/B3、vocabPronDone。参考https://surgo-mobile.vercel.app/，390×844，中英14个实际状态。每个词的朗读/模拟录音/自评本身就是源三个路由。完成本轮实现与核对，不标完全保真。

## 实现与原规则

- `vocab_pron_study_view.dart`恢复44px词/30px原speaker SVG、15px IPA、13px例句、44/24/52卡内距、20px圆角无边框、原阴影；去掉多余顶空16px。
- 共用原vs-top布局，通过`VocabDetailTop.exitTarget`参数返回vocabPron，默认详情页返回vocab不变。
- 88px麦克风/停止按钮、36px原SVG，黄/红源颜色阴影；提示和底部文字按源间距。speaker及“无法录音？改用手动评价”仍无点击处理，没擅自补功能。
- 自评两个原20px勾/叉SVG、红/绿边框、16px圆角/间距、52px高按钮；源字号/中英换行。只有空间不足时Wrap换行，正常390保持同行。
- 完成页复用先前校正的`VocabDoneView(pronunciation:true)`，只参数化原发音标题/30和14计数/返回路径。原vocabDone默认2/1/32不变；新旧中英截图逐像素相同。
- Identify保留源例句；Adapt无例句。没有新增题目、计时器、真实录音、上传、AI评分或复习数据库。
- 原两条路线：read→recording→judge；judge任一按钮前进下个词/完成，重录回当前词read；退出→vocabPron；完成返回→vocabPron/复习→vocabPronStudy。
- 原完成“30/14/32”与只演示2词的不一致按原型保留，未擅改数字。

## 测试

新增`test/vocab_pron_visual_test.dart`14项（7×2），实际字体和390×844，检查卡片顶部zh96/en92、44px词/30speaker、无额外交互、例句有无、88/36控件、52px同行自评、全部分支和重录/退出、等待30秒仍停留模拟状态、完成统计/双按钮。

原vocab_pron_study_test、共用的vocab_quiz_visual_test/vocab_detail_visual_test均通过。

全路由Ahem测试发现44px英文Identify非flex Row溢出86px；以Flexible给长词可用宽度而不缩小字号解决。真实字体14张重截图与修正前逐像素相同，没有放宽/删掉全路由测试。

2026-09-22T23:40:36+08:00，完整verify_handover：326 tests、30 checks全通过；analyze零问题、141路由、生产Web release、原H5四hash不变。

## 截图与结论

源14张：`artifacts/online/{zh,en}/{route}.png`；台账`online-vocabPronStudy,vocabPronStudy2,vocabPronStudy3,vocabPronStudyB,vocabPronStudyB2,vocabPronStudyB3,vocabPronDone-capture.json`。

最终原生14张：`artifacts/flutter-vpron2/{zh,en}/{route}.png`；对应同名`flutter-vpron2-…-capture.json`。全部捕获无错误。

人工7张并排：`artifacts/visual_audit/vpron1-{route}.png`，均已检查；vpron2的14图与vpron1像素完全一致，因此保留相同人工结论。28张原图SHA与状态：`vocab_pron_reviewed.json`。

共用回归截图：`artifacts/flutter-vpron1/{zh,en}/vocabDone.png`与`flutter-vquiz3`两图完全一致。

- 6个学习状态：大词、源控件、卡片高度/间距接近线上，原逻辑保持；字重/IPA形状/小幅位移、按钮边框抗锯齿仍可见差异。
- 完成页：完整180px水獭/28px分段标题/3列/提示/横排CTA恢复；书本仍单色、勾字形/字重、中文几px偏差未消除。
- 原站全局按钮覆盖顶部计数在两边都存在，本轮未改源设计。
- 未验真机/所有系统字号/按压缩放动画及完整无障碍；这14态不是整站全部状态。

没有Git提交/推送/远程部署或SDK升级。冻结282项历史视觉表不因本批测试通过被改成通过。
