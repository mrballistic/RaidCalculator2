# RAID Calculator: product page brief

Handoff for designing a product (marketing) page for RAID Calculator, a native iOS app. Everything below is product truth from the shipping codebase. Where something isn't decided or doesn't exist, it says so; please don't invent it.

## The product in one line

A native iPhone and iPad calculator that shows how much space a RAID array actually gives you, how many drives can fail, and, for Synology owners, exactly which drive to buy next.

## Who it's for

- **Primary: home-lab and NAS owners.** People who self-host (Plex, file servers, backups, small clusters), know roughly what RAID is, and want to sanity-check capacity and redundancy before buying drives or building an array. Many own a Synology DiskStation with drives of mixed sizes, bought over several years.
- **Secondary: people learning RAID** (students, junior engineers) who want to understand what changes between levels.
- **Secondary: IT generalists** who need a quick, offline capacity figure in a meeting or at a whiteboard.

The page is a **Persuade** surface: the visitor should understand what the app does in seconds and tap through to the App Store.

## Positioning

- **It answers the real question, not the textbook one.** Most RAID calculators assume identical drives. Real home NAS boxes have a 4 TB from 2019 next to a 16 TB from last month. RAID Calculator's Synology mode models each bay separately, shows the capacity a mixed set leaves unused, and names the single upgrade that unlocks the most.
- **It shows, not just tells.** A drive-by-drive picture (data, parity, mirror, unused) makes the tradeoff visible at a glance.
- **It’s a real iOS app.** Native SwiftUI, Liquid Glass, Dynamic Type, VoiceOver, dark mode, iPhone and iPad. It's meant to sit naturally next to Apple's own utilities.
- **Private by construction.** No account, no analytics, no tracking, no network calls. Works fully offline.

## Feature list

### RAID tab: classic RAID in seconds

- **Levels:** RAID 0, 1, 5, 6, 10 and JBOD.
- **Inputs:** number of drives (1–24) and drive size in GB or TB. Remembers your last setup.
- **The answer first:** usable capacity is the biggest thing on screen, with raw capacity and storage efficiency beneath it (“of 96 TB raw · 67% efficient”).
- **Drive strip:** one bar per drive, coloured by what it does (data, parity, mirror), so you can see why RAID 6 costs two drives.
- **Fault tolerance:** how many drives can fail, honest about the conditional cases (RAID 10: “Up to 4, depending on which drives fail”).
- **TB vs TiB:** shows the figure most NAS operating systems will report (“≈ 58.2 TiB as most NAS systems report it”), so the number matches what you see after setup.
- **Speed and availability ratings:** 1–5 stars per level, labelled as relative comparisons, not benchmarks.
- **Helpful guardrails:**
  - Invalid setups explain themselves and offer a one-tap fix (“RAID 10 requires an even number of drives. Use 6 drives”).
  - RAID 5 with drives of 8 TB or more shows a rebuild-risk caution suggesting RAID 6.
- **Learn each level:** an info sheet per level with an overview, pros, cons, typical use cases and ratings.

### Synology tab: plan mixed-drive upgrades

- **Bay-by-bay drives:** set each bay's drive size separately, or leave bays empty.
- **SHR and SHR-2 (Synology Hybrid RAID)** alongside Synology's RAID 1, 5 and 6, so you can see what SHR saves you over classic RAID with the same drives. Example: 2 × 4 TB + 2 × 8 TB gives 12 TB in classic RAID 5, but 16 TB in SHR.
- **Model presets for current DiskStations:**

  | Bays | Models |
  |---|---|
  | 2 | DS225+, DS725+, DS223j |
  | 4 | DS425+, DS925+, DS423 |
  | 5 | DS1525+ |
  | 6 | DS625slim |
  | 8 | DS1825+ |
  | 12 | DS2422+ |

  There's also a custom bay count (2–12).
- **Bay diagram:** every drive drawn to scale and split into the layers SHR actually builds. Unused capacity is hatched, so you can see exactly what's being wasted and why.
- **Unused-capacity callout:** “8 TB unused with this mix of drives.”
- **Biggest upgrade:** the single drive purchase that unlocks the most space, with a one-tap “try it” (“Replace bay 4 (4 TB) with 16 TB: +12 TB usable”).
- **Before and after:** every change is compared with your saved current setup (“+4 TB usable”), with Save as Current Setup and Revert.
- **The key insight this delivers:** upgrading one drive in an SHR array often gains less than expected until a second large drive joins it. The app shows that number before you buy.

### Everywhere

- **Five languages:** English, Spanish, French, Italian and Japanese.
- **Accessibility:** works at every Dynamic Type size, including the largest accessibility sizes. VoiceOver reads ratings and drive diagrams as full sentences (“Speed, 3 of 5, Medium”; “Bay 1, 16 TB: 8 TB parity, 8 TB unused”).
- **iPhone and iPad**, light and dark mode.
- **Privacy:** no data collection of any kind. The published policy says the app collects nothing, uses no third-party services, and every calculation happens on the device.

## Facts for the page

| Item | Value |
|---|---|
| App name | **RAID Calculator** (RAID in capitals) |
| Developer | mrBallistic |
| Platforms | iPhone and iPad |
| Requires | iOS 26 or later |
| App Store ID | `395601653` (`https://apps.apple.com/app/id395601653`) |
| History | First published around 2010; rebuilt from scratch for iOS 26 |
| Languages | English, Spanish, French, Italian, Japanese |
| Privacy | Data Not Collected |
| Privacy policy | `privacy.md` in the repo (contact: mrballistic@gmail.com) |

**Not decided yet (leave as placeholders):** price, the public release date of the rebuilt version, a support URL, and the App Store subtitle.

## Evidence and assets

- **App icon:** `marketing/appstore.png` (1024 px). The source icon is `RaidCalculator2/AppIcon.icon` (Icon Composer, with light/dark/tinted variants).
- **Screenshots** in `marketing/screenshots/`, at App Store sizes, with a clean 9:41 status bar. They're numbered in a suggested order, with the differentiator first.
  - **iPhone** (6.9-inch, 1320 × 2868):
    - `01-iphone-synology-upgrade.png`: Synology DS925+ with 16/8/8/4 TB. 8 TB hatched as unused, “Replace bay 4 (4 TB) with 16 TB: +12 TB usable”, and +4 TB against the current setup
    - `02-iphone-synology-8bay.png`: DS1825+ with five drives and three empty bays, suggesting a 24 TB drive for bay 6 (+24 TB)
    - `03-iphone-raid-raid6.png`: RAID tab, RAID 6 with 6 × 16 TB. 64 TB usable and the data/parity drive strip
    - `04-iphone-raid-raid5-caution.png`: RAID 5 on 8 × 20 TB with the rebuild-risk caution
    - `05-iphone-raid-invalid-fix.png`: RAID 10 with 5 drives, dimmed results and the “Use 6 drives” fix
    - `06-iphone-synology-ja.png`: the Synology upgrade scene in Japanese
    - `07-iphone-synology-dark.png`: the Synology upgrade scene in dark mode
    - `08-iphone-raid-raid10-dark.png`: RAID 10 with 8 × 12 TB in dark mode, mirrored pairs
  - **iPad** (13-inch, 2064 × 2752):
    - `09-ipad-synology-upgrade.png`: the Synology upgrade scene
    - `10-ipad-raid-raid6.png`: RAID 6
    - `11-ipad-synology-dark.png`: Synology in dark mode
- **There are no testimonials, reviews, ratings, download counts, press quotes or customer logos.** Do not write or imply any. If the page needs social proof, leave a clearly marked empty slot.

## Copy and brand rules

- **Typography in copy:**
  - Use smart punctuation throughout: curly quotes (“ ”), curly apostrophes (’), en dashes in ranges (1–24).
  - Em dashes only where they do real work, closed up (`word—word`), at most one per sentence.
- **Synology trademark (required):**
  - “Synology”, “DiskStation” and “SHR” may appear only as factual descriptions of compatibility (“Plan upgrades for your Synology”, “Supports Synology Hybrid RAID (SHR)”).
  - Never use Synology's logo or product photography, and never imply partnership or endorsement.
  - Include this line in the footer, verbatim: “Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc.”
- **Honesty:**
  - Speed and availability ratings are relative, not benchmarks, so don't present them as measured performance.
  - Capacity figures use standard simplified formulas, so don't promise exactness against a specific vendor's filesystem overhead.
- **Voice:** plain, confident, practical. It talks like a friend who knows storage, not a vendor. Short sentences. Numbers do the persuading.

## Suggested page story (a starting point, not a mandate)

1. **Hook:** the question every NAS owner asks: “How much space will I actually get?” Answer it with a real number on a real screenshot.
2. **The mixed-drive problem:** an old 4 TB next to a new 16 TB, the wasted space made visible with the hatched bay diagram, and the “biggest upgrade” answer. This is the differentiator; give it the most room.
3. **Classic RAID, instantly:** the RAID tab, the drive strip, TB vs TiB, and the rebuild caution.
4. **Learn as you go:** the per-level info sheets.
5. **Made for iOS:** iPhone and iPad, dark mode, Dynamic Type, VoiceOver, five languages.
6. **Private:** no account, no tracking, works offline.
7. **Call to action:** Download on the App Store (official Apple badge), plus the Synology not-affiliated line in the footer.

Sections like a FAQ (“What’s SHR?”, “Why does my NAS show less than I expected?”) would suit this audience well. If you add one, answer only with facts from this brief.
