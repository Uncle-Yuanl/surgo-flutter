import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'build/route_coverage.json').read_text())
classes={}
for p in (ROOT/'lib').rglob('*.dart'):
    for name in re.findall(r'class\s+(\w+)',p.read_text()):
        classes.setdefault(name,[]).append(str(p.relative_to(ROOT)))
rows=[]
for route in data['routes']:
    files=sorted({p for c in route['mountedTypes'] for p in classes.get(c,[]) if p.startswith(('lib/features','lib/pages'))})
    assert files,(route['key'],'No real mounted feature found')
    rows.append({'route':route['key'],'files':files})
assert len(rows)==141 and data['native']==141 and not data['errors']
body='# H5 → Flutter 路由映射\n\n由实际 Widget 挂载审计及类定义生成，共141条。不是仅凭枚举计数；这里只证明页面已接入，规则/视觉验收见其他文档。\n\n统一入口 `lib/app/shell.dart`；源注册 `../surgo-mobile-new/app.js` 的 `V.<route>`；共享controller/data请查同一feature目录。\n\n|H5路由|原生Widget文件|\n|---|---|\n'
for r in rows:body+='|`'+r['route']+'`|'+'<br>'.join('`'+p+'`' for p in r['files'])+'|\n'
(ROOT/'docs/ROUTE_MAPPING.md').write_text(body)
(ROOT/'docs/route_mapping.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print('Generated141 real mounted route mappings')
