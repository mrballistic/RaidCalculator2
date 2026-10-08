# RAID Calculator

A native iOS and iPadOS app, for iPhone, iPad and iPhone Duo, that shows how much space a set of drives actually gives you, how many can fail, and which drive is worth buying next. It's on the App Store as [RAID Calculator](https://apps.apple.com/app/id395601653), with a product page at [mrballistic.com/raid](https://mrballistic.com/raid/).

## What it does

**RAID tab: identical drives**
- RAID 0, 1, 5, 6, 10, 50, 60, JBOD, and ZFS RAID-Z1/Z2/Z3 (with groups), for 1–24 drives in GB or TB.
- Usable and raw capacity, efficiency, a drive strip showing data, parity and mirrors, and drive failures tolerated, including the conditional cases (“Up to 4 (depends on which drives fail)”).
- Invalid setups dim, VoiceOver says so, and they offer a one-tap fix (“Use 6 drives”).
- RAID 5, RAID 50 and RAID-Z1 on drives of 8 TB or more warn that a rebuild can take days and that a second failure during it loses the array, and offer a one-tap “Use RAID 6” (or RAID 60, or RAID-Z2) when the groups are wide enough to move up. Narrower groups get the warning without the button.
- Advice like this is marked as advice, with its own icon, so it doesn’t read as an error.
- RAID-Z shows an estimate of what ZFS will report, after padding and reserved space, always labeled as an estimate.

**NAS tab: mixed drives, bay by bay**
- One set of drives seen through five systems: Synology (SHR, SHR-2, classic RAID), Unraid, ZFS (one RAID-Z group), SnapRAID and Btrfs RAID1.
- A bay diagram drawn to scale, with unused capacity hatched.
- Biggest Upgrade: the single purchase that unlocks the most space.
- Save as Current Setup, and from then on every change reads as a difference from it, beside a line summarizing the saved setup. Until you save, there’s nothing to compare against. Revert asks before it restores the saved setup.
- Compare Systems: the same drives under every system, most usable first, saying when a system reads fewer bays than you set up, or more than the current one shows. A full-height sheet in one column, columns beside the bays in two.
- Advice with a one-tap fix, such as SnapRAID’s recommended parity count (“Use 2 parity drives”).

**Everywhere**
- An info sheet per RAID level and NAS system: overview, pros, cons, typical uses, ratings for RAID levels, and how the app calculates RAID-Z and each NAS system.
- Results beside inputs once the window is regular width, at least 800 points wide and at least 600 points tall, as on iPad and on iPhone Duo’s open inner display in landscape, where the fold falls in the gap between the columns. iPhone in landscape (the Pro Max included), iPhone Duo’s closed outer display (beside the system’s vertical bars) and its inner display in portrait, open or folded like a book, use one column. Bay diagrams stay legible up to 30 bays.
- Info sheets open as a sheet, except on iPhone Duo in two columns, where the info takes the place of the inputs so the results stay in view.
- iPhone rotates to landscape.
- At accessibility text sizes the level and unit pickers become menus.
- Light and dark mode, a tint dark enough for text contrast (darker still with Increase Contrast), Dynamic Type up to the largest accessibility sizes, VoiceOver (which reads each drive within a group), and Reduce Motion.
- English, Spanish, French, Italian, Japanese, German, Traditional Chinese, Simplified Chinese, Korean and Brazilian Portuguese.
- No account, no analytics, no network calls.

## Building

- Xcode 27.1 or later (iPhone Duo’s layout uses the iOS 27.1 SDK), iOS 26.0 deployment target, Swift 6 with default MainActor isolation. No third-party dependencies.
- Open `RAID Calculator.xcodeproj` and run the **RAID Calc** scheme.
- Folders are synchronized, so new `.swift` files are picked up without editing the project file.

## Testing

Unit tests use Swift Testing (target "RAID CalcTests", folder `RaidCalculator2Tests/`), and UI tests use XCTest (target "RAID CalcUITests", folder `RaidCalculator2UITests/`). Always pass `-parallel-testing-enabled NO`; parallel Simulator clones time out.

CI (`.github/workflows/ios.yml`) runs only the strings check and the unit tests, on the `xcode-27` runner with Xcode 27.1 and a 30-minute cap. UI tests and launch tests don't run there, because GitHub macOS minutes cost money. Run the UI suite locally before each release (about 15 minutes):

```bash
# Unit tests only, as CI runs them
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcTests"

# The UI suite, run locally
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcUITests"
```

`launchApp` passes `-selectedTab raid`, so tests start on the RAID tab. The `testIPad*` UI tests skip unless the two-column layout is on screen (they look for its `twoColumnLayout` identifier, and that layout follows size class and window size, not device type), so they skip on iPhone in portrait and run on an iPad Simulator (for example `name=iPad Pro 13-inch (M5)`) and on iPhone Duo’s inner display in landscape. iPhone Duo needs the iOS 27.1 Simulator runtime, and its pose and rotation can’t be scripted: set them in the Simulator and Xcode’s Device Hub.

## Strings

All user-facing text lives in `RaidCalculator2/Localizable.xcstrings`, in all ten languages. Never hand-edit the catalog; use the script:

```bash
python3 scripts/strings.py add new-strings.json   # {"key": {"en": "…", "es": "…", "fr": "…", "it": "…", "ja": "…", "de": "…", "zh-Hant": "…", "zh-Hans": "…", "ko": "…", "pt-BR": "…"}}
python3 scripts/strings.py remove key [key …]
python3 scripts/strings.py check                   # must print 0 problem(s)
```

Copy uses smart punctuation and American spelling, and keeps system names (Synology, SHR, Unraid, ZFS, SnapRAID, Btrfs RAID1) untranslated.

## Project layout

```
RaidCalculator2/
├── Models.swift, RaidCalculator.swift      # RAID levels, configurations and the RAID tab's math
├── RaidCalculatorViewModel.swift           # RAID tab state and persistence
├── ContentView.swift                       # RAID tab UI, shared rows and the drive strip
├── ZFSEstimate.swift                       # What ZFS reports: padding and slop space
├── Bays.swift                              # Bay segments, results and suggestions shared by NAS systems
├── NAS.swift                               # NAS systems, settings, setups, hints, comparison
├── Synology.swift, ParityArrayCalculator.swift, ZFSMixedCalculator.swift, BtrfsRaid1Calculator.swift
├── NASViewModel.swift                      # Shared drives, per-system lens, current setup, persistence
├── NASView.swift, NASComparisonViews.swift # NAS tab UI, bay diagram, Compare Systems
├── AdaptiveLayout.swift                    # Two-column and bay-row rules (regular width, 800 × 600 pt or more)
├── TwoColumnLayout.swift                   # Results beside inputs; the fold-aware split and the info pane on iPhone Duo
├── Colors.swift                            # Data-mark fill color, kept apart from the contrast-darkened tint
├── InfoSheet.swift                         # The shared info sheet
├── Extensions.swift                        # Small shared helpers
├── Localizable.xcstrings                   # Every user-facing string, in ten languages
└── RaidCalculator2App.swift                # Tabs
```

## Docs

- `prd.md`: the product requirements, including every decision made for 1.5, 1.6 and 1.7.
- `PRODUCT.md`: who the app is for and how it should feel.
- `docs/RELEASE.md`: how App Store builds and the website ship.
- `docs/app-store-assets-brief.md`: the 1.7.0 store deliverables, sizes and the iPhone Duo traps.
- `docs/superpowers/plans/`: the implementation plans behind 1.5.0, 1.6.0 and 1.7.0, including the 1.6.5 polish, which ships in 1.7.0. The 1.7.0 plan is `2026-10-06-1.7.0-duo-and-review.md`.
- `scripts/store-assets/`: `compose.py` builds the composed App Store screenshots, `capture_duo.sh` captures iPhone Duo poses; see its README.
- `www/`: the product page. `marketing/`: listing copy and screenshots (`marketing/screenshots/1.7.0/`: `store/`, `raw/`, `ax-sweep/`).

## Releasing

- **App:** 1.7.0 is archived and uploaded from **local** Xcode 27.1 (27A9275). `.github/workflows/deploy.yml` can do it from a `v*` tag or a manual dispatch (it reuses `ios.yml` as its gate, then archives and uploads after approval in the `app-store` environment), but the `xcode-27` runner image carries a beta 27.1 build (27A9269) and App Store Connect rejects uploads built with a beta Xcode, so it isn’t used for 1.7.0. See `docs/RELEASE.md`.
- **Website:** push a `www-v<version>` tag. `.github/workflows/www.yml` deploys `www/` to the server.

## Trademarks

Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc. Not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc. ZFS is a trademark of Oracle and/or its affiliates. Not affiliated with or endorsed by Oracle.

## License

MIT. See [LICENSE](LICENSE).
