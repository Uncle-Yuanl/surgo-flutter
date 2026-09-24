"""Attach the Chinese fallback chain to every Outfit heading style.

Outfit has no CJK glyphs. Without an explicit fontFamilyFallback, CanvasKit
resolves Chinese characters on its own and can render stray ink marks instead of
proper 苹方 glyphs. Any TextStyle that pins fontFamily:'Outfit' therefore needs
the same fallback list the shell uses for body text.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
FALLBACK = "fontFamilyFallback: SurgoFontFamily.fallback, "
TOKENS_IMPORT = re.compile(r"""import ['"][^'"]*tokens\.dart['"];""")

changed = []
for path in sorted(LIB.rglob("*.dart")):
    text = path.read_text()
    if "'Outfit'" not in text:
        continue
    original = text

    # Insert the fallback right after each Outfit family, skipping styles that
    # already declare one.
    out = []
    index = 0
    for match in re.finditer(r"fontFamily: *'Outfit', *", text):
        window = text[match.end() : match.end() + 200]
        out.append(text[index : match.end()])
        if "fontFamilyFallback" not in window[:120]:
            out.append(FALLBACK)
        index = match.end()
    out.append(text[index:])
    text = "".join(out)

    if text == original:
        continue

    # tokens.dart defines SurgoFontFamily; every other file must import it.
    if path.name != "tokens.dart" and not TOKENS_IMPORT.search(text):
        depth = len(path.relative_to(LIB).parts) - 1
        prefix = "../" * depth if depth else ""
        text = re.sub(
            r"(import [^\n]*;\n)(?!import)",
            r"\1import '" + prefix + "theme/tokens.dart';\n",
            text,
            count=1,
        )

    path.write_text(text)
    changed.append(str(path.relative_to(ROOT)))

print(f"{len(changed)} files given a CJK fallback on Outfit styles")
for rel in changed:
    print("  " + rel)
if not changed:
    sys.exit(1)
