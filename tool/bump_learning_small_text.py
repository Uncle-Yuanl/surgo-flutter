"""Enlarge the new learning-report small text by one step, capped, without touching other pages."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS = [
    "lib/features/report/learning_details.dart",
    "lib/features/report/learning_advice.dart",
    "lib/features/report/learning_trends.dart",
]
# Only bump genuinely small sizes; leave section titles and big numbers alone.
BUMP = {"10": "11.5", "10.5": "12", "11": "12.5", "11.5": "12.5", "12": "13"}
changed = []
for rel in TARGETS:
    path = ROOT / rel
    text = path.read_text()
    original = text

    def repl(match):
        value = match.group(1)
        return f"fontSize: {BUMP[value]}" if value in BUMP else match.group(0)

    text = re.sub(r"fontSize: (\d+(?:\.\d+)?)", repl, text)
    if text != original:
        path.write_text(text)
        changed.append(rel)
print("changed:", changed)
if not changed:
    sys.exit(1)
