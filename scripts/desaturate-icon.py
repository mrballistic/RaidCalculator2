#!/usr/bin/env python3
"""Turn every image layer of AppIcon.icon to grayscale, keeping its alpha.

  /tmp/raid-assets/venv/bin/python scripts/desaturate-icon.py

For the RAID Calc2 legacy release only. Running it again changes nothing:
grayscale stays grayscale.
"""
import pathlib

from PIL import Image

ASSETS = pathlib.Path(__file__).resolve().parent.parent / "RaidCalculator2" / "AppIcon.icon" / "Assets"

for path in sorted(ASSETS.glob("*.png")):
    rgba = Image.open(path).convert("RGBA")
    gray = rgba.convert("L").convert("RGBA")
    gray.putalpha(rgba.getchannel("A"))
    gray.save(path)
    print(f"{path.name}: grayscale")
