# Architecture

How RAID Calculator is built. For what the app does, see [README.md](README.md); for CI and releasing, see [DEPLOY.md](DEPLOY.md). The requirements and every product decision live in [prd.md](prd.md).

## Stack

- SwiftUI, with `@Observable` view models (MVVM-lite).
- iOS 26.0 deployment target, iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`). iPhone Duo is supported on iOS 27.1.
- Swift 6 with default MainActor isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) and approachable concurrency.
- Built with Xcode 27.1 and the iOS 27.1 SDK, which `TwoColumnLayout`’s `ArrangementView` and the fold reader need. Their 27.1 code sits behind `if #available(iOS 27.1, *)`.
- No third-party dependencies. Python 3 is used only for the strings tooling and the store-assets scripts.

Open `RAID Calculator.xcodeproj` and run the **RAID Calc** scheme. Folders are synchronized groups, so new `.swift` files are picked up without editing the project file.

## Project layout

```
RaidCalculator2/
├── RaidCalculator2App.swift      # Entry point: the RAID and NAS tabs, selected tab in @AppStorage
├── Models.swift                  # RaidLevel, RaidFamily, CapacityUnit, RaidConfiguration, RaidResult, DriveRole
├── RaidCalculator.swift          # RAID tab math: capacity, validation, failures, ratings, one-tap fixes, cautions
├── RaidCalculatorViewModel.swift # RAID tab state, clamping and persistence
├── ContentView.swift             # RAID tab UI, plus rows the NAS tab reuses (CapacitySummary, FailuresToleratedRow,
│                                 #   AdvisoryLabel, InvalidSetupPrefix, CountStepper, RatingRow, DriveSizeField, DriveStrip)
├── ZFSEstimate.swift             # What ZFS will report for a RAID-Z pool: padding and slop space
├── Bays.swift                    # Bay model shared by the NAS calculators: BaySegment, BayResult, BaySuggestion
├── NAS.swift                     # NASSystem, NASSettings, NASSetup, NASHint, NASCalculator (dispatch, Biggest Upgrade,
│                                 #   hints) and NASComparison
├── Synology.swift                # SynologyCalculator: SHR/SHR-2 layers and classic RAID 1/5/6
├── ParityArrayCalculator.swift   # Unraid and SnapRAID: dedicated parity on the largest drives
├── ZFSMixedCalculator.swift      # One RAID-Z group of mixed drives
├── BtrfsRaid1Calculator.swift    # Btrfs RAID1: two copies on different drives
├── NASViewModel.swift            # Shared drives, the per-system lens, the saved current setup, persistence
├── NASView.swift                 # NAS tab UI: system picker, bays, NASSummary, BayDiagram, current-setup section
├── NASComparisonViews.swift      # Compare Systems: a sheet in one column, columns in two
├── AdaptiveLayout.swift          # Pure layout rules: two columns, split margins, bay rows, grouped strip rows
├── TwoColumnLayout.swift         # Results beside inputs; the fold-aware split and in-pane info on iPhone Duo
├── InfoSheet.swift               # The info sheet shared by RAID levels and NAS systems
├── Colors.swift                  # Color.dataFill, the data-mark color kept apart from the tint
├── Extensions.swift              # String.localized()
├── Localizable.xcstrings         # Every user-facing string, in ten languages
├── Assets.xcassets               # AccentColor (the tint), DataColor, the Messages sticker icon
├── AppIcon.icon                  # App icon, with appearance variants
└── Preview Content/
RaidCalculator2Tests/             # Unit tests (Swift Testing), one suite per calculator and model
RaidCalculator2UITests/           # UI tests and launch tests (XCTest)
scripts/strings.py                # Add, remove and check catalog strings
scripts/store-assets/             # App Store screenshot composition and iPhone Duo capture
www/                              # The product page at mrballistic.com/raid
```

## Calculation model

Every calculator is a pure value type that takes a configuration and returns a result. Views never do math, and the unit tests call the calculators directly. All figures are simplified standard formulas; the only estimate is the ZFS one, and it is always labeled as such.

### RAID tab: identical drives

`RaidConfiguration` holds the level, drive count (1–24, `RaidCalculator.driveCountRange`), drive size, unit (GB or TB) and groups. `RaidCalculator.calculate(config:)` returns a `RaidResult`:

| Level | Usable | Failures tolerated | Minimum |
|---|---|---|---|
| RAID 0 | n × size | 0 | 1 drive |
| RAID 1 | size | n − 1 | 2 drives |
| RAID 5 | (n − 1) × size | 1 | 3 drives |
| RAID 6 | (n − 2) × size | 2 | 4 drives |
| RAID 10 | n/2 × size | 1, up to n/2 (depends on which drives fail) | 4 drives, even |
| JBOD | n × size | 0 | 1 drive |
| RAID 50 / 60 | groups × (width − parity) × size | parity, up to groups × parity | 2 groups; width 3 / 4 |
| RAID-Z1 / Z2 / Z3 | groups × (width − parity) × size | parity, up to groups × parity | width 2 / 3 / 4 |

- Grouped levels have 1, 2 or 3 parity drives per group (`RaidLevel.parityPerGroup`). The drive count must divide evenly into the groups. RAID 50 and 60 need two groups; with one they are RAID 5 and RAID 6.
- **One-tap fixes:** `suggestedDriveCount` (and `suggestedDriveCountGroups` when the fix also changes the groups) and `suggestedGroups`. Fixes never exceed 24 drives.
- **Rebuild caution:** RAID 5, RAID 50 and RAID-Z1 on drives of 8 TB or more return a `RebuildCaution`: `.suggest` RAID 6, RAID 60 or RAID-Z2 when the groups are wide enough to move up, otherwise `.warnOnly`. Three-drive RAID 5 is `.warnOnly`, since RAID 6 needs four.
- **Wide RAID-Z note:** `wideZFSGroupWidth` returns the width when a RAID-Z group is wider than 12 drives.
- **Ratings** are fixed 1–5 values per level (`speedRating`, `availabilityRating`), not benchmarks.
- `RaidResult.driveRoles` gives one data, parity or mirror role per drive for the drive strip, and `groupSize` puts gaps between groups.

### NAS tab: mixed drives, bay by bay

The drives are one array of optional sizes in TB (`nil` is an empty bay), shared by every system. A `NASSetup` is the system, its bays and `NASSettings`, which keeps every system’s own setting (Synology RAID type; Unraid, SnapRAID and ZFS parity) so switching systems and back restores it.

`NASCalculator.calculate(_:)` dispatches to one calculator per system:

| System | Calculator | Bays | Setting | Model |
|---|---|---|---|---|
| Synology | `SynologyCalculator` | 2–12 | SHR, SHR-2, RAID 1, 5, 6 | SHR splits the drives into layers at each distinct size and protects each layer reached by enough drives; a layer reached by too few is unused. Classic RAID treats every drive as the smallest. |
| Unraid | `ParityArrayCalculator` | 2–30 | 1–2 parity | The largest drives are parity (ties go to the lower bay); every data drive’s full size is usable. At most 28 data drives. |
| SnapRAID | `ParityArrayCalculator` | 2–30 | 1–6 parity | Same as Unraid, with no data-drive limit, plus SnapRAID’s published parity recommendation as a hint. |
| ZFS | `ZFSMixedCalculator` | 2–30 | RAID-Z1, Z2, Z3 | One RAID-Z group; each drive counts up to the smallest drive’s size, and the rest is unused. |
| Btrfs RAID1 | `BtrfsRaid1Calculator` | 2–30 | none | Usable is half the total, unless the largest drive is bigger than all the others combined; then its excess is unused. |

### The bay model

Each calculator returns a `BayResult`: usable, raw and unused capacity, failures tolerated, an optional warning, an optional `ZFSEstimate`, and `bays`, a list of `BaySegment`s per bay (bottom layer first, `nil` for an empty bay). A segment is a size with a `SegmentRole`: data, parity, mirror or unused. The bay diagram draws these segments to scale and hatches the unused ones; VoiceOver reads them as sentences. Zero-size slices are dropped (`withoutEmptySlices`), so an invalid layout never draws or reads a 0 TB layer.

On top of the result:

- **Biggest Upgrade** (`NASCalculator.suggestion`) returns a `BaySuggestion`, either `.add(bay:)` or `.replace(bay:currentSize:)`, with the size and the gain. The candidate depends on the system (the size of the largest drive for Synology and Btrfs, the smallest parity drive for Unraid and SnapRAID, the next size up replacing the uniquely smallest drive for ZFS), and is offered only when it actually gains space.
- **Hints** (`NASHint`) are advice, never a block: SnapRAID’s recommended parity count, and a RAID-Z group wider than 12 drives.
- **Compare Systems** (`compare(_:requestedBayCount:shownBayCount:)`) runs the same drives through every system, each with its own setting, sorted valid first, then most usable, then picker order. It flags systems that read fewer bays than set up (`bayLimit`, Synology stops at 12) or more than the current system shows (`readsAllBays`).

### The ZFS estimate

`ZFSEstimate` models what ZFS will report for a RAID-Z pool at OpenZFS defaults (4K sectors, 128K records). It is used by RAID-Z on the RAID tab and by the ZFS system on the NAS tab.

- **Padding:** a 128K record is 32 sectors. RAID-Z adds parity per row and rounds each allocation up to a multiple of parity + 1 sectors (`allocatedSectors(width:parity:)`), so some widths lose a slice of every record. `dataFraction` is 32 ÷ allocated sectors; `paddingLoss` is the shortfall against the textbook (width − parity) ÷ width.
- **Slop space:** ZFS holds back 1/32 of the pool, capped at 128 GiB, with a 128 MiB floor (or half the pool, if that is smaller). Verified against `spa_get_slop_space()` in OpenZFS 2.1.0–2.4.4.
- `reportedBytes` is data space minus slop. The views show it in TiB or GiB to match the chosen decimal unit.

## Persistence

Both view models write to `UserDefaults` on every change (guarded while loading) and read back on launch. There is no settings screen and no migration step.

| Key | Owner | Value |
|---|---|---|
| `selectedTab` | `RaidCalculator2App` (`@AppStorage`) | `"raid"` or `"nas"`. Anything else, such as 1.4’s `"synology"`, opens the RAID tab. |
| `selectedLevel` | `RaidCalculatorViewModel` | `RaidLevel` raw value: `"R 0"`, `"R 1"`, `"R 5"`, `"R 6"`, `"R 10"`, `"JBOD"`, `"R 50"`, `"R 60"`, `"Z1"`, `"Z2"`, `"Z3"`. These never change; an unknown value keeps the default. |
| `driveCount`, `driveSize`, `unit`, `groups` | `RaidCalculatorViewModel` | Integers, a double, `"GB"`/`"TB"`. A stored 0 falls back to the default (4 drives, 4 TB, 1 group). |
| `synology.bays` | `NASViewModel` | JSON `[Double?]`, every bay set up, including ones the current system hides. The key predates the NAS tab. |
| `nas.system`, `nas.bayCount` | `NASViewModel` | System raw value; the bay count asked for, before the system’s limit. |
| `nas.settings` | `NASViewModel` | JSON `NASSettings`. Parity values are clamped to each system’s range on load. |
| `nas.currentSetup` | `NASViewModel` | JSON `NASSetup`, the saved current setup, also clamped on load. |
| `nas.hasSavedCurrent` | `NASViewModel` | `true` once the user has saved a current setup. |
| `synology.raidType`, `synology.currentBays`, `synology.currentRaidType` | `NASViewModel` | Read only, as fallbacks from 1.4’s Synology tab. |

**The `hasSavedCurrent` rule.** The NAS tab compares changes only against a setup the user saved. Before 1.7.0 the sample setup (Synology SHR, 4, 4, 8 and 8 TB) was written to `nas.currentSetup` on every edit, so a stored setup alone proves nothing. On load, the user counts as having saved when:

- `nas.hasSavedCurrent` is `true`, or
- a stored `nas.currentSetup` (or 1.4’s `synology.currentBays`) exists and is not equivalent to the sample.

A stored setup equal to the sample counts as unsaved. The current setup and the flag are written only after Save as Current Setup, never on an ordinary edit. `NASSetup.isEquivalent(to:)` compares the system, the bays and only that system’s own setting.

Switching to a system with fewer bays hides the extra drives but keeps them; lowering the bay count explicitly trims them.

## Layout

Layouts follow size class and window size, never the device idiom.

- **`AdaptiveLayout`** holds the rules as pure functions, unit-tested in `AdaptiveLayoutTests`:
  - `usesTwoColumns`: a regular width class, at least 800 points wide (`twoColumnMinWidth`) and at least 600 points tall (`twoColumnMinHeight`). That puts iPad (full screen, either orientation) and iPhone Duo’s inner display in landscape (951 × 669) in two columns, and keeps iPad mini in portrait (744 wide) and every iPhone in landscape, the Pro Max (956 × 440) included, in one. The views measure height including the bars’ safe area, so the gate compares the window, not what is left under the bars.
  - `bayRows`: wraps a bay diagram into evenly shared rows at regular width, so 30 bays stay legible.
  - `groupsAsRows`: gives each RAID-tab group its own strip row at regular width, for two to six groups.
  - `splitInnerMargin`: the margin each pane takes where the split meets.
- **`TwoColumnLayout`** puts results beside inputs, results first in reading and VoiceOver order. It carries the `twoColumnLayout` accessibility identifier the UI tests look for.
  - On iOS 27.1 or later **and only on a device with a fold**, the columns are an `ArrangementView` with `.arrangementViewStyle(.split)`, which keeps iPhone Duo’s fold in the gap between them. Each pane takes the system container margin on its inner edge, and the grouped background is painted behind the split.
  - Everywhere else (iPad, any iPhone, or before 27.1) the columns are a plain `HStack` with a divider.
  - `readsFold` detects the fold from `reservedRegions(kind: .division, options: .includeInactive)`, a hardware feature rather than the idiom. It is always false before iOS 27.1.
- **In-pane info on iPhone Duo.** When two columns are showing on a device with a fold, the info button shows `InfoSheet` in the inputs pane (with the `infoInPane` environment value set) instead of a sheet, because a system sheet would land over the results. The inputs stay underneath, hidden, so their scroll position survives; the info button reads as selected while the pane is open, and VoiceOver focus returns to it on close. iPad and every single-column layout keep the modal sheet.
- In one column the Form centers at a readable width (720 points) on wide windows.

## Accessibility conventions

- **Dynamic Type at every size.** At accessibility sizes the level and unit pickers become menus with full level names, stepper and rating rows stack, the drive-size field leads under its label, and bay diagrams drop units.
- **VoiceOver:**
  - Segmented level picker segments read full names (“RAID 5”, not “5”).
  - Result rows combine into one element each. An invalid setup is announced, not only dimmed: `InvalidSetupPrefix` puts “Not a valid setup.” ahead of the capacity summary, the figures dim to 55%, the failures row hides, and the warning stays at full contrast.
  - The drive strip reads a summary, then each group, then each drive in it (“Group 2 of 3, drive 1: Parity”). Bay diagrams read each bay as a sentence, and empty bays have a localized label.
  - Ratings are stars with a text label and a spoken equivalent.
  - Advice uses `AdvisoryLabel`: an orange info symbol (errors keep the multicolor warning triangle) and the hint “Advice, not an error.”, with a one-tap fix button where one exists.
- **Contrast:** the tint (`AccentColor`) meets 4.5:1 against the system, secondary grouped and grouped backgrounds in light and dark mode, with darker Increase Contrast variants, pinned by `TintContrastTests`. Data marks (strip bars, bay swatches, stars, the shield) use `Color.dataFill`, which doesn’t need text contrast.
- **Reduce Motion:** layout changes use `.snappy` and numbers `.numericText()`. With Reduce Motion on, every animation falls back to a short crossfade with no movement; grouped strip rows and bay diagrams crossfade instead of sliding. There are no entrance animations.
- **Haptics:** `.selection` for pickers and steppers, `.success` only when a setup becomes valid.

## Strings and localization

All user-facing text lives in `RaidCalculator2/Localizable.xcstrings`, read with `"key".localized()`, in ten languages: `en`, `es`, `fr`, `it`, `ja`, `de`, `zh-Hant`, `zh-Hans`, `ko`, `pt-BR`. Info-sheet copy follows a key pattern: `<prefix>_description`, `_pros`, `_cons`, `_use_cases` and optionally `_calculation`, where the prefix is `RaidLevel.stringKeyPrefix` or the NAS system’s raw value.

Never hand-edit the catalog; Xcode and the script both rewrite it. Use `scripts/strings.py`:

```bash
# Add keys from a JSON file; every key needs all ten languages
python3 scripts/strings.py add new-strings.json
# {"key": {"en": "…", "es": "…", "fr": "…", "it": "…", "ja": "…", "de": "…", "zh-Hant": "…", "zh-Hans": "…", "ko": "…", "pt-BR": "…"}}

# Remove keys (to change a string: remove, then add)
python3 scripts/strings.py remove key [key …]

# Check every language is translated with matching format specifiers; must print 0 problem(s)
python3 scripts/strings.py check
```

CI runs the check on every push and pull request. A build can reorder the catalog or add auto-extracted literals; the check skips entries with no localizations.

Copy and glossary rules:

- Smart punctuation (“ ” ’) and American spelling. Em-dashes are rare and closed up; en dashes in ranges stay. Use positional specifiers (`%1$d`, `%2$@`) when a string has more than one.
- System names stay untranslated: Synology, SHR, SHR-2, Unraid, ZFS, RAID-Z1/Z2/Z3, SnapRAID, Btrfs RAID1.
- Spanish says “disco” on the NAS tab and “unidad” on the RAID tab and in the info sheets.
- Japanese counts drives with 台 on both tabs.
- French puts a no-break space (U+00A0) before `:` and a narrow no-break space (U+202F) before `;`, `!` and `?`.
- German uses “Laufwerk” and “Setup”, with informal “du”. Traditional Chinese uses 硬碟 counted with 顆, Simplified Chinese 硬盘 counted with 块, both with 配置 for “setup”. Korean uses 드라이브 counted with 개. Brazilian Portuguese uses “você”.
- Trademark lines (`not_affiliated`, `unraid_not_affiliated`, `zfs_not_affiliated`) appear only in the matching info sheets; the RAID-Z sheets carry the ZFS line.

## Testing

| Target | Folder | Framework |
|---|---|---|
| RAID CalcTests | `RaidCalculator2Tests/` | Swift Testing |
| RAID CalcUITests | `RaidCalculator2UITests/` | XCTest (plus the launch tests) |

Always pass `-parallel-testing-enabled NO`: parallel Simulator clones time out.

```bash
# Unit tests only, as CI runs them
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcTests"

# The UI suite (about 15 minutes), run locally before each release
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcUITests"

# The same UI suite on iPad, so the two-column tests run instead of skipping
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcUITests"
```

- CI runs only the strings check and the unit tests (see [DEPLOY.md](DEPLOY.md)). The UI suite and launch tests run locally.
- `launchApp` passes `-selectedTab raid` (and the level, drives, size and groups as launch arguments), so RAID-tab tests start on the RAID tab whatever was stored; the NAS helper passes `-selectedTab nas`.
- The `testIPad*` tests skip unless the `twoColumnLayout` identifier is on screen. That layout follows size class and window size, not device type, so they skip on iPhone and run on an iPad Simulator and on iPhone Duo’s inner display in landscape.
- iPhone Duo needs the iOS 27.1 Simulator runtime. Its pose and rotation can’t be scripted; set them in the Simulator and Xcode’s Device Hub.
- The Reduce Motion pass is manual, on iPhone and iPad, before each release.

## Store assets

`scripts/store-assets/` builds the App Store screenshots: `compose.py` composes raw Simulator captures into the store images (and the header and search art) at Apple’s exact sizes, and `capture_duo.sh` captures iPhone Duo poses. Setup, sizes, folders and usage are in [scripts/store-assets/README.md](scripts/store-assets/README.md); the 1.7.0 deliverables and the iPhone Duo traps are in [docs/app-store-assets-brief.md](docs/app-store-assets-brief.md).
