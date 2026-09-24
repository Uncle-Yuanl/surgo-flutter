"""Preload the new Outfit / SF Pro families in every test that preloads fonts.

Geometry tests measure real glyph metrics, so a family that is registered in
pubspec but not loaded in the test binding falls back to the square test font
and inflates every height. This adds the two new families alongside the
existing VioletSans loader without changing any expected value.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TESTS = ROOT / "test"
HELPER = "test/support/fonts.dart"

changed = []
for path in sorted(TESTS.rglob("*_test.dart")):
    text = path.read_text()
    if "VioletSans" not in text:
        continue
    if "loadSurgoTestFonts" in text:
        continue
    original = text

    # Replace the whole existing VioletSans FontLoader statement with a call to
    # the shared helper, which loads VioletSans plus the new families.
    patterns = [
        # await (FontLoader('VioletSans')..addFont(...)).load();
        r"await \(FontLoader\('VioletSans'\)\s*\.\.addFont\([^;]*?\)\)\s*\.load\(\);",
        # final f = FontLoader('VioletSans')..addFont(...); await f.load();
        r"final \w+ = FontLoader\('VioletSans'\)\s*\.\.addFont\([^;]*?\);\s*await \w+\.load\(\);",
    ]
    for pattern in patterns:
        text, count = re.subn(
            pattern, "await loadSurgoTestFonts();", text, flags=re.S
        )
        if count:
            break
    else:
        # Tuple-list style: ('VioletSans', '...'), plus a loop. Append the call.
        text = re.sub(
            r"(setUpAll\(\(\) async \{\n)",
            r"\1    await loadSurgoTestFonts();\n",
            text,
            count=1,
        )

    if "support/fonts.dart" not in text:
        depth = len(path.relative_to(TESTS).parts) - 1
        prefix = "../" * depth
        text = re.sub(
            r"(import [^\n]*;\n)(?!import)",
            r"\1import '" + prefix + "support/fonts.dart';\n",
            text,
            count=1,
        )

    if text != original:
        path.write_text(text)
        changed.append(str(path.relative_to(ROOT)))

print(f"{len(changed)} test files updated")
for rel in changed:
    print("  " + rel)
if not changed:
    sys.exit(1)
