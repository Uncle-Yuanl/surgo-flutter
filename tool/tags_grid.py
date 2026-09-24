"""Crop the top strip of every answering page so the session tags can be
reviewed side by side in one image."""
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
BATCH = ROOT / "artifacts/flutter-tags1/zh"
PAGES = [
    "readingSession",
    "listeningSession",
    "speakingSession",
    "mockReadingQ",
    "mockListeningQ",
    "mockWritingQ",
    "mockSpeakingQ",
    "tfRead2Q",
    "tfDailyLife",
    "tfDailyConvo",
    "tfListenQ",
    "tfDailyRetell",
    "tfSpk1Q",
    "tfWr2Q",
]
STRIP = 150  # top area holding the home row plus the tags
sheet = Image.new("RGB", (390, STRIP * len(PAGES)), "white")
for index, name in enumerate(PAGES):
    path = BATCH / f"{name}.png"
    if not path.is_file():
        print(f"missing {name}")
        continue
    image = Image.open(path).convert("RGB").crop((0, 40, 390, 40 + STRIP))
    sheet.paste(image, (0, STRIP * index))
sheet.save("/tmp/tags_grid.png")
print(f"grid: {len(PAGES)} pages -> /tmp/tags_grid.png")
