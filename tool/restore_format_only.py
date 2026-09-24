"""Restore files that only `dart format` touched, keeping genuine font edits.

A file is restored from the pre-change backup when the backup contains no
'Outfit' occurrence and the current file contains none either: such a file was
never a target of the font change, so any difference is pure reformatting.
"""
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
BACKUP = pathlib.Path("/tmp/surgo_lib_backup")

restored = []
for current in sorted(LIB.rglob("*.dart")):
    rel = current.relative_to(LIB)
    original = BACKUP / rel
    if not original.is_file():
        continue
    current_text = current.read_text()
    original_text = original.read_text()
    if current_text == original_text:
        continue
    if "Outfit" in current_text or "Outfit" in original_text:
        continue
    shutil.copyfile(original, current)
    restored.append(str(rel))

print(f"restored {len(restored)} reformat-only files")
for rel in restored:
    print("  lib/" + rel)
