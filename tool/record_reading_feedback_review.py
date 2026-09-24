"""Record an explicitly manually reviewed revision, not capture success."""
import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
revision = sys.argv[1]
if '--reviewed' not in sys.argv:
    raise SystemExit('Require --reviewed only after visual inspection of all12 grids')
rows = []
for fixture in ['daily', '1', '2', '3']:
    for suffix in ['', '-scroll600', '-bottom']:
        for lang in ['zh', 'en']:
            paths = [f'artifacts/{folder}/{lang}/readingFeedback-review{fixture}{suffix}.png'
                     for folder in ['h5', f'flutter-{revision}']]
            rows.append({'fixture': fixture, 'locale': lang, 'state': suffix or 'initial',
                         'result': 'reviewed-with-differences',
                         'images': [{'path': p, 'sha256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()}
                                    for p in paths]})
summary = {'reviewedAt': datetime.now().astimezone().isoformat(),
           'source': 'Local read-only H5; four core hashes match previously verified online. Current online load failed.',
           'revision': revision, 'pairs': len(rows), 'images': len(rows) * 2,
           'fullVisualAcceptance': False,
           'observations': ['Daily/mock3Passage content and fixed scores restored',
                            'Pills single-line/row wrapping corrected with local width+scaleDown',
                            'Font weights, highlighted baseline, glyphs and several linebreaks still differ',
                            'Mock summary Chinese paragraph native one extra line; cumulative layout differences remain',
                            'Source noncollapsing8px subtitle and6px button gaps retained after DOM measurement',
                            'No complete end-to-end mock submission/device acceptance'],
           'rows': rows}
p = ROOT / 'artifacts/visual_audit/reading_feedback_reviewed.json'
p.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
print(p, len(rows), 'pairs')
