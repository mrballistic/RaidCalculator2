#!/usr/bin/env python3
"""Add, remove and check strings in RaidCalculator2/Localizable.xcstrings.

  scripts/strings.py add new-strings.json   # {"key": {"en": "…", "es": "…", …}}
  scripts/strings.py remove key [key …]
  scripts/strings.py check                   # every language in LANGS, matching specifiers

Never hand-edit the catalog JSON; Xcode and this script both rewrite it.
"""
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = pathlib.Path(os.environ.get("STRINGS_CATALOG", ROOT / "RaidCalculator2" / "Localizable.xcstrings"))
LANGS = ["en", "es", "fr", "it", "ja", "de", "zh-Hant", "zh-Hans", "ko", "pt-BR"]
# printf-style specifiers as Foundation uses them; %% is a literal percent.
# No space flag: "50% storage" must not parse as a specifier.
SPEC = re.compile(r"%(?:(\d+)\$)?[-+0#]*\d*(?:\.\d+)?(ld|lu|lld|[dif@sucxX])")


def load():
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def save(doc):
    text = json.dumps(doc, ensure_ascii=False, indent=2, sort_keys=True, separators=(",", " : "))
    CATALOG.write_text(text + "\n", encoding="utf-8")


def specifiers(value):
    """Specifier types in argument order, so %1$@ %2$d and %@ %d compare equal."""
    found = []
    for index, match in enumerate(SPEC.finditer(value.replace("%%", ""))):
        position = int(match.group(1)) if match.group(1) else index + 1
        found.append((position, match.group(2)))
    return sorted(found)


def add(path):
    new = json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
    doc = load()
    for key, values in new.items():
        missing = [lang for lang in LANGS if not values.get(lang)]
        if missing:
            sys.exit(f"{key}: missing {', '.join(missing)}")
        doc["strings"][key] = {
            "extractionState": "manual",
            "localizations": {
                lang: {"stringUnit": {"state": "translated", "value": values[lang]}} for lang in LANGS
            },
        }
    save(doc)
    print(f"added {len(new)} key(s)")


def remove(keys):
    doc = load()
    for key in keys:
        if doc["strings"].pop(key, None) is None:
            sys.exit(f"{key}: not in catalog")
    save(doc)
    print(f"removed {len(keys)} key(s)")


def check():
    problems = []
    for key, entry in load()["strings"].items():
        localizations = entry.get("localizations")
        if not localizations or entry.get("shouldTranslate") is False:
            continue  # auto-extracted literals with no translations, such as "TB"
        english = localizations.get("en", {}).get("stringUnit", {}).get("value")
        if english is None:
            problems.append(f"{key}: no English value")
            continue
        for lang in LANGS:
            unit = localizations.get(lang, {}).get("stringUnit", {})
            if unit.get("state") != "translated" or not unit.get("value"):
                problems.append(f"{key}: {lang} missing or untranslated")
            elif specifiers(unit["value"]) != specifiers(english):
                problems.append(f"{key}: {lang} specifiers {specifiers(unit['value'])} ≠ en {specifiers(english)}")
    for line in problems:
        print(line)
    print(f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    command, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("", [])
    if command == "add" and len(args) == 1:
        add(args[0])
    elif command == "remove" and args:
        remove(args)
    elif command == "check" and not args:
        sys.exit(check())
    else:
        sys.exit(__doc__)
