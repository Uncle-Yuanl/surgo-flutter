"""Find English strings that the Chinese UI cannot translate.

SURGO_ZH maps an English source string to Chinese. Any English string the app
renders through the translator but that is missing from SURGO_ZH stays English
in Chinese mode. This lists the gaps for a given data file's description texts.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
i18n = json.loads((ROOT / "assets/data/i18n.json").read_text())
ZH = i18n["SURGO_ZH"]
EN = i18n["SURGO_EN"]

target = ROOT / (sys.argv[1] if len(sys.argv) > 1 else "assets/data/task_brief.json")
data = json.loads(target.read_text())

LATIN = re.compile(r"[A-Za-z]{3,}")
CJK = re.compile(r"[\u4e00-\u9fff]")

missing = []


def walk(node, path=""):
    if isinstance(node, dict):
        for key, value in node.items():
            walk(value, f"{path}/{key}")
    elif isinstance(node, list):
        for index, value in enumerate(node):
            walk(value, f"{path}[{index}]")
    elif isinstance(node, str):
        text = node.strip()
        # English-looking sentence with no Chinese characters.
        if len(text) > 12 and LATIN.search(text) and not CJK.search(text):
            if text not in ZH:
                missing.append((path, text))


walk(data)
print(f"{target.relative_to(ROOT)}: {len(missing)} untranslatable English strings")
for path, text in missing:
    print(f"  {path}\n    {text[:96]}")
