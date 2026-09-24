"""Capture the current reading release; never marks captures as reviewed."""
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
env = os.environ.copy()
env['NO_PROXY'] = env['no_proxy'] = 'localhost,127.0.0.1,::1'
base = ['node', str(ROOT / 'tool/visual_capture.cjs'), 'flutter']
cases = [('typeSession', [f'--read-type={kind}']) for kind in
         'mc tfng yyng imatch hmatch fmatch ematch scomplete summary diagram short'.split()]
cases += [('readingSession', [])]
cases += [('readingSession', [f'--read-action={action}']) for action in
          'pick nav qbottom abottom drag'.split()]
cases += [('typeSession', ['--read-action=nav']),
          ('typeSession', ['--read-type=short', '--read-action=input'])]
for route, flags in cases:
    command = base + [route, '2500', 'readingfinal1', '8956', '--font-cache'] + flags
    print('CAPTURE', route, flags, flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)
print('All readingfinal1 captures complete; visual review still required.', flush=True)
