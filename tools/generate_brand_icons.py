#!/usr/bin/env python3
"""Generate Ashgrid app icons and the menu wordmark.

The mark is an original isometric voxel tank on an ash-green field.
Run from the repo root: python3 tools/generate_brand_icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "assets" / "icons" / "ashgrid"
WORDMARK = ROOT / "assets" / "gui" / "menu" / "ashgrid_wordmark.png"

BG = (26, 36, 32, 255)
GROUND = (61, 74, 50, 255)
GROUND_DARK = (36, 46, 34, 255)
HULL = (227, 155, 58, 255)
HULL_DARK = (140, 86, 32, 255)
TRACK = (42, 36, 28, 255)
BARREL = (232, 220, 196, 255)
EMBER = (196, 72, 42, 255)


def _px(draw, x, y, color, scale=1):
    draw.rectangle([x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1], fill=color)


def _iso_diamond(draw, cx, cy, rx, ry, color):
    draw.polygon([(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)], fill=color)


def paint_mark(size, padding=0, opaque=True, mono=False):
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0) if not opaque else BG)
    draw = ImageDraw.Draw(image)
    inner = size - padding * 2
    # Paint in a 64-cell grid mapped into the safe area.
    cells = 64
    scale = inner / cells

    def cell(x, y, color):
        x0 = padding + int(round(x * scale))
        y0 = padding + int(round(y * scale))
        x1 = padding + int(round((x + 1) * scale)) - 1
        y1 = padding + int(round((y + 1) * scale)) - 1
        if mono:
            color = (255, 255, 255, 255) if color[3] else color
        draw.rectangle([x0, y0, max(x0, x1), max(y0, y1)], fill=color)

    if opaque and not mono:
        draw.rectangle([0, 0, size - 1, size - 1], fill=BG)
        # Rounded-rect crop so the home-screen icon is not a hard square of art.
        radius = int(size * 0.18)
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    else:
        mask = None

    if not mono:
        _iso_diamond_cells(cell)
    _tank_cells(cell, mono)
    if mask is not None:
        bg = Image.new("RGBA", (size, size), BG)
        bg.paste(image, mask=mask)
        # Fill outside the rounded rect with the same field so the store icon stays opaque.
        flat = Image.new("RGBA", (size, size), BG)
        flat.paste(bg, mask=mask)
        image = flat
    return image


def _iso_diamond_cells(cell):
    # Ground plate, isometric diamond.
    for y in range(22, 50):
        span = int((y - 22) * 1.15) if y < 36 else int((50 - y) * 1.15)
        for x in range(32 - span, 33 + span):
            shade = GROUND_DARK if (x + y) % 7 == 0 else GROUND
            cell(x, y, shade)


def _tank_cells(cell, mono):
    hull = (255, 255, 255, 255) if mono else HULL
    dark = (210, 210, 210, 255) if mono else HULL_DARK
    track = (255, 255, 255, 255) if mono else TRACK
    barrel = (255, 255, 255, 255) if mono else BARREL
    ember = (255, 255, 255, 255) if mono else EMBER
    # Tracks.
    for x in range(22, 42):
        cell(x, 30, track)
        cell(x, 38, track)
    for y in range(30, 39):
        cell(22, y, track)
        cell(41, y, track)
    # Hull.
    for y in range(31, 38):
        for x in range(24, 40):
            cell(x, y, hull if y < 35 else dark)
    # Turret.
    for y in range(27, 33):
        for x in range(28, 37):
            cell(x, y, hull)
    cell(32, 26, hull)
    # Barrel, pointing up-right in isometric space.
    for i in range(8):
        cell(36 + i, 28 - i // 2, barrel)
    cell(44, 24, barrel)
    # Ember on the rear deck.
    cell(26, 33, ember)
    cell(27, 34, ember)


# 5x7 pixel glyphs. 1 is ink.
GLYPHS = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
}


def paint_wordmark():
    text = "ASHGRID"
    scale = 10
    gap = 2
    glyph_w = 5
    width = (glyph_w * len(text) + gap * (len(text) - 1)) * scale + 48
    height = 7 * scale + 44
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle([4, 4, width - 5, height - 5], radius=16, fill=(18, 14, 10, 220))

    def stamp(origin_x, origin_y, color):
        x = origin_x
        for char in text:
            rows = GLYPHS[char]
            for row, bits in enumerate(rows):
                for col, bit in enumerate(bits):
                    if bit != "1":
                        continue
                    draw.rectangle(
                        [
                            x + col * scale,
                            origin_y + row * scale,
                            x + (col + 1) * scale - 2,
                            origin_y + (row + 1) * scale - 2,
                        ],
                        fill=color,
                    )
            x += (glyph_w + gap) * scale

    for ox, oy in ((-3, 0), (3, 0), (0, -3), (0, 3), (-3, -3), (3, -3), (-3, 3), (3, 3)):
        stamp(24 + ox, 18 + oy, (12, 8, 6, 255))
    stamp(24, 18, HULL)
    return image


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    master = paint_mark(1024, opaque=True)
    master.save(ICON_DIR / "icon_1024.png")
    ios_sizes = [40, 58, 60, 76, 80, 87, 114, 120, 128, 136, 152, 167, 180, 192]
    for side in ios_sizes:
        master.resize((side, side), Image.Resampling.LANCZOS).save(ICON_DIR / f"ios_{side}.png")
    for side in (48, 72, 96, 144, 192, 512):
        master.resize((side, side), Image.Resampling.LANCZOS).save(ICON_DIR / f"android_{side}.png")
    # Adaptive icons keep the tank inside the center safe zone.
    fg = paint_mark(432, padding=78, opaque=False)
    fg.save(ICON_DIR / "adaptive_fg.png")
    bg = Image.new("RGBA", (432, 432), BG)
    bg.save(ICON_DIR / "adaptive_bg.png")
    mono = paint_mark(432, padding=78, opaque=False, mono=True)
    mono.save(ICON_DIR / "adaptive_mono.png")
    paint_wordmark().save(WORDMARK)
    print(f"wrote icons under {ICON_DIR}")


if __name__ == "__main__":
    main()
