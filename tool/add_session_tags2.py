"""Second batch: session tags on the TOEFL daily/mock pages.

Anchors are the closing paren of each page's SurgoTopBar(...) call, which is the
top row (home + clock). Values differ per page, so they are explicit.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
IMPORT = "import '../../widgets/session_tags.dart';\n"

EDITS = {
    # 托福听力日常：四种任务类型作为第三段。
    "lib/features/tf_listening_daily/module.dart": (
        "fontSize:14,height:1.3,color:Colors.white,fontWeight:FontWeight.w800)))),",
        "\n   SessionTags(mock:false,subject:'托福听力',part:{'respond':'听后选择回应','convo':'听对话','announce':'听通知','lecture':'听学术讲座'}[widget.kind]),",
    ),
    # 托福口语日常：听读复述 / 参加访谈。
    "lib/features/tf_speaking_daily/module.dart": (
        "fontSize: 14, height: 1.3, color: Colors.white, fontWeight: FontWeight.w800)))),",
        "\n      SessionTags(mock: false, subject: '托福口语', part: widget.kind == 'retell' ? '听读复述' : '参加访谈'),",
    ),
    # 托福写作：daily 决定训练类型，task 决定第三段。
    "lib/features/tf_writing/module.dart": (
        "fontSize:14,height:1.3,fontWeight:FontWeight.w800,color:Colors.white)))),",
        "\n   SessionTags(mock:!daily,subject:'托福写作',part:'Task $task'),",
    ),
}

changed = []
for rel, (anchor, insert) in EDITS.items():
    path = ROOT / rel
    text = path.read_text()
    if "SessionTags" in text:
        print(f"skip (already present): {rel}")
        continue
    if text.count(anchor) != 1:
        print(f"ANCHOR {text.count(anchor)}x (need 1): {rel}")
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
