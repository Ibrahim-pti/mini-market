#!/usr/bin/env python3
"""Generates the Mini Market app logo (1024x1024 PNG).

A white market storefront with a striped awning on the brand
indigo -> violet gradient. Rendered at 4x and downscaled for smooth edges.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

BASE = 1024
S = 4               # supersampling factor
SIZE = BASE * S

# Brand palette
INDIGO = (79, 70, 229)      # #4F46E5  top of gradient
VIOLET = (124, 58, 237)     # #7C3AED  bottom of gradient
AMBER = (245, 158, 11)      # #F59E0B  awning accent
WHITE = (255, 255, 255)
DOOR = (99, 91, 233)        # slightly lighter indigo for door/windows


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def px(v):
    return int(round(v * S))


def build():
    # 1) Vertical gradient background.
    bg = Image.new("RGB", (SIZE, SIZE), INDIGO)
    gd = ImageDraw.Draw(bg)
    for y in range(SIZE):
        t = y / SIZE
        gd.line([(0, y), (SIZE, y)], fill=lerp(INDIGO, VIOLET, t))

    # Soft diagonal highlight (top-left) for a premium feel.
    glow = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(glow).ellipse(
        [px(-260), px(-320), px(620), px(560)], fill=70
    )
    glow = glow.filter(ImageFilter.GaussianBlur(px(120)))
    white_layer = Image.new("RGB", (SIZE, SIZE), WHITE)
    bg = Image.composite(white_layer, bg, glow)

    icon = bg.convert("RGBA")
    draw = ImageDraw.Draw(icon)

    # 2) Soft shadow behind the storefront group.
    shadow = Image.new("L", (SIZE, SIZE), 0)
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [px(286), px(330), px(738), px(770)], radius=px(30), fill=120
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(px(28)))
    dark = Image.new("RGBA", (SIZE, SIZE), (20, 16, 60, 255))
    icon = Image.composite(
        dark, icon, shadow.point(lambda v: int(v * 0.55))
    )
    draw = ImageDraw.Draw(icon)

    # 3) Shop body (white rounded rectangle).
    draw.rounded_rectangle(
        [px(290), px(440), px(734), px(760)], radius=px(26), fill=WHITE
    )

    # 4) Door (opens to the brand colour) + windows.
    draw.rounded_rectangle(
        [px(452), px(556), px(572), px(760)], radius=px(20), fill=DOOR
    )
    draw.ellipse([px(497), px(642), px(517), px(662)], fill=WHITE)  # handle
    for wx in (px(318), px(606)):
        draw.rounded_rectangle(
            [wx, px(556), wx + px(100), px(648)], radius=px(14), fill=DOOR
        )

    # 5) Striped, scalloped awning.
    ax1, ax2 = px(244), px(780)
    atop, abot = px(300), px(424)
    n = 7
    stripe_w = (ax2 - ax1) / n
    awn = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ad = ImageDraw.Draw(awn)
    for i in range(n):
        x = ax1 + i * stripe_w
        color = AMBER if i % 2 == 0 else WHITE
        ad.rectangle([x, atop, x + stripe_w + 1, abot], fill=color + (255,))
        cx = x + stripe_w / 2
        r = stripe_w / 2
        ad.ellipse([cx - r, abot - r, cx + r, abot + r], fill=color + (255,))
    amask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(amask).rounded_rectangle(
        [ax1, atop, ax2, int(abot + stripe_w / 2)], radius=px(16), fill=255
    )
    awn.putalpha(Image.composite(
        awn.getchannel("A"), Image.new("L", (SIZE, SIZE), 0), amask))
    icon.alpha_composite(awn)
    draw = ImageDraw.Draw(icon)

    # Thin valance line where the awning meets the shop.
    draw.rounded_rectangle(
        [ax1, px(288), ax2, px(312)], radius=px(12), fill=(216, 138, 8, 255)
    )

    # 6) Round the whole icon (small transparent margin for macOS).
    margin = px(60)
    radius = px(232)
    card = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(card).rounded_rectangle(
        [margin, margin, SIZE - margin, SIZE - margin], radius=radius, fill=255
    )
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(icon, (0, 0), card)

    out = out.resize((BASE, BASE), Image.LANCZOS)

    dest_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, "app_logo.png")
    out.save(dest)
    print("Saved", os.path.abspath(dest))


if __name__ == "__main__":
    build()
