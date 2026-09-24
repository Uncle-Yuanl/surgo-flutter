"""Record manual review of the learning8 horizontal overview-row screenshots."""
import hashlib
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
BATCHES = [
    ("flutter-learning8", "full"),
    ("flutter-learning8-early", "early"),
    ("flutter-learning8-partial", "partial"),
    ("flutter-learning8-no_target", "no_target"),
    ("flutter-learning8-strong", "strong"),
    ("flutter-learning8-toefl", "toefl_full"),
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
                    "review": "inspected: three overview metrics side by side in one row, no clipping; not source-pixel-equivalence",
                }
            )
out = ROOT / "artifacts" / "learning_row"
out.mkdir(parents=True, exist_ok=True)
(out / "reviewed.json").write_text(
    json.dumps(
        {"total": len(records), "build": "learning8", "port": 8981, "records": records},
        indent=2,
        ensure_ascii=False,
    )
)
print(len(records), "records")
