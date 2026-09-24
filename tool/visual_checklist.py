from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
h5=(ROOT.parent/'surgo-mobile-new/app.js').read_text()
a=h5.index('const V = {'); b=h5.index('\n};',a)
source=re.findall(r'^  ([A-Za-z]\w*):',h5[a:b],re.M)
dart=(ROOT/'lib/app/routes.dart').read_text().split('enum SurgoPage {',1)[1].split('}',1)[0]
native=re.findall(r'^\s*(\w+),',dart,re.M)
assert len(source)==len(native)==141 and set(source)==set(native)
mapping={r['route']:r['files'] for r in json.loads((ROOT/'docs/route_mapping.json').read_text())}
rows=[]
for route in source:
 for lang in ['zh','en']:
  module='/'.join(mapping[route][0].split('/')[1:-1])
  rows.append(dict(route=route,locale=lang,module=module,h5=f'artifacts/h5/{lang}/{route}.png',flutter=f'artifacts/flutter/{lang}/{route}.png',diff=f'artifacts/diff/{lang}/{route}.png',status='待验',conclusion='尚未完成同状态截图人工验收'))
out=ROOT/'artifacts/visual_audit';out.mkdir(parents=True,exist_ok=True)
(out/'routes.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
lines=['# 逐页视觉验收清单','', '390×844逻辑视口，DPR=1。原生接入/结构测试不代表视觉通过；截图存在也不代表人工验收通过。', '', '|路由|模块|语言|H5截图|Flutter截图|差异结论|状态|','|---|---|---|---|---|---|---|']
for r in rows:lines.append('|'+ '|'.join([r['route'],r['module'],r['locale'],r['h5'],r['flutter'],r['conclusion'],r['status']])+'|')
(ROOT/'docs/visual_audit_checklist.md').write_text('\n'.join(lines)+'\n')
print('Exact H5 and Dart route sets match: 141; checklist rows:',len(rows))
