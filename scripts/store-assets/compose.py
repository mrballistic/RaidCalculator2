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
  python compose.py                      render every shot in SHOTS
  python compose.py --only 03-saved-setup
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
    "ipad": {"radius": 0.058, "bezel": 0.030, "island": False},
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


def font(px):
    f = ImageFont.truetype(SF, max(8, round(px)))
    # Axes: Width, Optical Size, GRAD, Weight. 96 is the display cut.
    f.set_variation_by_axes([100, 96, 400, 700])
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


def fit_headline(d, text, max_w, size, max_lines=2):
    """Largest size (down to 70%) at which the headline fits max_lines."""
    s = size
    while s > size * 0.7:
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
    return body


def compose(raw, out, size, bg, headline, kind):
    check_copy(headline)
    W, H = size
    pal = BACKGROUNDS[bg]
    canvas = Image.new("RGBA", size, pal["bg"] + (255,))
    d = ImageDraw.Draw(canvas)
    shot = Image.open(raw)
    if H >= W:
        # Headline across the top, device centred beneath it, all inside the
        # middle ~80% width.
        margin_top = H * 0.055
        f, lines = fit_headline(d, headline, W * 0.84, W * 0.088)
        text_h = draw_lines(d, lines, f, pal["ink"], 0, W, margin_top, "center")
        gap, bottom = H * 0.035, H * 0.035
        avail_h = H - (margin_top + text_h + gap) - bottom
        spec = DEVICES[kind]
        ratio = shot.height / shot.width
        # Solve screen width so the framed device fits both ways.
        b = spec["bezel"]
        sw = min(W * 0.80 / (1 + 2 * b), avail_h / (ratio + 2 * b))
        body = device(shot, round(sw), kind)
        x = (W - body.width) // 2
        y = round(margin_top + text_h + gap + (avail_h - body.height) / 2)
        canvas.alpha_composite(body, (x, y))
    else:
        # Landscape: headline on the left 36%, device on the right, both
        # vertically centred inside the middle 75% height.
        f, lines = fit_headline(d, headline, W * 0.30, H * 0.085, max_lines=3)
        asc, desc = f.getmetrics()
        text_h = round((asc + desc) * 1.08) * len(lines)
        draw_lines(d, lines, f, pal["ink"], W * 0.08, W * 0.30, (H - text_h) / 2, "left")
        spec = DEVICES[kind]
        ratio = shot.height / shot.width
        max_w, max_h = W * 0.52, H * 0.80
        sw = min(max_w, max_h / ratio)
        body = device(shot, round(sw), kind)
        x = round(W * 0.92 - body.width)
        y = (H - body.height) // 2
        canvas.alpha_composite(body, (x, y))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    canvas.convert("RGB").save(out, "PNG", optimize=True)
    return out


# (set folder, file name, raw capture, size, background, device, headline)
SHOTS = [
    ("iphone-1320x2868", "03-saved-setup", "iphone-nas-saved-light.png", (1320, 2868),
     "orange", "iphone", "See what your next drive adds"),
    ("iphone-1320x2868", "04-rebuild-caution", "iphone-raid5-caution-dark.png", (1320, 2868),
     "indigo", "iphone", "Warns you before a risky rebuild"),
]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--only", help="render only this file name from SHOTS")
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
    for folder, name, raw, size, bg, kind, headline in SHOTS:
        if a.only and a.only != name:
            continue
        src = os.path.join(RAW, raw)
        if not os.path.exists(src):
            print(f"skip {name}: missing {src}", file=sys.stderr)
            continue
        print(compose(src, os.path.join(OUT, folder, f"{name}.png"), size, bg, headline, kind))


if __name__ == "__main__":
    main()
