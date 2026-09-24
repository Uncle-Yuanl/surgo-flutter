"""Measure the vertical gaps between top-level cards on a captured page.

Cards sit on the page background; a gap is a run of rows where the sampled
column matches the page colour. Sampling near the left card edge avoids being
confused by text or inner fields.
"""
import pathlib
import sys

from PIL import Image

path = pathlib.Path(sys.argv[1])
image = Image.open(path).convert("RGB")
width, height = image.size
# Page background, sampled outside the cards.
page = image.getpixel((4, height // 2))
# Column just inside the card's left edge: no text there, so a card row is
# card-coloured and a gap row is page-coloured.
x = 24


def is_gap(y):
    r, g, b = image.getpixel((x, y))
    pr, pg, pb = page
    return abs(r - pr) <= 2 and abs(g - pg) <= 2 and abs(b - pb) <= 2


gaps = []
start = None
for y in range(100, height):
    if is_gap(y):
        if start is None:
            start = y
    elif start is not None:
        if y - start >= 4:
            gaps.append((start, y - 1, y - start))
        start = None

print(f"page bg {page}, sampled x={x}")
for top, bottom, size in gaps:
    print(f"gap rows {top}..{bottom}  height={size}")
