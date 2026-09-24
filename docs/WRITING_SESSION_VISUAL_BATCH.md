# 写作题目确认页：四题型修正（2026-09-23）

范围writingSession，四fixture=t2/t1/letter/email，双语。新增writing_session_view.dart/writing_source_chart.dart；只替换确认页，规划/作答/计时controller未改变。

恢复固定Home、19px横向步骤条、源元数据SVG/色标签、22px提示卡、50/47px确认按钮。HTML普通空白折叠保留为显示变换，不修改题库原始换行。原代码只计算但未插入DOM的points/hints未擅自展示。

图表由原300×190/0..100/8柱坐标直接转CustomPainter，保留原数据和颜色；新增原型已存在但旧native缺失的放大/关闭。JS toFixed值实际执行校验：第二柱x62.3/末柱261.8，测试预期据此修正。

新增9测试：8个题型语言组合+chart几何，含原prompt保留、Home固定、确认清空规划选择进入analysis、图表打开关闭。全量最后verify_handover已过30checks/355tests/analyze/release/H5 hashes，时间见verification/summary.json。

实际图：source online/{zh,en}/writingSession-{t2,t1,letter,email}.png；native flutter-wsession2同名8图；4个双语并排wsession2-*都已看。图表zoom源online-t1-zoom，原生最新flutter-wsession4/{zh,en}/writingSession-t1-zoom.png。v2弹窗有默认淡紫surfaceTint和缺字符；v3改白底和原45%棕遮罩，实际看英文图仍缺关闭glyph；v4改11px原生叉号Icon，不再依赖缺失字形，重截图已完成并已看过中英v4图：白底及叉号可见，仍有标题/图表字重和约数px高度差，不标完全通过。

审计目标main_visual_audit新增card/exam参数；capture新增--fixture=t2/t1/letter/email，源仅变浏览器session，截图/台账另存；--chart-zoom通过实际点击进入，非伪造dialog。默认采集不变。

残余：源SF Pro与native sans-serif字形/字重/折行不同，按钮字体、约数px位置差；小图表文本字形；zoom最终v4已复核但仍有字重/高度差。mock模式/放大字体/所有动态状态未全面截图。规划writingPlan和作答writingCompose只采了参考尚未修正，下一继续这两页。没有提交/push/远程部署，H5只读。
