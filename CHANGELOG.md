# Changelog

How RAID Calculator got from 1.3 to 1.7, newest first. Dates come from the release tags or, where there is no tag, the commit that finished the release. Requirement numbers (FR-*n*) refer to [prd.md](prd.md), and the implementation plans are in `docs/superpowers/plans/`.

## 1.7.0 (2026-10-08)

Merged to `main` on 2026-10-08 and uploaded from local Xcode 27.1, so there is no `v1.7.0` tag (see [DEPLOY.md](DEPLOY.md)). It also carries everything from 1.6.5, listed separately below. Plan: `2026-10-06-1.7.0-duo-and-review.md`; requirements FR-21 and FR-22.

- **iPhone Duo.** The closed outer display shows one column beside the system’s vertical bars. The open inner display in landscape puts results beside inputs, with the fold in the gap between the columns; portrait, open or folded like a book, is one column.
- **Info in place of the inputs on iPhone Duo.** In two columns, the info button shows the info in the inputs pane, with a Close button, so the results stay in view. iPad keeps the sheet.
- **iPhone rotates to landscape.** Two columns now also need at least 600 points of height, so every iPhone in landscape, the Pro Max included, stays one column.
- **The NAS comparison waits for a saved setup.** Until you save, the section only offers Save as Current Setup. Once saved, it shows the setup it compares against (“Current setup: 16 TB usable · Synology SHR · 4 bays”), and Revert asks first.
- **Advice looks different from errors.** The rebuild caution, the SnapRAID parity hint and the wide RAID-Z note get an info icon and the VoiceOver hint “Advice, not an error.”, with a one-tap fix where there is one (“Use RAID 6”, “Use 2 parity drives”).
- **Narrow groups get the rebuild warning too.** RAID 50 and RAID-Z1 groups on 8 TB+ drives that are too narrow to move up to RAID 60 or RAID-Z2 now get the caution, without a level to suggest.
- **Invalid setups are announced.** VoiceOver starts the summary with “Not a valid setup.”, the figures dim to 55%, the failures row hides, and the warning stays at full contrast.
- **A higher-contrast tint** that meets 4.5:1 for text in light and dark mode, darker still with Increase Contrast. Data marks (strip bars, bay swatches, stars) keep a separate, brighter data color.
- **Menus at accessibility text sizes.** The level and unit pickers become menus with full level names, and the segmented level picker reads full names to VoiceOver.

**Under the hood**

- Built with Xcode 27.1 and the iOS 27.1 SDK; the deployment target stays iOS 26.0. On a fold device on iOS 27.1, the two columns are an `ArrangementView` split; everywhere else they stay an `HStack`.
- New `nas.hasSavedCurrent` key. A stored setup equal to the sample counts as unsaved, because 1.6 wrote the sample on every edit.
- CI runs only the strings check and the unit tests; the UI suite runs locally before each release.
- `scripts/store-assets/` composes the App Store screenshots and captures iPhone Duo poses.

## 1.6.5 (never released; rolled into 1.7.0)

Polish planned as its own release (`2026-10-06-1.6.5-polish.md`, branch `feat/1.6.5-polish`), finished on 2026-10-06 and shipped as part of 1.7.0.

- **Five more languages,** for ten: German, Traditional Chinese, Simplified Chinese, Korean and Brazilian Portuguese join English, Spanish, French, Italian and Japanese.
- **VoiceOver reads each drive within a group** (“Group 2 of 3, drive 1: Parity”), and empty bays have a localized label.
- **Compare Systems opens at full height,** and says when a system reads more bays than the current one shows (“Uses all *N* bays”).
- **Japanese counts drives with 台** in the RAID-tab validations.
- **At accessibility sizes, the drive size lines up under its label.**

**Under the hood**

- Stored NAS parity settings, in the last configuration and the saved setup, are clamped to each system’s range on load.

## 1.6.0 (2026-10-05)

Tagged `v1.6.0` on 2026-10-05. Plans: `2026-10-04-nas-tab.md`, `2026-10-05-compare-and-ipad.md` and `2026-10-05-copy-site-and-rows.md`; requirements FR-10 to FR-20.

- **The Synology tab becomes the NAS tab,** titled “NAS Calculator”, with five systems: Synology (SHR, SHR-2, RAID 1/5/6), Unraid, ZFS (one RAID-Z group), SnapRAID and Btrfs RAID1. Switching systems re-splits the same drives in place.
- **One bay count** from 2 to 30 (Synology stays at 12) replaces the DiskStation model presets. A system with fewer bays hides the extra drives but keeps them.
- **Biggest Upgrade, Save as Current Setup and Revert** work for every system, with per-system rules. Unraid and SnapRAID put parity on the largest drives; SnapRAID suggests a parity count from its published recommendation, and ZFS notes a group wider than 12 drives.
- **Compare Systems:** the same drives under every system, most usable first, saying when a system reads fewer bays than you set up. A sheet on iPhone, columns on iPad; tapping a system switches to it.
- **iPad layouts:** results beside inputs on a wide iPad (regular width, 800 points or more), bay diagrams wrapped into rows up to 30 bays, and RAID-tab drive groups in their own rows.
- **Info sheets for every NAS system,** including how the app calculates each, with the Synology, Unraid and ZFS trademark lines in their sheets.
- **“Drive failures tolerated” on one line** when it fits, never shortened to fit.
- **The drive-size field:** while it’s empty or reads 0, the results ask for a size instead of showing the last result, and the NAS tab’s Custom Size alert can’t be confirmed empty.
- The product page and App Store copy describe every system, with all three trademark lines.

**Under the hood**

- The tab’s stored value is `"nas"`, with no migration; an unknown value such as `"synology"` opens the RAID tab. Stored bays keep their `synology.bays` key.
- One shared `InfoSheet` for RAID levels and NAS systems, and pure layout rules in `AdaptiveLayout`.
- CI runs tests serially (`-parallel-testing-enabled NO`), since parallel Simulator clones timed out.
- `prd-update.md` was merged into `prd.md`.

## 1.5.0 (2026-10-04)

Tagged `v1.5.0` on 2026-10-04. Plan: `2026-10-03-raid-tab-nested-zfs.md`; requirements FR-8, FR-9, and the RAID-tab parts of FR-17 and FR-20. The 1.6.0 App Store notes list these changes too.

- **RAID 50, RAID 60 and ZFS RAID-Z1, Z2 and Z3** on the RAID tab, in a menu beside the standard levels, with a Groups setting. RAID 50 and 60 need at least two groups.
- **An estimate of what ZFS will report** for RAID-Z, after padding and slop space, always labeled as an estimate.
- **One-tap fixes for groups:** “Use *N* groups”, and a drive-count fix that changes the groups too when it needs to. Fixes never go past 24 drives.
- **The rebuild caution** for 8 TB+ drives covers RAID 50 (suggesting RAID 60) and RAID-Z1 (suggesting RAID-Z2), as well as RAID 5; a RAID-Z group wider than 12 drives gets a note.
- **Info sheets** for the new levels; RAID-Z’s explain how the estimate is calculated.
- **The drive strip shows groups,** and changing Groups slides the bars into place, or crossfades under Reduce Motion. Stepper rows hold up at accessibility text sizes.

**Under the hood**

- `scripts/strings.py` adds, removes and checks catalog strings, and CI runs the check.
- New stored values: the `groups` key and the `"R 50"`, `"R 60"`, `"Z1"`, `"Z2"` and `"Z3"` level values.

## 1.4.1 (2026-10-03)

Tagged `v1.4.1` on 2026-10-03 (FR-19).

- **The drive-size field’s cursor.** Tapping the field and pressing backspace often deleted nothing, because a tap left of the digits put the cursor before them. The cursor now moves to the end of the number on focus, wherever the tap lands.

## 1.4.0 (2026-10-01)

Tagged `v1.4.0` on the 2026-10-01 merge, and submitted to App Review on 2026-10-02. The first version from this codebase on the original App Store record.

- **Rebuilt for iOS 26.** A redesigned RAID screen that puts the answer first: usable capacity, then raw capacity, efficiency, and a drive-by-drive strip of data, parity and mirrors.
- **The TiB figure** a NAS will report, beside the decimal capacity.
- **Invalid setups dim** and offer a one-tap fix, and RAID 5 on drives of 8 TB or more shows a rebuild-risk caution.
- **A Synology tab** for mixed drives: a size per bay, SHR and SHR-2 alongside RAID 1/5/6, presets for DiskStation models, a to-scale bay diagram with unused capacity hatched, the single upgrade that unlocks the most space, and a comparison against a saved current setup.
- iPad support, dark mode, Dynamic Type and VoiceOver throughout, in English, Spanish, French, Italian and Japanese.

**Under the hood**

- iOS 26.0 deployment target, Swift 6 with main-actor default isolation, Xcode 27.
- Translations moved to a String Catalog.
- The project points at the original record’s bundle ID, and `deploy.yml` can upload to App Store Connect from a `v*` tag.
- The product page at mrballistic.com/raid first deployed on 2026-10-02 (`www-v1.0.0`).

## 1.3 and earlier (legacy)

What the repo records about the app before 1.4.0:

- **The original app.** The App Store record dates from 2010 (bundle ID `53Q4825KDF`). 1.2 was the last version shipped on it before 1.4.0. The repo has no code or notes from that version.
- **This codebase began on 2025-11-22** as a SwiftUI rewrite, working name “RAIDGauge” (the project folder is still `RaidCalculator2`). It calculated RAID 0, 1, 5, 6, 10 and JBOD for 1–24 drives in GB or TB: usable capacity, drive failures tolerated, speed and availability star ratings, validation warnings and an info sheet per level. It remembered the last configuration, supported dark mode, Dynamic Type and VoiceOver, and was translated into Spanish, French, Italian and Japanese.
- **1.3** (2025-11-22): iPhone only, portrait only, with the RAID Calculator name and new icons.
- **1.3.1** (2025-11-23): iPad support with a two-column layout, and an accent color in place of hard-coded orange.
- **1.3.2** (2025-12-05): iOS 26 glass styling on buttons and steppers, and app icon appearance variants.
- Earlier docs recorded 1.3.2 as the version live on the App Store, and asked that the first version on the original record be numbered above 1.3.2 to avoid confusion with the separate **RAID Calc2** record (bundle ID `com.mrballistic.RaidCalculator2`).
