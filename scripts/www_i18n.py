#!/usr/bin/env python3
"""Website translations: www/assets/i18n/<lang>.json, applied by assets/i18n.js.

  scripts/www_i18n.py annotate   # one-off: tag the pages' copy with data-i18n keys
  scripts/www_i18n.py extract    # write en.json from the tagged pages (rerun after editing English)
  scripts/www_i18n.py check      # every language has every key, with the same markup

The HTML stays the English source. Text elements carry data-i18n="<key>" and
their translation replaces the element's inner HTML; attributes carry
data-i18n-<attr>="<key>" (alt, aria-label, content). Values may hold the same
inline markup and entities as the English (<a>, <br>, &nbsp;, &#8209;).
"""
import html
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "www"
PAGES = {"index": ROOT / "index.html", "privacy": ROOT / "privacy" / "index.html"}
I18N = ROOT / "assets" / "i18n"
LANGS = ["en", "es", "fr", "it", "ja", "de", "zh-Hant", "zh-Hans", "ko", "pt-BR"]
# Strings that are names, not copy.
KEEP = {"RAID Calculator", "mrBallistic", "mrballistic.com", "mrballistic@gmail.com"}
# Copy the scripts create, which no page contains.
SCRIPT_STRINGS = {
    "consent.label": "Analytics cookies",
    "consent.text": "This site uses Google Analytics cookies to count visits. The app itself collects nothing.",
    "consent.policy": "Privacy policy",
    "consent.decline": "Decline",
    "consent.accept": "Accept",
    "lang.label": "Language",
    "privacy.note": "This translation is provided for convenience. If it differs from the English version, the English version applies.",
}

INLINE = r"(?:<a\b[^>]*>|</a>|<br>|<strong>|</strong>|<em>|</em>)"
LEAF = re.compile(
    r"<(title|h1|h2|h3|p|li|figcaption|strong|span|a|button|div)(\s[^>]*)?>"
    r"((?:[^<]|" + INLINE + r")*?)</\1>", re.S)
ATTRS = ("alt", "aria-label", "content")


def visible(inner):
    text = html.unescape(re.sub(r"<[^>]+>", "", inner)).strip()
    return text if re.search(r"[A-Za-z]{3,}", text) and text not in KEEP else None


def annotate():
    for page, path in PAGES.items():
        src = path.read_text(encoding="utf-8")
        head, body = src.split("<body", 1) if page else (src, "")
        n = 0

        def tag_leaf(m):
            nonlocal n
            name, attrs, inner = m.group(1), m.group(2) or "", m.group(3)
            if "data-i18n" in attrs or " lang=" in attrs or not visible(inner):
                return m.group(0)
            # A link inside a tagged paragraph is translated with it.
            n += 1
            return f'<{name}{attrs} data-i18n="{page}.{n:03d}">{inner}</{name}>'

        def tag_attr(m):
            nonlocal n
            tag = m.group(0)
            for attr in ATTRS:
                v = re.search(rf'\s{attr}="([^"]*)"', tag)
                if not v or f"data-i18n-{attr}" in tag or not visible(v.group(1)):
                    continue
                if attr == "content" and not re.search(r'(name|property)="(description|og:title|og:description|og:image:alt|twitter:title|twitter:description|twitter:image:alt)"', tag):
                    continue
                n += 1
                tag = tag[:-1].rstrip("/").rstrip() + f' data-i18n-{attr}="{page}.{n:03d}">'
            return tag

        # Titles and meta tags in the head; copy and attributes in the body.
        head = re.sub(r"<title>.*?</title>", lambda m: tag_leaf(LEAF.match(m.group(0))), head, flags=re.S)
        head = re.sub(r"<meta\s[^>]*>", tag_attr, head)
        # Innermost first: tag leaves, then attributes on any tag.
        body = LEAF.sub(tag_leaf, body)
        body = re.sub(r"<(?:img|span|a|section|nav|select)\s[^>]*>", tag_attr, body)
        path.write_text(head + "<body" + body, encoding="utf-8")
        print(f"{path.relative_to(ROOT)}: {n} keys")


def strings(path):
    src = path.read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'<(\w+)(\s[^>]*?)data-i18n="([^"]+)"([^>]*)>(.*?)</\1>', src, re.S):
        out[m.group(3)] = m.group(5).strip()
    for m in re.finditer(r"<\w+\s[^>]*>", src):
        tag = m.group(0)
        for attr in ATTRS:
            k = re.search(rf'data-i18n-{attr}="([^"]+)"', tag)
            v = re.search(rf'\s{attr}="([^"]*)"', tag)
            if k and v:
                out[k.group(1)] = html.unescape(v.group(1))
    return out


def extract():
    en = {}
    for path in PAGES.values():
        en.update(strings(path))
    en.update(SCRIPT_STRINGS)
    I18N.mkdir(parents=True, exist_ok=True)
    (I18N / "en.json").write_text(json.dumps(en, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"en.json: {len(en)} strings")


def markup(value):
    return re.findall(r"<[^>]+>|&[a-z#0-9]+;", value)


def check():
    en = json.loads((I18N / "en.json").read_text(encoding="utf-8"))
    problems = []
    for lang in LANGS[1:]:
        path = I18N / f"{lang}.json"
        if not path.exists():
            problems.append(f"{lang}: missing {path.name}")
            continue
        tr = json.loads(path.read_text(encoding="utf-8"))
        for key, value in en.items():
            if key not in tr or not tr[key].strip():
                problems.append(f"{lang}: {key} missing")
            elif [t for t in markup(value) if t.startswith("<")] != [t for t in markup(tr[key]) if t.startswith("<")]:
                problems.append(f"{lang}: {key} markup differs from English")
            elif '"' in re.sub(r"<[^>]+>", "", tr[key]):
                problems.append(f"{lang}: {key} has a straight quote")
        problems += [f"{lang}: {k} isn't in en.json" for k in tr if k not in en]
        for badge in (f"app-store-{lang}.svg", f"google-play-{lang}.png"):
            if not (ROOT / "assets" / "badges" / badge).is_file():
                problems.append(f"{lang}: missing assets/badges/{badge}")
    print("\n".join(problems) or f"{len(LANGS) - 1} languages × {len(en)} strings: ok")
    return 1 if problems else 0


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "annotate":
        annotate()
    elif command == "extract":
        extract()
    elif command == "check":
        sys.exit(check())
    else:
        sys.exit(__doc__)
