"""Enlarge and darken the review annotation / widget text.

User 2026-09-24: on the L1-transfer annotation cards and the muted captions the
text is both too small and too light. review_widgets.dart and
review_annotations.dart were missed by the earlier pass, so they still carry the
old sizes and the pale greys.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS = [
    "lib/features/writing_review/review_widgets.dart",
    "lib/features/writing_review/review_annotations.dart",
    "lib/features/writing_review/review_content.dart",
    "lib/features/writing_review/review_header.dart",
]
SIZE = {
    "10": "12.5",
    "10.5": "12.5",
    "11": "13",
    "11.5": "13",
    "12": "13.5",
    "12.5": "13.5",
    "13": "13.5",
}
# Pale greys -> darker, keeping the warm hue family.
COLOR = {
    "0xffa99a82": "0xff7b6f5c",
    "0xff8a8378": "0xff6a645b",
    "0xff6b6255": "0xff544e44",
    "0xff8a7a45": "0xff6d6033",
    "0xff6b5d2e": "0xff574b22",
    "0xff8a7530": "0xff6d5c24",
}

changed = []
for rel in TARGETS:
    path = ROOT / rel
    if not path.is_file():
        print(f"missing: {rel}")
        continue
    text = path.read_text()
    original = text

    def bump(match):
        value = match.group(1)
        return f"fontSize: {SIZE[value]}" if value in SIZE else match.group(0)

    text = re.sub(r"fontSize: (\d+(?:\.\d+)?)", bump, text)
    for old, new in COLOR.items():
        text = text.replace(old, new)
    if text != original:
        path.write_text(text)
        changed.append(rel)

print(f"{len(changed)} files updated")
for rel in changed:
    print("  " + rel)
if not changed:
    sys.exit(1)
