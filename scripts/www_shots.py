#!/usr/bin/env python3
"""The website's app screenshots in each language: www/assets/l10n/<lang>/.

  /tmp/raid-assets/venv/bin/python scripts/www_shots.py <screenshots dir> [<lang>...]

<screenshots dir> is marketing/screenshots/1.7.1 from the release/1.7.1
branch (or main once it's merged): its raw/<lang>/ holds the App Store
captures and web/<lang>/ the extra scenes from
`WEB=1 scripts/store-assets/capture_localized.sh`. Each output keeps the
English file's name and pixel size, so i18n.js can swap [data-shot] images
by language and the alt text, which describes the same setups, still fits.
The iPhone Duo and Android images, and the 日本語 example, stay English.
"""
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent / "www" / "assets"
LANGS = ["es", "fr", "it", "ja", "de", "zh-Hant", "zh-Hans", "ko", "pt-BR", "ru"]
IPHONE, IPAD = "iphone-1320x2868", "ipad-2064x2752"

# site image -> (folder, set, raw scene). The size and the top crop come from
# the English file, which is a scaled capture, cropped from the top for iPad.
SHOTS = {
    "17-iphone-nas-shr-light": ("raw", IPHONE, "01-usable-space-light"),
    "17-iphone-raid5-caution-dark": ("raw", IPHONE, "04-rebuild-caution-dark"),
    "17-iphone-raid6-invalid-light": ("raw", IPHONE, "05-invalid-fix-light"),
    "17-iphone-raid5-caution-light": ("web", IPHONE, "04-rebuild-caution-light"),
    "17-iphone-nas-saved-dark": ("web", IPHONE, "03-saved-setup-dark"),
    "08-iphone-raid-raid10-dark": ("web", IPHONE, "07-raid10-dark"),
    "17-ipad-nas-saved-light": ("web", IPAD, "03-saved-setup-light"),
    "17-ipad-unraid-30-bays-dark": ("web", IPAD, "06-thirty-bays-dark"),
}


def latest(path):
    """Raws are never overwritten; a re-capture is -v2, -v3... Use the newest."""
    best, n = path, 2
    while path.with_name(f"{path.stem}-v{n}{path.suffix}").exists():
        best = path.with_name(f"{path.stem}-v{n}{path.suffix}")
        n += 1
    return best


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    shots = pathlib.Path(sys.argv[1])
    langs = sys.argv[2:] or LANGS
    missing = []
    for lang in langs:
        out_dir = ROOT / "l10n" / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        for name, (folder, kind, scene) in SHOTS.items():
            src = latest(shots / folder / lang / kind / f"{scene}.png")
            if not src.exists():
                missing.append(str(src))
                continue
            w, h = Image.open(ROOT / f"{name}.webp").size
            im = Image.open(src).convert("RGB")
            # Same width, then the English file's aspect from the top.
            scale = w / im.width
            im = im.crop((0, 0, im.width, round(h / scale))).resize((w, h), Image.LANCZOS)
            im.save(out_dir / f"{name}.webp", "WEBP", quality=82, method=6)
        print(f"{lang}: {len(SHOTS)} images in {out_dir.relative_to(ROOT.parent.parent)}")
    if missing:
        sys.exit("missing raws:\n  " + "\n  ".join(missing))


if __name__ == "__main__":
    main()
