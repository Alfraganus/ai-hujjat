"""Generates the installer wizard images (installer/wizard_large.bmp, wizard_small.bmp)
from the app icon renders in build/icon (run test/icon_gen_test.dart first)."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "build" / "icon"
OUT = ROOT / "installer"


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = row
    return img


# Large side panel (Inno shows it at 164x314 at 100% scale; supply 2x for sharper high-DPI).
w, h = 328, 628
large = gradient((w, h), (0x12, 0x14, 0x2B), (0x2A, 0x2C, 0x6B))
logo = Image.open(ICONS / "128.png").convert("RGBA").resize((176, 176), Image.LANCZOS)
large.paste(logo, ((w - 176) // 2, 150), logo)
d = ImageDraw.Draw(large)
d.ellipse((-120, h - 220, 200, h + 100), fill=(0x3B, 0x3F, 0x9E))
large.save(OUT / "wizard_large.bmp")

# Small header image (55x58 at 100%).
small = Image.new("RGB", (110, 116), (255, 255, 255))
logo_s = Image.open(ICONS / "96.png").convert("RGBA").resize((88, 88), Image.LANCZOS)
small.paste(logo_s, (11, 14), logo_s)
small.save(OUT / "wizard_small.bmp")
print("wrote", OUT / "wizard_large.bmp", "and", OUT / "wizard_small.bmp")
