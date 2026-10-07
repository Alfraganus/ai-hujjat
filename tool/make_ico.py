"""Packs build/icon/<size>.png (from test/icon_gen_test.dart) into a Windows .ico.

Usage: python tool/make_ico.py
Each size is stored as a PNG entry (valid since Windows Vista); no resampling,
so every size keeps its own crisp rendering.
"""
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIZES = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]
OUT = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"

images = [(n, (ROOT / "build" / "icon" / f"{n}.png").read_bytes()) for n in SIZES]

header = struct.pack("<HHH", 0, 1, len(images))
offset = 6 + 16 * len(images)
entries = b""
blobs = b""
for n, data in images:
    dim = 0 if n >= 256 else n  # 0 means 256 in the ICO directory
    entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(data), offset)
    blobs += data
    offset += len(data)

OUT.write_bytes(header + entries + blobs)
print(f"wrote {OUT} ({OUT.stat().st_size} bytes, sizes {SIZES})")
