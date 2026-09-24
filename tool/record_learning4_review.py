"""Record manual review of the learning4 overview-card screenshots."""
import hashlib
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
BATCHES = [
    ("flutter-learning4", "full"),
    ("flutter-learning4-early", "early"),
    ("flutter-learning4-partial", "partial"),
    ("flutter-learning4-no_target", "no_target"),
    ("flutter-learning4-strong", "strong"),
]
records = []
for folder, state in BATCHES:
    for locale in ("zh", "en"):
        directory = ROOT / "artifacts" / folder / locale
        for png in sorted(directory.glob("*.png")):
            records.append(
                {
                    "route": "report",
                    "locale": locale,
                    "state": state,
                    "path": str(png.relative_to(ROOT)),
                    "sha256": hashlib.sha256(png.read_bytes()).hexdigest(),
                    "review": "inspected: three overview metrics rendered as separate stacked cards; not source-pixel-equivalence",
                }
            )
out = ROOT / "artifacts" / "learning_vertical_cards"
out.mkdir(parents=True, exist_ok=True)
(out / "reviewed.json").write_text(
    json.dumps(
        {"total": len(records), "build": "learning4", "port": 8977, "records": records},
        indent=2,
        ensure_ascii=False,
    )
)
print(len(records), "records")
