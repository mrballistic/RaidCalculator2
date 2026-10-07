"""Composed App Store screenshots for RAID Calculator.

Each image is one short headline and the device on a flat background, nothing
else. Rendered natively at the exact Apple size (never stretched from a
master), saved as PNG with no alpha channel.

Backgrounds (and the only headline colors allowed on them):
  orange  #FF9500 with near-black #1C1917 text (8:1)
  indigo  #5856D6 with white text (5.6:1)
Typeface: SF Pro Display (the variable /System/Library/Fonts/SFNS.ttf at a
display optical size, Bold).

Usage:
  python compose.py --headers --contact  render everything, plus contact sheets
  python compose.py --only iphone        shots whose set or name contains this
  python compose.py --raw shot.png --out out.png --size 1320x2868 \
      --bg orange --device iphone --headline "See what your next drive adds"

Paths in SHOTS are relative to the repo root.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW = os.path.join(REPO, "marketing/screenshots/1.7.0/raw")
OUT = os.path.join(REPO, "marketing/screenshots/1.7.0/store")
SF = "/System/Library/Fonts/SFNS.ttf"

BACKGROUNDS = {
    "orange": {"bg": (0xFF, 0x95, 0x00), "ink": (0x1C, 0x19, 0x17)},
    "indigo": {"bg": (0x58, 0x56, 0xD6), "ink": (0xFF, 0xFF, 0xFF)},
}

# Screen corner radius and bezel, as fractions of the screen's short side.
# iPhone 17 Pro Max: about 62 pt corners on a 440 pt wide screen.
DEVICES = {
    "iphone": {"radius": 0.141, "bezel": 0.024, "island": True},
    "ipad": {"radius": 0.035, "bezel": 0.030, "island": False},
    "duo-outer": {"radius": 0.090, "bezel": 0.024, "island": False},
    "duo-inner": {"radius": 0.060, "bezel": 0.020, "island": False},
}
BEZEL = (0x0A, 0x0A, 0x0B)
SS = 4  # supersampling for anti-aliased rounded corners


def luminance(rgb):
    def ch(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


for name, pair in BACKGROUNDS.items():
    assert contrast(pair["bg"], pair["ink"]) >= 4.5, f"{name}: headline contrast below 4.5:1"


def font(px, weight=700):
    f = ImageFont.truetype(SF, max(8, round(px)))
    # Axes: Width, Optical Size, GRAD, Weight. 96 is the display cut.
    f.set_variation_by_axes([100, 96, 400, weight])
    return f


def check_copy(text):
    """The store copy rules that a machine can check."""
    problems = []
    if "—" in text:
        problems.append("em dash")
    if '"' in text or "'" in text:
        problems.append("straight quote (use curly)")
    for bad in ("IPHONE", "IPAD", "iPhones", "iPads", "Iphone", "Ipad"):
        if bad in text:
            problems.append(f"Apple mark misspelled: {bad}")
    if problems:
        raise SystemExit(f"copy rule broken in {text!r}: {', '.join(problems)}")


def wrap(d, text, f, max_w):
    """Greedy wrap, then rebalance two lines so neither is a lone word."""
    words, lines, line = text.split(), [], ""
    for w in words:
        trial = f"{line} {w}".strip()
        if d.textlength(trial, font=f) <= max_w or not line:
            line = trial
        else:
            lines.append(line)
            line = w
    lines.append(line)
    if len(lines) == 2:
        best = None
        for i in range(1, len(words)):
            a, b = " ".join(words[:i]), " ".join(words[i:])
            wa, wb = d.textlength(a, font=f), d.textlength(b, font=f)
            if max(wa, wb) <= max_w and (best is None or abs(wa - wb) < best[0]):
                best = (abs(wa - wb), [a, b])
        if best:
            lines = best[1]
    return lines


def fit_headline(d, text, max_w, size, max_lines=2, floor=0.7):
    """Largest size (down to `floor` of `size`) at which the headline fits max_lines."""
    s = size
    while s > size * floor:
        f = font(s)
        lines = wrap(d, text, f, max_w)
        if len(lines) <= max_lines and all(d.textlength(l, font=f) <= max_w for l in lines):
            return f, lines
        s *= 0.96
    f = font(s)
    return f, wrap(d, text, f, max_w)


def draw_lines(d, lines, f, ink, box_x, box_w, top, align, leading=1.08):
    asc, desc = f.getmetrics()
    step = round((asc + desc) * leading)
    for i, line in enumerate(lines):
        w = d.textlength(line, font=f)
        x = box_x + (box_w - w) / 2 if align == "center" else box_x
        d.text((x, top + i * step), line, font=f, fill=ink)
    return step * len(lines) - (step - asc - desc)


def rounded_mask(size, radius):
    w, h = size
    big = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], radius=radius * SS, fill=255)
    return big.resize(size, Image.LANCZOS)


def device(shot, screen_w, kind):
    """The capture as a device: a slim near-black bezel following the screen's
    real corner radius, plus the Dynamic Island on iPhone (simulator captures
    leave it out). Returns an RGBA image."""
    spec = DEVICES[kind]
    shot = shot.convert("RGB")
    scale = screen_w / shot.width
    screen = shot.resize((screen_w, round(shot.height * scale)), Image.LANCZOS)
    short = min(screen.size)
    r = round(short * spec["radius"])
    bezel = max(4, round(short * spec["bezel"]))
    W, H = screen.width + 2 * bezel, screen.height + 2 * bezel
    body = Image.new("RGBA", (W, H), BEZEL + (0,))
    body.putalpha(rounded_mask((W, H), r + bezel))
    body.paste(screen, (bezel, bezel), rounded_mask(screen.size, r))
    if spec["island"] and screen.height > screen.width:
        iw, ih = screen.width * 0.286, screen.width * 0.084
        top = bezel + screen.width * 0.025
        x0 = (W - iw) / 2
        isl = Image.new("L", (W * SS, H * SS), 0)
        ImageDraw.Draw(isl).rounded_rectangle(
            [x0 * SS, top * SS, (x0 + iw) * SS, (top + ih) * SS], radius=ih / 2 * SS, fill=255)
        isl = isl.resize((W, H), Image.LANCZOS)
        body.paste(Image.new("RGBA", (W, H), (0, 0, 0, 255)), (0, 0), isl)
    body.info["radius"] = r + bezel
    return body


# Flat long shadow: the device silhouette swept 45 degrees down and to the
# right, hard-edged, black at SHADOW_ALPHA. Length is a fraction of the
# device's short side, the same on every image.
SHADOW_ALPHA = 0.20
SHADOW_LENGTH = 0.45
SHADOW_SS = 2  # supersampling for anti-aliased edges


def long_shadow(canvas, x, y, w, h, radius):
    """Draw the swept silhouette of the rounded rect (x, y, w, h). A convex
    shape swept along a line is the hull of its two end copies, so it's two
    rounded rects plus the band joining their 45-degree tangent points."""
    W, H = canvas.size
    k = SHADOW_SS
    L = SHADOW_LENGTH * min(w, h) * k
    x0, y0, x1, y1, r = x * k, y * k, (x + w) * k, (y + h) * k, radius * k
    m = Image.new("L", (W * k, H * k), 0)
    d = ImageDraw.Draw(m)
    for t in (0, L):
        d.rounded_rectangle([x0 + t, y0 + t, x1 + t, y1 + t], radius=r, fill=255)
    c = r * (1 - 2 ** -0.5)
    tr, bl = (x1 - c, y0 + c), (x0 + c, y1 - c)
    d.polygon([tr, (tr[0] + L, tr[1] + L), (bl[0] + L, bl[1] + L), bl], fill=255)
    m = m.resize((W, H), Image.LANCZOS).point(lambda a: round(a * SHADOW_ALPHA))
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    shade.putalpha(m)
    canvas.alpha_composite(shade)


def place(canvas, body, x, y):
    """Shadow first, then the device, both clipped to the canvas."""
    x, y = round(x), round(y)
    long_shadow(canvas, x, y, body.width, body.height, body.info.get("radius", 0))
    W, H = canvas.size
    visible = body.crop((max(0, -x), max(0, -y), min(body.width, W - x), min(body.height, H - y)))
    canvas.alpha_composite(visible, (max(0, x), max(0, y)))


def compose(raw, out, size, bg, headline, kind, text_frac=0.20, bleed=False, eyebrow=None):
    """Portrait canvases: headline on top, device beneath. Landscape canvases:
    headline in a left column `text_frac` of the width, device on the right.
    With `bleed` (headers: a portrait phone on a wide canvas) the phone runs
    off the bottom edge so it can be large while its top stays in the safe area.
    `eyebrow` (landscape only) is a secondary line above the headline, in
    Medium at 45% of the headline's size."""
    check_copy(headline)
    if eyebrow:
        check_copy(eyebrow)
    W, H = size
    pal = BACKGROUNDS[bg]
    canvas = Image.new("RGBA", size, pal["bg"] + (255,))
    d = ImageDraw.Draw(canvas)
    shot = Image.open(raw)
    spec = DEVICES[kind]
    b = spec["bezel"]
    ratio = shot.height / shot.width
    short = min(1, ratio)
    if H >= W:
        # Headline across the top, device centred beneath it, inside the
        # middle ~84% width.
        margin_top = H * 0.05
        f, lines = fit_headline(d, headline, W * 0.84, min(W, H / 2.17) * 0.088)
        text_h = draw_lines(d, lines, f, pal["ink"], 0, W, margin_top, "center")
        gap, bottom = H * 0.03, H * 0.03
        avail_h = H - (margin_top + text_h + gap) - bottom
        sw = min(W * 0.84 / (1 + 2 * b * short), avail_h / (ratio + 2 * b * short))
        body = device(shot, round(sw), kind)
        x = (W - body.width) / 2
        y = margin_top + text_h + gap + (avail_h - body.height) / 2
        draw_text = None
    else:
        # Landscape: headline left, device right, the pair centred as one
        # group inside the middle ~88% width.
        if bleed or eyebrow:
            f, lines = fit_headline(d, headline, W * text_frac, H * 0.09, max_lines=2, floor=0.6)
        else:
            # Prefer three lines unless that costs more than 20% in size
            # over four (a lone short word on its own line reads badly).
            f, lines = fit_headline(d, headline, W * text_frac, H * 0.09, max_lines=4, floor=0.6)
            f3, lines3 = fit_headline(d, headline, W * text_frac * 1.15, H * 0.09, max_lines=3, floor=0.6)
            if len(lines3) <= 3 and f3.size >= f.size * 0.8:
                f, lines = f3, lines3
        asc, desc = f.getmetrics()
        text_h = round((asc + desc) * 1.08) * len(lines) - round((asc + desc) * 0.08)
        text_w = max(d.textlength(l, font=f) for l in lines)
        eb = None
        if eyebrow:
            ef = font(f.size * 0.45, weight=510)
            e_asc, e_desc = ef.getmetrics()
            e_gap = round(f.size * 0.30)
            text_w = max(text_w, d.textlength(eyebrow, font=ef))
            eb = (ef, e_asc + e_desc + e_gap)
            text_h += eb[1]
        gap = W * 0.04
        if bleed:
            # Phone 1.1x the canvas height, top at 12.5%, bottom cropped.
            sw = H * 1.10 / (ratio + 2 * b)
        else:
            room_w = W * 0.88 - text_w - gap
            sw = min(room_w / (1 + 2 * b * short), H * 0.80 / (ratio + 2 * b * short))
        body = device(shot, round(sw), kind)
        x0 = (W - (text_w + gap + body.width)) / 2
        x = x0 + text_w + gap
        y = H * 0.125 if bleed else (H - body.height) / 2
        text_y = (H - text_h) / 2 - desc / 2
        if bleed:
            # Centre the headline on the visible part of the phone.
            text_y = (y + H) / 2 - text_h / 2 - desc / 2
        draw_text = (lines, f, x0, text_w, text_y, eyebrow, eb)
    place(canvas, body, x, y)
    if draw_text:
        lines, f, tx, tw, ty, eyebrow, eb = draw_text
        if eyebrow:
            d.text((tx, ty), eyebrow, font=eb[0], fill=pal["ink"])
            ty += eb[1]
        draw_lines(d, lines, f, pal["ink"], tx, tw, ty, "left")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    canvas.convert("RGB").save(out, "PNG", optimize=True)
    return out


def latest(path):
    """A raw is never overwritten; a re-capture is saved as -v2, -v3... Use the newest."""
    base, ext = os.path.splitext(path)
    n, best = 2, path
    while os.path.exists(f"{base}-v{n}{ext}"):
        best = f"{base}-v{n}{ext}"
        n += 1
    return best


def contact_sheet(folder):
    """One row of every image in a set, on neutral grey, beside the set."""
    files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
    if not files:
        return None
    ims = [Image.open(os.path.join(folder, f)).convert("RGB") for f in files]
    h = 900 if ims[0].height >= ims[0].width else 560
    thumbs = [im.resize((round(im.width * h / im.height), h), Image.LANCZOS) for im in ims]
    gap = 24
    sheet = Image.new("RGB", (sum(t.width for t in thumbs) + gap * (len(thumbs) + 1), h + 2 * gap), (236, 236, 238))
    x = gap
    for t in thumbs:
        sheet.paste(t, (x, gap))
        x += t.width + gap
    out = os.path.join(os.path.dirname(folder.rstrip("/")), f"contact-{os.path.basename(folder.rstrip('/'))}.png")
    sheet.save(out, "PNG", optimize=True)
    return out


# Raw captures live in raw/<set>/<NN-scene>-<light|dark>.png.
IPHONE, IPAD = (1320, 2868), (2064, 2752)
DUO_OP, DUO_OL, DUO_IP, DUO_IL = (1398, 2034), (2034, 1398), (2007, 2853), (2853, 2007)
USABLE = "Know your real usable space"
COMPARE = "Every system, same drives"
SAVED = "See what your next drive adds"
REBUILD = "Warns you before a risky rebuild"
DUO = "Built for iPhone Duo"

# (store set, file name, raw path under RAW, size, background, device, headline)
SHOTS = [
    ("iphone-1320x2868", "01-usable-space", "iphone-1320x2868/01-usable-space-light.png", IPHONE, "orange", "iphone", USABLE),
    ("iphone-1320x2868", "02-compare-systems", "iphone-1320x2868/02-compare-systems-light.png", IPHONE, "indigo", "iphone", COMPARE),
    ("iphone-1320x2868", "03-saved-setup", "iphone-1320x2868/03-saved-setup-light.png", IPHONE, "orange", "iphone", SAVED),
    ("iphone-1320x2868", "04-rebuild-caution", "iphone-1320x2868/04-rebuild-caution-dark.png", IPHONE, "indigo", "iphone", REBUILD),
    ("iphone-1320x2868", "05-invalid-fix", "iphone-1320x2868/05-invalid-fix-light.png", IPHONE, "orange", "iphone", "One tap to a valid setup"),
    ("iphone-1320x2868", "06-thirty-bays", "iphone-1320x2868/06-thirty-bays-light.png", IPHONE, "indigo", "iphone", "Up to 30 bays, drawn to scale"),
    ("ipad-2064x2752", "01-usable-space", "ipad-2064x2752/01-usable-space-light.png", IPAD, "orange", "ipad", USABLE),
    ("ipad-2064x2752", "02-rebuild-caution", "ipad-2064x2752/02-rebuild-caution-dark.png", IPAD, "indigo", "ipad", REBUILD),
    ("ipad-2064x2752", "03-thirty-bays", "ipad-2064x2752/06-thirty-bays-light.png", IPAD, "orange", "ipad", "Up to 30 bays, drawn to scale"),
    ("duo-inner-2853x2007", "01-built-for-duo", "duo-inner-2853x2007/01-usable-space-light.png", DUO_IL, "orange", "duo-inner", DUO),
    ("duo-inner-2853x2007", "02-rebuild-caution", "duo-inner-2853x2007/02-rebuild-caution-dark.png", DUO_IL, "indigo", "duo-inner", REBUILD),
    ("duo-inner-2007x2853", "01-built-for-duo", "duo-inner-2007x2853/01-usable-space-light.png", DUO_IP, "orange", "duo-inner", DUO),
    ("duo-inner-2007x2853", "02-rebuild-caution", "duo-inner-2007x2853/02-rebuild-caution-dark.png", DUO_IP, "indigo", "duo-inner", REBUILD),
    ("duo-outer-1398x2034", "01-usable-space", "duo-outer-1398x2034/01-usable-space-light.png", DUO_OP, "orange", "duo-outer", USABLE),
    ("duo-outer-1398x2034", "02-rebuild-caution", "duo-outer-1398x2034/02-rebuild-caution-dark.png", DUO_OP, "indigo", "duo-outer", REBUILD),
    ("duo-outer-2034x1398", "01-usable-space", "duo-outer-2034x1398/01-usable-space-light.png", DUO_OL, "orange", "duo-outer", USABLE),
    ("duo-outer-2034x1398", "02-rebuild-caution", "duo-outer-2034x1398/02-rebuild-caution-dark.png", DUO_OL, "indigo", "duo-outer", REBUILD),
]

# Header / search images, each laid out natively:
# (file name, size, headline column width, raw, device, headline, bleed[, eyebrow]).
# 21:9 (3840x1646) is the product page header; 16:9 serves both; 3:2 is search.
HEADER_RAW = "iphone-1320x2868/01-usable-space-light.png"
DUO_HEADER_RAW = "duo-inner-2853x2007/01-usable-space-light.png"
HEADERS = [
    ("header-5244x2950", (5244, 2950), 0.40, HEADER_RAW, "iphone", USABLE, True, None),
    ("header-3840x2560", (3840, 2560), 0.44, HEADER_RAW, "iphone", USABLE, True, None),
    ("header-1920x1280", (1920, 1280), 0.44, HEADER_RAW, "iphone", USABLE, True, None),
    ("header-3840x1646", (3840, 1646), 0.40, HEADER_RAW, "iphone", USABLE, True, None),
    ("header-3840x1646-duo", (3840, 1646), 0.40, DUO_HEADER_RAW, "duo-inner", USABLE, False, DUO),
]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--only", help="render only shots whose store set or file name contains this")
    p.add_argument("--headers", action="store_true", help="also render the header / search images")
    p.add_argument("--contact", action="store_true", help="also write a contact sheet per set")
    p.add_argument("--raw")
    p.add_argument("--out")
    p.add_argument("--size", help="WxH, e.g. 1320x2868")
    p.add_argument("--bg", choices=sorted(BACKGROUNDS))
    p.add_argument("--device", choices=sorted(DEVICES), default="iphone")
    p.add_argument("--headline")
    a = p.parse_args()
    if a.raw:
        if not (a.out and a.size and a.bg and a.headline):
            p.error("--raw needs --out, --size, --bg and --headline")
        w, h = (int(v) for v in a.size.lower().split("x"))
        print(compose(a.raw, a.out, (w, h), a.bg, a.headline, a.device))
        return
    sets = set()
    for folder, name, raw, size, bg, kind, headline in SHOTS:
        if a.only and a.only not in folder and a.only not in name:
            continue
        src = latest(os.path.join(RAW, raw))
        if not os.path.exists(src):
            print(f"skip {folder}/{name}: missing {src}", file=sys.stderr)
            continue
        print(compose(src, os.path.join(OUT, folder, f"{name}.png"), size, bg, headline, kind))
        sets.add(folder)
    if a.headers:
        for name, size, frac, raw, kind, headline, bleed, eyebrow in HEADERS:
            src = latest(os.path.join(RAW, raw))
            if not os.path.exists(src):
                print(f"skip header/{name}: missing {src}", file=sys.stderr)
                continue
            out = os.path.join(OUT, "header", f"{name}.png")
            print(compose(src, out, size, "orange", headline, kind, frac, bleed=bleed, eyebrow=eyebrow))
        sets.add("header")
    if a.contact:
        for folder in sorted(sets):
            sheet = contact_sheet(os.path.join(OUT, folder))
            if sheet:
                print(sheet)


if __name__ == "__main__":
    main()
