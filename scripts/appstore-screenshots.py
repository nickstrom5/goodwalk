#!/usr/bin/env python3
"""Build the six App Store screenshots (6.9-inch, 1320x2868) from simulator captures.

Usage:  python3 scripts/appstore-screenshots.py            (needs Pillow: pip install pillow)
Reads docs/screenshots/*.png, writes playbook/app-store/NN-name.png. Each frame is a dark
background, a caption in the brand accent at the top, and the capture in a device-style
rounded frame below. Captions come from playbook/06-app-store-listing.md.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "screenshots"
OUT = ROOT / "playbook" / "app-store"
W, H = 1320, 2868
BG = (250, 245, 236)
ACCENT = (201, 85, 27)
FONT = "/System/Library/Fonts/SFCompact.ttf" if Path("/System/Library/Fonts/SFCompact.ttf").exists() \
    else "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# order, source capture, caption (first line white, second line yellow)
FRAMES = [
    ("01-home",      "home.png",      ("Your dog's streak,", "every day.")),
    ("02-reveal",    "reveal.png",    ("See what your", "dog needs.")),
    ("03-walking",   "walking.png",   ("No collar.", "No map.")),
    ("04-milestone", "milestone.png", ("A card every", "milestone.")),
    ("05-dog",       "dog.png",       ("Their face", "on everything.")),
    ("06-paywall",   "paywall.png",   ("Free for 7 days.", "Then $1.67 a month.")),
]


def caption_font(size):
    return ImageFont.truetype(FONT, size)


def frame(name, capture, lines):
    shot = Image.open(SRC / capture).convert("RGB")
    canvas = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(canvas)

    # Caption block
    f1 = caption_font(96)
    y = 170
    for i, text in enumerate(lines):
        w = d.textlength(text, font=f1)
        d.text(((W - w) / 2, y), text, font=f1, fill=(46, 34, 25) if i == 0 else ACCENT)
        y += 112

    # Device frame with the capture inside
    top = 470
    scale = (H - top - 90) / shot.height
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    x = (W - sw) // 2
    pad = 18
    d.rounded_rectangle([x - pad, top - pad, x + sw + pad, top + sh + pad], radius=110, fill=(239, 230, 214))
    d.rounded_rectangle([x - pad + 3, top - pad + 3, x + sw + pad - 3, top + sh + pad - 3], radius=107, outline=(226, 214, 195), width=3)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=92, fill=255)
    canvas.paste(shot, (x, top), mask)

    OUT.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT / f"{name}.png", optimize=True)
    print("wrote", OUT / f"{name}.png")


if __name__ == "__main__":
    for name, capture, lines in FRAMES:
        frame(name, capture, lines)
