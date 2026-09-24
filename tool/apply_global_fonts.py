"""Apply the user's global font split: headings/subtitles -> Outfit, body/questions -> SF Pro.

Body inherits the family from the shell DefaultTextStyle, so only heading-weight
TextStyle literals need an explicit family. A TextStyle that already pins a
family (VioletSans / Arimo / Inter, i.e. deliberate source-fidelity choices)
is left untouched.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
HEADING = "'Outfit'"
HEADING_WEIGHTS = re.compile(r"FontWeight\.(w700|w800|w900|bold)\b")
HAS_FAMILY = re.compile(r"\bfontFamily\s*:")


def spans(text):
    """Yield (start, end) of every TextStyle(...) argument list, innermost-safe.

    Matches the TextStyle constructor only: a preceding identifier character
    would make it DefaultTextStyle / StrutStyle-like, which take no fontFamily.
    """
    for match in re.finditer(r"(?<![A-Za-z0-9_])TextStyle\(", text):
        i = match.end()
        depth = 1
        while i < len(text) and depth:
            char = text[i]
            if char in "([{":
                depth += 1
            elif char in ")]}":
                depth -= 1
            elif char in "'\"":
                quote = char
                i += 1
                while i < len(text) and text[i] != quote:
                    i += 2 if text[i] == "\\" else 1
            i += 1
        yield match.end(), i - 1


changed = []
for path in sorted(LIB.rglob("*.dart")):
    text = path.read_text()
    edits = []
    for start, end in spans(text):
        args = text[start:end]
        if HAS_FAMILY.search(args):
            continue
        if not HEADING_WEIGHTS.search(args):
            continue
        edits.append(start)
    if not edits:
        continue
    for start in sorted(edits, reverse=True):
        text = text[:start] + f"fontFamily: {HEADING}, " + text[start:]
    path.write_text(text)
    changed.append((str(path.relative_to(ROOT)), len(edits)))

total = sum(count for _, count in changed)
print(f"{len(changed)} files, {total} heading styles")
for rel, count in changed:
    print(f"  {rel}: {count}")
if not changed:
    sys.exit(1)
