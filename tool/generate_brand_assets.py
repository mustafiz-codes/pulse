#!/usr/bin/env python3
"""Generate the PULSE demo's simple vector-style brand assets.

Run from the project root: python3 tool/generate_brand_assets.py
Requires Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "assets" / "branding"
FONTS = ROOT / "assets" / "fonts"

NAVY = (11, 16, 32, 255)
SURFACE = (24, 34, 53, 255)
LIME = (185, 245, 118, 255)
SKY = (138, 190, 255, 255)

SCALE = 4


def pulse_points(size: int, inset: float = 0.18):
    """Return the heartbeat polyline scaled into a square canvas."""
    w = size
    pad = w * inset
    span = w - pad * 2
    pts = [
        (0.00, 0.55),
        (0.20, 0.55),
        (0.30, 0.55),
        (0.38, 0.34),
        (0.47, 0.75),
        (0.55, 0.44),
        (0.62, 0.55),
        (0.82, 0.55),
        (1.00, 0.55),
    ]
    return [(pad + x * span, pad + y * span) for x, y in pts]


def draw_mark(draw: ImageDraw.ImageDraw, size: int, inset: float, width: int):
    pts = pulse_points(size, inset)
    draw.line(pts, fill=LIME, width=width, joint="curve")
    for x, y in (pts[0], pts[-1]):
        r = width / 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=LIME)
    # Sky accent dot at the peak of the pulse.
    x, y = pts[4]
    r = width * 0.62
    draw.ellipse((x - r, y - r, x + r, y + r), fill=SKY)


def make_icon() -> None:
    size = 1024 * SCALE
    img = Image.new("RGBA", (size, size), NAVY)
    d = ImageDraw.Draw(img)
    # Subtle elevated inner square.
    pad = size * 0.13
    d.rounded_rectangle(
        (pad, pad, size - pad, size - pad),
        radius=size * 0.18,
        fill=SURFACE,
    )
    draw_mark(d, size, inset=0.26, width=int(size * 0.052))
    img.resize((1024, 1024), Image.LANCZOS).save(BRANDING / "app_icon.png")


def make_foreground() -> None:
    size = 1024 * SCALE
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_mark(d, size, inset=0.27, width=int(size * 0.05))
    img.resize((1024, 1024), Image.LANCZOS).save(
        BRANDING / "app_icon_foreground.png"
    )


def make_splash() -> None:
    size = 768 * SCALE
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_mark(d, size, inset=0.22, width=int(size * 0.045))

    font_path = FONTS / "Inter-Bold.ttf"
    if font_path.exists():
        font = ImageFont.truetype(str(font_path), int(size * 0.105))
        text = "PULSE"
        box = d.textbbox((0, 0), text, font=font)
        tw = box[2] - box[0]
        d.text(
            ((size - tw) / 2, size * 0.66),
            text,
            font=font,
            fill=(245, 247, 250, 255),
        )
    img.resize((768, 768), Image.LANCZOS).save(BRANDING / "splash_mark.png")


if __name__ == "__main__":
    BRANDING.mkdir(parents=True, exist_ok=True)
    make_icon()
    make_foreground()
    make_splash()
    print("Brand assets written to", BRANDING)
