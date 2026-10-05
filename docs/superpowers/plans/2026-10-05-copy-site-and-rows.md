# Copy, Website and Small Rows Implementation Plan (1.6.0, plan 4 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish 1.6.0 for release:
- the one-line “Drive failures tolerated” row (FR-18)
- FR-19’s two leftovers
- the parked translation and catalog polish
- the website and App Store copy for the NAS tab, with every trademark line (FR-16)
- fresh screenshots
- `prd-update.md` merged into `prd.md`

**Architecture:**
- **Rows:** a shared `FailuresToleratedRow` replaces the duplicated label code in both result cards.
- **Drive size:** `DriveSizeField` reports when it’s empty, so the RAID card can say “Enter a drive size.”
- **Custom size:** the NAS custom-size alert edits text and disables Done until it parses.
- **Copy:** drafted by one translator-grade pass into a JSON change set, then applied with `scripts/strings.py`.
- **Website:** `www/index.html` gets exact replacement copy, and new screenshots are captured from the Simulator with fixed launch arguments.

**Tech Stack:** Swift 6 (default MainActor isolation), SwiftUI, iOS 26.0, Swift Testing (unit), XCTest (UI), Xcode 27, `scripts/strings.py`, `cwebp`, `magick`, static HTML in `www/`.

**Spec:** `prd-update.md`. This plan implements:
- FR-16’s website and App Store parts
- FR-18
- FR-19’s “still open” items
- the copy items parked by plans 1 and 2 (memory: `plan1-parked-items`, `plan2-parked-items`)
- the PRD merge the spec’s header calls for at ship time

**Branch:** `feat/1.6.0-copy-site`, created from plan 3’s `feat/1.6.0-compare-ipad`. The screenshots need plan 3’s compare and iPad layouts.

## Global Constraints

- iOS 26.0, native SwiftUI, no third-party dependencies. Swift 6 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- **Strings:**
  - Every user-facing string is a key in `RaidCalculator2/Localizable.xcstrings`, in `en`, `es`, `fr`, `it` and `ja`, with identical positional specifiers.
  - Add and remove keys only with `python3 scripts/strings.py add <file.json>` / `remove <key>…`. To change a value, `remove` then `add`.
  - `python3 scripts/strings.py check` prints `0 problem(s)` before every commit that touches strings.
- **Copy, in the app and on the website:**
  - Smart punctuation (curly “ ” ’) and American spelling.
  - Em dashes only where they earn it, at most one per sentence, closed up (`word—word`).
  - En dashes in ranges stay (`2–12`).
  - System names stay untranslated: Synology, SHR, SHR-2, Unraid, ZFS, RAID-Z1/Z2/Z3, SnapRAID, Btrfs RAID1.
- **Terminology per screen:**
  - On the NAS screen, Spanish says “disco” and Japanese counts drives with 台.
  - The RAID tab and the info sheets keep Spanish “unidad”, which plan 2 ruled acceptable.
- **The honesty rule (FR-18):** conditional fault tolerance (“Up to 4 (depends on which drives fail)”) is never shortened to fit one line. The ZFS figure is always labeled an estimate.
- **Trademarks (FR-16):** nominative mentions only, and no logos.
  - **App:** each line lives in its system’s info sheet.
  - **Website footer and App Store description:** every line, in this exact wording:
    - “Not affiliated with or endorsed by Synology Inc. Synology and SHR are trademarks of Synology Inc.”
    - “Not affiliated with or endorsed by Lime Technology, Inc. Unraid is a trademark of Lime Technology, Inc.”
    - “ZFS is a trademark of Oracle and/or its affiliates. Not affiliated with or endorsed by Oracle.”
- **Don’t release.** No `v*` or `www-v*` tags, and no pushes. FR-16 says the website ships as a `www-v*` release only once the app is live, which is the user’s call.
- **`marketing/app-store-listing.md` is untracked on purpose.** Edit it, but don’t `git add` it.
- **Build churn:** Xcode’s build may rewrite `Localizable.xcstrings`. If `strings.py check` still passes with the intended key set, commit it as is.
- Every commit message ends with the Co-Authored-By trailer the implementer’s own harness attribution gives.

**Commands** (repo root):

```bash
DEST='platform=iOS Simulator,name=iPhone 17'
xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST" -parallel-testing-enabled NO -only-testing:"RAID CalcUITests/RaidCalculator2UITests/testFailuresToleratedFitsOneLine"
```

- **Always pass `-parallel-testing-enabled NO`.**
- **Builds:** run one at a time, in the background with a long timeout, and read the log for `** TEST SUCCEEDED **` or `FAILED`.

## Review Focus

Each has its test in the task that owns the code.

1. **Conditional fault tolerance on the RAID tab** (RAID 10, 8 drives: “Up to 4 (depends on which drives fail)”) falls back to the stacked row and shows the whole phrase. Test: `testFailuresToleratedFitsOneLine` checks both forms (Task 1).
2. **A drive size typed as 0, or erased,** shows “Enter a drive size.” rather than the last result as if it were current. Done restores the last size. Test: `testEmptyDriveSizeShowsPrompt` (Task 2).
3. **The custom-size alert with an empty or zero field** can’t be confirmed, and a valid entry still applies. Test: `testCustomSizeNeedsANumber` (Task 2).
4. **The trademark line still appears in every system’s sheet** after the footer moves out of its empty section. Test: the existing `testNASInfoSheetHasTrademarkLine`, plus `testRaidZInfoSheetKeepsTrademarkLine` (Task 4).
5. **The website** has no leftover claims that 1.6.0 lacks something it now has (RAID 50/60, ZFS, Unraid), no DiskStation model names, and no broken image paths. Test: the grep and link checks in Task 6, Step 6.

## File map

| File | Change | Responsibility |
|---|---|---|
| `RaidCalculator2/ContentView.swift` | modify | `FailuresToleratedRow`; `CapacitySummary` uses it and gets an “Enter a drive size” state; `DriveSizeField` reports when it’s empty |
| `RaidCalculator2/NASView.swift` | modify | `NASSummary` uses `FailuresToleratedRow`; the custom-size alert edits text |
| `RaidCalculator2/InfoSheet.swift` | modify | The trademark footnote joins the last section instead of an empty one |
| `RaidCalculator2/Localizable.xcstrings` | modify | `enter_drive_size`, plus the polish change set |
| `RaidCalculator2UITests/RaidCalculator2UITests.swift` | modify | Row, prompt, alert and sheet tests |
| `www/index.html` | modify | NAS-tab copy, FAQ, metadata, footer trademarks, new screenshot references |
| `www/assets/*.webp` | add/replace | New screenshots |
| `marketing/screenshots/1.6.0/*.png` | add | Full-size App Store screenshots |
| `marketing/app-store-listing.md` | modify, **not committed** | Version 1.6.0 section |
| `prd.md`, `prd-update.md`, `PRODUCT.md` | modify | Merge the spec delta for release |

## Execution order and models

| Task | Model | Depends on |
|---|---|---|
| 1. One-line “Drive failures tolerated” (FR-18) | sonnet | none |
| 2. FR-19 leftovers: empty drive size, custom-size alert | sonnet | none |
| 3. Draft the copy polish change set (no build) | opus | none (parallel from the start) |
| 4. Apply the copy polish, and close the info-sheet footer gap | sonnet | 3 |
| 5. Website copy | opus | none |
| 6. Screenshots, and wire them into the site | sonnet | 1, 2, 4, 5 |
| 7. App Store listing and PRD merge | opus | 5 |
| 8. Full verification | sonnet | all |

Tasks run 1 → 2 → 4 → 5 → 6 → 7 → 8. Task 3 runs in parallel from the start. Reviews use sonnet, except opus for Tasks 3, 5 and 7 and the final whole-branch review.

---

### Task 1: One-line “Drive failures tolerated” (FR-18)

**Files:**
- Modify: `RaidCalculator2/ContentView.swift` (add `FailuresToleratedRow` after `CapacitySummary`; replace the `Label` at lines 315–327 today)
- Modify: `RaidCalculator2/NASView.swift` (`NASSummary`’s `Label`, lines 310–323 today)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Produces: `FailuresToleratedRow(value: String)`, with accessibility identifier `failuresTolerated`.

- [ ] **Step 1: Write the failing UI test.**

```swift
    /// FR-18: label and value share a line when they fit; the conditional
    /// value falls back to the stacked form, never shortened.
    @MainActor
    func testFailuresToleratedFitsOneLine() throws {
        let app = launchApp()  // RAID 5, 4 × 4 TB
        let row = app.descendants(matching: .any).matching(identifier: "failuresTolerated").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.label, "Drive Failures Tolerated, 1")
        XCTAssertLessThan(row.frame.height, 34, "one line")
        app.terminate()

        let raid10 = launchApp(level: "R 10", drives: 8)
        let conditional = raid10.descendants(matching: .any).matching(identifier: "failuresTolerated").firstMatch
        XCTAssertTrue(conditional.waitForExistence(timeout: 5))
        XCTAssertTrue(conditional.label.contains("Up to 4"), conditional.label)
        XCTAssertTrue(conditional.label.contains("depends on which drives fail"), conditional.label)
        XCTAssertGreaterThan(conditional.frame.height, 34, "stacked")
    }
```

  Check `"R 10"` against `RaidLevel`’s raw value in `Models.swift`, and the exact conditional wording against the catalog. Adjust the test’s literals only, never the copy.

- [ ] **Step 2: Run it and watch it fail.** Expected: no element with identifier `failuresTolerated`. Record it.

- [ ] **Step 3: Implement.** Add to `ContentView.swift`:

```swift
/// “Drive Failures Tolerated … 1” on one line when it fits; otherwise the
/// label above the value, as before. The value is never shortened to make
/// it fit (FR-18), so conditional wording and large text sizes stack.
struct FailuresToleratedRow: View {
    let value: String

    var body: some View {
        Label {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    title.lineLimit(1)
                    Spacer(minLength: 0)
                    valueText.lineLimit(1)
                }
                VStack(alignment: .leading, spacing: 2) {
                    title
                    valueText
                }
            }
        } icon: {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("failuresTolerated")
    }

    private var title: some View {
        Text("drive_failures_tolerated".localized())
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var valueText: some View {
        Text(value)
            .font(.body.weight(.semibold))
            .contentTransition(.numericText())
    }
}
```

  Then make two replacements:
  - In `CapacitySummary`, replace the `Label { VStack { … } } icon: { … }.accessibilityElement(children: .combine)` block with `FailuresToleratedRow(value: result.failuresTolerated)`.
  - In `NASSummary`, inside `if isValid { … }`, replace the same shape with `FailuresToleratedRow(value: result.failuresTolerated.formatted())`.

- [ ] **Step 4: Run the tests.** Run the new test, then the full UI target. The VoiceOver text is unchanged: “Drive Failures Tolerated, 1”.

- [ ] **Step 5: Screenshot check.** Capture the iPhone 17 at default size in English and Japanese (RAID 5, then RAID 10 with 8 drives), plus AX XXXL in French (RAID 5), using `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`. Also capture the NAS tab in English. Save to `/tmp/p4-t1-*.png`.
  - **Expected:**
    - RAID 5 and the NAS tab show one line.
    - RAID 10 is stacked and shows the full wording.
    - AX XXXL is stacked.
    - Japanese short values are one line.

- [ ] **Step 6: Commit.**

```bash
git add RaidCalculator2/ContentView.swift RaidCalculator2/NASView.swift RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Put drive failures tolerated on one line when it fits"
```

---

### Task 2: FR-19 leftovers: empty drive size, custom-size alert

**Files:**
- Modify: `RaidCalculator2/ContentView.swift` (`DriveSizeField`, `CapacitySummary`, and `ContentView`’s state and call sites)
- Modify: `RaidCalculator2/NASView.swift` (custom-size state, the alert, and `bayRow`’s Custom Size button)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`

**Interfaces:**
- Produces:
  - `DriveSizeField(value:focus:isAwaitingValue:)`
  - `CapacitySummary(result:unit:awaitingSize:)`, where `awaitingSize` defaults to `false`
  - Accessibility identifier `enterDriveSize`

- [ ] **Step 1: Add the string.** Run `python3 scripts/strings.py add /tmp/p4-t2-strings.json`, then `check`. The Spanish matches the RAID tab’s “Tamaño de Unidad”.

```json
{
  "enter_drive_size": {
    "en": "Enter a drive size.",
    "es": "Introduce un tamaño de unidad.",
    "fr": "Saisissez une taille de disque.",
    "it": "Inserisci la dimensione del disco.",
    "ja": "ドライブサイズを入力してください。"
  }
}
```

- [ ] **Step 2: Write the failing UI tests.**

```swift
    /// FR-19: while the size field is empty (or 0) the card asks for a size
    /// instead of showing the last result as current; Done restores the size.
    @MainActor
    func testEmptyDriveSizeShowsPrompt() throws {
        let app = launchApp()
        let field = app.textFields["driveSizeField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        let prompt = app.descendants(matching: .any).matching(identifier: "enterDriveSize").firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 2))
        field.typeText("0")
        XCTAssertTrue(prompt.exists, "0 isn't a drive size")
        app.toolbars.buttons["Done"].tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: prompt)
        wait(for: [gone], timeout: 2)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 12 TB,"), capacity(app))
    }

    /// FR-19: the custom-size alert can't be confirmed empty.
    @MainActor
    func testCustomSizeNeedsANumber() throws {
        let app = launchNAS()
        let bay1 = app.buttons["bay1"]
        reveal(bay1, in: app)
        bay1.tap()
        app.buttons["Custom Size…"].tap()
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6))
        let done = app.alerts.buttons["Done"]
        XCTAssertFalse(done.isEnabled, "empty")
        field.typeText("5")
        XCTAssertTrue(done.isEnabled)
        done.tap()
        XCTAssertTrue(bay1.label.contains(tb(5)), bay1.label)
    }
```

  If `bay1`’s label doesn’t carry the size, assert it the way the existing bay tests do. `capacity`, `tb` and `reveal` are the file’s helpers.

- [ ] **Step 3: Run them and watch them fail.**
  - Expected: `enterDriveSize` never appears.
  - For the alert, Done is enabled while empty. If the field starts with a value, `isEnabled` is still true after deleting.
  - Record both.

- [ ] **Step 4: Implement the drive-size prompt.**
  - In `DriveSizeField`, add `@Binding var isAwaitingValue: Bool`.
  - Replace its `onChange(of: text)` and its focus handler:

```swift
            .onChange(of: text) {
                // Parsing follows the current locale, so “12,5” works in Spanish, French and Italian.
                if let parsed = try? Self.format.parseStrategy.parse(text), parsed > 0 {
                    value = parsed
                    isAwaitingValue = false
                } else {
                    isAwaitingValue = true
                }
            }
```

```swift
            .onChange(of: focus.wrappedValue) { _, focused in
                if focused {
                    // Runs after the tap has placed the cursor, so this placement wins.
                    Task { @MainActor in selection = TextSelection(insertionPoint: text.endIndex) }
                } else {
                    text = value.formatted(Self.format)
                    isAwaitingValue = false
                }
            }
```

  - Update the type’s doc comment: an empty, zero or unparseable field now tells the card it is waiting for a size, and still restores the last value when editing ends.
  - In `ContentView`, add `@State private var awaitingDriveSize = false`. Pass `isAwaitingValue: $awaitingDriveSize` to `DriveSizeField`, and `awaitingSize: awaitingDriveSize` to `CapacitySummary`.
  - In `CapacitySummary`:
    - Add `var awaitingSize = false`.
    - Change `isValid` to `result.warningMessage == nil && !awaitingSize`.
    - Rename today’s `body` content to `private var content: some View`, keeping everything except the final `.padding`, `.opacity` and `.animation`.
    - Add the new `body`:

```swift
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if awaitingSize {
                Label("enter_drive_size".localized(), systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier("enterDriveSize")
            }
            content
                .opacity(isValid ? 1 : 0.4)
                .animation(.default, value: isValid)
        }
        .padding(.vertical, 6)
    }
```

  The `.success` haptic stays keyed on `result.warningMessage`. An empty field isn’t an invalid configuration.

- [ ] **Step 5: Implement the custom-size alert.**
  - In `NASView`, replace `@State private var customSize: Double = 8` with:

```swift
    @State private var customSizeText = ""

    /// The custom size, if what's typed is a size; locale-aware, so “2,5” works.
    private var parsedCustomSize: Double? {
        guard let value = try? FloatingPointFormatStyle<Double>.number.parseStrategy.parse(customSizeText), value > 0 else { return nil }
        return value
    }
```

  - In `bayRow`, the Custom Size button sets `customSizeText = (size ?? 8).formatted(.number.precision(.fractionLength(0...1)))` before `customSizeBay = index`.
  - Replace the alert’s content:

```swift
        {
            TextField("TB", text: $customSizeText)
                .keyboardType(.decimalPad)
            Button("cancel".localized(), role: .cancel) {}
            Button("done".localized()) {
                if let bay = customSizeBay, let size = parsedCustomSize {
                    withAnimation(motion) { viewModel.setSize(size, forBay: bay) }
                }
            }
            .disabled(parsedCustomSize == nil)
        }
```

  If the UI test shows `.disabled` has no effect inside an alert on iOS 26, report BLOCKED with the test output. Don’t invent a workaround. The alternatives (a sheet instead of an alert) change the UI and are the controller’s call.

- [ ] **Step 6: Run the tests.** Run both new tests, then every `testDriveSize…` test, `testEmptyDriveSizeRestoredOnDone`, `testDriveSizeAcceptsDecimalCommaInSpanish`, and the full UI target.

- [ ] **Step 7: Commit.**

```bash
git add RaidCalculator2/ContentView.swift RaidCalculator2/NASView.swift RaidCalculator2/Localizable.xcstrings RaidCalculator2UITests/RaidCalculator2UITests.swift
git commit -m "Ask for a drive size while the field is empty, and require one in the custom-size alert"
```

---

### Task 3: Draft the copy polish change set (no build)

**Files:**
- Create (outside the repo): `/tmp/p4-copy/remove.txt`, `/tmp/p4-copy/add.json` and `/tmp/p4-copy/rationale.md`

**Model:** opus, with translator judgment. **No build, no catalog edits:** this task only writes the three files above, and Task 4 applies them.

**Inputs:**
- Read the catalog with Python, never by hand-editing it: `python3 -c "import json; d=json.load(open('RaidCalculator2/Localizable.xcstrings'))['strings']; …"`.
- Read neighboring keys to match each language’s tone.

**Items** (from the plan 1 and plan 2 parking lots). Each is a judgment, not a mandated rewrite. Change a string only when the change is clearly better, and say why in the rationale.

1. **Japanese:**
   - The write-hole term (find the key whose ja value has 「ライトホール」 or similar; decide whether 「書き込みホール」 or 「ライトホール問題」 reads better to a Japanese NAS user)
   - The phrasing rendered as “doesn’t overwrite in place” (「その場で上書きしない」)
   - “faster than RAID 5” (「RAID 5より高い速度」)
   - “nested RAID levels” (「ネスト構成のRAIDレベル」)

   The exact ja text may differ from these glosses. Find the keys by meaning.
2. **Spanish:** “sobrescribe los datos existentes”. Find the key and check the phrasing.
3. **Italian:** “Lo spazio utilizzabile più ampio”. Find the key and check it reads naturally.
4. **French typography, catalog-wide:**
   - Before `:`, use a no-break space U+00A0.
   - Before `;`, `!` and `?`, use a narrow no-break space U+202F.
   - Inside « » (if any), use U+00A0.

   Today 17 fr values have a plain space before one of these. Change every affected fr value and no other language.
5. **`groups_uneven`:** “%1$d drives don’t divide evenly into %2$d groups.” reads “1 drives” when the count is 1. Rephrase so it’s correct for any count without plural variations, which `strings.py` doesn’t support. Do this in all five languages, keeping `%1$d` and `%2$d`. For example: “Can’t split %1$d drives evenly…” still fails, but “These drives don’t divide evenly into %2$d groups (%1$d in all).” works. Pick the most natural option per language.
6. **Japanese counters:** list every ja value that counts drives. On NAS-screen keys, drives use 台. On RAID-tab keys, keep whichever counter the key’s RAID-tab neighbors use. Change only the inconsistent ones.
7. **The remaining plan-2 nits:** es/it phrasing in the NAS sheets (`*_description`, `*_pros`, `*_cons`, `*_use_cases`, `*_calculation` for synology, unraid, zfs, snapraid and btrfs). Fix only clear errors or awkwardness.

**Rules:**
- Never change English meaning, except item 5.
- Never change a positional specifier.
- Keep curly punctuation.
- System names stay untranslated.
- Every key you touch gets all five languages in `add.json`, unchanged languages copied verbatim from the catalog. To change a value, `strings.py` needs `remove` then `add`.

**Outputs:**
- `remove.txt`: one key per line.
- `add.json`: exactly the shape `scripts/strings.py add` accepts. Read its usage first.
- `rationale.md`: a table with key, language, before, after and why, plus a list of items you looked at and deliberately left alone.

Report the counts: keys changed, per item.

---

### Task 4: Apply the copy polish, and close the info-sheet footer gap

**Files:**
- Modify: `RaidCalculator2/Localizable.xcstrings`, via `strings.py` only
- Modify: `RaidCalculator2/InfoSheet.swift` (the footnote section, lines 82–89 today)
- Test: `RaidCalculator2UITests/RaidCalculator2UITests.swift`, `RaidCalculator2Tests/InfoSheetCopyTests.swift`

- [ ] **Step 1: Apply the change set.**
  - Run `xargs python3 scripts/strings.py remove < /tmp/p4-copy/remove.txt`, then `python3 scripts/strings.py add /tmp/p4-copy/add.json`, then `python3 scripts/strings.py check`. Expected: `0 problem(s)`.
  - Then run `git diff --stat RaidCalculator2/Localizable.xcstrings`. The changed keys should match `remove.txt`.
- [ ] **Step 2: Fix any test that asserted old copy.** Run `"RAID CalcTests"` and fix any `InfoSheetCopyTests` assertion that pinned changed text, using the new text. Don’t change copy to satisfy a test.
- [ ] **Step 3: Write the failing UI test for the footer.** The trademark line must sit under the last section, not in an empty section of its own.

```swift
    /// The trademark line closes the sheet's last section rather than an
    /// empty one of its own (plan 2's footer gap).
    @MainActor
    func testRaidZInfoSheetKeepsTrademarkLine() throws {
        let app = launchApp(level: "Z2", drives: 6)
        app.buttons["raidInfo"].tap()
        let footnote = app.descendants(matching: .any).matching(identifier: "infoFootnote").firstMatch
        reveal(footnote, in: app)
        XCTAssertTrue(footnote.label.contains("Oracle"), footnote.label)
        let ratingsNote = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Ratings compare")).firstMatch
        if ratingsNote.exists {
            XCTAssertLessThan(footnote.frame.minY - ratingsNote.frame.maxY, 24, "no empty section between them")
        }
    }
```

  Check the start of `ratings_footnote`’s English text in the catalog and use it in the predicate.

- [ ] **Step 4: Run it and watch it fail** on the gap assertion. Record the measured distance. If it already passes, the gap is cosmetic at this size. Still do Step 5, and report the before and after distances.
- [ ] **Step 5: Implement.** In `InfoSheet`:
  - Add `private var footnote: String? { topic.footnoteKey.flatMap { optionalKey($0) } }`.
  - Delete the standalone `if let footnote … Section {} footer:` block.
  - The ratings section’s footer becomes:

```swift
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ratings_footnote".localized())
                            if let footnote { footnoteText(footnote) }
                        }
                    }
```

  - The “How the app calculates this” section gains a footer that shows the footnote only when there are no ratings:

```swift
                if let calculation = optionalText("calculation") {
                    Section {
                        Text(calculation)
                            .accessibilityIdentifier("howCalculated")
                    } header: {
                        Text("how_calculated".localized())
                    } footer: {
                        if topic.ratings == nil, let footnote { footnoteText(footnote) }
                    }
                }
```

  - When a topic has neither ratings nor a calculation section, keep the old standalone footer section as the fallback:

```swift
                if topic.ratings == nil, optionalText("calculation") == nil, let footnote {
                    Section {
                    } footer: {
                        footnoteText(footnote)
                    }
                }
```

  - Add:

```swift
    private func footnoteText(_ text: String) -> some View {
        Text(text)
            .accessibilityIdentifier("infoFootnote")
    }
```

- [ ] **Step 6: Run the tests.** Run `testRaidZInfoSheetKeepsTrademarkLine`, `testNASInfoSheetHasTrademarkLine`, `testRaid5InfoSheetHasNoEstimateSection`, `testRaidZInfoSheetExplainsEstimate`, `testInfoSheetPresentation`, then both full targets.
- [ ] **Step 7: Screenshot check.** Capture:
  - the Unraid sheet in English
  - the RAID-Z2 sheet in French, scrolled to the bottom
  - one changed Japanese string in context

  Save to `/tmp/p4-t4-*.png`.
- [ ] **Step 8: Commit.**

```bash
git add RaidCalculator2/Localizable.xcstrings RaidCalculator2/InfoSheet.swift RaidCalculator2UITests/RaidCalculator2UITests.swift RaidCalculator2Tests/InfoSheetCopyTests.swift
git commit -m "Polish translations, fix French spacing, and close the info sheet's footer gap"
```

---

### Task 5: Website copy

**Files:**
- Modify: `www/index.html`

Use exact replacements. Leave each `<img>` element’s `src` alone: Task 6 swaps the images. Leave structure and CSS alone, except the one new feature item and the one new FAQ item below. Each “Before” is quoted from today’s file.

- [ ] **Step 1: Metadata.**
  - **`<meta name="description">` and the hero `<p class="hero-sub">`** both become:
    > RAID Calculator for iPhone and iPad shows your usable capacity, how many drives can fail, and which drive to buy next, whether your NAS runs Synology, Unraid, ZFS, SnapRAID or Btrfs.
  - **`og:description` and `twitter:description`** both become:
    > Usable capacity, fault tolerance and the one drive worth buying next. RAID 0 to 60, ZFS RAID-Z, Synology SHR, Unraid, SnapRAID and Btrfs RAID1, for iPhone and iPad.
  - **The JSON-LD `"description"`** becomes:
    > Shows usable capacity, how many drives can fail, and which drive to buy next. RAID 0, 1, 5, 6, 10, 50, 60, JBOD and RAID-Z on identical drives; Synology SHR and SHR-2, Unraid, ZFS, SnapRAID and Btrfs RAID1 with mixed drives.
- [ ] **Step 2: The mixed-drives section** (`.synology`; keep the class name).
  - **The first feature’s `<span>`** becomes:
    > Set each bay’s drive size or leave it empty. Every drive is drawn to scale and split into what it actually holds: data, parity, a mirror copy, or nothing at all.
  - **Insert a new feature `<div>`** after it, before “Wasted space, made visible”:

    ```html
    <div><strong>Five systems, the same drives</strong><span class="muted">Switch between Synology, Unraid, ZFS, SnapRAID and Btrfs RAID1 and watch the same bays re-split. Compare Systems lines them all up, most usable space first.</span></div>
    ```

  - **The `<figcaption>`** becomes:
    > 16, 8, 8 and 4&nbsp;TB drives in SHR on iPad, with every system compared beside them.
  - **The `.models` paragraph** becomes:
    > Pick a bay count from 2 to 12 for Synology, or up to 30 for Unraid, ZFS, SnapRAID and Btrfs RAID1. SHR and SHR-2 sit alongside Synology’s RAID 1, 5 and 6. Unraid and SnapRAID put parity on your largest drives automatically, and ZFS shows the figure it will report, labeled as an estimate.
- [ ] **Step 3: The RAID section.**
  - **The `<h2>`** becomes:
    > RAID 0 to 60, RAID-Z and JBOD. The answer first, the reasoning right under it.
  - **Append to the `.lede`:**
    > Nested levels and RAID-Z show their groups, and RAID-Z adds what ZFS itself will report.
  - **The third card’s last sentence** (“Each level also has an info sheet…”) becomes:
    > Every level and every NAS system has an info sheet: overview, pros, cons, typical uses and how the app calculates it.
- [ ] **Step 4: The iOS section.** The “On iPad” paragraph becomes:
  > Results beside inputs, every system compared at a glance, and up to 30 bays on screen at once. It adapts to split view too.
- [ ] **Step 5: FAQ.**
  - **Insert after “What is SHR?”:**

    ```html
    <div>
      <h3>Which systems does it cover?</h3>
      <p>On identical drives: RAID 0, 1, 5, 6, 10, 50 and 60, JBOD, and ZFS RAID-Z1, Z2 and Z3. With mixed drives, bay by bay: Synology SHR and SHR-2, Unraid, ZFS, SnapRAID and Btrfs RAID1.</p>
    </div>
    ```

  - **“Why does my NAS show less than I expected?”** Append:
    > For ZFS it also estimates what ZFS itself will report after padding and reserved space, and labels it an estimate.
  - **“What doesn’t it cover?”** becomes:
    > Synology expansion units, SSD cache, and Unraid’s separate cache and ZFS pools aren’t covered. It doesn’t estimate cost, power or IOPS, and it never touches your actual disks.
  - **“Are the speed ratings benchmarks?”** Append:
    > NAS systems get no stars at all, since their speed depends on how each one is set up.
- [ ] **Step 6: The footer.** Replace the single Synology `<span class="quiet">` with three spans, one per line, in the Global Constraints wording and order.
- [ ] **Step 7: Check.**
  - `grep -nE "DS[0-9]{3}|DiskStation|Model presets|aren’t supported" www/index.html`. The only hits allowed are in `alt` text, which Task 6 replaces. List them in the report.
  - `grep -nE " — |--" www/index.html` must find no spaced em dashes in visible copy.
  - Open the page with `python3 -m http.server -d www 8765` in the background, plus Playwright or a browser screenshot at 390 and 1280 wide. Confirm the new feature and FAQ items lay out in the existing grid. Save to `/tmp/p4-t5-*.png`.
- [ ] **Step 8: Commit.**

```bash
git add www/index.html
git commit -m "Update the website for the NAS tab, every system, and their trademarks"
```

---

### Task 6: Screenshots, and wire them into the site

**Files:**
- Add or replace: `www/assets/*.webp` (names below)
- Add: `marketing/screenshots/1.6.0/*.png`
- Modify: `www/index.html` (`src`, `width`, `height` and `alt` only), `www/assets` cleanup

**Setup:**
- **Build:** `xcodebuild build -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" -destination "$DEST"`, then install the app on each Simulator with `xcrun simctl install booted <path to RAID Calc.app>`. Find the path in `-showBuildSettings`, as `TARGET_BUILD_DIR`.
- **Status bar,** on every Simulator: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`.
- **Launch:** `xcrun simctl launch booted <bundle id> <args>`. Wait 3 seconds, then `xcrun simctl io booted screenshot <file>.png`.
- **Appearance:** `xcrun simctl ui booted appearance light|dark`.
- **NAS launches** use the hex encoding the UI tests use: `python3 -c "print('<'+'[16,8,8,4]'.encode().hex()+'>')"`. Pass `-nas.settings "" -nas.currentSetup ""` for a clean comparison state.

- [ ] **Step 1: Capture.** Save full-size PNGs to `marketing/screenshots/1.6.0/`.

| File | Device | Appearance, language | Launch arguments |
|---|---|---|---|
| `01-iphone-nas-shr.png` | iPhone 17 | light, en | `-selectedTab nas -nas.system synology -nas.bayCount 4 -synology.bays <[16,8,8,4]>` |
| `02-iphone-nas-compare.png` | iPhone 17 | light, en | as 01, then open Compare Systems (tap with `xcrun simctl` isn’t possible, so use a one-off XCUITest or the `mcp__cmux-cua` tools to tap `compareSystems`) |
| `03-iphone-raid-raid6.png` | iPhone 17 | light, en | `-selectedTab raid -selectedLevel "R 6" -driveCount 6 -driveSize 16 -groups 1 -unit TB` |
| `04-iphone-raid-raid5-caution.png` | iPhone 17 | light, en | `-selectedLevel "R 5" -driveCount 8 -driveSize 20` |
| `05-iphone-raid-invalid-fix.png` | iPhone 17 | light, en | `-selectedLevel "R 10" -driveCount 5 -driveSize 4` |
| `06-iphone-nas-ja.png` | iPhone 17 | light, ja | as 01 plus `-AppleLanguages "(ja)" -AppleLocale ja_JP` |
| `07-iphone-nas-dark.png` | iPhone 17 | dark, en | `-nas.system unraid -nas.bayCount 8 -synology.bays <[20,16,12,8,8,4,null,null]>` |
| `08-iphone-raid-raid10-dark.png` | iPhone 17 | dark, en | `-selectedLevel "R 10" -driveCount 8 -driveSize 12` |
| `09-ipad-nas-compare.png` | iPad Pro 13-inch (M5), portrait | light, en | as 01 |
| `11-ipad-nas-dark.png` | iPad Pro 13-inch (M5), portrait | dark, en | `-nas.system zfs -nas.bayCount 12 -synology.bays <[16,16,16,16,12,12,12,12,8,8,8,8]>` |

  **Capture every row in both light and dark** (the user wants both kept for the website rebuild): save as `<name>.png` and `<name>-dark.png`, or `<name>-light.png` for the rows marked dark. Start from plan 3’s sweep in `marketing/screenshots/1.6.0/sweep/` where a capture already matches a row.

  Check each against these expectations, and recapture if a shot is wrong:
  - 01 shows the 16 TB drive’s top hatched.
  - 02 shows five systems.
  - 07 shows parity on the 20 TB.
  - 09 and 11 are two columns.

- [ ] **Step 2: Convert for the web**, at the existing dimensions. Write into `www/assets/` with the same base names.
  - **iPhone:** `magick in.png -resize 640x1391! /tmp/x.png && cwebp -q 82 /tmp/x.png -o www/assets/<name>.webp`.
  - **iPad:** `magick in.png -resize 1400x -crop 1400x1234+0+0 +repage /tmp/x.png && cwebp -q 82 …`, cropped to the top, as the old `*-top` images were.
  - **Skip** `01-iphone-nas-shr` for the web. It’s for the App Store set only.
- [ ] **Step 3: Wire them in.**
  - **Hero:** the second phone becomes `02-iphone-nas-compare.webp`.
  - **Mixed-drives figure:** `09-ipad-nas-compare.webp`.
  - **iOS section:** `11-ipad-nas-dark.webp`, `07-iphone-nas-dark.webp` and `06-iphone-nas-ja.webp`.
  - **JSON-LD `screenshot` array:** update the iPad entry.
  - **Alt text:** rewrite every replaced image’s `alt` to describe what the new capture actually shows: real numbers, no DiskStation models, curly punctuation. For example: “The NAS tab on iPad: 16, 8, 8 and 4 TB drives in SHR, 20 TB usable, with Synology, Unraid, SnapRAID, Btrfs RAID1 and ZFS compared beside it”.
  - **RAID-tab images** (03, 04, 05, 08): replace the files in place under the same names, and update their `alt` text only if the numbers changed.
- [ ] **Step 4: Remove the orphans.** `git rm` the old `02-iphone-synology-8bay.webp`, `06-iphone-synology-ja.webp`, `07-iphone-synology-dark.webp`, `09-ipad-synology-upgrade-top.webp` and `11-ipad-synology-dark-top.webp`, after `grep -rn "<name>" www/` shows no references.
- [ ] **Step 5: Look at it.** Serve `www/`, then screenshot the page at 390 and 1280 wide, in light mode and with the dark sections in view. Save to `/tmp/p4-t6-*.png`, and check that the hero fan and phone frames still crop correctly.
- [ ] **Step 6: Link and claim check.**
  - `grep -o 'assets/[^"]*' www/index.html | sort -u | while read f; do test -f "www/$f" || echo "missing $f"; done` prints nothing.
  - `grep -nE "DS[0-9]{3}|DiskStation|Model presets" www/index.html` prints nothing.
- [ ] **Step 7: Commit** (the PNGs too; they’re the App Store set):

```bash
git add www/ marketing/screenshots/1.6.0/
git commit -m "Refresh the screenshots for the NAS tab and the iPad layout"
```

---

### Task 7: App Store listing and PRD merge

**Files:**
- Modify, **not committed:** `marketing/app-store-listing.md`
- Modify: `prd.md`, `prd-update.md`, `PRODUCT.md`

- [ ] **Step 1: App Store listing.** Read the whole file first. It documents 1.4.0 and explains its trademark choices. Add a `## Version 1.6.0` section above `## Version 1.4.0`, matching that section’s shape:
  - **Promotional text** (170 characters).
  - **Description** (4000). This covers both tabs, the five NAS systems, compare systems and iPad, and ends with the three trademark lines from Global Constraints, each a quoted line like today’s.
  - **What’s New** (since 1.4.x, all of 1.5.0 and 1.6.0):
    - RAID 50/60 and RAID-Z
    - the NAS tab and its systems
    - compare systems
    - iPad layouts
    - the drive-size fixes
  - **Keywords** (100). Keep the existing policy: no third-party trademarks in keywords. So no “Synology”, “Unraid” or “ZFS”, and say so in the note.
  - **The App Review note**, rewritten for the NAS tab. Third-party names are used only to describe compatibility, and the not-affiliated lines sit in each system’s info sheet (not at the bottom of a tab). There is still no data collection and no network.
  - **The Screenshots list,** pointing at `marketing/screenshots/1.6.0/`.

  Show character counts the way the file does. Smart punctuation, no spaced em dashes.
- [ ] **Step 2: PRD merge.** The spec’s header says “the two get merged when this ships”.
  - Fold `prd-update.md`’s functional and non-functional requirements and its testing table into `prd.md`, in `prd.md`’s own structure. The new levels go into its RAID requirements, the NAS tab replaces its Synology requirements, and FR numbers are kept where they already exist.
  - Mark resolved decisions as decisions, not open questions.
  - Replace `prd-update.md`’s contents with one line: “Merged into `prd.md` for 1.6.0 on <date>.”
  - Update `PRODUCT.md`’s release line, if it has one, to 1.6.0.
  - Don’t drop any decided detail: limits, rulings, the ZFS formula, trademark placement.
- [ ] **Step 3: Commit** (the PRD files only):

```bash
git add prd.md prd-update.md PRODUCT.md
git commit -m "Merge the 1.5 and 1.6 spec into the PRD"
```

  Report the listing’s character counts. Say that the listing file is edited but deliberately not committed.

---

### Task 8: Full verification

- [ ] **Step 1:** Run `python3 scripts/strings.py check`. Expected: `0 problem(s)`.
- [ ] **Step 2:** Run the full suite on the iPhone 17, serially. Expected: `** TEST SUCCEEDED **`. Apply plan 3’s Task 8 rule for single-test environment stalls.
- [ ] **Step 3:** Run every `testIPad…` test on the iPad Pro 13-inch (M5). Expected: they pass.
- [ ] **Step 4:** Take screenshots of the iPhone 17 at AX XXXL in Japanese and in French, on both tabs, including the one-line row and the “Enter a drive size” prompt. Check for clipping, mid-word breaks and raw placeholders. Report the paths.
- [ ] **Step 5:** Re-run Task 6’s link and claim checks on `www/index.html`.
- [ ] **Step 6: Report.** Don’t tag, push, merge or release. Name what remains for the user:
  - the `v1.6.0` tag (App Store)
  - App Store Connect metadata and screenshots, from the listing file and `marketing/screenshots/1.6.0/`
  - the `www-v*` tag once the app is live
