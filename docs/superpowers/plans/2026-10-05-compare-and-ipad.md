# Compare Systems and iPad Layouts Implementation Plan (1.6.0, plan 3 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- Show the same drives under every NAS system at once: a sheet on iPhone, columns on iPad. Tapping a system switches to it.
- Give both tabs a size-class-adaptive layout: results and inputs side by side on a wide iPad, stacked everywhere else.
- Bay diagrams stay legible up to 30 bays on iPad, and grouped drive strips show groups as rows.
- Fix the Dynamic Type rows parked by plans 1 and 2.

**Architecture:**
- **Comparison:** a pure model, `NASCalculator.compare(_:requestedBayCount:)` → `[NASComparison]`, fed by `NASViewModel.comparison`. Each system reads the drives through the same lens as switching to it, via `bays(for:)`.
- **Layout decisions:** pure, unit-tested functions in `AdaptiveLayout`: when to use two columns, and how to split bays into rows.
- **Views:** each tab's `Form` is split into section builders, so the same sections can go in one `Form` (compact) or two side-by-side `Form`s (wide). `BayDiagram` and `DriveStrip` read the size class themselves.

**Tech Stack:** Swift 6 (default MainActor isolation), SwiftUI, iOS 26.0, Swift Testing (unit), XCTest (UI), Xcode 27, `scripts/strings.py`.

**Spec:** `prd-update.md`. This plan implements:
- FR-13
- FR-14
- §1.6's accessibility and performance lines for the new views, including VoiceOver reading group structure
- the parked plan-1 and plan-2 items in this area (memory: `plan1-parked-items`, `plan2-parked-items`)

Plan 4 is copy, trademarks and the website (FR-16), plus FR-18 and FR-19's leftovers.

**Branch:** `feat/1.6.0-compare-ipad`, created from `feat/1.6.0-nas-tab` (plan 2 isn't merged yet, and all of 1.6.0 ships together).

## Global Constraints

- iOS 26.0, native SwiftUI, no third-party dependencies. Swift 6 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Values used in `@Test(arguments:)` must be literals or `nonisolated`.
- **Strings:**
  - Every user-facing string is a key in `RaidCalculator2/Localizable.xcstrings`, read with `"key".localized()`, in `en`, `es`, `fr`, `it` and `ja`, all `translated`, with identical positional specifiers.
  - Add and remove keys only with `python3 scripts/strings.py add <file.json>` / `remove <key>…`.
  - `python3 scripts/strings.py check` must print `0 problem(s)` before every commit that touches strings.
- **Copy:**
  - Smart punctuation (curly “ ” ’) and American spelling.
  - Em dashes are rare and closed up.
  - Positional specifiers whenever there is more than one.
  - System names stay untranslated.
  - On the NAS screen, Spanish says “disco” and Japanese counts drives with 台 (plan 2’s I7).
- **Size-class adaptive, never iPad-only (FR-14):**
  - Two columns only when the horizontal size class is regular **and** the window is at least 800 points wide (`AdaptiveLayout.twoColumnMinWidth`).
  - Everything else is stacked: iPhone, iPad mini in portrait (744 points), and iPad split view and Slide Over.
- **Reading order:** in two columns, results lead (left) and inputs follow (right), so VoiceOver and reading order match the stacked layout, where the answer comes first.
- **Motion (FR-20):**
  - `.snappy` for layout changes.
  - `.numericText()` on changing numbers.
  - A `.selection` haptic on pickers and steppers.
  - Under `accessibilityReduceMotion`, a 0.2 s crossfade with no movement.
  - No entrance animations.
- **The honesty rule:** a system that can’t use some of the drives says so. In the comparison, Synology reads at most 12 bays and states “Uses the first 12 bays”. Invalid setups show their warning, never a misleading number.
- **Spec gaps decided in this plan:**
  1. **The RAID tab had no two-column layout.** FR-14 says “the RAID tab already has a two-column iPad layout”. It doesn’t: both tabs only center a 720-point readable column. This plan builds the two-column layout for both tabs.
  2. **Each system in the comparison uses the user’s current setting for that system** (`NASSettings`): Unraid’s and SnapRAID’s parity, the ZFS level, the Synology RAID type. These are the same values switching to that system would show.
  3. **Comparison sort order:** valid before invalid, then usable capacity (descending), then the picker’s order.
  4. **The iPhone sheet applies the switch after it dismisses,** so the user sees the bays re-split (FR-20’s signature moment). On iPad the switch is immediate, with the diagram beside it.
  5. **Bay diagram, more bays than fit one row:**
     - **Regular width:** wrap into balanced rows (30 bays become 2 × 15).
     - **Compact width:** scroll horizontally, as today.
     - **Narrowest column:** 24 points, scaled with Dynamic Type.
  6. **At accessibility text sizes,** bay labels drop the unit (“16” rather than “16 TB”), and the legend says “Sizes in TB” once. VoiceOver labels keep full units.
  7. **Drive strip:** at regular width, a grouped level draws each group as its own row. There are no visible group labels. VoiceOver gets one element per group: “Group 2 of 3: 3 Data, 1 Parity”.
- **Build churn:** Xcode’s build may rewrite `Localizable.xcstrings`. If `strings.py check` still passes with the intended key set, commit it as is.
- Every commit message ends with the Co-Authored-By trailer the implementer’s own harness attribution gives (it names the model that wrote the commit).

**Commands** (repo root):

```bash
DEST='platform=iOS Simulator,name=iPhone 17'
IPAD='platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -parallel-testing-enabled NO -only-testing:"RAID CalcTests"
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -parallel-testing-enabled NO -only-testing:"RAID CalcTests/AdaptiveLayoutTests"
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$IPAD" -parallel-testing-enabled NO -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testIPadPutsResultsBesideInputs"
```

- **Timing:** a first build plus Simulator boot takes 5–10 minutes, and `xcodebuild` may hang for several minutes after a run before it exits. Run it in the background with a long timeout, and read the log for `** TEST SUCCEEDED **` or `FAILED`.
- **Always pass `-parallel-testing-enabled NO`.** Parallel Simulator clones time out on this machine.
- **One build at a time:** never run two `xcodebuild` processes at once.
- **iPad-only UI tests** begin with `try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")`, so they skip on the iPhone run and run on `$IPAD`.

## Review Focus

Each has its test in the task that owns the code.

1. **More than 12 bays, compared:** Synology reads only the first 12 and says so, and the other systems read all of them. Test: `comparisonNotesSynologysBayLimit` (Task 1).
2. **A system that can’t use the drives** (SnapRAID with 2 parity and 2 drives) sorts below every working system and shows its warning, not 0 TB. Test: `invalidSetupsSortLast` (Task 1). The cell hides the number when invalid (Task 6).
3. **A regular-width window narrower than 800 points** (iPad mini portrait, a half split on a 13-inch iPad) stays stacked, never two cramped columns. Test: `twoColumnsNeedRegularWidthAndRoom` (Task 2).
4. **The diagram before its width is known** (width 0 on first layout) draws one row, never one bay per row. Test: `unknownWidthIsOneRow` (Task 2).
5. **Choosing a system from the comparison keeps the drives:** the bays and sizes are unchanged after switching. Test: `testCompareSystemsSwitchesSystem` asserts the capacity and that bay 4 still shows 8 TB (Task 6).

## File map

| File | Change | Responsibility |
|---|---|---|
| `RaidCalculator2/NAS.swift` | modify | `NASComparison`, `NASCalculator.compare` |
| `RaidCalculator2/NASViewModel.swift` | modify | `bays(for:)`, `comparison` |
| `RaidCalculator2/AdaptiveLayout.swift` | create | `usesTwoColumns`, `bayRows` |
| `RaidCalculator2/ContentView.swift` | modify | Section builders, two-column body; `DriveStrip` group rows and VoiceOver; `RatingRow` and Drive Size at accessibility sizes |
| `RaidCalculator2/NASView.swift` | modify | Section builders, two-column body, comparison entry points; `BayDiagram` rows and accessibility-size labels |
| `RaidCalculator2/NASComparisonViews.swift` | create | `NASComparisonCell`, `NASComparisonSheet`, `NASComparisonColumns` |
| `RaidCalculator2Tests/NASCalculatorTests.swift` | modify | Comparison tests |
| `RaidCalculator2Tests/NASViewModelTests.swift` | modify | Comparison lens test |
| `RaidCalculator2Tests/AdaptiveLayoutTests.swift` | create | Layout math |
| `RaidCalculator2UITests/RaidCalculator2UITests.swift` | modify | Compare, iPad and Dynamic Type UI tests |

## Execution order and models

| Task | Model | Depends on |
|---|---|---|
| 1. Comparison model | sonnet | none |
| 2. Layout math | haiku | none |
| 3. Two-column layout for both tabs | sonnet | 2 |
| 4. Bay diagram rows and accessibility-size labels | opus | 2, 3 |
| 5. Drive strip group rows and VoiceOver groups | opus | 3 |
| 6. Compare systems UI | opus | 1, 3 |
| 7. Rating and Drive Size rows at accessibility sizes | sonnet | 3 |
| 8. Full verification, iPhone and iPad | sonnet | all |

Tasks run in order 1 → 8. Reviews use sonnet, except opus for Tasks 4–6 and the final whole-branch review.

---

### Task 1: Comparison model

**Files:**
- Modify: `RaidCalculator2/NAS.swift` (append after `NASCalculator`)
- Modify: `RaidCalculator2/NASViewModel.swift`
- Test: `RaidCalculator2Tests/NASCalculatorTests.swift`, `RaidCalculator2Tests/NASViewModelTests.swift`

**Interfaces:**
- Consumes:
  - `NASCalculator.calculate(_ setup: NASSetup) -> BayResult`
  - `NASSetup(system:bays:settings:)`
  - `NASSystem.allCases`, `NASSystem.bayRange`
  - `NASViewModel`’s private `allBays` and `requestedBayCount`
- Produces:
  - `struct NASComparison: Identifiable, Equatable { system, usableCapacity, unusedCapacity, failuresTolerated: Int, warningMessage: String?, bayLimit: Int?; id; isValid }`
  - `NASCalculator.compare(_ setups: [NASSetup], requestedBayCount: Int) -> [NASComparison]`
  - `NASViewModel.bays(for: NASSystem) -> [Double?]`
  - `NASViewModel.comparison: [NASComparison]`

- [ ] **Step 1: Write the failing tests.** Append to `NASCalculatorTests`:

```swift
    // Same drives, every system (FR-13). Synology, Unraid and SnapRAID tie
    // at 20 TB, so the picker's order decides between them.
    @Test func compareSortsByUsableThenPickerOrder() {
        let bays: [Double?] = [16, 8, 8, 4]
        let rows = NASCalculator().compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: bays, settings: NASSettings()) },
            requestedBayCount: 4
        )
        #expect(rows.map(\.system) == [.synology, .unraid, .snapraid, .btrfs, .zfs])
        #expect(rows.map(\.usableCapacity) == [20, 20, 20, 18, 12])
        #expect(rows.allSatisfy { $0.isValid && $0.failuresTolerated == 1 && $0.bayLimit == nil })
        #expect(rows.last?.unusedCapacity == 20)
    }

    // Review Focus 2: a system that can't use the drives sorts below every one that can.
    @Test func invalidSetupsSortLast() throws {
        var settings = NASSettings()
        settings.snapraidParity = 2
        let rows = NASCalculator().compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: [8, 8], settings: settings) },
            requestedBayCount: 2
        )
        let firstInvalid = try #require(rows.firstIndex { !$0.isValid })
        #expect(rows[firstInvalid...].allSatisfy { !$0.isValid })
        #expect(rows[..<firstInvalid].allSatisfy(\.isValid))
        #expect(rows.first { $0.system == .snapraid }?.isValid == false)
    }
```

Append to `NASViewModelTests`:

```swift
    // Review Focus 1: Synology reads the first 12 of 14 bays; the rest read all 14.
    @Test func comparisonNotesSynologysBayLimit() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.system = .unraid
        model.setBayCount(14)
        for bay in 0..<14 { model.setSize(8, forBay: bay) }
        let rows = model.comparison
        #expect(rows.count == 5)
        #expect(rows.first { $0.system == .synology }?.bayLimit == 12)
        #expect(rows.filter { $0.system != .synology }.allSatisfy { $0.bayLimit == nil })
        #expect(rows.first { $0.system == .unraid }?.usableCapacity == 13 * 8)
        #expect(model.bays(for: .synology).count == 12)
        #expect(model.bays.count == 14)
    }
```

- [ ] **Step 2: Run them and watch them fail.** Run `xcodebuild test … -only-testing:"RAID CalcTests/NASCalculatorTests" -only-testing:"RAID CalcTests/NASViewModelTests"`. Expected: a compile failure, “value of type 'NASCalculator' has no member 'compare'” (and the same for `comparison` and `bays(for:)`). Record the output.

- [ ] **Step 3: Implement.** Append to `NAS.swift`:

```swift
/// One system's answer for the same drives, for “compare systems” (FR-13).
struct NASComparison: Identifiable, Equatable {
    let system: NASSystem
    let usableCapacity: Double
    let unusedCapacity: Double
    let failuresTolerated: Int
    let warningMessage: String?
    /// How many bays this system reads, when that's fewer than the user set
    /// up (Synology stops at 12); nil when it reads them all.
    let bayLimit: Int?

    var id: NASSystem { system }
    var isValid: Bool { warningMessage == nil }
}

extension NASCalculator {
    /// The same drives under every system, most usable first. Setups that
    /// don't work sort last; ties keep the picker's order.
    func compare(_ setups: [NASSetup], requestedBayCount: Int) -> [NASComparison] {
        let order = Dictionary(uniqueKeysWithValues: NASSystem.allCases.enumerated().map { ($1, $0) })
        return setups.map { setup in
            let result = calculate(setup)
            return NASComparison(
                system: setup.system,
                usableCapacity: result.usableCapacity,
                unusedCapacity: result.unusedCapacity,
                failuresTolerated: result.failuresTolerated,
                warningMessage: result.warningMessage,
                bayLimit: setup.bays.count < requestedBayCount ? setup.bays.count : nil
            )
        }
        .sorted { a, b in
            if a.isValid != b.isValid { return a.isValid }
            if a.usableCapacity != b.usableCapacity { return a.usableCapacity > b.usableCapacity }
            return order[a.system, default: 0] < order[b.system, default: 0]
        }
    }
}
```

In `NASViewModel`, replace the `bays` property with the lens function plus a property that uses it, and add `comparison` after `hints`:

```swift
    var bays: [Double?] { bays(for: system) }

    /// What `system` reads of the drives: the first bays up to its limit, the
    /// same rule as switching to it.
    func bays(for system: NASSystem) -> [Double?] {
        let count = min(max(requestedBayCount, system.bayRange.lowerBound), system.bayRange.upperBound)
        return Array(allBays.prefix(count)) + Array(repeating: nil, count: max(0, count - allBays.count))
    }
```

```swift
    /// The same drives under every system, each with its own setting (FR-13).
    var comparison: [NASComparison] {
        calculator.compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: bays(for: $0), settings: settings) },
            requestedBayCount: requestedBayCount
        )
    }
```

Leave `bayCount` as it is. It already equals `bays(for: system).count`.

- [ ] **Step 4: Run them and watch them pass.** Run the same command. Expected: every test in both suites passes. Then run the full `"RAID CalcTests"` target once.

- [ ] **Step 5: Commit.**

```bash
git add RaidCalculator2/NAS.swift RaidCalculator2/NASViewModel.swift RaidCalculator2Tests/NASCalculatorTests.swift RaidCalculator2Tests/NASViewModelTests.swift
git commit -m "Compare the same drives under every NAS system"
```

---

### Task 2: Layout math

**Files:**
- Create: `RaidCalculator2/AdaptiveLayout.swift`
- Test: `RaidCalculator2Tests/AdaptiveLayoutTests.swift`

**Interfaces:**
- Produces:
  - `AdaptiveLayout.twoColumnMinWidth: CGFloat` (800)
  - `AdaptiveLayout.usesTwoColumns(isRegularWidth: Bool, width: CGFloat) -> Bool`
  - `AdaptiveLayout.bayRows(count: Int, width: CGFloat, minColumn: CGFloat, spacing: CGFloat, wrap: Bool) -> [Range<Int>]`

- [ ] **Step 1: Write the failing tests.** Create `RaidCalculator2Tests/AdaptiveLayoutTests.swift`:

```swift
//
//  AdaptiveLayoutTests.swift
//  RaidCalculator2Tests
//

import CoreGraphics
import Testing
@testable import RAID_Calc

struct AdaptiveLayoutTests {

    // Review Focus 3: regular width alone isn't enough room for two columns.
    @Test func twoColumnsNeedRegularWidthAndRoom() {
        #expect(AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 1032))   // 13-inch iPad, portrait
        #expect(AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 800))
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 744))   // iPad mini, portrait
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 678))   // half of a 13-inch iPad
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: false, width: 1200))
    }

    @Test func baysThatFitStayInOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 12, width: 480, minColumn: 24, spacing: 4, wrap: true) == [0..<12])
    }

    // 17 columns of 24 points fit in 480; 30 bays become two balanced rows of 15.
    @Test func tooManyBaysWrapIntoBalancedRows() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 480, minColumn: 24, spacing: 4, wrap: true) == [0..<15, 15..<30])
        #expect(AdaptiveLayout.bayRows(count: 13, width: 300, minColumn: 24, spacing: 4, wrap: true) == [0..<7, 7..<13])
    }

    @Test func withoutWrappingEveryBayIsOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 480, minColumn: 24, spacing: 4, wrap: false) == [0..<30])
    }

    // Review Focus 4: before layout the width is 0; never one bay per row.
    @Test func unknownWidthIsOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 0, minColumn: 24, spacing: 4, wrap: true) == [0..<30])
    }

    @Test func noBaysNoRows() {
        #expect(AdaptiveLayout.bayRows(count: 0, width: 480, minColumn: 24, spacing: 4, wrap: true).isEmpty)
    }
}
```

- [ ] **Step 2: Run them and watch them fail.** Run `xcodebuild test … -only-testing:"RAID CalcTests/AdaptiveLayoutTests"`. Expected: “cannot find 'AdaptiveLayout' in scope”. Record it.

- [ ] **Step 3: Implement.** Create `RaidCalculator2/AdaptiveLayout.swift`:

```swift
//
//  AdaptiveLayout.swift
//  RaidCalculator2
//
//  Size-class decisions both tabs share, kept pure so they can be tested.
//

import CoreGraphics

enum AdaptiveLayout {
    /// Narrowest window that puts results and inputs side by side. A regular
    /// size class alone isn't enough: iPad mini in portrait (744 points) and
    /// half of a 13-inch iPad are regular, but two columns there would each
    /// be narrower than an iPhone.
    static let twoColumnMinWidth: CGFloat = 800

    static func usesTwoColumns(isRegularWidth: Bool, width: CGFloat) -> Bool {
        isRegularWidth && width >= twoColumnMinWidth
    }

    /// The bays in each row of a bay diagram. One row when the bays fit at
    /// `minColumn` each, when wrapping is off, or before the width is known;
    /// otherwise as few rows as fit, with the bays shared out evenly.
    static func bayRows(count: Int, width: CGFloat, minColumn: CGFloat, spacing: CGFloat, wrap: Bool) -> [Range<Int>] {
        guard count > 0 else { return [] }
        let perRow = max(1, Int((width + spacing) / (minColumn + spacing)))
        guard wrap, width > 0, count > perRow else { return [0..<count] }
        let rowCount = (count + perRow - 1) / perRow
        let size = (count + rowCount - 1) / rowCount
        return stride(from: 0, to: count, by: size).map { $0..<min($0 + size, count) }
    }
}
```

- [ ] **Step 4: Run them and watch them pass.** Run the same command. Expected: 6 tests pass.

- [ ] **Step 5: Commit.**

```bash
git add RaidCalculator2/AdaptiveLayout.swift RaidCalculator2Tests/AdaptiveLayoutTests.swift
git commit -m "Add the layout rules for two columns and wrapped bay rows"
```

---

### Task 3: Two-column layout for both tabs

**Files:**
- Modify: `RaidCalculator2/ContentView.swift` (`ContentView` only, lines 10–240)
- Modify: `RaidCalculator2/NASView.swift` (`NASView.body` only, lines 20–198)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Consumes: `AdaptiveLayout.usesTwoColumns(isRegularWidth:width:)` (Task 2).
- Produces:
  - In `ContentView`: `answerSections`, `inputSections` and `ratingsSection`.
  - In `NASView`: `summarySection`, `setupSection`, `adviceSections` and `drivesSection`, all `@ViewBuilder` properties.
  - `private var twoColumns: Bool` in both views. Task 6 adds the comparison inside `summarySection` and the two-column left `Form`.

This is a move, not a rewrite. Every section keeps its code, identifiers, haptics and transitions exactly as they are. Only where the sections live changes.

- [ ] **Step 1: Write the failing UI tests.** Add to `RaidCalculator2UITests`:

```swift
    /// FR-14: on a wide iPad the answer sits beside the inputs, so both are
    /// on screen without scrolling. Skips on iPhone.
    @MainActor
    func testIPadPutsResultsBesideInputs() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchApp()
        let usable = app.staticTexts.matching(identifier: "usableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))
        let count = app.staticTexts.matching(identifier: "driveCount").firstMatch
        XCTAssertTrue(count.isHittable)
        XCTAssertLessThan(usable.frame.maxX, count.frame.minX, "results should lead, inputs follow")
    }

    @MainActor
    func testIPadNASPutsResultsBesideInputs() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchNAS()
        let usable = app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))
        let picker = app.buttons["nasSystem"]
        XCTAssertTrue(picker.isHittable)
        XCTAssertLessThan(usable.frame.maxX, picker.frame.minX)
        XCTAssertTrue(app.buttons["bay4"].isHittable, "every bay of a 4-bay setup fits beside the results")
    }
```

- [ ] **Step 2: Run them on the iPad and watch them fail.** Run `xcodebuild test … -destination "$IPAD" -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testIPadPutsResultsBesideInputs" -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testIPadNASPutsResultsBesideInputs"`. Expected: both fail at the `XCTAssertLessThan` frame check, because today the layout is stacked. Record it.

- [ ] **Step 3: Split `ContentView` into sections.**
  - Add `@Environment(\.horizontalSizeClass) private var horizontalSizeClass`.
  - Move the existing sections, unchanged, into three builders. Inside them, `result` becomes `viewModel.result`.

```swift
    private var twoColumns: Bool {
        AdaptiveLayout.usesTwoColumns(isRegularWidth: horizontalSizeClass == .regular, width: contentWidth)
    }

    /// The answer and anything wrong with it.
    @ViewBuilder private var answerSections: some View {
        // (move here, unchanged: the CapacitySummary section, then the whole
        //  `if let warning … else if … caution` block, lines 26–67 today)
    }

    /// What the user sets: the level, then the drives.
    @ViewBuilder private var inputSections: some View {
        // (move here, unchanged: the "raid_level" section and the
        //  "drive_configuration" section, lines 69–163 today)
    }

    @ViewBuilder private var ratingsSection: some View {
        // (move here, unchanged: the ratings section, lines 165–172 today)
    }
```

  Then replace `body` with the following. The modifiers after `Group` are today’s modifiers on the `Form`, in the same order. The horizontal `contentMargins` applies to the stacked `Form` only.

```swift
    var body: some View {
        Group {
            if twoColumns {
                // Results lead so reading and VoiceOver order match the
                // stacked layout, where the answer comes first.
                HStack(alignment: .top, spacing: 0) {
                    Form {
                        answerSections
                        ratingsSection
                    }
                    Divider()
                    Form { inputSections }
                }
            } else {
                Form {
                    answerSections
                    inputSections
                    ratingsSection
                }
                .contentMargins(
                    .horizontal,
                    contentWidth > readableWidth + 40 ? (contentWidth - readableWidth) / 2 : nil,
                    for: .scrollContent
                )
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }
        .navigationTitle("app_title".localized())
        .toolbar {
            // (unchanged: the info button and the keyboard Done button)
        }
        .scrollDismissesKeyboard(.interactively)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
        .sensoryFeedback(.selection, trigger: viewModel.selectedLevel)
        .sheet(isPresented: $showingInfoSheet) {
            InfoSheet(topic: .level(viewModel.selectedLevel))
        }
    }
```

- [ ] **Step 4: Split `NASView` into sections the same way.**
  - Add `@Environment(\.horizontalSizeClass) private var horizontalSizeClass` and the same `twoColumns` property.
  - Move these existing pieces, unchanged, into four builders (`result` becomes `viewModel.result`):
    - `summarySection`: the `NASSummary` section (lines 24–26).
    - `setupSection`: the `"nas_setup"` section (28–87).
    - `adviceSections`: the warning/suggestion block, the hints section and the comparison-with-current section (89–148).
    - `drivesSection`: the drives section with its footer (150–161).
  - Replace `body`:

```swift
    var body: some View {
        Group {
            if twoColumns {
                HStack(alignment: .top, spacing: 0) {
                    Form {
                        summarySection
                        adviceSections
                    }
                    Divider()
                    Form {
                        setupSection
                        drivesSection
                    }
                }
            } else {
                // Setup sits above every section that comes and goes, so the
                // system picker stays put under the user's finger.
                Form {
                    summarySection
                    setupSection
                    adviceSections
                    drivesSection
                }
                .contentMargins(
                    .horizontal,
                    contentWidth > readableWidth + 40 ? (contentWidth - readableWidth) / 2 : nil,
                    for: .scrollContent
                )
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }
        .navigationTitle("tab_nas".localized())
        .toolbar {
            // (unchanged: the info button)
        }
        .sheet(isPresented: $showingInfo) {
            InfoSheet(topic: .system(viewModel.system))
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
        .alert(
            // (unchanged: the custom-size alert)
        )
    }
```

- [ ] **Step 5: Run the iPad tests and watch them pass.** Run the Step 2 command. Expected: both pass. Then run the full `"RAID CalcUITests"` target on `$DEST` (iPhone). Every existing test must still pass, and the two iPad tests must report as skipped.

- [ ] **Step 6: Screenshot check.**
  - Boot the iPad Pro 13-inch (M5) and the iPad mini (A17 Pro).
  - On each, run the app in portrait and in landscape: `xcrun simctl launch booted <bundle id> -selectedTab nas`, then `xcrun simctl io booted screenshot /tmp/p3-t3-<device>-<orientation>-<tab>.png`.
  - Get the bundle id from `PRODUCT_BUNDLE_IDENTIFIER` with `xcodebuild -showBuildSettings`.
  - **Expected:**
    - The 13-inch shows two columns in both orientations.
    - The mini shows two columns in landscape (1133 points) and is stacked in portrait (744 points).
  - Report the paths.

- [ ] **Step 7: Commit.**

```bash
git add RaidCalculator2/ContentView.swift RaidCalculator2/NASView.swift RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Put results beside inputs on a wide iPad"
```

---

### Task 4: Bay diagram rows and accessibility-size labels

**Files:**
- Modify: `RaidCalculator2/NASView.swift` (`BayDiagram`, lines 365–484 today)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Consumes:
  - `AdaptiveLayout.bayRows(count:width:minColumn:spacing:wrap:)` (Task 2)
  - `NASView.tb(_:)`, `SegmentSwatch`
- Produces: `BayDiagram(bays:system:)` with an unchanged signature.

**Behavior:**
- **Regular width:** bays wrap into balanced rows.
- **Compact width:** a single row scrolls when its columns would be narrower than `minColumn`. This replaces today’s fixed `bays.count > 12` rule.
- **At accessibility sizes:** labels show the number only, and the legend adds “Sizes in TB”.
- **Motion:** the Reduce Motion crossfade and the `.snappy` re-split stay as they are.

- [ ] **Step 1: Add the string.** Write `/tmp/p3-t4-strings.json` and run `python3 scripts/strings.py add /tmp/p3-t4-strings.json`, then `python3 scripts/strings.py check`:

```json
{
  "bay_sizes_in_tb": {
    "en": "Sizes in TB",
    "es": "Tamaños en TB",
    "fr": "Tailles en TB",
    "it": "Dimensioni in TB",
    "ja": "容量はTB単位"
  }
}
```

  If `strings.py add` expects a different JSON shape, read `scripts/strings.py`’s usage text and adapt the file, keeping the values verbatim.

- [ ] **Step 2: Write the failing UI test.**

```swift
    /// FR-14: 30 bays stay legible on iPad, in rows, with no scrolling.
    @MainActor
    func testIPadShowsThirtyBaysWithoutScrolling() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let bays = "[" + Array(repeating: "8", count: 30).joined(separator: ",") + "]"
        let app = launchNAS(system: "unraid", bays: bays, bayCount: 30)
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 5))
        for bay in [1, 15, 16, 30] {
            let column = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Bay \(bay), ")).firstMatch
            XCTAssertTrue(column.exists, "bay \(bay)")
            XCTAssertTrue(column.isHittable, "bay \(bay) should be on screen without scrolling")
        }
    }
```

- [ ] **Step 3: Run it on the iPad and watch it fail.** Expected: bay 30 (or 16) is not hittable, because today’s diagram scrolls past 12 bays. Record it.

- [ ] **Step 4: Implement.** In `BayDiagram`:
  - Add the environment values, the scaled minimum column and the measured width.
  - Replace `body`, `columns` and the per-bay column code.
  - Keep `column(_:)`, `legend`, `total(_:)` and `accessibilityLabel(bay:segments:)` as they are.

```swift
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Narrowest a column gets before the diagram wraps (regular width) or
    /// scrolls (compact). Grows with Dynamic Type, so labels stay readable.
    @ScaledMetric(relativeTo: .caption2) private var minColumn: CGFloat = 24
    @State private var width: CGFloat = 0

    private var spacing: CGFloat { bays.count > 8 ? 4 : 8 }

    private var rows: [Range<Int>] {
        AdaptiveLayout.bayRows(count: bays.count, width: width, minColumn: minColumn, spacing: spacing, wrap: horizontalSizeClass == .regular)
    }

    /// A single row that doesn't fit scrolls rather than squeezing its columns.
    private var scrolls: Bool {
        rows.count == 1 && width > 0 && CGFloat(bays.count) * (minColumn + spacing) - spacing > width
    }

    /// At accessibility sizes the labels drop the unit, which the legend states once.
    private var numberOnlyLabels: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Under full motion the same bays animate their segments in place
            // with .snappy, whatever changed. Under Reduce Motion nothing moves:
            // every change is a new diagram that crossfades over the old one.
            Group {
                if scrolls {
                    ScrollView(.horizontal, showsIndicators: false) { columns }
                } else {
                    columns
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: bays)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private var columns: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(rows, id: \.lowerBound) { row in
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(row, id: \.self) { index in bayColumn(index) }
                    }
                }
            }
            // Keyed on the whole diagram under Reduce Motion, so any change swaps
            // the view instead of resizing its bars. The transition carries its
            // own animation because the change itself arrives unanimated.
            .id(reduceMotion ? AnyHashable([AnyHashable(system), AnyHashable(bays), AnyHashable(rows.count)]) : AnyHashable(0))
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }

    private func bayColumn(_ index: Int) -> some View {
        let segments = bays[index]
        return VStack(spacing: 4) {
            column(segments)
                .frame(minWidth: scrolls ? minColumn : nil, maxWidth: 72)
                .frame(height: maxHeight, alignment: .bottom)
            Text(label(for: segments))
                .font(bays.count > 6 ? .caption2 : .caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(scrolls ? 0.6 : 0.8)
                .fixedSize(horizontal: bays.count <= 6, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(bay: index, segments: segments))
    }

    private func label(for segments: [BaySegment]?) -> String {
        guard let segments else { return "empty_bay".localized() }
        return numberOnlyLabels
            ? total(segments).formatted(.number.precision(.fractionLength(0...2)))
            : NASView.tb(total(segments))
    }
```

  Then, in `legend`, after the `ForEach`, add:

```swift
        if numberOnlyLabels {
            Text("bay_sizes_in_tb".localized())
        }
```

- [ ] **Step 5: Run the iPad test, then the iPhone UI target.**
  - The new iPad test must pass.
  - The full `"RAID CalcUITests"` target on `$DEST` must still pass, including `testNASSwitchSystem`, `testSnapRAIDParityHint` and the Reduce Motion test.

- [ ] **Step 6: Screenshot check** of the cases parked from plan 2:
  - Launch the iPhone 17 with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` and these setups:
    - `-AppleLanguages "(ja)"`: ZFS with 14 bays, sizes `[20,16,16,12,12,8,8,8,8,4,4,4,4,4]`
    - French: the same ZFS setup
    - Japanese: Synology with 7 bays, `[16,8,8,4,4,4,4]`
  - Use `-selectedTab nas -nas.system zfs -nas.bayCount 14 -synology.bays <hex of the JSON>`, the same hex encoding `launchNAS` uses.
  - Save to `/tmp/p3-t4-<case>.png`.
  - **Expected:** labels show numbers with no unit and no clipping (no “4 TE”), the legend shows “容量はTB単位” / “Tailles en TB”, and the diagram scrolls horizontally.
  - Also capture the 13-inch iPad in landscape with 30 Unraid bays (`/tmp/p3-t4-ipad-30.png`). **Expected:** two rows of 15.
  - Report the paths.

- [ ] **Step 7: Commit.**

```bash
git add RaidCalculator2/NASView.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Wrap big bay diagrams into rows on iPad, and drop units at accessibility sizes"
```

---

### Task 5: Drive strip group rows and VoiceOver groups

**Files:**
- Modify: `RaidCalculator2/ContentView.swift` (`DriveStrip`, lines 377–497 today)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Produces: `DriveStrip(roles:groupSize:)` with an unchanged signature.

**Behavior:**
- **Regular width, grouped level:** each group is drawn as its own row, with bars up to 44 points wide. Bars keep their identity across layouts through `matchedGeometryEffect`, so regrouping slides the bars under full motion.
- **Compact width:** unchanged. One row with group gaps.
- **VoiceOver, everywhere:** the strip reads its summary, then one element per group.

- [ ] **Step 1: Add the strings.** Run `python3 scripts/strings.py add /tmp/p3-t5-strings.json`, then `check`:

```json
{
  "drive_strip_group_accessibility": {
    "en": "Group %1$d of %2$d: %3$@",
    "es": "Grupo %1$d de %2$d: %3$@",
    "fr": "Groupe %1$d sur %2$d : %3$@",
    "it": "Gruppo %1$d di %2$d: %3$@",
    "ja": "グループ%1$d/%2$d：%3$@"
  }
}
```

- [ ] **Step 2: Write the failing UI test** (runs on iPhone):

```swift
    /// §1.6: VoiceOver reads group structure, one element per group.
    @MainActor
    func testDriveStripReadsEachGroup() throws {
        let app = launchApp(level: "R 60", drives: 12, groups: 2)
        XCTAssertTrue(app.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        for group in 1...2 {
            let element = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Group \(group) of 2: ")).firstMatch
            XCTAssertTrue(element.exists, "group \(group)")
            XCTAssertTrue(element.label.contains("4 Data") && element.label.contains("2 Parity"), element.label)
        }
    }
```

- [ ] **Step 3: Run it and watch it fail.** Expected: no element whose label begins “Group 1 of 2: ”. Record it.

- [ ] **Step 4: Implement.** In `DriveStrip`, add:

```swift
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var bars

    /// On a regular-width layout each group gets its own row, using the extra width.
    private var groupsAsRows: Bool { horizontalSizeClass == .regular && groupCount > 1 }
    private var rowSpacing: CGFloat { barSpacing * 2 }

    private var rowsHeight: CGFloat {
        CGFloat(groupCount) * barHeight + CGFloat(groupCount - 1) * rowSpacing
    }

    private func groupRange(_ group: Int) -> Range<Int> {
        let size = groupSize ?? roles.count
        return (group * size)..<min((group + 1) * size, roles.count)
    }

    /// Ties a bar to its drive across the inline and row layouts, so
    /// regrouping slides it rather than replacing it. Off under Reduce Motion,
    /// where the strip crossfades instead.
    @ViewBuilder
    private func tracked(_ bar: some View, index: Int) -> some View {
        if reduceMotion {
            bar
        } else {
            bar.matchedGeometryEffect(id: index, in: bars)
        }
    }
```

  Replace the `GeometryReader` block inside `body` with the following. The inline branch is today’s code, with each bar wrapped in `tracked`.

```swift
            GeometryReader { proxy in
                if groupsAsRows {
                    let size = groupSize ?? roles.count
                    let width = max(0, min(44, (proxy.size.width - CGFloat(size - 1) * barSpacing) / CGFloat(size)))
                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(0..<groupCount, id: \.self) { group in
                            HStack(spacing: barSpacing) {
                                ForEach(groupRange(group), id: \.self) { index in
                                    tracked(bar(for: roles[index]).frame(width: width, height: barHeight), index: index)
                                }
                            }
                        }
                    }
                    .id(reduceMotion ? "rows-\(groupSize ?? 0)-\(roles.count)" : "rows")
                    .transition(.opacity)
                } else {
                    let width = barWidth(in: proxy.size.width)
                    ZStack(alignment: .leading) {
                        HStack(spacing: barSpacing) {
                            ForEach(roles.indices, id: \.self) { index in
                                tracked(bar(for: roles[index])
                                    .frame(width: width, height: barHeight)
                                    .padding(.leading, isGroupStart(index) ? groupGap : 0), index: index)
                            }
                        }
                        .id(reduceMotion ? "\(groupSize ?? 0)-\(roles.count)" : "")
                        .transition(.opacity)
                    }
                }
            }
            .frame(height: groupsAsRows ? rowsHeight : barHeight)
```

  Replace the strip’s `.accessibilityElement(children: .ignore)` and `.accessibilityLabel(accessibilitySummary)` with:

```swift
        // The summary, then one element per group, so VoiceOver reads the structure.
        .accessibilityRepresentation {
            VStack {
                Text(accessibilitySummary)
                if groupCount > 1 {
                    ForEach(0..<groupCount, id: \.self) { group in
                        Text(groupAccessibility(group))
                    }
                }
            }
        }
```

  Then add:

```swift
    private func groupAccessibility(_ group: Int) -> String {
        let members = roles[groupRange(group)]
        let parts = presentRoles.compactMap { role -> String? in
            let count = members.filter { $0 == role }.count
            return count > 0 ? String(format: "role_count".localized(), count, Self.name(of: role)) : nil
        }.joined(separator: ", ")
        return String(format: "drive_strip_group_accessibility".localized(), group + 1, groupCount, parts)
    }
```

  If `matchedGeometryEffect` produces visible glitches, such as bars flying in from the origin on first appearance or a doubled bar during the switch, remove `tracked` and keep the plain bars. A crossfade between layouts is acceptable. Record that decision in the report.

- [ ] **Step 5: Run the tests.**
  - The new test must pass on `$DEST`.
  - `testNestedLevelFromMenu`, `testStandardLevelHidesGroups` and `testNestedLevelFixFromDefaults` must still pass.
  - Then run the full UI target.

- [ ] **Step 6: Screenshot check.**
  - Capture the 13-inch iPad in landscape: RAID 60 with 24 drives in 4 groups, and RAID-Z2 with 12 drives in 2 groups. Use `-selectedLevel "R 60" -driveCount 24 -groups 4`. Save to `/tmp/p3-t5-*.png`.
  - **Expected:** one row per group, bars at full width.
  - Also capture the iPhone 17 with the same RAID 60 setup. **Expected:** unchanged, one row with gaps.

- [ ] **Step 7: Commit.**

```bash
git add RaidCalculator2/ContentView.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Show drive groups as rows on iPad, and read each group to VoiceOver"
```

---

### Task 6: Compare systems UI

**Files:**
- Create: `RaidCalculator2/NASComparisonViews.swift`
- Modify: `RaidCalculator2/NASView.swift` (`summarySection`, the two-column left `Form`, a new sheet)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Consumes:
  - `NASViewModel.comparison`, `NASComparison` (Task 1)
  - `twoColumns`, `summarySection` (Task 3)
  - `NASView.tb(_:)`
- Produces:
  - `NASComparisonCell(comparison:isCurrent:)`
  - `NASComparisonSheet(comparison:current:select:)`
  - `NASComparisonColumns(comparison:current:select:)`
  - Accessibility identifiers: `compareSystems` (the iPhone button), `compare_<rawValue>` (each system), `closeCompare`

- [ ] **Step 1: Add the strings.** Run `python3 scripts/strings.py add /tmp/p3-t6-strings.json`, then `check`:

```json
{
  "compare_systems": {
    "en": "Compare Systems",
    "es": "Comparar sistemas",
    "fr": "Comparer les systèmes",
    "it": "Confronta i sistemi",
    "ja": "システムを比較"
  },
  "compare_header": {
    "en": "Every System, Same Drives",
    "es": "Todos los sistemas, mismos discos",
    "fr": "Tous les systèmes, mêmes disques",
    "it": "Tutti i sistemi, stessi dischi",
    "ja": "同じドライブ、すべてのシステム"
  },
  "compare_failures": {
    "en": "Failures tolerated: %d",
    "es": "Fallos tolerados: %d",
    "fr": "Pannes tolérées : %d",
    "it": "Guasti tollerati: %d",
    "ja": "許容故障数：%d"
  },
  "compare_unused": {
    "en": "%@ unused",
    "es": "%@ sin usar",
    "fr": "%@ inutilisés",
    "it": "%@ inutilizzati",
    "ja": "%@未使用"
  },
  "compare_first_bays": {
    "en": "Uses the first %d bays",
    "es": "Usa las primeras %d bahías",
    "fr": "Utilise les %d premières baies",
    "it": "Usa i primi %d alloggiamenti",
    "ja": "最初の%dベイを使用"
  },
  "compare_hint": {
    "en": "Switches the NAS tab to this system.",
    "es": "Cambia la pestaña NAS a este sistema.",
    "fr": "Fait passer l’onglet NAS à ce système.",
    "it": "Passa la scheda NAS a questo sistema.",
    "ja": "NASタブをこのシステムに切り替えます。"
  }
}
```

- [ ] **Step 2: Write the failing UI tests.**

```swift
    /// FR-13 on iPhone: a sheet from the results card; tapping a system
    /// switches to it and keeps the drives (Review Focus 5).
    @MainActor
    func testCompareSystemsSwitchesSystem() throws {
        let app = launchNAS()
        let compare = app.buttons["compareSystems"]
        XCTAssertTrue(compare.waitForExistence(timeout: 5))
        compare.tap()
        let zfs = app.buttons["compare_zfs"]
        XCTAssertTrue(zfs.waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'compare_'")).count, 5)
        zfs.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: zfs)
        wait(for: [gone], timeout: 3)
        XCTAssertEqual(nasCapacity(app), tb(12))
        let bay4 = app.buttons["bay4"]
        reveal(bay4, in: app)
        XCTAssertTrue(bay4.label.contains(tb(8)), bay4.label)
    }

    /// FR-13 on iPad: columns beside the results, no sheet.
    @MainActor
    func testIPadComparesSystemsInColumns() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchNAS()
        let unraid = app.buttons["compare_unraid"]
        XCTAssertTrue(unraid.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["compareSystems"].exists)
        app.buttons["compare_zfs"].tap()
        XCTAssertEqual(nasCapacity(app), tb(12))
    }
```

  `tb` and `nasCapacity` are the file’s existing helpers. If `bay4`’s label doesn’t contain the size, assert on its value the way existing bay tests do.

- [ ] **Step 3: Run them and watch them fail.** Expected: no `compareSystems` button on iPhone and no `compare_unraid` on iPad. Record both.

- [ ] **Step 4: Create `RaidCalculator2/NASComparisonViews.swift`:**

```swift
//
//  NASComparisonViews.swift
//  RaidCalculator2
//
//  “Same drives, every system” (FR-13): a sheet of rows on iPhone, columns
//  beside the results on iPad. Tapping a system switches the tab to it.
//

import SwiftUI

/// One system's answer. A setup that can't work shows its warning, not a number.
struct NASComparisonCell: View {
    let comparison: NASComparison
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(comparison.system.displayName)
                    .font(.headline)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            if comparison.isValid {
                Text(NASView.tb(comparison.usableCapacity))
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Group {
                    Text(String(format: "compare_failures".localized(), comparison.failuresTolerated))
                    if comparison.unusedCapacity > 0 {
                        Text(String(format: "compare_unused".localized(), NASView.tb(comparison.unusedCapacity)))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else if let warning = comparison.warningMessage {
                Text(warning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let limit = comparison.bayLimit {
                Text(String(format: "compare_first_bays".localized(), limit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint("compare_hint".localized())
    }
}

/// iPhone: rows in a sheet. The choice is applied after the sheet closes,
/// so the user sees the bays re-split.
struct NASComparisonSheet: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(comparison) { row in
                Button {
                    select(row.system)
                    dismiss()
                } label: {
                    NASComparisonCell(comparison: row, isCurrent: row.system == current)
                }
                .tint(.primary)
                .accessibilityIdentifier("compare_\(row.system.rawValue)")
            }
            .navigationTitle("compare_systems".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                        .accessibilityIdentifier("closeCompare")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// iPad: the systems side by side, or stacked when the column is too narrow
/// (accessibility text sizes).
struct NASComparisonColumns: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                cells.frame(minWidth: 96, maxWidth: .infinity, alignment: .topLeading)
            }
            VStack(alignment: .leading, spacing: 14) { cells }
        }
    }

    private var cells: some View {
        ForEach(comparison) { row in
            Button {
                select(row.system)
            } label: {
                NASComparisonCell(comparison: row, isCurrent: row.system == current)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("compare_\(row.system.rawValue)")
        }
    }
}
```

- [ ] **Step 5: Wire it into `NASView`.**
  - Add state:

```swift
    @State private var showingComparison = false
    @State private var pendingSystem: NASSystem?
```

  - `summarySection` becomes:

```swift
    @ViewBuilder private var summarySection: some View {
        Section {
            NASSummary(result: viewModel.result, system: viewModel.system)
            if !twoColumns {
                Button {
                    showingComparison = true
                } label: {
                    Label("compare_systems".localized(), systemImage: "rectangle.split.3x1")
                }
                .accessibilityIdentifier("compareSystems")
            }
        }
    }
```

  - In the two-column left `Form`, between `summarySection` and `adviceSections`, add:

```swift
                        Section("compare_header".localized()) {
                            NASComparisonColumns(comparison: viewModel.comparison, current: viewModel.system) { system in
                                withAnimation(motion) { viewModel.system = system }
                            }
                        }
```

  - After the info sheet’s `.sheet`, add:

```swift
        .sheet(isPresented: $showingComparison, onDismiss: {
            // Applied once the sheet is gone, so the bays visibly re-split.
            if let system = pendingSystem {
                pendingSystem = nil
                withAnimation(motion) { viewModel.system = system }
            }
        }) {
            NASComparisonSheet(comparison: viewModel.comparison, current: viewModel.system) { pendingSystem = $0 }
        }
```

  The system picker’s existing `.sensoryFeedback(.selection, trigger: viewModel.system)` gives the haptic on either path. Don’t add another.

- [ ] **Step 6: Run the tests.**
  - iPhone: the new test and the full UI target on `$DEST`.
  - iPad: `testIPadComparesSystemsInColumns` and the two Task 3 tests on `$IPAD`.

- [ ] **Step 7: Screenshot check.** Use Synology `[16,8,8,4]`.
  - iPhone 17 with the sheet open, in English and in Japanese at the default text size: `/tmp/p3-t6-iphone-en.png`, `/tmp/p3-t6-iphone-ja.png`.
  - iPhone 17 with the sheet at AX XXXL in French.
  - 13-inch iPad in landscape: `/tmp/p3-t6-ipad.png`. **Expected:** five columns, Synology checked, ZFS last at 12 TB with “20 TB unused”.
  - Unraid with 14 bays on iPad. **Expected:** Synology’s column says “Uses the first 12 bays”.

- [ ] **Step 8: Commit.**

```bash
git add RaidCalculator2/NASComparisonViews.swift RaidCalculator2/NASView.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Compare every NAS system on the same drives"
```

---

### Task 7: Rating and Drive Size rows at accessibility sizes

**Files:**
- Modify: `RaidCalculator2/ContentView.swift` (`RatingRow`; the Drive Size `LabeledContent` in `inputSections`)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

This fixes plan 1’s parked rows. At AX5, `RatingRow` breaks mid-word (ja 中程/度, fr “Moyen”), and the Drive Size row squeezes its label. Both adopt `CountStepper`’s pattern: at accessibility sizes the label gets its own line.

- [ ] **Step 1: Write the failing UI test.** First add a `contentSize: String? = nil` parameter to `launchApp`. When it is set, append `"-UIPreferredContentSizeCategoryName", contentSize` to the launch arguments. Then add:

```swift
    /// At the largest text size the drive size is still on screen and editable.
    @MainActor
    func testDriveSizeAtAccessibilitySize() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        let field = app.textFields["driveSizeField"]
        reveal(field, in: app)
        let label = app.staticTexts["Drive Size"]
        XCTAssertTrue(label.exists)
        XCTAssertLessThan(label.frame.maxY, field.frame.minY + 1, "label sits above the field")
        field.tap()
        field.typeText(XCUIKeyboardKey.delete.rawValue + "8")
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 24 TB,"), capacity(app))
    }
```

  RAID 5 with 4 × 8 TB gives 24 TB. Note that `staticTexts["Drive Size"]` must be visible to accessibility in the stacked layout, so don’t hide it there.

- [ ] **Step 2: Run it and watch it fail.** Expected: the frame assertion fails, because the label sits beside the field. Record it.

- [ ] **Step 3: Implement `RatingRow`.**

```swift
struct RatingRow: View {
    let title: String
    let rating: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var label: String { RaidCalculator.ratingLabel(rating) }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Title, stars and word each get their own line, so none breaks mid-word.
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    stars
                    Text(label)
                        .foregroundStyle(.secondary)
                }
            } else {
                LabeledContent {
                    HStack(spacing: 8) {
                        stars
                        Text(label)
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Text(title)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "rating_accessibility".localized(), title, rating, label))
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            }
        }
        .font(.footnote)
    }
}
```

- [ ] **Step 4: Implement the Drive Size row.** In `inputSections`, replace the `LabeledContent("drive_size".localized()) { … }` with:

```swift
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("drive_size".localized())
                        driveSizeControls
                    }
                } else {
                    LabeledContent("drive_size".localized()) { driveSizeControls }
                }
```

  Then add:

```swift
    private var driveSizeControls: some View {
        HStack(spacing: 12) {
            DriveSizeField(value: $viewModel.driveSize, focus: $sizeFieldFocused)
                .frame(minWidth: 56, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 140)

            Picker(selection: $viewModel.unit) {
                ForEach(CapacityUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            } label: {
                Text("drive_size".localized())
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
    }
```

- [ ] **Step 5: Run the tests.** Run the new test, then every `testDriveSize…` test plus `testEmptyDriveSizeRestoredOnDone`, then the full UI target.

- [ ] **Step 6: Screenshot check.** Capture the iPhone 17 at AX XXXL:
  - The RAID tab’s ratings section and the RAID 5 info sheet, in Japanese and in French
  - The drive-size row in Japanese

  Save to `/tmp/p3-t7-*.png`. **Expected:** no mid-word breaks.

- [ ] **Step 7: Commit.**

```bash
git add RaidCalculator2/ContentView.swift RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Stack the rating and drive-size rows at accessibility text sizes"
```

---

### Task 8: Full verification, iPhone and iPad

- [ ] **Step 1:** Run `python3 scripts/strings.py check`. Expected: `0 problem(s)`.
- [ ] **Step 2:** Run the full suite on the iPhone 17, serially: `xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -parallel-testing-enabled NO`. Expected: `** TEST SUCCEEDED **`, with the iPad tests skipped.
  - If a single UI test fails after a stall of more than 5 minutes at “Setting up automation session” or “Wait for … to idle”, rerun that test alone. If it passes, report it as an environment stall with both log excerpts.
- [ ] **Step 3:** Run every test whose name starts with `testIPad` on `$IPAD`. Expected: all pass. Then run them on the iPad mini (A17 Pro).
  - **Expected on the mini:** the two-column tests skip or fail only in portrait, because 744 points is stacked by design. Run the mini in landscape (`XCUIDevice.shared.orientation = .landscapeLeft`, which the tests already set). Report what happened.
- [ ] **Step 4: Screenshot sweep.** Light and dark, both tabs:
  - 13-inch iPad, portrait and landscape
  - iPad mini, portrait (stacked) and landscape (two columns)
  - iPhone 17
  - iPhone 17e at AX XXXL in Japanese

  Check for:
  - clipping
  - mid-word breaks
  - raw `%1$d` placeholders
  - a column narrower than an iPhone
  - the results column leading

  Save every capture, in both light and dark, to `marketing/screenshots/1.6.0/sweep/` (not `/tmp`) as `<device>-<orientation>-<tab>-<light|dark>.png`; plan 4 rebuilds the website from them. Commit them with the report. Report the paths.
- [ ] **Step 5: Performance (§1.6).** Use Unraid with 30 bays and open the comparison. Scroll it, change bay 1’s size from its menu, and switch systems five times. Report any visible lag. Comparing five systems at 30 bays is 5 small calculations and should be instant.
- [ ] **Step 6: Report.** Don’t tag, merge or release.
