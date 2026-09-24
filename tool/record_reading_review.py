"""Index manually reviewed reading comparisons; keep capture ledgers intact."""
import hashlib
import json
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
rows = []
cases = [('typeSession', '-' + t) for t in
         'mc tfng yyng imatch hmatch fmatch ematch scomplete summary diagram short'.split()]
cases += [('readingSession', s) for s in
          ['', '-pick', '-nav', '-qbottom', '-abottom', '-drag']]
cases += [('typeSession', '-nav'), ('typeSession', '-short-input'),
          ('readingSession', '-overtime-frame1')]
for route, suffix in cases:
    for lang in ['zh', 'en']:
        revision = 'readingfinal1'
        if suffix == '-overtime-frame1':
            revision = 'readingmedia4'
        elif suffix == '-drag' or (route == 'typeSession' and suffix in ['-nav', '-short-input']) or (suffix == '-abottom' and lang == 'zh'):
            revision = 'readingfinal2'
        paths = [f'artifacts/online/{lang}/{route}{suffix}.png',
                 f'artifacts/flutter-{revision}/{lang}/{route}{suffix}.png']
        images = [{'path': p, 'sha256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()}
                  for p in paths]
        observations = ['28px centered Home-row clock is an authorized change; do not restore old header.',
                        'Font weight/glyph/line metrics still differ; not a complete-fidelity pass.']
        if suffix == '-overtime-frame1':
            observations = ['Both decoded video frames at 1.000s; CSS brightness1.033, radius14, muted and loop verified.',
                            'Video rect89,452.5,212,212 and button height55 restored; minor text rasterization differences remain.',
                            'Raw corresponding video crop RGB mean absolute differences about0.0108/0.0106/0.0107 on0-255 scale.']
        elif suffix == '-drag':
            observations += ['Partial upward drag sampled; different header clamp is authorized. Absolute maximum covered in widget tests, not this pointer sample.']
        elif suffix == '-short-input':
            observations += ['Real input sample and blur: both Answered1/2; source English refresh text retained.']
        elif suffix == '-abottom':
            observations += ['Both at article bottom; extra native visible article area follows compact header.']
        elif suffix in ['-nav', '-pick']:
            observations += ['Navigation modal or selected state compared; remaining small typography/position differences.']
        rows.append({'route': route, 'locale': lang, 'state': suffix or 'initial',
                     'result': 'reviewed-with-differences', 'images': images,
                     'observations': observations})
summary = {'reviewedAt': datetime.now().astimezone().isoformat(),
           'scope': 'Two source routes;40 language-specific screenshot pairs manually viewed in19 four-column and2 two-column grids.',
           'pairs': len(rows), 'images': len(rows) * 2,
           'fullVisualAcceptance': False, 'rows': rows,
           'verification': json.loads((ROOT / 'docs/verification/summary.json').read_text())['generated'],
           'excluded': ['readingmedia1 zh seek failure', 'readingmedia2 zh seek failure',
                        'readingfinal1 readingSession zh abottom font transport failure'],
           'limitations': ['Not every question index/selection/error/disabled state',
                           'No device iOS/Android/media lifecycle acceptance',
                           'No dynamic timer-second equivalence from different-time screenshots']}
p = ROOT / 'artifacts/visual_audit/reading_reviewed_final.json'
p.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
print(p, summary['pairs'], 'pairs', summary['images'], 'images')
