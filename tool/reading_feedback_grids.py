"""Compose unmodified images; does not mark their contents reviewed."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
revision = sys.argv[1]
output = ROOT / 'artifacts/visual_audit' / f'{revision}_grids'
output.mkdir(exist_ok=True)
for fixture in ['daily', '1', '2', '3']:
    for suffix in ['', '-scroll600', '-bottom']:
        files = [ROOT / f'artifacts/{folder}/{lang}/readingFeedback-review{fixture}{suffix}.png'
                 for lang in ['zh', 'en'] for folder in ['h5', f'flutter-{revision}']]
        if not all(p.exists() for p in files):
            print('Missing', fixture, suffix)
            continue
        grid = Image.new('RGB', (1560, 874), '#eee')
        draw = ImageDraw.Draw(grid)
        for i, file in enumerate(files):
            grid.paste(Image.open(file), (i * 390, 30))
            draw.text((i * 390 + 8, 8), ['H5 zh', 'Flutter zh', 'H5 en', 'Flutter en'][i], fill='black')
        path = output / f'{fixture}{suffix}.png'
        grid.save(path)
        print(path)
