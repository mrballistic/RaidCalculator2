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

Unit tests use Swift Testing (`RaidCalculator2Tests/`), and UI tests use XCTest (`RaidCalculator2UITests/`). Run them serially; parallel Simulator clones time out.

```bash
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO
```

The `testIPad*` UI tests skip unless the two-column layout is on screen (they look for its `twoColumnLayout` identifier, and that layout follows size class and window size, not device type), so they skip on iPhone in portrait and run on an iPad Simulator (for example `name=iPad Pro 13-inch (M5)`) and on iPhone Duo’s inner display in landscape. iPhone Duo needs the iOS 27.1 Simulator runtime, and its pose and rotation can’t be scripted: set them in the Simulator and Xcode’s Device Hub.

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
├── AdaptiveLayout.swift                    # Two-column and bay-row rules
├── InfoSheet.swift                         # The shared info sheet
└── RaidCalculator2App.swift                # Tabs
```

## Docs

- `prd.md`: the product requirements, including every decision made for 1.5, 1.6 and 1.7.
- `PRODUCT.md`: who the app is for and how it should feel.
- `docs/RELEASE.md`: how App Store builds ship.
- `docs/superpowers/plans/`: the implementation plans behind 1.5.0, 1.6.0 and 1.7.0 (including the 1.6.5 polish, which ships in 1.7.0).
- `www/`: the product page. `marketing/`: listing copy and screenshots.

## Releasing

- **App:** push a `v<version>` tag (for example `v1.7.0`). `.github/workflows/deploy.yml` runs the full CI gate, archives and uploads to App Store Connect after approval in the `app-store` environment. See `docs/RELEASE.md`. App Store Connect rejects uploads built with a beta Xcode, so if the CI image’s Xcode 27.1 is still a beta, archive and upload 1.7.0 locally from Xcode instead.
- **Website:** push a `www-v<version>` tag. `.github/workflows/www.yml` deploys `www/` to the server.

## Trademarks

Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc. Not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc. ZFS is a trademark of Oracle and/or its affiliates. Not affiliated with or endorsed by Oracle.

## License

MIT. See [LICENSE](LICENSE).
