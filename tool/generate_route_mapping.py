import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'build/route_coverage.json').read_text())
classes={}
for p in (ROOT/'lib').rglob('*.dart'):
    for name in re.findall(r'class\s+(\w+)',p.read_text()):
        classes.setdefault(name,[]).append(str(p.relative_to(ROOT)))
rows=[]
# 用户 2026-09-25：新增 13 个登录注册页（Figma gW9DKhEd6UuQQAnv32BlXH · Page 5）。
# 这份映射表的用途是「H5 原型 → Flutter」对照，原型里没有这批页面，
# 所以单独成表，不混进 141 条原型路由里。
AUTH_PREFIX='auth'
auth_rows=[]
for route in data['routes']:
    files=sorted({p for c in route['mountedTypes'] for p in classes.get(c,[]) if p.startswith(('lib/features','lib/pages'))})
    assert files,(route['key'],'No real mounted feature found')
    entry={'route':route['key'],'files':files}
    (auth_rows if route['key'].startswith(AUTH_PREFIX) else rows).append(entry)
assert len(rows)==141,f'原型路由应为 141 条，实际 {len(rows)}'
assert len(auth_rows)==13,f'登录注册应为 13 条，实际 {len(auth_rows)}'
assert data['native']==141+13 and not data['errors']
body='# H5 → Flutter 路由映射\n\n由实际 Widget 挂载审计及类定义生成，共141条。不是仅凭枚举计数；这里只证明页面已接入，规则/视觉验收见其他文档。\n\n统一入口 `lib/app/shell.dart`；源注册 `../surgo-mobile-new/app.js` 的 `V.<route>`；共享controller/data请查同一feature目录。\n\n|H5路由|原生Widget文件|\n|---|---|\n'
for r in rows:body+='|`'+r['route']+'`|'+'<br>'.join('`'+p+'`' for p in r['files'])+'|\n'
body+='\n## 新增：登录注册（Figma gW9DKhEd6UuQQAnv32BlXH · Page 5）\n\n原型 H5 里没有这批页面，属于新增设计稿，共13条。\n\n|路由|原生Widget文件|\n|---|---|\n'
for r in auth_rows:body+='|`'+r['route']+'`|'+'<br>'.join('`'+p+'`' for p in r['files'])+'|\n'
(ROOT/'docs/ROUTE_MAPPING.md').write_text(body)
(ROOT/'docs/route_mapping.json').write_text(json.dumps(rows+auth_rows,ensure_ascii=False,indent=2)+'\n')
print(f'Generated {len(rows)} prototype + {len(auth_rows)} auth route mappings')
