# RAID Calc2 Legacy Release (1.8.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn this codebase, on branch `legacy/raidcalc2`, into RAID Calc2 1.8.0: a classic-levels RAID calculator with a desaturated icon and a retirement notice pointing to RAID Calculator, plus its full App Store listing and screenshots.

**Architecture:** Subtract first: the NAS tab, then the nested and ZFS levels, then their strings. Then add a small pure `Retirement` type (date, phase, copy, store IDs), an `AppStorePage` presenter wrapping `SKStoreProductViewController`, and two views (a first-launch sheet and a permanent banner) wired into `ContentView`. Store assets reuse `scripts/store-assets/compose.py` and `capture_duo.sh`, extended with a legacy mode, so the 1.7.0 pipeline is untouched.

**Tech Stack:** Swift 6, SwiftUI, iOS 26 SDK (Xcode 27.1), StoreKit (`SKStoreProductViewController`), Swift Testing (unit), XCTest (UI), Python 3 + Pillow (icon and screenshots), `scripts/strings.py` (string catalog).

**Spec:** `docs/superpowers/specs/2026-10-13-raidcalc2-legacy-design.md`

## Global Constraints

- Branch `legacy/raidcalc2` only. Push it, but never open a PR and never merge into `main`. No `v*` tags; if a tag is wanted, it's `legacy-v1.8.0`.
- App target: `PRODUCT_BUNDLE_IDENTIFIER = com.mrballistic.RaidCalculator2`, `INFOPLIST_KEY_CFBundleDisplayName = "RAID Calc2"`, `MARKETING_VERSION = 1.8.0`, `CURRENT_PROJECT_VERSION = 1`. `IPHONEOS_DEPLOYMENT_TARGET` stays `26.0`. Test-target bundle IDs are unchanged.
- Levels: RAID 0, 1, 5, 6, 10 and JBOD only. Persisted raw values (`"R 0"`, `"R 1"`, `"R 5"`, `"R 6"`, `"R 10"`, `"JBOD"`) never change. An unknown stored level loads as RAID 5.
- Retirement date: **December 31, 2026**, the last day on sale, as a Gregorian date in the user's own time zone. `.retired` from local midnight starting January 1, 2027.
- New app: App Store ID `395601653`. Fallback URL `https://apps.apple.com/app/id395601653`.
- Defaults keys: `legacy.hasSeenRetirementNotice` (Bool). DEBUG-only launch hooks: `legacy.resetNotice` (Bool) and `legacy.now` (`yyyy-MM-dd`).
- All user-facing copy in all 10 languages (`en es fr it ja de zh-Hant zh-Hans ko pt-BR`), added only through `scripts/strings.py add`, never by hand-editing the catalog. Curly punctuation (’ “ ”). At most one em-dash per sentence in app UI copy, closed up. "RAID Calc2" and "RAID Calculator" are never translated.
- Store copy and screenshot headlines: **no em-dashes at all**; "iPhone"/"iPad" exactly so, never capitalised or plural; trademarks spelled exactly and used descriptively; no prices, URLs or awards.
- Screenshots are English only, used for every localization. Only listing text is translated.
- Machine hygiene: one booted Simulator at a time, one `xcodebuild` at a time. Never write a wait loop whose pattern can match itself (`pgrep -f` on its own command line). Shut down Simulators you booted when a task ends.
- Every `xcodebuild test` passes `-parallel-testing-enabled NO`.
- Module name in tests: `@testable import RAID_Calc`. Scheme `RAID Calc`. Targets `RAID CalcTests` and `RAID CalcUITests`.

**Standard commands** (each task refers to them by name):

```bash
# UNIT: unit tests on iPhone 17
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcTests" 2>&1 | tail -40

# UI <test>: one UI test on iPhone 17
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:"RAID CalcUITests/RaidCalculator2UITests/<test>" 2>&1 | tail -40

# BUILD: compile only
xcodebuild build -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|warning: .*deprecated|BUILD (SUCCEEDED|FAILED)"

# STRINGS
python3 scripts/strings.py check
```

## Review Focus

1. **A user whose calendar isn't Gregorian** (Japanese imperial or Buddhist calendar in Settings). They expect the same day, December 31, 2026, written in their calendar, and the switch on the same day as everyone else. Pinned in Task 5 (`japaneseCalendarUserSeesTheSameDay`, `phaseIgnoresTheUserCalendar`).
2. **Time zones at the date line** (Kiritimati UTC+14, Baker Island UTC−12). They expect the copy to switch at their own local midnight and the date to read December 31 wherever they are. Pinned in Task 5 (`retiringThroughTheLastLocalDay`, `dateTextIsTheLastDayEverywhere`).
3. **Stored state from a newer build** (TestFlight 1.4+ wrote `selectedLevel = "R 50"`, `"Z2"`, `groups = 3`, `selectedTab = "nas"`). They expect the app to open on RAID 5 without crashing. Pinned in Task 3 (`LegacyStateTests`) and Task 2 (the app no longer reads `selectedTab`).
4. **The store page can't load** (offline, or in the Simulator, which has no App Store). They expect the button to still go somewhere: the App Store URL opens, and no blank modal is left on screen. Manual check in Task 6, Step 8.
5. **The largest text size, and long German or French copy.** They expect the sheet's two buttons to stay reachable and the banner to wrap, never truncate. Pinned in Task 6 (`testRetirementNoticeAtLargestTextSize`), with truncation checked by eye in the Task 9 screenshots.

---

### Task 1: Identity, title and branch notice

**Files:**
- Modify: `RAID Calculator.xcodeproj/project.pbxproj` (app target Debug and Release build settings)
- Modify: `README.md` (first line)
- Modify: `RaidCalculator2/Localizable.xcstrings` (via `strings.py`, key `app_title`)
- Modify: `RaidCalculator2UITests/RaidCalculator2UITests.swift` (navigation bar title assertions)

**Interfaces:**
- Produces: the navigation title "RAID Calc2" in every language; UI tests assert `app.navigationBars["RAID Calc2"]`.

- [ ] **Step 1: Change the app target's identity**

```bash
sed -i '' \
  -e 's/PRODUCT_BUNDLE_IDENTIFIER = 53Q4825KDF;/PRODUCT_BUNDLE_IDENTIFIER = com.mrballistic.RaidCalculator2;/' \
  -e 's/INFOPLIST_KEY_CFBundleDisplayName = "RAID Calculator";/INFOPLIST_KEY_CFBundleDisplayName = "RAID Calc2";/' \
  -e 's/MARKETING_VERSION = 1.7.0;/MARKETING_VERSION = 1.8.0;/' \
  "RAID Calculator.xcodeproj/project.pbxproj"
grep -n "PRODUCT_BUNDLE_IDENTIFIER\|CFBundleDisplayName\|MARKETING_VERSION\|CURRENT_PROJECT_VERSION" "RAID Calculator.xcodeproj/project.pbxproj"
```

Expected: the app target shows `com.mrballistic.RaidCalculator2`, `"RAID Calc2"` and `1.8.0` twice each (Debug and Release). The test targets still show `com.mrballistic.RaidCalculator2Tests` / `UITests` and `MARKETING_VERSION = 1.0`. `CURRENT_PROJECT_VERSION = 1` everywhere.

- [ ] **Step 2: Make the navigation title "RAID Calc2" in every language**

Write `/tmp/raid-legacy/app-title.json`:

```json
{"app_title": {"en": "RAID Calc2", "es": "RAID Calc2", "fr": "RAID Calc2", "it": "RAID Calc2", "ja": "RAID Calc2", "de": "RAID Calc2", "zh-Hant": "RAID Calc2", "zh-Hans": "RAID Calc2", "ko": "RAID Calc2", "pt-BR": "RAID Calc2"}}
```

Run: `python3 scripts/strings.py add /tmp/raid-legacy/app-title.json && python3 scripts/strings.py check`
Expected: `added 1 key(s)`, then a clean check.

- [ ] **Step 3: Update UI-test title assertions**

```bash
grep -n 'navigationBars\["RAID Calculator"\]' RaidCalculator2UITests/RaidCalculator2UITests.swift
sed -i '' 's/navigationBars\["RAID Calculator"\]/navigationBars["RAID Calc2"]/g' RaidCalculator2UITests/RaidCalculator2UITests.swift
```

Also grep for localized titles that tests assert in other languages (`RAID-Rechner`, `Calculadora RAID`, `Calculateur RAID`, `Calcolatore RAID`, `RAID計算機`, `RAID 계산기`, `RAID 计算器`, `RAID 計算機`) and replace each with `RAID Calc2`.

- [ ] **Step 4: Add the branch notice to the README**

Insert as the very first lines of `README.md`:

```markdown
> **Branch `legacy/raidcalc2`:** the final RAID Calc2 release (`com.mrballistic.RaidCalculator2`, App Store 6755641457). Never open a pull request from this branch or merge it into `main`. Spec: `docs/superpowers/specs/2026-10-13-raidcalc2-legacy-design.md`.

```

- [ ] **Step 5: Verify**

Run `xcodebuild -showBuildSettings -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" 2>/dev/null | grep -E " PRODUCT_BUNDLE_IDENTIFIER| MARKETING_VERSION| INFOPLIST_KEY_CFBundleDisplayName"`
Expected: `com.mrballistic.RaidCalculator2`, `1.8.0`, `RAID Calc2`.
Run UI `testAppLaunchesSuccessfully`. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add "RAID Calculator.xcodeproj/project.pbxproj" README.md RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Make this branch RAID Calc2 1.8.0"
```

---

### Task 2: Remove the NAS tab

**Files:**
- Delete: `RaidCalculator2/{NASView,NASViewModel,NASComparisonViews,NAS,Synology,Bays,ParityArrayCalculator,ZFSMixedCalculator,BtrfsRaid1Calculator}.swift`
- Delete: `RaidCalculator2Tests/{NASCalculatorTests,NASModelTests,NASViewModelTests,SynologyCalculatorTests,ParityArrayCalculatorTests,ZFSMixedCalculatorTests,BtrfsRaid1CalculatorTests}.swift`
- Modify: `RaidCalculator2/RaidCalculator2App.swift` (whole file)
- Modify: `RaidCalculator2/InfoSheet.swift` (remove `InfoTopic.system`)
- Modify: `RaidCalculator2Tests/InfoSheetCopyTests.swift`
- Modify: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

The project uses file-system-synchronized groups, so deleting a file removes it from the target. No `project.pbxproj` edit is needed.

**Interfaces:**
- Produces: `RaidCalculator2App` shows `NavigationStack { ContentView() }` with no `TabView`. The `selectedTab` key is no longer read.

- [ ] **Step 1: Confirm the files to delete have no RAID-tab callers**

```bash
grep -n "NASSystem\|BayResult\|BaySegment\|SegmentRole\|withoutEmptySlices\|ParityArray\|ZFSMixed\|BtrfsRaid1\|Synology" RaidCalculator2/ContentView.swift RaidCalculator2/InfoSheet.swift RaidCalculator2/AdaptiveLayout.swift RaidCalculator2/TwoColumnLayout.swift RaidCalculator2/Models.swift RaidCalculator2/RaidCalculator.swift RaidCalculator2/RaidCalculatorViewModel.swift
```

Expected: only `InfoSheet.swift`'s `static func system(_ system: NASSystem)`. If anything else matches, stop and report it.

- [ ] **Step 2: Delete the NAS sources and their tests**

```bash
git rm -q RaidCalculator2/{NASView,NASViewModel,NASComparisonViews,NAS,Synology,Bays,ParityArrayCalculator,ZFSMixedCalculator,BtrfsRaid1Calculator}.swift
git rm -q RaidCalculator2Tests/{NASCalculatorTests,NASModelTests,NASViewModelTests,SynologyCalculatorTests,ParityArrayCalculatorTests,ZFSMixedCalculatorTests,BtrfsRaid1CalculatorTests}.swift
```

- [ ] **Step 3: Replace `RaidCalculator2App.swift`**

```swift
//
//  RaidCalculator2App.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

@main
struct RaidCalculator2App: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
```

- [ ] **Step 4: Drop `InfoTopic.system`**

In `RaidCalculator2/InfoSheet.swift`, delete:

```swift
    static func system(_ system: NASSystem) -> InfoTopic {
        InfoTopic(title: system.displayName, keyPrefix: system.stringKeyPrefix, ratings: nil, footnoteKey: system.notAffiliatedKey)
    }
```

Change the doc comment on `struct InfoTopic` to `/// What an info sheet is about: a RAID level.`

- [ ] **Step 5: Drop the NAS copy tests**

In `RaidCalculator2Tests/InfoSheetCopyTests.swift`, delete `everySystemHasItsSheetCopy`, `snapraidSheetSaysProtectionIsOnlyAsCurrentAsTheLastSync` and `zfsSheetExplainsTheReservation` (with its `// Final review M7` comment). `zfsLevelsExplainTheEstimate` goes in Task 3.

- [ ] **Step 6: Remove the NAS UI tests and helpers**

In `RaidCalculator2UITests/RaidCalculator2UITests.swift`, delete these test methods: `testBayDiagramColumnsKeepTheirOwnFrames`, `testNASSwitchSystem`, `testNASSettingsPerSystem`, `testSnapRAIDParityHint`, `testSnapRAIDHintAppliesParity`, `testNASInfoSheetHasTrademarkLine`, `testCompareSystemsSwitchesSystem`, `testFreshInstallAsksToSaveFirst`, `testRevertAsksForConfirmation`, `testUnknownStoredTabOpensRaidTab`, `testIPadNASPutsResultsBesideInputs`, `testIPadShowsThirtyBaysWithoutScrolling`, `testIPadComparesSystemsInColumns`, `testIPadComparesSystemsInColumnsInPortrait`, `testIPadSwitchToSynologyFromThirtyBays`.

Delete these helpers: `launchNAS`, `nasCapacity`, `tabButton`, `tabBarFrame`, plus any helper whose only callers were the deleted tests (`grep -n "func " ...` and check each private helper still has a caller).

In `launchApp`, delete the two lines:

```swift
            // A test that leaves the NAS tab selected must not move the next one.
            "-selectedTab", "raid",
```

In `reveal(_:in:scrollingDown:)`, delete the tab-bar block:

```swift
        // The floating tab bar covers the last rows, which still report hittable.
        if element.exists, let bar = tabBarFrame(in: app), element.frame.intersects(bar) {
            scroll(down: true)
        }
```

Then run `grep -n "nas\|NAS\|Synology\|tabBar\|selectedTab\|Bay" RaidCalculator2UITests/RaidCalculator2UITests.swift`. Expected: no matches, apart from words inside unrelated identifiers (check each one).

- [ ] **Step 7: Build and run the unit tests**

Run BUILD, then UNIT. Expected: BUILD SUCCEEDED, all unit tests pass.
Run UI `testAppLaunchesSuccessfully`. Expected: PASS, with no tab bar on screen.

- [ ] **Step 8: Commit**

```bash
git add -A RaidCalculator2 RaidCalculator2Tests RaidCalculator2UITests
git commit -m "Remove the NAS tab"
```

---

### Task 3: Classic levels only

**Files:**
- Create: `RaidCalculator2Tests/LegacyStateTests.swift`
- Modify (whole file): `RaidCalculator2/Models.swift`, `RaidCalculator2/RaidCalculator.swift`, `RaidCalculator2/RaidCalculatorViewModel.swift`
- Modify: `RaidCalculator2/ContentView.swift` (`answerSections`, `inputSections`, `CapacitySummary`, level bindings and helpers)
- Modify: `RaidCalculator2/InfoSheet.swift` (`InfoTopic.level` footnote)
- Delete: `RaidCalculator2/ZFSEstimate.swift`, `RaidCalculator2Tests/ZFSEstimateTests.swift`, `RaidCalculator2Tests/GroupedLevelTests.swift` (after Step 1)
- Modify: `RaidCalculator2Tests/ModelTests.swift` (whole file), `RaidCalculator2Tests/InfoSheetCopyTests.swift`, `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Produces: `enum RaidLevel: String, CaseIterable, Identifiable` with exactly `raid0, raid1, raid5, raid6, raid10, jbod`, and `displayName`, `shortLabel`, `stringKeyPrefix`.
- Produces: `struct RaidConfiguration { level, driveCount, driveSize, unit }` (no `groups`).
- Produces: `struct RaidResult { usableCapacity, rawCapacity, failuresTolerated, speedRating, availabilityRating, warningMessage, suggestedDriveCount, driveRoles }` plus `efficiency`.
- Produces: `RaidCalculatorViewModel.init(userDefaults: UserDefaults = .standard)`; `selectedLevel`, `driveCount`, `driveSize`, `unit`, `result`, `rebuildCaution`, `applySuggestedDriveCount()`.
- Produces: `enum RebuildCaution { case suggest(RaidLevel), warnOnly }`. `.warnOnly` now means only "RAID 5 on 3 drives".

- [ ] **Step 1: Keep the classic-level tests from `GroupedLevelTests` before deleting it**

Run: `grep -n "@Test\|level: \.\|\.raid5\|\.raid6" RaidCalculator2Tests/GroupedLevelTests.swift`
Move any test that uses only `.raid0/.raid1/.raid5/.raid6/.raid10/.jbod`, with no `groups:`, into `RaidCalculator2Tests/RaidCalculator2Tests.swift` unchanged (rebuild-caution tests on RAID 5 are the likely ones). Then:

```bash
git rm -q RaidCalculator2Tests/GroupedLevelTests.swift RaidCalculator2Tests/ZFSEstimateTests.swift
```

- [ ] **Step 2: Write the failing stored-state test**

Create `RaidCalculator2Tests/LegacyStateTests.swift`:

```swift
//
//  LegacyStateTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

/// RAID Calc2 1.8.0 keeps only the classic levels. A setup saved by a
/// TestFlight build of 1.4 or later can name a level this build doesn't
/// have; it must open on RAID 5, not crash or show nothing.
@MainActor @Suite(.serialized)
struct LegacyStateTests {
    private func defaults(_ values: [String: Any]) -> UserDefaults {
        let name = "LegacyStateTests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        for (key, value) in values { defaults.set(value, forKey: key) }
        return defaults
    }

    @Test(arguments: ["R 50", "R 60", "Z1", "Z2", "Z3", "nonsense"])
    func unknownStoredLevelOpensOnRAID5(raw: String) {
        let model = RaidCalculatorViewModel(userDefaults: defaults(["selectedLevel": raw, "groups": 3, "driveCount": 6]))
        #expect(model.selectedLevel == .raid5)
        #expect(model.driveCount == 6)
        #expect(model.result.warningMessage == nil)
    }

    @Test(arguments: [("R 0", RaidLevel.raid0), ("R 1", .raid1), ("R 5", .raid5), ("R 6", .raid6), ("R 10", .raid10), ("JBOD", .jbod)])
    func classicStoredLevelsStillLoad(raw: String, level: RaidLevel) {
        let model = RaidCalculatorViewModel(userDefaults: defaults(["selectedLevel": raw]))
        #expect(model.selectedLevel == level)
    }
}
```

- [ ] **Step 3: Run it to confirm it fails**

Run UNIT. Expected: compile error, because `RaidCalculatorViewModel(userDefaults:)` doesn't exist yet.

- [ ] **Step 4: Replace `RaidCalculator2/Models.swift`**

```swift
//
//  Models.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

enum RaidLevel: String, CaseIterable, Identifiable {
    case raid0 = "R 0"
    case raid1 = "R 1"
    case raid5 = "R 5"
    case raid6 = "R 6"
    case raid10 = "R 10"
    case jbod = "JBOD"

    var id: String { rawValue }

    /// Full name for headings, VoiceOver and the info sheet. The raw value stays
    /// "R 5" etc. because it's what UserDefaults has persisted since 1.0.
    var displayName: String {
        switch self {
        case .raid0: "RAID 0"
        case .raid1: "RAID 1"
        case .raid5: "RAID 5"
        case .raid6: "RAID 6"
        case .raid10: "RAID 10"
        case .jbod: "JBOD"
        }
    }

    /// Segment label. The section header already says “RAID Level”, so the
    /// numerals alone are enough and six of them fit on the narrowest iPhone.
    var shortLabel: String {
        switch self {
        case .raid0: "0"
        case .raid1: "1"
        case .raid5: "5"
        case .raid6: "6"
        case .raid10: "10"
        case .jbod: "JBOD"
        }
    }

    /// Prefix for this level's keys in Localizable.xcstrings (raid5_description…).
    var stringKeyPrefix: String {
        switch self {
        case .raid0: "raid0"
        case .raid1: "raid1"
        case .raid5: "raid5"
        case .raid6: "raid6"
        case .raid10: "raid10"
        case .jbod: "jbod"
        }
    }
}

/// What each physical drive contributes to the array, for the drive strip.
enum DriveRole {
    case data
    case parity
    case mirror
}

enum CapacityUnit: String, CaseIterable, Identifiable {
    case gb = "GB"
    case tb = "TB"
    
    var id: String { rawValue }
}

struct RaidConfiguration {
    var level: RaidLevel
    var driveCount: Int
    var driveSize: Double
    var unit: CapacityUnit
}

struct RaidResult {
    var usableCapacity: Double     // normalized to selected unit
    var rawCapacity: Double        // driveCount × driveSize, same unit
    var failuresTolerated: String  // string to allow "up to 3"
    var speedRating: Int           // 1–5
    var availabilityRating: Int    // 1–5
    var warningMessage: String?    // for invalid configs
    var suggestedDriveCount: Int?  // nearest valid count when the count is the problem
    var driveRoles: [DriveRole]    // one entry per drive, in display order

    var efficiency: Double { rawCapacity > 0 ? usableCapacity / rawCapacity : 0 }
}
```

- [ ] **Step 5: Replace `RaidCalculator2/RaidCalculator.swift`**

```swift
//
//  RaidCalculator.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

struct RaidCalculator {

    static let driveCountRange = 1...24

    func validate(_ config: RaidConfiguration) -> String? {
        if let count = invalidDriveCountKey(config) {
            return count.localized()
        }
        if !(config.driveSize > 0) {
            return "drive_size_invalid".localized()
        }
        return nil
    }

    /// Nearest valid drive count at or above the current one, when the count
    /// is what makes the configuration invalid. Drives the one-tap fix.
    func suggestedDriveCount(for config: RaidConfiguration) -> Int? {
        let n = config.driveCount
        guard invalidDriveCountKey(config) != nil else { return nil }
        switch config.level {
        case .raid0, .jbod: return max(n, 1)
        case .raid1: return max(n, 2)
        case .raid5: return max(n, 3)
        case .raid6: return max(n, 4)
        case .raid10: return max(n + n % 2, 4)
        }
    }

    /// RAID 5 on drives of 8 TB or more: a rebuild takes days, and a second
    /// failure during it loses the array.
    func rebuildCaution(for config: RaidConfiguration) -> RebuildCaution? {
        guard validate(config) == nil, config.level == .raid5 else { return nil }
        let terabytes = config.unit == .tb ? config.driveSize : config.driveSize / 1000
        guard terabytes >= 8 else { return nil }
        // RAID 6 needs a fourth drive; below that, warn without a level to move to.
        var raid6 = config
        raid6.level = .raid6
        return validate(raid6) == nil ? .suggest(.raid6) : .warnOnly
    }

    private func invalidDriveCountKey(_ config: RaidConfiguration) -> String? {
        let n = config.driveCount
        switch config.level {
        case .raid0: return n < 1 ? "raid0_validation" : nil
        case .raid1: return n < 2 ? "raid1_validation" : nil
        case .raid5: return n < 3 ? "raid5_validation" : nil
        case .raid6: return n < 4 ? "raid6_validation" : nil
        case .raid10: return n < 4 || n % 2 != 0 ? "raid10_validation" : nil
        case .jbod: return n < 1 ? "jbod_validation" : nil
        }
    }

    func calculate(config: RaidConfiguration) -> RaidResult {
        let n = config.driveCount
        let size = config.driveSize  // assume already in chosen unit

        var usable: Double
        var failures: String
        var roles: [DriveRole]

        switch config.level {
        case .raid0:
            usable = Double(n) * size
            failures = "raid0_failures".localized()
            roles = Array(repeating: .data, count: n)
        case .raid1:
            usable = size
            failures = String(format: "raid1_failures".localized(), max(0, n - 1))
            roles = [.data] + Array(repeating: .mirror, count: max(0, n - 1))
        case .raid5:
            usable = Double(max(0, n - 1)) * size
            failures = "raid5_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 1)) + [.parity]
        case .raid6:
            usable = Double(max(0, n - 2)) * size
            failures = "raid6_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 2)) + Array(repeating: .parity, count: min(2, n))
        case .raid10:
            usable = Double(n / 2) * size
            failures = String(format: "raid10_failures".localized(), n / 2)
            // Mirrored pairs, striped: data, copy, data, copy…
            roles = (0..<n).map { $0.isMultiple(of: 2) ? .data : .mirror }
        case .jbod:
            usable = Double(n) * size
            failures = "jbod_failures".localized()
            roles = Array(repeating: .data, count: n)
        }

        return RaidResult(
            usableCapacity: usable,
            rawCapacity: Double(n) * size,
            failuresTolerated: failures,
            speedRating: speedRating(for: config.level),
            availabilityRating: availabilityRating(for: config.level),
            warningMessage: validate(config),
            suggestedDriveCount: suggestedDriveCount(for: config),
            driveRoles: Array(roles.prefix(n))
        )
    }

    func speedRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0: return 5
        case .raid10: return 4
        case .raid5: return 3
        case .raid6, .raid1, .jbod: return 2
        }
    }

    func availabilityRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0, .jbod: return 1
        case .raid5: return 3
        case .raid6: return 4
        case .raid1, .raid10: return 5
        }
    }

    /// Word for a 1–5 rating, shared by the results and the info sheet.
    static func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "very_high".localized()
        case 4: return "high".localized()
        case 3: return "medium".localized()
        case 2: return "low".localized()
        case 1: return "very_low".localized()
        default: return ""
        }
    }
}

enum RebuildCaution: Equatable {
    /// RAID 6, which this setup has the drives for.
    case suggest(RaidLevel)
    /// RAID 5 on three large drives: one short of RAID 6, so warn without a suggestion.
    case warnOnly
}
```

- [ ] **Step 6: Replace `RaidCalculator2/RaidCalculatorViewModel.swift`**

```swift
//
//  RaidCalculatorViewModel.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation
import SwiftUI

@Observable
final class RaidCalculatorViewModel {
    static let driveCountRange = RaidCalculator.driveCountRange
    /// Upper bound for a single drive, in either unit. Keeps a stray paste from
    /// producing a capacity no layout can hold.
    static let maxDriveSize = 999_999.0

    var selectedLevel: RaidLevel = .raid5 { didSet { saveConfiguration() } }
    var driveCount: Int = 4 {
        didSet {
            let clamped = min(max(driveCount, Self.driveCountRange.lowerBound), Self.driveCountRange.upperBound)
            if clamped != driveCount { driveCount = clamped } else { saveConfiguration() }
        }
    }
    var driveSize: Double = 4 {
        didSet {
            if driveSize > Self.maxDriveSize { driveSize = Self.maxDriveSize } else { saveConfiguration() }
        }
    }
    var unit: CapacityUnit = .tb { didSet { saveConfiguration() } }

    private var configuration: RaidConfiguration {
        RaidConfiguration(level: selectedLevel, driveCount: driveCount, driveSize: driveSize, unit: unit)
    }

    /// Recomputed whenever an input changes; Observation tracks the reads.
    var result: RaidResult { calculator.calculate(config: configuration) }

    /// RAID 5 on drives of 8 TB or more: a suggested level, or a bare warning.
    var rebuildCaution: RebuildCaution? { calculator.rebuildCaution(for: configuration) }

    @ObservationIgnored private let calculator = RaidCalculator()
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var isLoading = false

    private struct Keys {
        static let selectedLevel = "selectedLevel"
        static let driveCount = "driveCount"
        static let driveSize = "driveSize"
        static let unit = "unit"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadConfiguration()
    }

    func applySuggestedDriveCount() {
        if let suggested = result.suggestedDriveCount {
            driveCount = suggested
        }
    }

    private func saveConfiguration() {
        guard !isLoading else { return }
        userDefaults.set(selectedLevel.rawValue, forKey: Keys.selectedLevel)
        userDefaults.set(driveCount, forKey: Keys.driveCount)
        userDefaults.set(driveSize, forKey: Keys.driveSize)
        userDefaults.set(unit.rawValue, forKey: Keys.unit)
    }

    private func loadConfiguration() {
        isLoading = true
        defer { isLoading = false }

        // A level a newer build saved (RAID 50, RAID-Z…) matches nothing here,
        // so the default, RAID 5, stays.
        if let levelString = userDefaults.string(forKey: Keys.selectedLevel),
           let level = RaidLevel.allCases.first(where: { $0.rawValue == levelString }) {
            selectedLevel = level
        }

        driveCount = userDefaults.integer(forKey: Keys.driveCount)
        if driveCount == 0 { driveCount = 4 }

        driveSize = userDefaults.double(forKey: Keys.driveSize)
        if driveSize == 0 { driveSize = 4 }

        if let unitString = userDefaults.string(forKey: Keys.unit),
           let loadedUnit = CapacityUnit.allCases.first(where: { $0.rawValue == unitString }) {
            unit = loadedUnit
        }
    }
}
```

- [ ] **Step 7: Simplify `ContentView.swift`'s answer sections**

Replace everything inside `answerSections` after the `CapacitySummary` section (from `if let warning = result.warningMessage {` through the `.transition(.opacity)` closing the caution section) with:

```swift
        if let warning = result.warningMessage {
            Section {
                Label {
                    Text(warning)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                }
                .accessibilityIdentifier("configurationWarning")

                if let suggested = result.suggestedDriveCount, suggested != viewModel.driveCount {
                    Button(String(format: "use_drive_count".localized(), suggested)) {
                        withAnimation(motion) { viewModel.applySuggestedDriveCount() }
                    }
                    .accessibilityIdentifier("applySuggestedDriveCount")
                }
            }
        } else if let caution = viewModel.rebuildCaution {
            Section {
                switch caution {
                case .suggest(let safer):
                    AdvisoryLabel(text: String(format: "rebuild_caution_level".localized(), viewModel.selectedLevel.displayName, safer.displayName))
                    useLevelButton(safer)
                case .warnOnly:
                    AdvisoryLabel(text: String(format: "rebuild_caution_add_drive".localized(), viewModel.selectedLevel.displayName))
                        .accessibilityIdentifier("narrowGroupCaution")
                }
            }
            .transition(.opacity)
        }
```

The identifier `narrowGroupCaution` is kept on purpose, because `testThreeDriveRaid5CautionAsksForAFourthDrive` looks for it.

- [ ] **Step 8: Simplify `ContentView.swift`'s input sections**

Replace the whole `Section("raid_level".localized()) { … }` with:

```swift
        Section("raid_level".localized()) {
            // Segmented controls stay near 13 pt at accessibility sizes, so
            // there the levels move into a menu with their full names.
            if dynamicTypeSize.isAccessibilitySize {
                Picker("raid_level".localized(), selection: levelSelection) {
                    ForEach(RaidLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("levelPicker")
            } else {
                Picker("raid_level".localized(), selection: levelSelection) {
                    ForEach(RaidLevel.allCases) { level in
                        Text(level.shortLabel)
                            .tag(level)
                            .accessibilityLabel(level.displayName)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
```

In the drive-configuration section, delete the whole `if viewModel.selectedLevel.usesGroups { CountStepper(… "groupCount" …) … }` block. Replace its `footer:` closure with:

```swift
        } footer: {
            // The card's prompt can be under the keyboard; this one sits by the field.
            if awaitingDriveSize {
                Text("enter_drive_size".localized())
                    .accessibilityIdentifier("enterDriveSizeFooter")
            }
        }
```

Delete `standardLevelSelection`, `levelButton(_:)` and `warnOnlyCautionKey`. Change `levelSelection`'s doc comment to `/// The selected level, animated.`. Update `CountStepper`'s doc comment so it no longer says "and the groups": `/// A count with a stepper, for the drive count.`.

- [ ] **Step 9: Simplify `CapacitySummary` and the drive strip call**

Change `DriveStrip(roles: result.driveRoles, groupSize: result.groupSize)` to `DriveStrip(roles: result.driveRoles)`. `DriveStrip` keeps its optional `groupSize` parameter, which now always defaults to `nil`. It's shared, already tested, and removing grouping from it is churn with no user-visible gain.

Replace the `if isValid, result.usableCapacity > 0 { … }` block with:

```swift
            if isValid, result.usableCapacity > 0 {
                Text(String(format: "binary_capacity_note".localized(), Self.binaryCapacity(result.usableCapacity, unit: unit)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
```

Delete `static func binaryBytes(_:unit:)`. Then delete the ZFS estimate source:

```bash
git rm -q RaidCalculator2/ZFSEstimate.swift
```

- [ ] **Step 10: Drop the ZFS footnote from the info sheet**

In `InfoSheet.swift`, `InfoTopic.level`: change `footnoteKey: level.isZFS ? "zfs_not_affiliated" : nil` to `footnoteKey: nil`.

- [ ] **Step 11: Rewrite the model tests and trim the copy tests**

Replace the body of `ModelTests` in `RaidCalculator2Tests/ModelTests.swift` with:

```swift
struct ModelTests {

    @Test func persistedRawValuesNeverChange() {
        #expect(RaidLevel.raid0.rawValue == "R 0")
        #expect(RaidLevel.raid1.rawValue == "R 1")
        #expect(RaidLevel.raid5.rawValue == "R 5")
        #expect(RaidLevel.raid6.rawValue == "R 6")
        #expect(RaidLevel.raid10.rawValue == "R 10")
        #expect(RaidLevel.jbod.rawValue == "JBOD")
    }

    @Test func classicLevelsOnlyInPickerOrder() {
        #expect(RaidLevel.allCases == [.raid0, .raid1, .raid5, .raid6, .raid10, .jbod])
    }

    @Test func namesAndKeys() {
        #expect(RaidLevel.raid10.displayName == "RAID 10")
        #expect(RaidLevel.jbod.shortLabel == "JBOD")
        #expect(RaidLevel.raid6.stringKeyPrefix == "raid6")
    }
}
```

In `InfoSheetCopyTests.swift`, delete `zfsLevelsExplainTheEstimate`. `everyLevelHasItsSheetCopy` stays, and now covers the six levels.

In `RaidCalculator2Tests/RaidCalculator2Tests.swift` (and any test moved there in Step 1), remove `groups:` arguments and any `groupSize`, `suggestedGroups`, `suggestedDriveCountGroups` or `zfsEstimate` expectations. The compiler lists them.

- [ ] **Step 12: Remove the nested and ZFS UI tests**

Delete: `testNestedLevelFromMenu`, `testNestedLevelFixFromDefaults`, `testStandardLevelHidesGroups`, `testDriveStripReadsEachGroup`, `testZFSEstimateShown`, `testNarrowGroupsWarnWithoutSuggestion`, `testAccessibilityLevelMenuShowsNestedLevel`, `testWideRaidZGroupCaution`, `testRaidZInfoSheetExplainsEstimate`, `testRaidZInfoSheetKeepsTrademarkLine`.

Remove the `groups` parameter from `launchApp` and its `"-groups", "\(groups)",` line.

Then: `grep -n 'R 50\|R 60\|"Z[123]"\|RAID 50\|RAID 60\|RAID-Z\|moreLevels\|More Levels\|groupCount\|Groups\|zfs\|ZFS' RaidCalculator2UITests/RaidCalculator2UITests.swift`. For each remaining match, either drop the assertion (if it was about a removed level or control) or delete the test if that was its whole point. `testPickersBecomeMenusAtAccessibilitySize` should keep asserting that the menu exists, minus anything about nested levels.

- [ ] **Step 13: Run the tests**

Run BUILD. Expected: BUILD SUCCEEDED. Fix any remaining reference the compiler flags (`usesGroups`, `family`, `isZFS`, `groups`, `zfsEstimate`, `wideZFSGroupWidth`).
Run UNIT. Expected: all pass, including `LegacyStateTests` (6 + 6 cases).
Run UI `testRaidLevelSelection`, `testInvalidConfigurationOffersFix`, `testRebuildCautionOffersSaferLevel`, `testThreeDriveRaid5CautionAsksForAFourthDrive` and `testPickersBecomeMenusAtAccessibilitySize`, one at a time. Expected: PASS.

- [ ] **Step 14: Commit**

```bash
git add -A RaidCalculator2 RaidCalculator2Tests RaidCalculator2UITests
git commit -m "Keep only the classic RAID levels"
```

---

### Task 4: Remove strings nothing uses

**Files:**
- Create (outside the repo): `/tmp/raid-legacy/unused_keys.py`
- Modify: `RaidCalculator2/Localizable.xcstrings` (via `strings.py remove`)

**Interfaces:**
- Consumes: the Swift sources as left by Tasks 2 and 3.

- [ ] **Step 1: Write the finder**

`/tmp/raid-legacy/unused_keys.py`:

```python
"""Print catalog keys that no app source refers to, literally or through a level prefix."""
import json, pathlib, re, sys

repo = pathlib.Path(sys.argv[1])
catalog = json.loads((repo / "RaidCalculator2/Localizable.xcstrings").read_text(encoding="utf-8"))["strings"]
source = "\n".join(p.read_text(encoding="utf-8") for p in (repo / "RaidCalculator2").rglob("*.swift"))
literals = set(re.findall(r'"([A-Za-z0-9_.]+)"', source))
levels = ["raid0", "raid1", "raid5", "raid6", "raid10", "jbod"]
fields = ["description", "pros", "cons", "use_cases", "calculation", "validation", "failures"]
dynamic = {f"{level}_{field}" for level in levels for field in fields}
for key, entry in sorted(catalog.items()):
    if not entry.get("localizations"):
        continue  # auto-extracted literals with no translations
    if key not in literals and key not in dynamic:
        print(key)
```

- [ ] **Step 2: Review the list**

Run: `python3 -I /tmp/raid-legacy/unused_keys.py "$PWD" | tee /tmp/raid-legacy/unused.txt`
Expected: keys from the removed features only: `tab_*`, `nas_*`, `synology*`, `shr*`, `unraid*`, `zfs*`, `snapraid*`, `btrfs*`, `raid50*`, `raid60*`, `raidz*`, `nested_*`, `more_levels`, `groups`, `group_*`, `groups_uneven`, `grouped_failures`, `use_drive_count_groups`, `use_group_count`, `use_one_group`, `wide_zfs_*`, `rebuild_caution_narrow`, and the compare/bay/setup keys. `drive_strip_group*` keys must NOT appear, because `DriveStrip` still references them. For any key that doesn't obviously belong to a removed feature, `grep -rn '<key>' RaidCalculator2` and either keep it (delete its line from `unused.txt`) or confirm it's dead.

- [ ] **Step 3: Remove them and check**

```bash
python3 scripts/strings.py remove $(cat /tmp/raid-legacy/unused.txt)
python3 scripts/strings.py check
python3 -I /tmp/raid-legacy/unused_keys.py "$PWD"
```

Expected: `removed N key(s)`, a clean check, and an empty finder output.

- [ ] **Step 4: Run the tests**

Run UNIT (`everyLevelHasItsSheetCopy` guards the info-sheet keys). Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add RaidCalculator2/Localizable.xcstrings
git commit -m "Remove strings for the NAS tab and the nested and ZFS levels"
```

---

### Task 5: The `Retirement` model

**Files:**
- Create: `RaidCalculator2/Retirement.swift`
- Create: `RaidCalculator2Tests/RetirementTests.swift`
- Modify: `RaidCalculator2/Localizable.xcstrings` (via `strings.py add`)

**Interfaces:**
- Produces:
  - `enum Retirement`
  - `enum Retirement.Phase: Equatable { case retiring, retired }`
  - `static let appStoreID: Int = 395601653`
  - `static let storeURL: URL`
  - `static let seenKey = "legacy.hasSeenRetirementNotice"`
  - `static func phase(now: Date, timeZone: TimeZone = .current) -> Phase`
  - `static func lastDayText(locale: Locale = .current, timeZone: TimeZone = .current) -> String`
  - `static func now(defaults: UserDefaults = .standard) -> Date`
  - `static func body(_ phase: Phase, dateText: String = lastDayText()) -> String`
  - `static func bannerTitle(_ phase: Phase, dateText: String = lastDayText()) -> String`
- Strings it consumes (added in Step 3): `retirement_body_retiring` (`%@` = date), `retirement_body_retired`, `retirement_banner_retiring` (`%@`), `retirement_banner_retired`.

- [ ] **Step 1: Write the failing tests**

`RaidCalculator2Tests/RetirementTests.swift`:

```swift
//
//  RetirementTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

@MainActor
struct RetirementTests {
    /// A wall-clock moment in a time zone, from Gregorian fields.
    private func moment(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, in zone: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test(arguments: ["America/Los_Angeles", "Europe/Berlin", "Asia/Tokyo", "Pacific/Kiritimati", "Etc/GMT+12"])
    func retiringThroughTheLastLocalDay(zone: String) {
        let tz = TimeZone(identifier: zone)!
        #expect(Retirement.phase(now: moment(2026, 10, 13, 12, 0, in: zone), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2026, 12, 31, 23, 59, in: zone), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2027, 1, 1, 0, 0, in: zone), timeZone: tz) == .retired)
        #expect(Retirement.phase(now: moment(2028, 6, 1, 12, 0, in: zone), timeZone: tz) == .retired)
    }

    @Test func phaseIgnoresTheUserCalendar() {
        // The boundary is computed in Gregorian whatever the device's calendar,
        // so a Japanese- or Buddhist-calendar user switches the same day.
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        #expect(Retirement.phase(now: moment(2026, 12, 31, 23, 59, in: "Asia/Tokyo"), timeZone: tz) == .retiring)
        #expect(Retirement.phase(now: moment(2027, 1, 1, 0, 1, in: "Asia/Tokyo"), timeZone: tz) == .retired)
    }

    @Test func lastDayInEnglishAndGerman() {
        let utc = TimeZone(identifier: "UTC")!
        #expect(Retirement.lastDayText(locale: Locale(identifier: "en_US"), timeZone: utc) == "December 31, 2026")
        #expect(Retirement.lastDayText(locale: Locale(identifier: "de_DE"), timeZone: utc) == "31. Dezember 2026")
    }

    @Test(arguments: ["Pacific/Kiritimati", "Etc/GMT+12", "America/Los_Angeles"])
    func dateTextIsTheLastDayEverywhere(zone: String) {
        #expect(Retirement.lastDayText(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: zone)!) == "December 31, 2026")
    }

    @Test func japaneseCalendarUserSeesTheSameDay() {
        let text = Retirement.lastDayText(locale: Locale(identifier: "ja_JP@calendar=japanese"), timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        // 2026 is Reiwa 8.
        #expect(text.contains("令和8"), "\(text)")
        #expect(text.contains("12月31日"), "\(text)")
    }

    @Test func storeLink() {
        #expect(Retirement.appStoreID == 395601653)
        #expect(Retirement.storeURL.absoluteString == "https://apps.apple.com/app/id395601653")
    }

    @Test func copyFollowsThePhase() {
        #expect(Retirement.body(.retiring, dateText: "DAY").contains("DAY"))
        #expect(!Retirement.body(.retired, dateText: "DAY").contains("DAY"))
        #expect(Retirement.bannerTitle(.retiring, dateText: "DAY").contains("DAY"))
        #expect(!Retirement.bannerTitle(.retired, dateText: "DAY").contains("DAY"))
        #expect(Retirement.body(.retiring) != Retirement.body(.retired))
    }

    @Test func nowReadsTheDebugOverride() {
        let name = "RetirementTests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        defaults.set("2027-01-02", forKey: "legacy.now")
        #expect(Retirement.phase(now: Retirement.now(defaults: defaults), timeZone: TimeZone(identifier: "UTC")!) == .retired)
        defaults.removeObject(forKey: "legacy.now")
        #expect(abs(Retirement.now(defaults: defaults).timeIntervalSinceNow) < 5)
    }
}
```

- [ ] **Step 2: Run them to confirm they fail**

Run UNIT. Expected: compile error, `cannot find 'Retirement' in scope`.

- [ ] **Step 3: Add the notice strings (all eight; Task 6 uses the rest)**

`/tmp/raid-legacy/retirement-strings.json`:

```json
{
  "retirement_title": {"en": "RAID Calc2 is retiring", "es": "RAID Calc2 se retira", "fr": "RAID Calc2 prend sa retraite", "it": "RAID Calc2 va in pensione", "ja": "RAID Calc2 は提供を終了します", "de": "RAID Calc2 wird eingestellt", "zh-Hant": "RAID Calc2 即將停止提供", "zh-Hans": "RAID Calc2 即将停止提供", "ko": "RAID Calc2 제공이 종료됩니다", "pt-BR": "O RAID Calc2 vai ser descontinuado"},
  "retirement_body_retiring": {"en": "RAID Calc2 leaves the App Store on %@. It keeps working, but won’t get updates.", "es": "RAID Calc2 dejará el App Store el %@. Seguirá funcionando, pero no recibirá actualizaciones.", "fr": "RAID Calc2 quittera l’App Store le %@. Elle continuera de fonctionner, mais ne recevra plus de mises à jour.", "it": "RAID Calc2 lascerà App Store il %@. Continuerà a funzionare, ma non riceverà aggiornamenti.", "ja": "RAID Calc2 は %@ に App Store から削除されます。引き続き使えますが、アップデートは提供されません。", "de": "RAID Calc2 verlässt den App Store am %@. Die App funktioniert weiter, erhält aber keine Updates mehr.", "zh-Hant": "RAID Calc2 將於 %@ 從 App Store 下架。App 仍可繼續使用，但不會再更新。", "zh-Hans": "RAID Calc2 将于 %@ 从 App Store 下架。App 仍可继续使用，但不会再更新。", "ko": "RAID Calc2는 %@에 App Store에서 내려갑니다. 계속 사용할 수 있지만 업데이트는 제공되지 않습니다.", "pt-BR": "O RAID Calc2 sai da App Store em %@. Ele continua funcionando, mas não vai receber atualizações."},
  "retirement_body_retired": {"en": "RAID Calc2 is no longer on the App Store. It keeps working, but won’t get updates.", "es": "RAID Calc2 ya no está en el App Store. Sigue funcionando, pero no recibirá actualizaciones.", "fr": "RAID Calc2 n’est plus sur l’App Store. Elle continue de fonctionner, mais ne recevra plus de mises à jour.", "it": "RAID Calc2 non è più su App Store. Continua a funzionare, ma non riceverà aggiornamenti.", "ja": "RAID Calc2 は App Store での提供を終了しました。引き続き使えますが、アップデートは提供されません。", "de": "RAID Calc2 ist nicht mehr im App Store. Die App funktioniert weiter, erhält aber keine Updates mehr.", "zh-Hant": "RAID Calc2 已從 App Store 下架。App 仍可繼續使用，但不會再更新。", "zh-Hans": "RAID Calc2 已从 App Store 下架。App 仍可继续使用，但不会再更新。", "ko": "RAID Calc2는 더 이상 App Store에 없습니다. 계속 사용할 수 있지만 업데이트는 제공되지 않습니다.", "pt-BR": "O RAID Calc2 não está mais na App Store. Ele continua funcionando, mas não vai receber atualizações."},
  "retirement_pitch": {"en": "RAID Calculator is the same app, plus NAS planning, RAID 50 and 60, and ZFS.", "es": "RAID Calculator es la misma app, con planificación de NAS, RAID 50 y 60, y ZFS.", "fr": "RAID Calculator, c’est la même app, avec en plus la planification NAS, les RAID 50 et 60, et ZFS.", "it": "RAID Calculator è la stessa app, con in più la pianificazione NAS, RAID 50 e 60 e ZFS.", "ja": "RAID Calculator は同じアプリに、NAS の計画、RAID 50 と 60、ZFS が加わりました。", "de": "RAID Calculator ist dieselbe App, dazu mit NAS-Planung, RAID 50 und 60 sowie ZFS.", "zh-Hant": "RAID Calculator 是同一款 App，另外加入 NAS 規劃、RAID 50 與 60，以及 ZFS。", "zh-Hans": "RAID Calculator 是同一款 App，另外加入了 NAS 规划、RAID 50 和 60，以及 ZFS。", "ko": "RAID Calculator는 같은 앱에 NAS 계획, RAID 50 및 60, ZFS가 더해졌습니다.", "pt-BR": "O RAID Calculator é o mesmo app, com planejamento de NAS, RAID 50 e 60, e ZFS."},
  "retirement_get": {"en": "Get RAID Calculator", "es": "Obtener RAID Calculator", "fr": "Obtenir RAID Calculator", "it": "Scarica RAID Calculator", "ja": "RAID Calculator を入手", "de": "RAID Calculator laden", "zh-Hant": "取得 RAID Calculator", "zh-Hans": "获取 RAID Calculator", "ko": "RAID Calculator 받기", "pt-BR": "Obter o RAID Calculator"},
  "retirement_not_now": {"en": "Not Now", "es": "Ahora no", "fr": "Plus tard", "it": "Non ora", "ja": "今はしない", "de": "Nicht jetzt", "zh-Hant": "現在不要", "zh-Hans": "以后再说", "ko": "나중에", "pt-BR": "Agora não"},
  "retirement_banner_retiring": {"en": "Retiring on %@", "es": "Se retira el %@", "fr": "Retrait le %@", "it": "Lascia App Store il %@", "ja": "%@ に提供終了", "de": "Wird am %@ eingestellt", "zh-Hant": "將於 %@ 停止提供", "zh-Hans": "将于 %@ 停止提供", "ko": "%@ 제공 종료", "pt-BR": "Sai da App Store em %@"},
  "retirement_banner_retired": {"en": "No longer on the App Store", "es": "Ya no está en el App Store", "fr": "N’est plus sur l’App Store", "it": "Non è più su App Store", "ja": "App Store での提供は終了しました", "de": "Nicht mehr im App Store", "zh-Hant": "已從 App Store 下架", "zh-Hans": "已从 App Store 下架", "ko": "더 이상 App Store에 없음", "pt-BR": "Não está mais na App Store"}
}
```

Run: `python3 scripts/strings.py add /tmp/raid-legacy/retirement-strings.json && python3 scripts/strings.py check`
Expected: `added 8 key(s)`, a clean check.

- [ ] **Step 4: Implement `RaidCalculator2/Retirement.swift`**

```swift
//
//  Retirement.swift
//  RaidCalculator2
//
//  RAID Calc2 leaves the App Store on December 31, 2026, in favour of
//  RAID Calculator. Everything the notice says comes from here.
//

import Foundation

enum Retirement {
    enum Phase: Equatable {
        /// Still on sale; the notice gives the date.
        case retiring
        /// Off sale; the app still runs on devices that have it.
        case retired
    }

    /// RAID Calculator's App Store ID and page.
    static let appStoreID = 395601653
    static let storeURL = URL(string: "https://apps.apple.com/app/id395601653")!

    /// Set once the first-launch notice has been dismissed.
    static let seenKey = "legacy.hasSeenRetirementNotice"

    /// The last day on sale is a Gregorian date in the user's own time zone,
    /// whatever calendar their device uses.
    private static func gregorian(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func phase(now: Date, timeZone: TimeZone = .current) -> Phase {
        let firstDayOff = gregorian(timeZone).date(from: DateComponents(year: 2027, month: 1, day: 1))!
        return now < firstDayOff ? .retiring : .retired
    }

    /// “December 31, 2026”, in the user's language and calendar.
    static func lastDayText(locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        // Midday, so no time zone can push the day either side of the 31st.
        let lastDay = gregorian(timeZone).date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 12))!
        let style = Date.FormatStyle(date: .long, time: .omitted, locale: locale, calendar: locale.calendar, timeZone: timeZone)
        return lastDay.formatted(style)
    }

    /// The current date. Debug builds take `-legacy.now yyyy-MM-dd` so UI
    /// tests and screenshots can show the copy from after the date.
    static func now(defaults: UserDefaults = .standard) -> Date {
        #if DEBUG
        if let override = defaults.string(forKey: "legacy.now"),
           let date = try? Date(override, strategy: .iso8601.year().month().day()) {
            return date
        }
        #endif
        return .now
    }

    static func body(_ phase: Phase, dateText: String = lastDayText()) -> String {
        switch phase {
        case .retiring: String(format: "retirement_body_retiring".localized(), dateText)
        case .retired: "retirement_body_retired".localized()
        }
    }

    static func bannerTitle(_ phase: Phase, dateText: String = lastDayText()) -> String {
        switch phase {
        case .retiring: String(format: "retirement_banner_retiring".localized(), dateText)
        case .retired: "retirement_banner_retired".localized()
        }
    }
}
```

- [ ] **Step 5: Run the tests**

Run UNIT. Expected: all of `RetirementTests` passes. If `nowReadsTheDebugOverride` fails, check that the scheme's Test action builds Debug.

- [ ] **Step 6: Commit**

```bash
git add RaidCalculator2/Retirement.swift RaidCalculator2Tests/RetirementTests.swift RaidCalculator2/Localizable.xcstrings
git commit -m "Add the retirement date, phase and store link"
```

---

### Task 6: Retirement notice: store page, sheet and banner

**Files:**
- Create: `RaidCalculator2/AppStorePage.swift`
- Create: `RaidCalculator2/RetirementNotice.swift`
- Modify: `RaidCalculator2/RaidCalculator2App.swift` (DEBUG reset hook)
- Modify: `RaidCalculator2/ContentView.swift` (banner in both layouts, sheet)
- Modify: `RaidCalculator2UITests/RaidCalculator2UITests.swift` (`launchApp`, three new tests)

**Interfaces:**
- Consumes: everything in `Retirement` from Task 5.
- Produces:
  - `AppStorePage.open(fallback: OpenURLAction)` (MainActor)
  - `RetirementSheet(phase:)`
  - `RetirementBanner(phase:)`
  - Accessibility identifiers `retirementTitle`, `retirementGet`, `retirementNotNow`, `retirementBanner`
  - UI test `launchApp(… showNotice: Bool = false, now: String? = nil)`

- [ ] **Step 1: Write the failing UI tests**

In `RaidCalculator2UITests.swift`, change `launchApp`'s signature to:

```swift
    private func launchApp(level: String = "R 5", drives: Int = 4, size: Int = 4, language: String = "en", locale: String = "en_US", contentSize: String? = nil, showNotice: Bool = false, now: String? = nil) -> XCUIApplication {
```

Before `app.launch()`, add:

```swift
        // Every other test starts with the notice already seen. Showing it
        // removes the saved flag instead of overriding it, so Not Now can
        // still save it during the test.
        app.launchArguments += showNotice ? ["-legacy.resetNotice", "YES"] : ["-legacy.hasSeenRetirementNotice", "YES"]
        if let now { app.launchArguments += ["-legacy.now", now] }
```

Add the tests:

```swift
    @MainActor
    func testRetirementNoticeShowsOnce() throws {
        let app = launchApp(showNotice: true)
        let title = app.staticTexts["retirementTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "RAID Calc2 is retiring")
        XCTAssertTrue(app.buttons["retirementGet"].exists)
        app.buttons["retirementNotNow"].tap()
        XCTAssertTrue(app.buttons["retirementBanner"].waitForExistence(timeout: 5))
        app.terminate()

        // No reset and no seeded flag: only what Not Now saved decides.
        let relaunched = XCUIApplication()
        relaunched.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        relaunched.launch()
        XCTAssertTrue(relaunched.buttons["retirementBanner"].waitForExistence(timeout: 5))
        XCTAssertFalse(relaunched.staticTexts["retirementTitle"].exists)
    }

    @MainActor
    func testBannerGivesTheDateThenSaysItIsGone() throws {
        let before = launchApp(now: "2026-12-30")
        let banner = before.buttons["retirementBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.label.contains("December 31, 2026"), banner.label)
        before.terminate()

        let after = launchApp(now: "2027-01-02")
        let gone = after.buttons["retirementBanner"]
        XCTAssertTrue(gone.waitForExistence(timeout: 5))
        XCTAssertTrue(gone.label.contains("No longer on the App Store"), gone.label)
        XCTAssertFalse(gone.label.contains("2026"), gone.label)
    }

    /// At the largest text size, both sheet buttons stay on screen and the
    /// banner keeps its full sentence.
    @MainActor
    func testRetirementNoticeAtLargestTextSize() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL", showNotice: true)
        let notNow = app.buttons["retirementNotNow"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5))
        XCTAssertTrue(notNow.isHittable)
        XCTAssertTrue(app.buttons["retirementGet"].isHittable)
        notNow.tap()
        let banner = app.buttons["retirementBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.isHittable)
        XCTAssertTrue(banner.label.contains("December 31, 2026"), banner.label)
    }
```

Check the content-size string matches the one `testRatingRowStacksAtAccessibilitySize` already uses. If it differs, use that one.

- [ ] **Step 2: Run one to confirm it fails**

Run UI `testRetirementNoticeShowsOnce`. Expected: FAIL, because `retirementTitle` doesn't exist.

- [ ] **Step 3: Implement `RaidCalculator2/AppStorePage.swift`**

```swift
//
//  AppStorePage.swift
//  RaidCalculator2
//

import StoreKit
import SwiftUI

/// RAID Calculator's App Store page, shown inside the app over whatever is on
/// screen (the retirement sheet included). When the page can't load, such
/// as offline or in the Simulator, it closes and the App Store URL opens instead.
enum AppStorePage {
    private static let delegate = Delegate()

    static func open(fallback openURL: OpenURLAction) {
        guard let presenter = topViewController() else {
            openURL(Retirement.storeURL)
            return
        }
        let store = SKStoreProductViewController()
        store.delegate = delegate
        presenter.present(store, animated: true)
        Task {
            do {
                try await store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: NSNumber(value: Retirement.appStoreID)])
            } catch {
                store.dismiss(animated: true)
                openURL(Retirement.storeURL)
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    private final class Delegate: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true)
        }
    }
}
```

If the compiler reports that `loadProduct(withParameters:)` returns `Bool`, write `_ = try await …`. If the async form is unavailable, use the completion form, with `Task { @MainActor in … }` inside the completion block for the failure branch.

- [ ] **Step 4: Implement `RaidCalculator2/RetirementNotice.swift`**

```swift
//
//  RetirementNotice.swift
//  RaidCalculator2
//

import SwiftUI

/// Shown once, on the first launch of 1.8.0: RAID Calc2 is retiring, and
/// RAID Calculator is where to go next.
struct RetirementSheet: View {
    let phase: Retirement.Phase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("retirement_title".localized())
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("retirementTitle")
                Text(Retirement.body(phase))
                Text("retirement_pitch".localized())
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        // Both buttons stay on screen at every text size; the copy scrolls.
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    AppStorePage.open(fallback: openURL)
                } label: {
                    Text("retirement_get".localized())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .accessibilityIdentifier("retirementGet")

                Button("retirement_not_now".localized()) { dismiss() }
                    .controlSize(.large)
                    .accessibilityIdentifier("retirementNotNow")
            }
            .frame(maxWidth: 480)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .presentationDetents([.medium, .large])
    }
}

/// A permanent row at the top of the form: the date, or that the app is gone,
/// and a way to RAID Calculator. It wraps at large sizes rather than truncating.
struct RetirementBanner: View {
    let phase: Retirement.Phase
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            AppStorePage.open(fallback: openURL)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Retirement.bannerTitle(phase))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("retirement_get".localized())
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier("retirementBanner")
    }
}

#Preview("Sheet") {
    Color.clear.sheet(isPresented: .constant(true)) { RetirementSheet(phase: .retiring) }
}

#Preview("Banner") {
    Form {
        Section { RetirementBanner(phase: .retiring) }
        Section { RetirementBanner(phase: .retired) }
    }
}
```

- [ ] **Step 5: Add the DEBUG reset hook**

In `RaidCalculator2App`, add before `var body`:

```swift
    init() {
        #if DEBUG
        // UI tests and screenshots: show the first-launch notice again.
        if UserDefaults.standard.bool(forKey: "legacy.resetNotice") {
            UserDefaults.standard.removeObject(forKey: Retirement.seenKey)
        }
        #endif
    }
```

- [ ] **Step 6: Wire the banner and sheet into `ContentView`**

Add to `ContentView`'s properties:

```swift
    @AppStorage(Retirement.seenKey) private var hasSeenRetirementNotice = false
    private var retirementPhase: Retirement.Phase { Retirement.phase(now: Retirement.now()) }

    /// Always first in the form, so it's the first thing read and seen.
    private var retirementSection: some View {
        Section { RetirementBanner(phase: retirementPhase) }
    }
```

In `layout`, change the inputs form in the two-column branch to `Form { retirementSection; inputSections }`. Write it on separate lines like the surrounding code: `retirementSection` first, then `inputSections`. Change the single-column form to put `retirementSection` before `answerSections`.

After the existing `.sheet(isPresented:…) { InfoSheet(…) }` modifier, add:

```swift
        .sheet(isPresented: Binding(
            get: { !hasSeenRetirementNotice },
            set: { if !$0 { hasSeenRetirementNotice = true } }
        )) {
            RetirementSheet(phase: retirementPhase)
        }
```

- [ ] **Step 7: Run the tests**

Run UNIT. Expected: all pass.
Run UI `testRetirementNoticeShowsOnce`, then `testBannerGivesTheDateThenSaysItIsGone`, then `testRetirementNoticeAtLargestTextSize`. Expected: PASS each.
Run UI `testAppLaunchesSuccessfully` and `testInfoSheetPresentation`. Expected: PASS, so the banner and the seeded flag don't disturb existing tests. If a test that scrolls (`reveal`) now needs one more swipe because of the extra row, raise that helper's loop count by one rather than editing each test.

- [ ] **Step 8: Manual check: the store page fails safe (Review Focus 4)**

Boot iPhone 17. Build and install, then launch with `-legacy.hasSeenRetirementNotice YES` and tap the banner. The Simulator has no App Store, so expect the product page to fail, then close, and Safari to open `apps.apple.com/app/id395601653`. Then relaunch with `-legacy.resetNotice YES` and tap **Get RAID Calculator** in the sheet. Expect the same fallback, with the sheet still there afterwards and **Not Now** working. Note the result in the commit message. If a blank modal stays up, fix it before committing. On a real device it's checked in Task 9.

- [ ] **Step 9: Commit**

```bash
git add RaidCalculator2 RaidCalculator2UITests
git commit -m "Show the retirement notice and link to RAID Calculator"
```

---

### Task 7: Desaturated icon

**Files:**
- Create: `scripts/desaturate-icon.py`
- Modify: `RaidCalculator2/AppIcon.icon/Assets/Image {2,3,4,5}.png`
- Maybe modify: `RaidCalculator2/AppIcon.icon/icon.json` (only through Icon Composer, Step 4)

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Turn every image layer of AppIcon.icon to grayscale, keeping its alpha.

  /tmp/raid-assets/venv/bin/python scripts/desaturate-icon.py

For the RAID Calc2 legacy release only. Running it again changes nothing:
grayscale stays grayscale.
"""
import pathlib

from PIL import Image

ASSETS = pathlib.Path(__file__).resolve().parent.parent / "RaidCalculator2" / "AppIcon.icon" / "Assets"

for path in sorted(ASSETS.glob("*.png")):
    rgba = Image.open(path).convert("RGBA")
    gray = rgba.convert("L").convert("RGBA")
    gray.putalpha(rgba.getchannel("A"))
    gray.save(path)
    print(f"{path.name}: grayscale")
```

- [ ] **Step 2: Run it**

```bash
[ -x /tmp/raid-assets/venv/bin/python ] || { python3 -m venv /tmp/raid-assets/venv && /tmp/raid-assets/venv/bin/pip install -q pillow; }
/tmp/raid-assets/venv/bin/python scripts/desaturate-icon.py
/tmp/raid-assets/venv/bin/python -c "
from PIL import Image, ImageStat; import glob
for p in sorted(glob.glob('RaidCalculator2/AppIcon.icon/Assets/*.png')):
    r,g,b,a = Image.open(p).convert('RGBA').split()
    print(p, 'max channel spread', max(abs(x-y) for x,y in zip(ImageStat.Stat(r).mean, ImageStat.Stat(b).mean)))"
```

Expected: four files reported, each with a channel spread of 0.0.

- [ ] **Step 3: Preview it**

Boot iPhone 17 and build and install the app. Terminate it so the Home Screen shows, and find the page with RAID Calc2. Then:

```bash
mkdir -p /tmp/raid-legacy/icon
xcrun simctl ui booted appearance light && xcrun simctl io booted screenshot /tmp/raid-legacy/icon/home-light.png
xcrun simctl ui booted appearance dark && xcrun simctl io booted screenshot /tmp/raid-legacy/icon/home-dark.png
open -a "Icon Composer" RaidCalculator2/AppIcon.icon
```

In Icon Composer, check the Default, Dark, Tinted and Clear previews.

- [ ] **Step 4: Gate: user approves the icon**

Show the user both Home Screen captures and ask whether the icon reads as retired. If the background fill (currently `automatic`) still looks too colourful or too bright beside the gray artwork, set the fill to a solid neutral gray **in Icon Composer** (never hand-edit `icon.json`), save, and re-capture. Don't continue until the user approves.

- [ ] **Step 5: Commit**

```bash
git add scripts/desaturate-icon.py RaidCalculator2/AppIcon.icon
git commit -m "Desaturate the app icon for the legacy release"
```

---

### Task 8: Deploy and changelog docs

**Files:**
- Modify: `DEPLOY.md` (new section after "Which App Store record a build lands on")
- Modify: `CHANGELOG.md` (new top entry)

- [ ] **Step 1: Add the DEPLOY section**

```markdown
### Legacy app: RAID Calc2 1.8.0 (branch `legacy/raidcalc2`)

The final RAID Calc2 release ships from the `legacy/raidcalc2` branch, never from `main`. That branch sets `PRODUCT_BUNDLE_IDENTIFIER = com.mrballistic.RaidCalculator2`, so its builds land on the **RAID Calc2** record (Apple ID `6755641457`). Never open a pull request from it.

- **Upload from local Xcode 27.1** (the release build), as for 1.7.0. Don't push a `v*` tag from the branch: `deploy.yml` would run, and the tag would read as a RAID Calculator release. Tag `legacy-v1.8.0` if a marker is wanted.
- **Listing and screenshots:** `marketing/raidcalc2-1.8.0-listing.md` and `marketing/screenshots/raidcalc2-1.8.0/store/`, on the branch.
- **On 2026-12-31:** in App Store Connect, RAID Calc2 → Pricing and Availability → remove from sale in every country. Installed copies keep working, and the in-app notice switches to “No longer on the App Store” on January 1.
- If signing fails, check that `com.mrballistic.RaidCalculator2` is registered under the current team (developer.apple.com → Identifiers).
```

- [ ] **Step 2: Add the CHANGELOG entry**

At the top of `CHANGELOG.md`, below the intro paragraph:

```markdown
## RAID Calc2 1.8.0 (legacy, branch `legacy/raidcalc2`)

The last release of RAID Calc2 (`com.mrballistic.RaidCalculator2`), built from 1.7.0 with the NAS tab and the nested and ZFS levels removed. Never merged into `main`. Spec: `docs/superpowers/specs/2026-10-13-raidcalc2-legacy-design.md`.

- **Retirement notice.** On first launch, a sheet says RAID Calc2 leaves the App Store on December 31, 2026, and offers RAID Calculator’s App Store page in the app. A banner at the top of the form stays, and says “No longer on the App Store” from January 1, 2027.
- **Classic levels only:** RAID 0, 1, 5, 6, 10 and JBOD, as in 1.3.2. A level saved by a newer build opens as RAID 5.
- **Desaturated icon.**
- Everything else from 1.7.0 stays: ten languages, iPad and iPhone Duo layouts, rebuild advice and accessibility.
```

- [ ] **Step 3: Commit**

```bash
git add DEPLOY.md CHANGELOG.md
git commit -m "Document the RAID Calc2 legacy release"
```

---

### Task 9: Full verification and targeted screenshots

**Files:** none changed unless a check fails. Checks go to `/tmp/raid-legacy/checks/`.

- [ ] **Step 1: Strings and unit tests**

Run STRINGS, then UNIT. Expected: clean, all pass.

- [ ] **Step 2: Full UI suite on iPhone, then iPad, serially**

```bash
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO \
  -only-testing:"RAID CalcUITests" 2>&1 | tail -60
xcrun simctl shutdown all
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -parallel-testing-enabled NO \
  -only-testing:"RAID CalcUITests" 2>&1 | tail -60
xcrun simctl shutdown all
```

Use the iPad name from `xcrun simctl list devices available | grep "iPad Pro 13"`. Expected: all pass; the `testIPad*` tests run on iPad instead of skipping. Report any failure with its output. Don't mark the task done with a failure outstanding.

- [ ] **Step 3: Targeted screenshots (no full language sweep)**

Build once to `/tmp/raid-legacy/dd`, then install it on each Simulator in turn. Use one booted at a time.

```bash
xcodebuild build -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/raid-legacy/dd 2>&1 | tail -3
APP="/tmp/raid-legacy/dd/Build/Products/Debug-iphonesimulator/RAID Calc.app"
B=com.mrballistic.RaidCalculator2
shot() { # <udid> <name> <launch args…>
  local u=$1 n=$2; shift 2
  xcrun simctl terminate "$u" $B >/dev/null 2>&1 || true
  xcrun simctl launch "$u" $B "$@" >/dev/null; sleep 4
  xcrun simctl io "$u" screenshot "/tmp/raid-legacy/checks/$n.png" >/dev/null
}
```

On iPhone 17 (`xcrun simctl boot`, `install`), capture the sheet (`-legacy.resetNotice YES`) and the banner (`-legacy.hasSeenRetirementNotice YES`) for:
- fr (`-AppleLanguages "(fr)" -AppleLocale fr_FR`)
- de (`-AppleLanguages "(de)" -AppleLocale de_DE`)
- ja (`-AppleLanguages "(ja)" -AppleLocale ja_JP`)
- en at AX XXXL (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`)
- en retired (`-legacy.now 2027-01-02`)

Then on the narrowest iPhone available (`xcrun simctl list devices available | grep iPhone`; pick the smallest screen), capture en sheet and banner.

- [ ] **Step 4: Gate: user reviews the checks**

Look at every capture for truncation, clipped buttons, a date in the wrong format, and straight quotes. Then show the user the set, and fix anything either of you finds before continuing. On a real device, if the user has one handy: tap **Get RAID Calculator** and confirm the in-app App Store page shows RAID Calculator (395601653).

---

### Task 10: English store copy

**Files:**
- Create: `marketing/raidcalc2-1.8.0-listing.md`

- [ ] **Step 1: Check what 1.3.2 had, so What's New claims only real changes**

```bash
git show 5cee346 --stat | head -40
git show 5cee346:RaidCalculator2/Localizable.xcstrings | python3 -c "import json,sys; d=json.load(sys.stdin)['strings']; print(sorted({l for v in d.values() for l in v.get('localizations',{})}))"
git ls-tree --name-only 5cee346 RaidCalculator2/
```

List what 1.3.2 had: its languages, whether it had iPad, the drive strip, rebuild advice, one-tap fixes, Duo and VoiceOver work. Drop any bullet below that 1.3.2 already had, and check privacy claims against `privacy.md`.

- [ ] **Step 2: Write the listing file**

```markdown
# App Store listing: RAID Calc2 1.8.0 (legacy)

Paste-ready copy for App Store Connect, record “RAID Calc2” (Apple ID 6755641457). Rules: no em dashes; “iPhone” and “iPad” exactly so; trademarks exact and descriptive; no prices, URLs or awards. Counts checked.

## App Information

| Field | Value | Count |
|---|---|---|
| Name (30) | RAID Calc2 | 10 |
| Subtitle (30) | Moving to RAID Calculator | 25 |

## Version 1.8.0

### Promotional text (170)

> RAID Calc2 retires on December 31, 2026. Get RAID Calculator, from the same developer: the same app, plus NAS planning, RAID 50 and 60, and ZFS.

### Description (4000)

> RAID Calc2 is retiring. It leaves the App Store on December 31, 2026. It keeps working on your device after that, but won’t get updates.
>
> Its successor is RAID Calculator, from the same developer. It’s the same calculator, plus NAS planning for Synology SHR, Unraid, ZFS, SnapRAID and Btrfs, RAID 50 and 60, and RAID-Z. Search the App Store for “RAID Calculator”, or tap the banner in the app.
>
> UNTIL THEN, RAID CALC2 STILL DOES THE JOB
> • RAID 0, 1, 5, 6, 10 and JBOD
> • Usable and raw capacity, and how efficient the layout is
> • A drive strip showing which drives hold data, parity or mirrors
> • How many drive failures the array survives
> • Speed and availability ratings, with a plain-language guide to every level
> • A caution before a risky rebuild on large drives, with a one-tap switch to RAID 6
> • One-tap fixes when the drive count doesn’t suit the level
>
> ON EVERY SCREEN
> • On iPad, and on iPhone Duo opened in landscape, results sit beside inputs
> • Built for iOS 26 with native controls and Liquid Glass
> • Dark mode, Dynamic Type at every size, and full VoiceOver support
> • In English, Spanish, French, Italian, Japanese, German, Traditional and Simplified Chinese, Korean and Brazilian Portuguese
>
> PRIVATE
> No accounts, no tracking, no ads. Everything stays on your device.

### What’s New in This Version (4000)

> This is the last update to RAID Calc2, which leaves the App Store on December 31, 2026. RAID Calculator, from the same developer, is the same app plus NAS planning, RAID 50 and 60, and ZFS. RAID Calc2 now tells you about the move and opens RAID Calculator’s App Store page for you.
>
> This update also brings what RAID Calc2 has been missing:
> • A new design for iOS 26
> • Ten languages
> • iPad and iPhone Duo layouts with results beside inputs
> • A caution before a risky rebuild, with a one-tap fix
> • One-tap fixes for setups that don’t work
> • Fuller VoiceOver and Dynamic Type support
>
> RAID Calc2 keeps working after December 31, 2026. It just won’t get updates.

### Keywords (100)

raid,calculator,storage,capacity,drive,disk,parity,mirror,array,jbod,stripe

### App Review notes

> RAID Calc2 is a fully working RAID capacity calculator (RAID 0, 1, 5, 6, 10, JBOD). This final update adds a notice that the app will be removed from sale on December 31, 2026, and points users to its successor from the same developer, RAID Calculator (Apple ID 395601653). The notice opens that app’s product page with SKStoreProductViewController. No sign-in is needed to review the app.

## Localized listings

Added in Task 13.
```

Edit the bullets to match Step 1's findings, then measure every field: `python3 -c "import sys; print(len(sys.stdin.read().strip()))" <<< '<text>'`. Write each count next to its heading, as in `marketing/app-store-listing.md`. Scan for em-dashes, straight quotes and capitalised device names: `grep -n "—\|\"\|IPHONE\|IPAD\|iPhones\|iPads" marketing/raidcalc2-1.8.0-listing.md`. The only straight `"` allowed is in the Markdown table syntax, if any.

- [ ] **Step 3: Gate: user approves the English copy**

Show the user the file. Make their changes. Don't translate until they approve.

- [ ] **Step 4: Commit**

```bash
git add marketing/raidcalc2-1.8.0-listing.md
git commit -m "Write the RAID Calc2 1.8.0 store listing"
```

---

### Task 11: Screenshot tooling and iPhone and iPad captures

**Files:**
- Modify: `scripts/store-assets/compose.py` (graphite background, legacy shot list, `--legacy` flag)
- Create: `scripts/store-assets/capture_legacy.sh`
- Modify: `scripts/store-assets/README.md` (short legacy section)
- Create: `marketing/screenshots/raidcalc2-1.8.0/raw/…`, `…/store/…`

**Interfaces:**
- Produces: `compose.py --legacy [--only <set>] [--contact]`, which reads `marketing/screenshots/raidcalc2-1.8.0/raw` and writes `…/store`.
- Produces: scene names `01-moving`, `02-usable-space`, `03-rebuild-caution`, `04-invalid-fix`. Task 12 uses `01-moving` and `02-usable-space`.

- [ ] **Step 1: Add the graphite background**

In `BACKGROUNDS`, add:

```python
    "graphite": {"bg": (0x3A, 0x3A, 0x3C), "ink": (0xFF, 0xFF, 0xFF)},
```

The existing contrast assertion covers it, at about 11:1.

- [ ] **Step 2: Add the legacy shot list**

After the iPhone-size derivation loop that follows `SHOTS`, add:

```python
# RAID Calc2 1.8.0 (legacy branch): graphite to match the desaturated icon.
LEGACY_RAW = os.path.join(REPO, "marketing/screenshots/raidcalc2-1.8.0/raw")
LEGACY_OUT = os.path.join(REPO, "marketing/screenshots/raidcalc2-1.8.0/store")
MOVING = "Moving to RAID Calculator"
FIX = "One tap to a valid setup"
G = "graphite"
LEGACY_SHOTS = [
    ("iphone-1320x2868", "01-moving", "iphone-1320x2868/01-moving-light.png", IPHONE, G, "iphone", MOVING),
    ("iphone-1320x2868", "02-usable-space", "iphone-1320x2868/02-usable-space-light.png", IPHONE, G, "iphone", USABLE),
    ("iphone-1320x2868", "03-rebuild-caution", "iphone-1320x2868/03-rebuild-caution-dark.png", IPHONE, G, "iphone", REBUILD),
    ("iphone-1320x2868", "04-invalid-fix", "iphone-1320x2868/04-invalid-fix-light.png", IPHONE, G, "iphone", FIX),
    ("ipad-2064x2752", "01-moving", "ipad-2064x2752/01-moving-light.png", IPAD, G, "ipad", MOVING),
    ("ipad-2064x2752", "02-usable-space", "ipad-2064x2752/02-usable-space-light.png", IPAD, G, "ipad", USABLE),
    ("ipad-2064x2752", "03-rebuild-caution", "ipad-2064x2752/03-rebuild-caution-dark.png", IPAD, G, "ipad", REBUILD),
]
for _set, _size, _kind in (("duo-inner-2853x2007", DUO_IL, "duo-inner"), ("duo-inner-2007x2853", DUO_IP, "duo-inner"),
                           ("duo-outer-1398x2034", DUO_OP, "duo-outer"), ("duo-outer-2034x1398", DUO_OL, "duo-outer")):
    LEGACY_SHOTS += [
        (_set, "01-moving", f"{_set}/01-moving-light.png", _size, G, _kind, MOVING),
        (_set, "02-usable-space", f"{_set}/02-usable-space-light.png", _size, G, _kind, USABLE),
    ]
for _size in ((1206, 2622), (1179, 2556)):
    LEGACY_SHOTS += [(f"iphone-{_size[0]}x{_size[1]}",) + shot[1:3] + (_size,) + shot[4:]
                     for shot in LEGACY_SHOTS if shot[0] == "iphone-1320x2868"]
```

- [ ] **Step 3: Add the `--legacy` flag**

In `main()`, add the argument:

```python
    p.add_argument("--legacy", action="store_true", help="RAID Calc2 1.8.0: legacy shots, raws and output folders")
```

Directly after `a = p.parse_args()` (match the existing variable name), add:

```python
    global RAW, OUT
    shots = SHOTS
    if a.legacy:
        if a.headers:
            p.error("--legacy has no header images")
        RAW, OUT, shots = LEGACY_RAW, LEGACY_OUT, LEGACY_SHOTS
```

Change `for folder, name, raw, size, bg, kind, headline in SHOTS:` to iterate `shots`. If `contact_sheet` or `latest` read `RAW`/`OUT` as globals, the `global` line covers them. Check with `grep -n "RAW\|OUT" scripts/store-assets/compose.py`.

Verify that 1.7.0 is untouched: `/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py --only nothing-matches`. Expected: no output, no error.

- [ ] **Step 4: Write `scripts/store-assets/capture_legacy.sh`**

```bash
#!/bin/bash
# RAID Calc2 1.8.0 App Store captures on iPhone (1320 x 2868) or iPad 13" (2064 x 2752).
#
#   scripts/store-assets/capture_legacy.sh iphone|ipad
#
# Boot the one Simulator first (iPhone 17 Pro Max, or iPad Pro 13-inch) and install
# the legacy build. Captures every scene in light and dark, never overwriting
# a raw (a re-run adds -v2, -v3...), then composes with compose.py --legacy.
#
# Env: UDID (default: the booted device), PY (default: /tmp/raid-assets/venv/bin/python).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
PY="${PY:-/tmp/raid-assets/venv/bin/python}"
BUNDLE=com.mrballistic.RaidCalculator2
U="${UDID:-$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/{print $2; exit}')}"
TMP="$(mktemp -d /tmp/raid-legacy-shots.XXXXXX)"

case "${1:-}" in
  iphone) W=1320; H=2868; SCENES="01-moving 02-usable-space 03-rebuild-caution 04-invalid-fix" ;;
  ipad)   W=2064; H=2752; SCENES="01-moving 02-usable-space 03-rebuild-caution" ;;
  *) echo "usage: $0 iphone|ipad" >&2; exit 2 ;;
esac
SET="$1-${W}x${H}"
RAW="$REPO/marketing/screenshots/raidcalc2-1.8.0/raw/$SET"

[ -n "$U" ] || { echo "No booted Simulator." >&2; exit 1; }
[ -x "$PY" ] || { echo "Pillow venv missing: python3 -m venv /tmp/raid-assets/venv && /tmp/raid-assets/venv/bin/pip install pillow" >&2; exit 1; }
xcrun simctl get_app_container "$U" "$BUNDLE" >/dev/null 2>&1 || { echo "RAID Calc2 ($BUNDLE) is not installed on $U." >&2; exit 1; }

ORIG_APPEARANCE=$(xcrun simctl ui "$U" appearance 2>/dev/null || echo light)
cleanup() {
  xcrun simctl status_bar "$U" clear >/dev/null 2>&1 || true
  case "$ORIG_APPEARANCE" in light|dark) xcrun simctl ui "$U" appearance "$ORIG_APPEARANCE" >/dev/null 2>&1 || true ;; esac
  rm -rf "$TMP"
}
trap cleanup EXIT

xcrun simctl status_bar "$U" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3
COMMON=(-unit TB -AppleLanguages "(en)" -AppleLocale en_US)
SEEN=(-legacy.hasSeenRetirementNotice YES)

keep() {
  local dest="$2.png" n=2
  while [ -e "$dest" ]; do dest="$2-v$n.png"; n=$((n + 1)); done
  mkdir -p "$(dirname "$dest")"; cp "$1" "$dest"; echo "  $dest"
}

for mode in light dark; do
  xcrun simctl ui "$U" appearance "$mode"
  for scene in $SCENES; do
    xcrun simctl terminate "$U" "$BUNDLE" >/dev/null 2>&1 || true
    case "$scene" in
      01-moving)          args=(-legacy.resetNotice YES -selectedLevel "R 6" -driveCount 6 -driveSize 12) ;;
      02-usable-space)    args=("${SEEN[@]}" -selectedLevel "R 6" -driveCount 6 -driveSize 12) ;;
      03-rebuild-caution) args=("${SEEN[@]}" -selectedLevel "R 5" -driveCount 8 -driveSize 20) ;;
      04-invalid-fix)     args=("${SEEN[@]}" -selectedLevel "R 10" -driveCount 5 -driveSize 8) ;;
    esac
    xcrun simctl launch "$U" "$BUNDLE" "${args[@]}" "${COMMON[@]}" >/dev/null
    sleep 4
    xcrun simctl io "$U" screenshot "$TMP/$scene-$mode.png" >/dev/null 2>&1
    size=$(sips -g pixelWidth -g pixelHeight "$TMP/$scene-$mode.png" | awk '/pixel/{printf "%s ", $2}')
    [ "$size" = "$W $H " ] || { echo "capture is $size, expected $W $H: wrong device or orientation" >&2; exit 1; }
    keep "$TMP/$scene-$mode.png" "$RAW/$scene-$mode"
  done
done

"$PY" "$HERE/compose.py" --legacy --only "$1-" --contact
```

Then: `chmod +x scripts/store-assets/capture_legacy.sh`.

- [ ] **Step 5: Capture iPhone, then iPad**

Build once to `/tmp/raid-legacy/dd` (as in Task 9). Boot iPhone 17 Pro Max, install, then run `scripts/store-assets/capture_legacy.sh iphone`. `xcrun simctl shutdown all`. Boot iPad Pro 13-inch, install, then run `scripts/store-assets/capture_legacy.sh ipad`. `xcrun simctl shutdown all`.

Then compose the extra iPhone sizes: `/tmp/raid-assets/venv/bin/python scripts/store-assets/compose.py --legacy --only iphone --contact`.

- [ ] **Step 6: Verify the outputs**

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha marketing/screenshots/raidcalc2-1.8.0/store/*/*.png | grep -B2 "hasAlpha: yes" || echo "no alpha anywhere"
ls marketing/screenshots/raidcalc2-1.8.0/store/
```

Expected: `no alpha anywhere`. Sets: `iphone-1320x2868` (4), `iphone-1206x2622` (4), `iphone-1179x2556` (4), `ipad-2064x2752` (3), and contact sheets.

- [ ] **Step 7: Document the legacy mode in the README**

Append to `scripts/store-assets/README.md`:

```markdown
## RAID Calc2 1.8.0 (legacy branch only)

`compose.py --legacy` uses `LEGACY_SHOTS` and `marketing/screenshots/raidcalc2-1.8.0/{raw,store}`, on a graphite background. `capture_legacy.sh iphone|ipad` captures and composes the iPhone and iPad sets. For iPhone Duo, run `capture_duo.sh` with `BUNDLE=com.mrballistic.RaidCalculator2 LEGACY=1`.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/store-assets marketing/screenshots/raidcalc2-1.8.0
git commit -m "Capture and compose RAID Calc2 iPhone and iPad screenshots"
```

---

### Task 12: iPhone Duo captures (user sets the poses)

**Files:**
- Modify: `scripts/store-assets/capture_duo.sh`
- Create: `marketing/screenshots/raidcalc2-1.8.0/raw/duo-*/…`, `…/store/duo-*/…`

- [ ] **Step 1: Make `capture_duo.sh` configurable, keeping the 1.7.0 defaults**

Edit the top of `capture_duo.sh`:

```bash
BUNDLE="${BUNDLE:-53Q4825KDF}"
# LEGACY=1: RAID Calc2 1.8.0 scenes and folders (legacy branch).
if [ "${LEGACY:-0}" = 1 ]; then
  SHOTS_ROOT="marketing/screenshots/raidcalc2-1.8.0"; SCENES="01-moving 02-usable-space"; COMPOSE=(--legacy)
else
  SHOTS_ROOT="marketing/screenshots/1.7.0"; SCENES="01-usable-space 02-rebuild-caution"; COMPOSE=()
fi
```

Replace `BUNDLE=53Q4825KDF` with the block above, and change `RAW="$REPO/marketing/screenshots/1.7.0/raw/$SET"` to `RAW="$REPO/$SHOTS_ROOT/raw/$SET"`. Change `for scene in 01-usable-space 02-rebuild-caution; do` to `for scene in $SCENES; do`. Add these cases to the scene `case`:

```bash
      01-moving)
        xcrun simctl launch "$U" "$BUNDLE" -legacy.resetNotice YES -selectedLevel "R 6" -driveCount 6 \
          -driveSize 12 "${COMMON[@]}" >/dev/null ;;
      02-usable-space)
        xcrun simctl launch "$U" "$BUNDLE" -legacy.hasSeenRetirementNotice YES -selectedLevel "R 6" -driveCount 6 \
          -driveSize 12 "${COMMON[@]}" >/dev/null ;;
```

Change the last compose call to `"$PY" "$HERE/compose.py" ${COMPOSE[@]+"${COMPOSE[@]}"} --only "$SET" --contact`. Update the header comment so it lists `BUNDLE` and `LEGACY`. Then run `bash -n scripts/store-assets/capture_duo.sh`. Expected: no output.

- [ ] **Step 2: Install the legacy build on the RAID Duo Simulator**

Shut down other Simulators. Boot "RAID Duo" (`E9EE5C1F-BDED-41CD-9C51-CDCA75209EE7`, iOS 27.1 runtime), build with `-destination id=E9EE5C1F-BDED-41CD-9C51-CDCA75209EE7 -derivedDataPath /tmp/raid-legacy/dd-duo`, and `xcrun simctl install` the app.

- [ ] **Step 3: Hand the four poses to the user**

Tell the user exactly what to set before each run, and run each one only after they confirm:

1. **Closed, upright** (Device Hub: closed; Simulator: portrait): `BUNDLE=com.mrballistic.RaidCalculator2 LEGACY=1 scripts/store-assets/capture_duo.sh outer-portrait`
2. **Closed, rotated** (Device › Rotate Left): `… capture_duo.sh outer-landscape`
3. **Open flat, upright** (Device Hub: open): `… capture_duo.sh inner-portrait`
4. **Open flat, rotated** (Device › Rotate Left): `… capture_duo.sh inner-landscape`

If the script reports a wrong size or a dark display, the pose is wrong. Ask the user to fix it and re-run. The script never overwrites a raw.

- [ ] **Step 4: Verify and gate on every contact sheet**

Run the same `sips` alpha check as in Task 11, over `store/duo-*`. Expected: 4 Duo sets × 2 images, no alpha, at sizes 1398×2034, 2034×1398, 2007×2853 and 2853×2007. Then show the user every contact sheet (iPhone, iPad, Duo). Re-capture anything they reject. Don't continue until they approve.

- [ ] **Step 5: Commit**

```bash
git add scripts/store-assets/capture_duo.sh marketing/screenshots/raidcalc2-1.8.0
git commit -m "Capture and compose RAID Calc2 iPhone Duo screenshots"
```

---

### Task 13: Localized listings

**Files:**
- Modify: `marketing/raidcalc2-1.8.0-listing.md` ("Localized listings" section)

- [ ] **Step 1: Translate the approved English**

For each of es-ES, es-MX (only if the record has both; otherwise just the Spanish the record has), fr-FR, it, ja, de-DE, zh-Hant, zh-Hans, ko and pt-BR, add a `### <Language> (<code>)` section with `#### Subtitle (30)`, `#### Promotional text (170)`, `#### Description (4000)`, `#### Keywords (100)` and `#### What’s New in This Version (4000)`. Follow the layout of `marketing/app-store-listing.md`'s localized sections (that file is untracked on this machine; read it from the working tree).

- Reuse the app's own wording where it overlaps, so store and app agree: the `retirement_*` strings from Task 6, and the level and feature names the catalog uses in each language.
- Store terms: es "el App Store", pt-BR "a App Store", it "App Store" with no article, fr "l’App Store", de "im App Store".
- Keep "RAID Calc2", "RAID Calculator", "iPhone", "iPad", "iPhone Duo", "Synology SHR", "Unraid", "ZFS", "SnapRAID", "Btrfs", "RAID-Z" and "JBOD" as they are.
- Use the date as each language writes it (de "31. Dezember 2026", fr "31 décembre 2026", ja "2026年12月31日", ko "2026년 12월 31일", zh "2026年12月31日").
- Keywords are written fresh per language, not translated literally: comma-separated, no spaces after commas, ≤ 100 characters.

- [ ] **Step 2: Check limits and rules**

Count every field (CJK characters count as one each in App Store Connect) and write the count after each heading. Run `grep -n "—" marketing/raidcalc2-1.8.0-listing.md`. Expected: no matches. Check that each section's quotes are the curly or language-native form (« » in French, „ “ in German, 「」 in Japanese and Chinese).

- [ ] **Step 3: Mark for review and commit**

Add under "## Localized listings": `Machine-assisted translations. Each needs a native speaker’s check before it’s submitted (DEPLOY.md release checklist, step 5).`

```bash
git add marketing/raidcalc2-1.8.0-listing.md
git commit -m "Add localized RAID Calc2 1.8.0 listings"
git push
```

---

### Task 14: Release handoff

**Files:** none. This is the user's checklist, given at the end of the work.

- [ ] **Step 1: Give the user this checklist, in order**

1. App Store Connect → RAID Calc2 (6755641457) → add version **1.8.0**.
2. In Xcode 27.1 (the release build), on branch `legacy/raidcalc2`: Any iOS Device → Product → Archive → Distribute App → App Store Connect → Upload. If signing fails, check that `com.mrballistic.RaidCalculator2` is under the current team.
3. Paste Name, Subtitle, Promotional Text, Description, Keywords and What’s New for every localization from `marketing/raidcalc2-1.8.0-listing.md`, after the native-speaker checks.
4. Upload the screenshots from `marketing/screenshots/raidcalc2-1.8.0/store/`: iPhone 6.9″ (1320 × 2868), iPad 13″ (2064 × 2752), iPhone Duo outer and inner (both orientations).
5. Paste the App Review notes. Select the build, then Add for Review.
6. Optional: `git tag legacy-v1.8.0 && git push origin legacy-v1.8.0`. This tag doesn't match `v*`, so it doesn't deploy.
7. **On December 31, 2026:** Pricing and Availability → remove RAID Calc2 from sale.

- [ ] **Step 2: Push the branch**

`git push`. Confirm that `git log origin/legacy/raidcalc2 -1` matches the local HEAD. No PR.
