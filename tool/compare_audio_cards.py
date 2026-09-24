"""Compare the audio card across IELTS and TOEFL pages, pixel by pixel.

The user asked for identical style and colour. Locating the card by its white
background lets us compare width, x-position and sampled colours instead of
eyeballing two screenshots.
"""
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
BATCH = ROOT / "artifacts/flutter-tfalign3/zh"
WHITE = (255, 255, 255)


def card_box(image):
    """Widest run of pure white rows: the audio card body."""
    width, height = image.size
    best = None
    for y in range(60, height):
        xs = [x for x in range(width) if image.getpixel((x, y)) == WHITE]
        if len(xs) < 200:
            continue
        span = (xs[0], xs[-1])
        if best is None or span[1] - span[0] > best[1][1] - best[1][0]:
            best = (y, span)
    return best


for name in ("listeningSession", "tfDailyConvo", "tfDailyRetell"):
    path = BATCH / f"{name}.png"
    if not path.is_file():
        print(f"{name}: missing")
        continue
    image = Image.open(path).convert("RGB")
    found = card_box(image)
    if not found:
        print(f"{name}: no card found")
        continue
    y, (left, right) = found
    print(f"{name:18} card x {left:3}..{right:3}  width {right - left + 1}")
