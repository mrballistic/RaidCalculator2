"""Check store-copy-1.7.1.json (beside this script) against the App Store rules for RAID Calculator 1.7.1.
Usage: python3 -I check_store_copy.py [path] [--table]
Prints every problem found, or "No problems." Exit status 1 if any problem."""
import json, re, sys

REPO = "/Users/todd.greco/current_work/RaidCalculator2"
args = [a for a in sys.argv[1:] if not a.startswith("--")]
HERE = __import__("pathlib").Path(__file__).resolve().parent
PATH = args[0] if args else str(HERE / "store-copy-1.7.1.json")
data = json.load(open(PATH, encoding="utf-8"))
CAT = json.load(open(f"{REPO}/RaidCalculator2/Localizable.xcstrings", encoding="utf-8"))["strings"]
LINES = {}
for f in ["store-lines-es-fr-it.json", "store-lines-ja-ko-de.json", "store-lines-zh-pt.json"]:
    LINES.update(json.load(open(HERE / f, encoding="utf-8")))
LINES["en"] = {
    "whats_new": "RAID Calculator now speaks Russian, for eleven languages in all. The App Store page now shows the app in your language, too.",
    "languages_bullet": "• English, Spanish, French, Italian, Japanese, German, Traditional and Simplified Chinese, Korean, Brazilian Portuguese and Russian",
}

LANGS = ["en", "es", "fr", "it", "ja", "de", "zh-Hant", "zh-Hans", "ko", "pt-BR", "ru"]
FIELDS = {"name": 30, "subtitle": 30, "promo": 170, "description": 4000, "keywords": 100, "whats_new": 4000}
TRADEMARKS = ["synology", "shr", "unraid", "zfs", "snapraid", "plex"]
QUOTES = set("“”„‟«»‹›「」『』‘‚＂")
ALLOWED_QUOTES = {
    "en": set("“”‘"), "es": set("“”"), "it": set("“”"), "pt-BR": set("“”"),
    "fr": set("«»"), "de": set("„“"), "ja": set("「」『』"), "zh-Hant": set("「」『』"),
    "zh-Hans": set("“”"), "ko": set("“”"), "ru": set("«»"),
}
PAIRS = {"en": [("“", "”")], "es": [("“", "”")], "it": [("“", "”")], "pt-BR": [("“", "”")],
         "fr": [("«", "»")], "de": [("„", "“")], "ja": [("「", "」"), ("『", "』")],
         "zh-Hant": [("「", "」"), ("『", "』")], "zh-Hans": [("“", "”")], "ko": [("“", "”")],
         "ru": [("«", "»")]}
# The language's own word for "English" opens its languages bullet.
ENGLISH_WORD = {"en": "English", "es": "Inglés", "fr": "Anglais", "it": "Inglese", "ja": "英語",
                "de": "Englisch", "zh-Hant": "英文", "zh-Hans": "英语", "ko": "영어",
                "pt-BR": "Inglês", "ru": "Английский"}
RUSSIAN_WORD = {"en": "Russian", "es": "ruso", "fr": "russe", "it": "russo", "ja": "ロシア語",
                "de": "Russisch", "zh-Hant": "俄文", "zh-Hans": "俄语", "ko": "러시아어",
                "pt-BR": "russo", "ru": "русский"}
STALE_TEN = {"en": r"\bten\b|\b10 languages", "es": r"\bdiez\b|10 idiomas", "fr": r"\bdix\b|10 langues",
             "it": r"\bdieci\b|10 lingue", "ja": r"10言語|10か国語|十言語", "de": r"\bzehn\b|10 Sprachen",
             "zh-Hant": r"十種|10 種", "zh-Hans": r"十种|10 种", "ko": r"10개 언어|열 가지",
             "pt-BR": r"\bdez\b|10 idiomas", "ru": r"десят\w* язык|10 язык"}
ELEVEN = {"en": "eleven", "es": "once", "fr": "onze", "it": "undici", "ja": "11言語", "de": "elf",
          "zh-Hant": "十一種", "zh-Hans": "十一种", "ko": "11개 언어", "pt-BR": "onze", "ru": "одиннадцать"}
REGISTER_BAD = {
    "es": r"\b(usted|ustedes|vosotros|vuestr[oa]s?|os)\b",
    "fr": r"\b(tu|toi|ton|ta|tes)\b|\bt’",
    "it": r"(?<![.!?]\s)\b(Lei|Suo|Sua|Suoi|Sue)\b|\b(voi|vostr[oaie])\b",
    "de": r"(?<![.!?:]\s)(?<!^)\b(Sie|Ihr|Ihre|Ihren|Ihrem|Ihrer|Ihres|Ihnen)\b|\b(euch|euer|eure)\b",
    "pt-BR": r"\b(tu|teu|tua|teus|tuas|vós|vosso|vossa)\b",
    "ru": r"(?i)\b(ты|тебя|тебе|тобой|твой|твоя|твоё|твое|твои|твоих|твоим)\b",
}
REGISTER_GOOD = {
    "es": r"\b(tu|tus|te|ti)\b", "fr": r"\b(vous|votre|vos)\b", "it": r"\b(tu|tuo|tua|tuoi|tue|ti)\b",
    "de": r"\b(du|dein\w*|dir|dich)\b", "pt-BR": r"\bvocê\b", "ru": r"(?i)\b(вы|вас|вам|ваш\w*)\b",
}
CURRENCY = r"[$€£¥₽₩₹]|\b(USD|EUR|GBP|JPY|RUB|KRW|BRL)\b|R\$"
URL = r"https?://|\bwww\.|\b[\w-]+\.(com|net|org|io|app|dev|de|fr|jp|ru)\b"
PRICE_WORDS = r"(?i)\b(free|gratis|gratuit\w*|kostenlos|grátis|бесплатн\w*)\b|無料|免費|免费|무료|\bprice\b|\bprecio\b|\bprezzo\b|\bpreço\b|\bPreis\b|\bцен[аы]\b"
AWARD_WORDS = r"(?i)\baward\w*|\bpremi[oa]d?[oa]?s?\b|\bprix\b|\bAuszeichnung\w*|\bprêmio\b|наград\w*|受賞|受赏|获奖|得獎|수상|editors?’? choice|app of the (day|year)|#1\b|\bbest app\b"

problems = []
def bad(lang, field, msg):
    problems.append(f"[{lang}.{field}] {msg}")

def cat(key, lang):
    return CAT[key]["localizations"][lang]["stringUnit"]["value"]

for lang in LANGS:
    if lang not in data:
        bad(lang, "-", "language missing"); continue
for lang in data:
    if lang not in LANGS:
        bad(lang, "-", "unexpected language")

for lang in LANGS:
    entry = data.get(lang)
    if not entry:
        continue
    if set(entry) != set(FIELDS):
        bad(lang, "-", f"fields {sorted(entry)} != {sorted(FIELDS)}")
    for field, limit in FIELDS.items():
        s = entry.get(field)
        if not isinstance(s, str) or not s.strip():
            bad(lang, field, "empty or not a string"); continue
        # length
        if len(s) > limit:
            bad(lang, field, f"{len(s)} chars > {limit}")
        # punctuation rules
        if "—" in s or "―" in s:
            bad(lang, field, "em dash / horizontal bar present")
        if '"' in s:
            bad(lang, field, "straight double quote")
        if "'" in s:
            bad(lang, field, "straight apostrophe")
        for q in sorted({c for c in s if c in QUOTES} - ALLOWED_QUOTES[lang]):
            bad(lang, field, f"quote mark {q!r} not used in {lang}")
        for o, c in PAIRS[lang]:
            if s.count(o) != s.count(c):
                bad(lang, field, f"unbalanced {o}{c}: {s.count(o)} vs {s.count(c)}")
        if lang in ("ja", "zh-Hant", "zh-Hans", "ko", "ru") and "’" in s:
            bad(lang, field, "curly apostrophe in a language that does not use one")
        # device names
        for m in re.finditer(r"(?i)ip(hone|ad)", s):
            word = m.group(0)
            if word not in ("iPhone", "iPad"):
                bad(lang, field, f"device name spelled {word!r}")
            nxt = s[m.end():m.end() + 2]
            if re.match(r"[sS](?![a-zA-Z])", nxt):
                bad(lang, field, f"plural device name {word + nxt[0]!r}")
        # URLs, prices, awards
        if re.search(URL, s):
            bad(lang, field, f"URL-like text {re.search(URL, s).group(0)!r}")
        if re.search(CURRENCY, s):
            bad(lang, field, f"currency {re.search(CURRENCY, s).group(0)!r}")
        if re.search(PRICE_WORDS, s):
            bad(lang, field, f"price word {re.search(PRICE_WORDS, s).group(0)!r}")
        if re.search(AWARD_WORDS, s):
            bad(lang, field, f"award word {re.search(AWARD_WORDS, s).group(0)!r}")
        # hygiene
        if re.search(r"[ \t]+\n|[ \t]+$|^[ \t]", s):
            bad(lang, field, "leading/trailing whitespace on a line")
        if "  " in s:
            bad(lang, field, "double space")
        if "\n\n\n" in s:
            bad(lang, field, "triple newline")
        if "\t" in s or "@" in s or "**" in s or re.search(r"(?m)^>", s):
            bad(lang, field, "tab, placeholder or markdown residue")
        if field in ("name", "subtitle", "promo", "keywords") and "\n" in s:
            bad(lang, field, "newline in a single-line field")
        # stale language count
        if re.search(STALE_TEN[lang], s):
            bad(lang, field, f"stale ten-languages wording {re.search(STALE_TEN[lang], s).group(0)!r}")
        # French spacing
        if lang == "fr":
            for m in re.finditer(r"[:;?!»]", s):
                if s[m.start() - 1] not in "  ":
                    bad(lang, field, f"no non-breaking space before {m.group(0)!r} at {s[max(0, m.start()-15):m.start()+1]!r}")
            for m in re.finditer(r"«", s):
                if s[m.end():m.end() + 1] not in (" ", " "):
                    bad(lang, field, f"no non-breaking space after « at {s[m.start():m.start()+15]!r}")
        else:
            if " " in s or " " in s:
                bad(lang, field, "non-breaking space outside French")

    name, sub = entry.get("name", ""), entry.get("subtitle", "")
    if name != "RAID Calculator":
        bad(lang, "name", f"name is {name!r}, not the brand")
    for field in ("name", "subtitle"):
        v = entry.get(field, "").lower()
        for t in TRADEMARKS:
            if re.search(rf"(?<![a-z]){t}(?![a-z])", v):
                bad(lang, field, f"third-party trademark {t!r}")

    # keywords
    kw = entry.get("keywords", "")
    if re.search(r",\s|\s,", kw):
        bad(lang, "keywords", "space next to a comma")
    toks = kw.split(",")
    if any(not t or t != t.strip() for t in toks):
        bad(lang, "keywords", "empty or padded keyword")
    if len(set(toks)) != len(toks):
        bad(lang, "keywords", "duplicate keyword")
    for t in toks:
        for tm in TRADEMARKS:
            if tm in t.lower() and not (tm == "shr" and t.lower() != "shr"):
                bad(lang, "keywords", f"third-party trademark in keyword {t!r}")
    if "raid calculator" in kw.lower():
        bad(lang, "keywords", "repeats the app name")

    # description content
    desc = entry.get("description", "")
    for key in ("not_affiliated", "unraid_not_affiliated", "zfs_not_affiliated"):
        line = cat(key, lang)
        if line not in desc.split("\n"):
            bad(lang, "description", f"trademark line {key} not copied exactly from the catalog")
    lang_lines = [l for l in desc.split("\n") if l.startswith("• " + ENGLISH_WORD[lang])]
    if len(lang_lines) != 1:
        bad(lang, "description", f"{len(lang_lines)} languages bullets (want 1)")
    elif lang in LINES and lang_lines[0] != LINES[lang]["languages_bullet"]:
        bad(lang, "description", f"languages bullet differs from the 1.7.1 line: {lang_lines[0]!r}")
    elif RUSSIAN_WORD[lang] not in lang_lines[0]:
        bad(lang, "description", "languages bullet lacks Russian")
    if "Synology" not in desc or "Unraid" not in desc:
        bad(lang, "description", "description no longer names the systems")

    # What's New
    wn = entry.get("whats_new", "")
    if lang in LINES and wn != LINES[lang]["whats_new"]:
        bad(lang, "whats_new", "differs from the 1.7.1 line")
    if ELEVEN[lang] not in wn:
        bad(lang, "whats_new", f"does not say {ELEVEN[lang]!r}")

    # register
    text = "\n".join(entry.get(f, "") for f in ("promo", "description", "whats_new"))
    if lang in REGISTER_BAD:
        for line in text.split("\n"):
            m = re.search(REGISTER_BAD[lang], line)
            if m:
                bad(lang, "register", f"off-register {m.group(0)!r} in {line[:60]!r}")
        if not re.search(REGISTER_GOOD[lang], text):
            bad(lang, "register", "no form of the required register found")
    if lang == "ja":
        for line in text.split("\n"):
            if line.startswith("• "):
                continue
            for sent in re.findall(r"[^。]*。", line):
                if not re.search(r"(ます|です|ません|ください|でしょうか|ました|ません)。$", sent):
                    bad(lang, "register", f"not です/ます: {sent[-25:]!r}")
            if re.search(r"(だ|である|だった)。", line):
                bad(lang, "register", f"plain form in {line[:40]!r}")
    if lang == "ko":
        for line in text.split("\n"):
            if line.startswith("• "):
                continue
            for sent in re.findall(r"[^.?!]*[.]", line):
                s2 = sent.strip()
                if re.search(r"(Inc|Inc\.)\.$", s2) or not re.search(r"[가-힣]", s2[-3:]):
                    continue
                if not re.search(r"(니다|세요)\.$", s2):
                    bad(lang, "register", f"prose not in ~합니다 form: {s2[-25:]!r}")

if "--table" in sys.argv:
    print(f"{'lang':8}" + "".join(f"{f:>13}" for f in FIELDS))
    for lang in LANGS:
        if lang in data:
            print(f"{lang:8}" + "".join(f"{len(data[lang].get(f, '')):>13}" for f in FIELDS))
    print(f"{'limit':8}" + "".join(f"{v:>13}" for v in FIELDS.values()))
    print()

if problems:
    print(f"{len(problems)} problem(s):")
    for p in problems:
        print(" ", p)
    sys.exit(1)
print("No problems.")
