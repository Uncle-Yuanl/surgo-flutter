"""Generate actual screenshot diffs. Metrics are NOT a fidelity/pass percentage."""
from pathlib import Path
from PIL import Image,ImageChops,ImageStat,ImageOps,ImageDraw
import json
ROOT=Path(__file__).resolve().parents[1]
rows=json.loads((ROOT/'artifacts/visual_audit/routes.json').read_text())
records=[]
for row in rows:
 a,b=ROOT/row['h5'],ROOT/row['flutter']
 r=dict(row)
 if not a.exists() or not b.exists():
  r.update(status='待验',conclusion='尚缺同路由/语言截图')
 else:
  x,y=Image.open(a).convert('RGB'),Image.open(b).convert('RGB')
  assert x.size==y.size==(390,844),(row['route'],x.size,y.size)
  diff=ImageChops.difference(x,y)
  mae=sum(ImageStat.Stat(diff).mean)/3
  channels=diff.split(); peak=ImageChops.lighter(ImageChops.lighter(channels[0],channels[1]),channels[2])
  mask=peak.point(lambda v:255 if v>24 else 0)
  changed=ImageStat.Stat(mask).mean[0]/255
  sheet=Image.new('RGB',(1170,878),'white')
  sheet.paste(x,(0,34));sheet.paste(y,(390,34));sheet.paste(Image.blend(y,Image.merge('RGB',(mask,Image.new('L',mask.size),mask)),.5),(780,34))
  d=ImageDraw.Draw(sheet);d.text((8,8),f"H5 | {row['route']} {row['locale']}",fill='black');d.text((398,8),'Flutter',fill='black');d.text((788,8),'Pixel delta > 24 (not a pass rate)',fill='black')
  out=ROOT/row['diff'];out.parent.mkdir(parents=True,exist_ok=True);sheet.save(out)
  r.update(mae=round(mae,3),changedPixelRatio=round(changed,4),status='待验',conclusion=f'已生成差异图，待人工核对状态/设计；MAE={mae:.2f}，阈值24差异像素={changed:.1%}')
 records.append(r)
(ROOT/'artifacts/visual_audit/comparison.json').write_text(json.dumps(records,ensure_ascii=False,indent=2))
lines=['# 逐页视觉验收清单','', '390×844逻辑视口，DPR=1。差异像素比例不是保真率；字体栅格化、动画/计时、初始状态差异会影响数值，必须人工审核。','', '|路由|模块|语言|H5截图|Flutter截图|差异结论|状态|','|---|---|---|---|---|---|---|']
for r in records:lines.append('|'+ '|'.join([r['route'],r['module'],r['locale'],r['h5'],r['flutter'],r['conclusion'],r['status']])+'|')
(ROOT/'docs/visual_audit_checklist.md').write_text('\n'.join(lines)+'\n')
print('pairs',sum('mae' in r for r in records),'pending',sum('mae' not in r for r in records))
