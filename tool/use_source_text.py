"""Use explicit, route-scoped source-DOM translation for rendered Text only.
Does not touch TextField, TextSpan data, controllers, JSON or input validation.
"""
from pathlib import Path
import re,sys
ROOT=Path(__file__).resolve().parents[1]
files=[]
for folder in ['lib/features','lib/pages']:
    for path in (ROOT/folder).rglob('*.dart'):
        before=path.read_text()
        if "import 'package:flutter/material.dart';" not in before:continue
        after=re.sub(r'(?<![\w.])Text(?=\s*(?:\(|\.rich\())','SourceText',before)
        if after==before:continue
        depth=len(path.relative_to(ROOT/'lib').parts)-1
        imp="import '"+'../'*depth+"widgets/source_text.dart';\n"
        after=imp+after
        files.append((path,before,after))
for p,b,a in files:
    print(str(p.relative_to(ROOT)),len(re.findall(r'\bSourceText[.(]',a)))
    if '--apply' in sys.argv:
        assert p.read_text()==b,'File changed during transform'
        p.write_text(a)
print('Updated' if '--apply' in sys.argv else 'Would update',len(files),'widget files')
