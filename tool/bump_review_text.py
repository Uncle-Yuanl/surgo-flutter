"""Enlarge the small text on the writing review pages.

User 2026-09-24: the review page's small copy is too small. Only genuinely
small sizes are bumped; section titles and the big band scores keep their size
so the visual hierarchy is preserved.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS = [
    "lib/features/writing_review/review_content.dart",
    "lib/features/writing_review/review_header.dart",
]
BUMP = {
    "10": "12",
    "10.5": "12.5",
    "11": "13",
    "11.5": "13",
    "12": "13.5",
    "12.5": "13.5",
}

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
