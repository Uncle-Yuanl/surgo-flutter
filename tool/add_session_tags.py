"""Insert the left-aligned three-part session title on every answering page.

Each page gets `SessionTags(mock:…, subject:…, part:…)` right after its top row
(home + clock). The anchor and the three values differ per page, so they are
listed explicitly rather than guessed. Pages already carrying the widget are
skipped so the script is safe to re-run.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
IMPORT = "import '../../widgets/session_tags.dart';\n"

# file -> (anchor line fragment, code to insert after it)
EDITS = {
    "lib/features/ielts_mock_listening/ielts_mock_listening_module.dart": (
        "                            const SizedBox(width: 86),\n                            ]),",
        "\n                            SessionTags(\n                                mock: true,\n                                subject: '雅思听力',\n                                part: 'Part $partNo'),",
    ),
    "lib/features/ielts_mock_writing/page.dart": (
        "  const SizedBox(width:86)]),",
        "\n  SessionTags(mock:true,subject:'雅思写作',part:tab==0?null:'Task ${c.task}'),",
    ),
    "lib/features/ielts_mock_speaking/page.dart": (
        "   const SizedBox(width:76),\n  ]),",
        "\n  SessionTags(mock:true,subject:'雅思口语',part:'Part ${x.part.substring(1)}'),",
    ),
    "lib/features/tf_reading_mock/page.dart": (
        "  const SizedBox(height:10),",
        "\n  Padding(padding:const EdgeInsets.symmetric(horizontal:13),child:SessionTags(mock:true,subject:'托福阅读',part:'Part ${widget.part}')),",
    ),
}

changed = []
for rel, (anchor, insert) in EDITS.items():
    path = ROOT / rel
    text = path.read_text()
    if "SessionTags" in text:
        print(f"skip (already present): {rel}")
        continue
    if anchor not in text:
        print(f"ANCHOR NOT FOUND: {rel}")
        continue
    text = text.replace(anchor, anchor + insert, 1)
    if IMPORT not in text:
        first = text.index("import ")
        text = text[:first] + IMPORT + text[first:]
    path.write_text(text)
    changed.append(rel)

print(f"\n{len(changed)} files updated")
for rel in changed:
    print("  " + rel)
if not changed:
    sys.exit(1)
