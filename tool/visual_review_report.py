"""Publish human-written screenshot observations without declaring fidelity success."""
from pathlib import Path
import json
from collections import Counter
ROOT=Path(__file__).resolve().parents[1]
audit=ROOT/'artifacts/visual_audit'
rows=json.loads((audit/'routes.json').read_text())
reviews={}
for f in sorted(audit.glob('manual_reviews*.json')):
 for route,review in json.loads(f.read_text())['reviews'].items():
  assert route not in reviews,route
  reviews[route]=review
assert set(reviews)=={r['route'] for r in rows},'Missing or unknown review routes'
results=[]
for row in rows:
 r=dict(row);v=reviews[r['route']]
 r['status']=v.get('statusByLocale',{}).get(r['locale'],v.get('status','有差异'))
 r['conclusion']=v['notes']+' '+v.get('localeNotes',{}).get(r['locale'],'')
 r['reviewSheet']=f"artifacts/visual_audit/review_sheets/{v['sheet']}.png"
 r['scope']='冻结基线的初始视口；非修后验收'
 for key in ['h5','flutter','reviewSheet']:
  assert (ROOT/r[key]).is_file(),r[key]
 results.append(r)
counts=Counter(r['status'] for r in results)
(audit/'reviewed_baseline.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
lines=['# 逐页视觉验收清单','',
 '基线：390×844逻辑视口、DPR1。564张截图已采集，141路由×中英文均已逐页检查初始视口。',
 '本表记录的是冻结基线发现，不代表当前修正版仍有全部相同问题，也不表示任一页面已完成全状态验收。',
 '像素误差不等于保真率；加载时刻、默认入口不同的3项保留待验，后续修复必须另附重截图。',
 f"基线结论：有差异 {counts['有差异']}，待验 {counts['待验']}，通过 {counts['通过']}。",'',
 '|路由|模块|语言|H5截图|Flutter截图|人工差异结论|状态|','|---|---|---|---|---|---|---|']
for r in results:
 lines.append('|'+ '|'.join([r['route'],r['module'],r['locale'],r['h5'],r['flutter'],r['conclusion'].replace('|','/'),r['status']])+'|')
(ROOT/'docs/visual_audit_checklist.md').write_text('\n'.join(lines)+'\n')
report=['# SURGO 页面视觉复核报告（进行中）','',
 '## 结论',
 f"141个源路由的中英282个初始视口已审阅。冻结基线中 {counts['有差异']} 项可见设计差异、{counts['待验']} 项入口/时态不一致需重验，0项可据此认定全页面保真通过。", 
 '这不是最终验收通过报告。差异覆盖布局、按钮、字体、翻译、图表、卡片样式，不仅是平台字体抗锯齿。',
 '', '## 证据与方法',
 '- H5只读，Chrome CDP真实渲染；去掉桌面外手机装饰框，保持内部390×844。Flutter使用独立审计target真实CanvasKit渲染，不用结构测试代替截图。',
 '- Flutter截图等待字体网络完成；282项fontsSettled=true、捕获无JS异常。H5路由实际值与请求相符。',
 '- `artifacts/visual_audit/baseline_image_manifest.json`保存564张PNG的SHA256。',
 '- `artifacts/visual_audit/manual_reviews*.json`为逐页人工观察；`reviewed_baseline.json`为语言级记录；`review_sheets/`为双语并排证据；`artifacts/diff/`为像素辅助图。',
 '- 原型初始视口有内容在屏下，长文与反馈滚动后区域、选中/禁用/提交/错误/弹窗状态尚未逐一验完。初始图有差异不等于题库不同；计时差异不能直接判为规则错误。',
 '', '## 已落实且有回归的修正',
 '- 公共默认行高/字距及嵌套卡片继承；AnimatedSwitcher紧约束避免短页垂直居中；TopBar额外Home字样、尺寸修正。',
 '- 考试入口双层边距、底部logo、非选中灰度；若干向导字号、卡图标、选中勾；已有r1/r2/r3双语重截图。',
 '- 报告重复背景、图片偏移、分数下划线已修改，r4双语重截图完成；仍需人工最终复核。',
 '- 用户新要求：首页完整插图、字号、全部消息页已通过专项与真实点击；金刚区最新13px，不能按旧H5回退。见 `HOME_NOTIFICATIONS_20260922.md`。',
 '', '## 已通过页面',
 '暂无页面可标记为完整视觉验收通过。已通过专项测试/局部改动，不等于整页所有状态通过。',
 '', '## 待同状态重验']
for r in results:
 if r['status']=='待验':report.append(f"- {r['route']} / {r['locale']}：{r['conclusion']} 证据：`{r['h5']}`、`{r['flutter']}`。")
report+=['','## 仍有差异的基线页面（逐路由×语言）','|路由|语言|差异|证据|','|---|---|---|---|']
for r in results:
 if r['status']=='有差异':report.append(f"|{r['route']}|{r['locale']}|{r['conclusion'].replace('|','/')}|`{r['h5']}` / `{r['flutter']}`|")
report+=['','## 最终回归状态',
 '最终修复未完成，因此不能把此前268测试/30校验全通过当作本轮最终验收。最近完整日志见docs/verification；后续代码每批测试并在收尾时重新完整analyze/test/release/hash。',
 'iOS/Android真机、TTS/输入法/键盘/后台计时等仍未全验。未做远程部署或Git推送。']
(ROOT/'docs/visual_audit_report.md').write_text('\n'.join(report)+'\n')
print('Human reviewed:',len(results),dict(counts))
