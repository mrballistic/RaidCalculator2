# RAID Calc2 legacy release (1.8.0): design

**Date:** 2026-10-13 · **Branch:** `legacy/raidcalc2` (from `main` at 9c7b032, never merged back)

## Goal

Two RAID calculators from the same developer are live on the App Store:

| | App Store ID | Bundle ID | Live | Min iOS |
|---|---|---|---|---|
| RAID Calc2 (legacy) | 6755641457 | `com.mrballistic.RaidCalculator2` | 1.3.2 | 18.6 |
| RAID Calculator (main) | 395601653 | `53Q4825KDF` | 1.7.0 | 26.0 |

Ship one last update to RAID Calc2 that tells its users it leaves the App Store on **December 31, 2026** and sends them to RAID Calculator. After that date, remove it from sale.

Success means:

- every RAID Calc2 user who can run RAID Calculator sees the notice and can install the new app in one tap
- RAID Calc2 is still a working, useful RAID calculator, so it clears App Review (guideline 4.2, minimum functionality)
- it is clearly smaller than RAID Calculator, so it gives users a reason to move and doesn't look like a duplicate app (guideline 4.3)

## Decisions

- **Built from `main`, deployment target stays iOS 26.0.** Users on iOS 18–25 won't be offered 1.8.0 and keep 1.3.2. That's intended: they can't install RAID Calculator either, so a notice pointing them to it would be a dead end.
- **RAID tab only, classic levels only:** RAID 0, 1, 5, 6, 10 and JBOD, the same set 1.3.2 had. No existing user loses a feature. NAS planning, RAID 50/60 and RAID-Z become the pitch for the new app.
- **Fixed date, not "30 days".** Review time and how long people take to update make a relative window meaningless.
- **No data migration.** Different bundle IDs mean separate storage. Moving saved data would need an App Group or a share link, and the legacy app has few users. The copy doesn't promise anything carries over.
- **Desaturated icon**, so the legacy app reads as retired on the Home Screen.

## 1. Identity

- App target: `PRODUCT_BUNDLE_IDENTIFIER = com.mrballistic.RaidCalculator2`, `INFOPLIST_KEY_CFBundleDisplayName = "RAID Calc2"`, `MARKETING_VERSION = 1.8.0`, `CURRENT_PROJECT_VERSION` reset to 1. The team stays the same.
- Test targets keep their bundle IDs (`com.mrballistic.RaidCalculator2Tests` / `UITests`).
- DEPLOY.md: a short "Legacy app" section covering the branch, the bundle ID, and removing the app from sale in App Store Connect on 2026-12-31.
- The branch doesn't change `www/` or the CHANGELOG's history. It adds a 1.8.0 entry to the CHANGELOG on the branch only. Its store assets and listing copy (section 5) are new files on the branch; the RAID Calculator listing and 1.7.0 screenshots are left alone.
- The branch is pushed to GitHub but **never opened as a pull request** and never merged into `main`. Pushing a non-`main` branch triggers no workflow (`ios.yml` runs on pushes to and PRs into `main`, `deploy.yml` on `v*` tags, `www.yml` on `www-v*` tags). The branch README starts with a one-line notice saying not to open a PR.
- No `v*` tag on this branch: a `v*` push triggers `deploy.yml`, and `v1.8.0` would look like a RAID Calculator release. Upload from local Xcode (the 1.7.0 path in DEPLOY.md). If a tag is wanted for the record, use `legacy-v1.8.0`.

## 2. Removals

**NAS tab.** Delete `NASView.swift`, `NASViewModel.swift`, `NASComparisonViews.swift`, `NAS.swift`, `Synology.swift`, `Bays.swift` (if only NAS uses it), `ParityArrayCalculator.swift`, `ZFSMixedCalculator.swift`, `ZFSEstimate.swift` (if only NAS uses it) and `BtrfsRaid1Calculator.swift`, along with their unit tests and the NAS UI tests. During implementation, confirm each file has no remaining RAID-tab callers before deleting it.

**Tab bar.** `RaidCalculator2App` shows `NavigationStack { ContentView() }` directly, and the `selectedTab` storage goes.

**Nested and ZFS levels.**
- `RaidLevel` keeps only `raid0`, `raid1`, `raid5`, `raid6`, `raid10` and `jbod`. The `standard` / `nested` / `zfs` family split goes, unless keeping a single family is the smaller diff.
- The groups stepper, the RAID-Z width advisory (`wideZFSGroupWidth`), the group suggestions (`suggestedGroups`, `suggestedDriveCountGroups`) and the narrow-group rebuild warning (`warnOnly`) go. The rebuild caution that suggests RAID 6 instead of RAID 5 on large drives stays.
- The info sheet's copy for the removed levels goes.

**Strings.** Remove the catalog keys nothing uses any more, so `scripts/strings.py` passes.

**Stored state.** If the saved `selectedLevel` raw value doesn't match a remaining level (for example, from a TestFlight build of 1.4+), fall back to RAID 5. If a saved `groups` value exists, ignore it.

**Kept as-is:** the iPad two-column layout, the iPhone Duo layout, the 10 languages, the accessibility work and the iOS 26 styling.

## 3. Retirement notice

**`Retirement`** is a small pure type, so it can be unit-tested:

- `static let date`: 2026-12-31. Compare by calendar day in the user's time zone, so the copy switches on January 1.
- `phase(now:) -> .retiring | .retired`.
- `newAppID = 395601653` and its fallback URL, `https://apps.apple.com/app/id395601653`.
- The date is shown with `Date.FormatStyle` (`.dateStyle(.long)`), localized.

**First-launch sheet.** It appears once, the first time 1.8.0 launches (`legacy.hasSeenRetirementNotice`), in either phase.

- Title: "RAID Calc2 is retiring"
- Body, while retiring: "RAID Calc2 leaves the App Store on December 31, 2026. It keeps working on this iPhone, but won’t get updates. RAID Calculator is the same app, plus NAS planning, RAID 50 and 60, and ZFS."
- Body, once retired: "RAID Calc2 is no longer on the App Store and won’t get updates." followed by the same pitch sentence.
- Buttons: **Get RAID Calculator** (primary) and **Not Now**.

On iPad the body says "this iPad". Pick the device word from the idiom, or use device-neutral copy if that reads better in translation.

**Persistent banner.** A row at the top of the form, before the capacity summary, that can't be dismissed. It shows an icon, one line ("Retiring December 31: get RAID Calculator", or "No longer on the App Store: get RAID Calculator") and a chevron, and tapping it opens the store page.

- Accessibility: a single button, with the full sentence as its label.
- At AX sizes the line wraps; it is never truncated.
- In two columns it stays at the top of the inputs column.

**Store page.** It's shown with `SKStoreProductViewController` for 395601653, presented from SwiftUI through a small `UIViewControllerRepresentable`. If loading fails, open the fallback URL with `openURL`.

**Copy rules.** Curly punctuation, at most one em-dash per sentence and only where it earns it, all 10 languages, and "RAID Calculator" / "RAID Calc2" left untranslated.

## 4. Desaturated icon

- A script, `scripts/desaturate-icon.swift` (or `.py` if it needs no third-party libraries), converts each PNG layer in `RaidCalculator2/AppIcon.icon/Assets/` to grayscale (luminance, alpha kept). The output replaces the originals in place on this branch.
- `icon.json`: the automatic background fill becomes a neutral gray solid fill for the default and dark appearances. Tinted mode is left alone, because the system tints it anyway.
- Gate: render light, dark and tinted previews (Icon Composer export or a Simulator Home Screen screenshot), and get the user's approval before the release build.

## 5. Store listing and graphics

The RAID Calc2 record (6755641457) needs a full set of listing copy and screenshots for 1.8.0. They go in `marketing/raidcalc2-1.8.0-listing.md` and `marketing/screenshots/raidcalc2-1.8.0/`, both committed on the branch.

**Copy, in English first:**

| Field | Limit | Content |
|---|---|---|
| Name | 30 | RAID Calc2, unchanged. |
| Subtitle | 30 | Moving to RAID Calculator |
| Promotional text | 170 | Says it's retiring on December 31, 2026, and that RAID Calculator, with NAS planning, RAID 50 and 60, and ZFS, is where to go next. |
| Description | 4000 | Opens with the retirement and a pointer to RAID Calculator by name. Then it describes, honestly, what the app does: RAID 0, 1, 5, 6, 10 and JBOD; usable and raw capacity, efficiency, the drive strip, failures tolerated, speed and availability ratings, and rebuild advice; iPad and iPhone Duo layouts, 10 languages, Dynamic Type and VoiceOver. It closes with what RAID Calculator adds. |
| What's New | 4000 | The retirement notice and date, plus what changed from 1.3.2 that a user will notice: the iOS 26 design, the 10 languages, the iPad and iPhone Duo layouts, rebuild advice with one-tap fixes, and accessibility. |
| Keywords | 100 | Kept short and honest: raid, calculator, storage, capacity, drives, parity, mirror. No competitor names. |

- **Copy rules,** from `docs/app-store-assets-brief.md` section 3: no em-dashes, "iPhone" and "iPad" exactly so, trademarks spelled exactly and used descriptively, and no prices, URLs or awards. Curly punctuation. Character counts are checked and written next to each field, as in the RAID Calculator listing.
- **App Store links** can't go in the copy (no URLs), so it names "RAID Calculator" and says to search for it or use the button in the app.
- **Localized listings:** all 10 app languages (en-US, es, fr, it, ja, de, zh-Hant, zh-Hans, ko, pt-BR), translated from the final English. Each is marked for a native-speaker check before submission, following the release checklist rule that machine translations aren't submitted unreviewed.
- **App Review notes:** the RAID calculator is fully functional; the notice points to the developer's own app, RAID Calculator (395601653), which supersedes it; and the store page opens with `SKStoreProductViewController`.

**Screenshots,** composed with `scripts/store-assets/compose.py` from fresh simulator captures of this build:

- **Sizes (all required; App Store Connect won't accept the submission without them, because the build targets iPhone, iPad and iPhone Duo):** iPhone at 1320 × 2868, plus the 1206 × 2622 and 1179 × 2556 sizes laid out from the same raws; iPad 13″ at 2064 × 2752; iPhone Duo inner at 2007 × 2853 and 2853 × 2007; and iPhone Duo outer at 1398 × 2034 and 2034 × 1398. No header or search images, since a retiring app won't be nominated for featuring.
- **Shot list:** four images on iPhone and three on iPad. The first shows the retirement sheet ("Moving to RAID Calculator"), then usable space, the rebuild caution with its one-tap fix, and the invalid-setup fix. iPad drops the invalid-setup fix. Each Duo set has two images, retirement and usable space; the inner landscape set shows the two-column layout.
- **Duo capture:** reuse `scripts/store-assets/capture_duo.sh`, with the bundle ID, output root and scenes made configurable through environment variables. The 1.7.0 defaults stay as they are. Neither `simctl` nor XCUITest can set the Duo's pose or rotation, so the user sets each of the four poses by hand: the pose in Xcode's Device Hub, rotation with Device › Rotate Left. The script then checks the capture size and that the display is lit, captures and composes.
- **Background:** a neutral graphite background, added to `compose.py` next to orange and indigo, with white text and the script's existing 4.5:1 contrast assertion. It matches the desaturated icon. The 1.7.0 shot list in `compose.py` stays as it is; the legacy shots are a separate list, selected by a flag.
- **English only.** Screenshots are captured in English and used for every localization; only the listing text is translated.
- **Raws** go under `marketing/screenshots/raidcalc2-1.8.0/raw/`, and composed images under `.../store/`. The checks are the same as for 1.7.0: exact pixel sizes, no alpha channel, and a contact sheet per set for review.
- **Gate:** the user approves the contact sheets and the English copy before the translations are made and before upload.

## 6. Testing

**Unit:**
- `Retirement.phase`: the day before, the day itself, and January 1, in more than one time zone.
- The stored-level fallback: an unknown raw value loads as RAID 5.
- The existing RAID tests, with nested and ZFS cases removed.

**UI:**
- The sheet appears on a fresh launch, Not Now closes it, and it doesn't come back on relaunch.
- The banner exists and is hittable.
- Remove the NAS and nested-level UI tests.
- Use a launch argument to set the "now" date, so the retired copy is testable.

**Gates before upload:**
- `scripts/strings.py` passes.
- The full unit and UI suites pass locally, with one Simulator and one xcodebuild at a time.
- Targeted screenshots of the sheet and banner in fr, de, ja (or zh-Hans), at AX XXXL and on the narrowest iPhone. This is not a full sweep across every language.

## Out of scope

- Data migration or deep links into RAID Calculator.
- Any change to RAID Calculator, `main` or the website.
- Supporting iOS versions below 26.
- Automatically removing the app from sale. On 2026-12-31 that's a manual step in App Store Connect, tracked in DEPLOY.md.
