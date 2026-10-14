#!/usr/bin/env python3
"""Writes marketing/app-store-listing-1.7.1.md from store-copy-1.7.1.json.

  python3 -I scripts/store-assets/listing/store_copy_doc.py

The JSON (beside this script) holds every language's App Store copy, and
check_store_copy.py (also here) enforces the store rules on it. Edit the
JSON, run the checker, then this.
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
COPY = json.loads((HERE / "store-copy-1.7.1.json").read_text(encoding="utf-8"))
NAMES = {"en": "English (U.S.)", "es": "Spanish (Spain)", "fr": "French", "it": "Italian", "ja": "Japanese",
         "de": "German", "zh-Hant": "Chinese, Traditional", "zh-Hans": "Chinese, Simplified", "ko": "Korean",
         "pt-BR": "Portuguese (Brazil)", "ru": "Russian"}
FIELDS = [("name", "Name", 30), ("subtitle", "Subtitle", 30), ("promo", "Promotional text", 170),
          ("description", "Description", 4000), ("keywords", "Keywords", 100), ("whats_new", "What’s New in This Version", 4000)]


def block(text):
    return "\n".join("> " + line if line else ">" for line in text.split("\n"))


out = [
    "# App Store listing: RAID Calculator 1.7.1",
    "",
    "Record “RAID calculator” (Apple ID 395601653, bundle ID `53Q4825KDF`). Paste-ready copy for every localization, generated from `scripts/store-assets/listing/store-copy-1.7.1.json` by `store_copy_doc.py`. `check_store_copy.py` enforces the store rules on that file: length limits, no em dashes, no straight quotes, “iPhone” and “iPad” spelled exactly, no trademarks in the name, subtitle or keywords, the trademark lines matching the app, and the register and quote marks of each language.",
    "",
    "1.7.1 adds Russian to the app (eleven languages in all), rewords one line in the RAID 1 and RAID 10 info sheets, and localizes the App Store page. Nothing else in the app changed.",
    "",
    "- **Privacy policy URL** (every localization): `https://mrballistic.com/raid/privacy/`. The page shows in the visitor’s own language.",
    "- **Russian** is a new localization on the record. Add it before pasting its copy.",
    "- **Translations are machine-assisted.** Have a native speaker check each one before it’s submitted (DEPLOY.md release checklist, step 5).",
    "",
    "## Screenshots",
    "",
    "| Language | iPhone 6.9″, 6.3″, 6.1″ | iPad 13″ | iPhone Duo, closed (1398 × 2034) | Header and search |",
    "|---|---|---|---|---|",
    "| English | `marketing/screenshots/1.7.0/store/iphone-*` | `…/1.7.0/store/ipad-2064x2752` | `…/1.7.0/store/duo-outer-1398x2034` | `…/1.7.0/store/header` |",
    "| All others | `marketing/screenshots/1.7.1/store/<lang>/iphone-*` | `…/1.7.1/store/<lang>/ipad-2064x2752` | `…/1.7.1/store/<lang>/duo-outer-1398x2034` | `…/1.7.1/store/<lang>/header` |",
    "",
    "Each localized set has the same scenes as English, with the app running in that language: six on iPhone, three on iPad and two on the closed Duo. The other Duo poses (closed landscape and open) stay as in 1.7.0, English in every language. Each folder has a contact sheet.",
    "",
    "To rebuild a set, run `scripts/store-assets/capture_localized.sh iphone|ipad <lang>…`. For the closed Duo, run `L10N=<lang> scripts/store-assets/capture_duo.sh outer-portrait` with the RAID Duo Simulator closed and upright.",
    "",
    "## App Review notes for 1.7.1",
    "",
    "> This update adds a Russian localization of the app and localizes the App Store page with screenshots in each of the app’s eleven languages. No functionality changed. Apart from the version number (1.7.0 to 1.7.1), the only changes are the new Russian strings and a clearer wording of one line in the RAID 1 and RAID 10 info sheets. The app works fully offline with no account, as in 1.7.0.",
    "",
]
for lang, name in NAMES.items():
    c = COPY[lang]
    out += [f"## {name} (`{lang}`)", ""]
    for key, label, limit in FIELDS:
        text = c[key]
        body = text if key in ("name", "subtitle", "keywords") else block(text)
        out += [f"### {label} ({limit})", "", body, "", f"{len(text)} chars.", ""]
(REPO / "marketing" / "app-store-listing-1.7.1.md").write_text("\n".join(out), encoding="utf-8")
print("wrote marketing/app-store-listing-1.7.1.md:", ", ".join(NAMES))
