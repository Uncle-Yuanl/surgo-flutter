"""Build an allowlist from captured source DOM nodes; never invent translations."""
import json
from collections import defaultdict
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
src=ROOT/'test/fixtures/source_dom_nodes.json'
data=json.loads(src.read_text())
out={}
for row in data['rows']:
    values=defaultdict(set)
    for node in row['nodes']:
        values[node['before'].strip()].add(node['after'].strip())
    changed={a:next(iter(b)) for a,b in values.items() if a and len(b)==1 and a!=next(iter(b))}
    if changed: out.setdefault(row['route'],{})[row['lang']]=changed
body=json.dumps({'provenance':data['method'],'routes':out},ensure_ascii=False,indent=2)+'\n'
target=ROOT/'assets/data/source_dom_translations.json'
import sys
if '--check' in sys.argv:
    assert target.read_text()==body
else:
    target.write_text(body)
print('Verified source DOM translations:',sum(len(m) for p in out.values() for m in p.values()))
