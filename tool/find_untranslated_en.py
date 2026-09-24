"""List English UI strings that stay English in Chinese mode.

Only literals actually passed to the translating widgets count: `T('...')` and
`SourceText('...')`. A literal is a gap when no Chinese exists for it in
i18n.json (either direction) nor in the supplementary table.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
i18n = json.loads((ROOT / "assets/data/i18n.json").read_text())
ZH_FOR = dict(i18n["SURGO_EN"])
for zh, en in i18n["SURGO_ZH"].items():
    ZH_FOR.setdefault(en, zh)

supp = (ROOT / "lib/app/supplementary_zh.dart").read_text()
for match in re.finditer(r"'((?:[^'\\]|\\.)*)':\s*'", supp):
    ZH_FOR.setdefault(match.group(1), "supplementary")

CJK = re.compile(r"[\u4e00-\u9fff]")
# T('literal' or SourceText('literal' — single-quoted, no interpolation.
CALL = re.compile(r"\b(?:T|SourceText)\(\s*'((?:[^'\\$]|\\.)+)'")

gaps = {}
for path in sorted((ROOT / "lib").rglob("*.dart")):
    if path.name == "supplementary_zh.dart":
        continue
    for match in CALL.finditer(path.read_text()):
        literal = match.group(1)
        if CJK.search(literal) or literal.count(" ") < 1:
            continue
        if literal in ZH_FOR:
            continue
        gaps.setdefault(str(path.relative_to(ROOT)), set()).add(literal)

total = sum(len(v) for v in gaps.values())
print(f"{total} English UI literals with no Chinese, across {len(gaps)} files\n")
for file, items in sorted(gaps.items(), key=lambda kv: -len(kv[1])):
    print(f"{file}  ({len(items)})")
    for literal in sorted(items):
        print(f"    {literal}")
