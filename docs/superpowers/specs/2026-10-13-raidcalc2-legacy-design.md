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
- The branch doesn't change `www/`, `marketing/`, `scripts/store-assets/` or the CHANGELOG's history. It adds a 1.8.0 entry to the CHANGELOG on the branch only.

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

## 5. Testing

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
