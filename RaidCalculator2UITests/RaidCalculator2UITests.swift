//
//  RaidCalculator2UITests.swift
//  RaidCalculator2UITests
//
//  Created by todd.greco on 11/22/25.
//

import XCTest

final class RaidCalculator2UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The iPad tests turn the device; put it back so the next test starts upright.
    override func tearDownWithError() throws {
        MainActor.assumeIsolated { XCUIDevice.shared.orientation = .portrait }
    }

    /// Launches with a known configuration. Launch arguments override the
    /// persisted UserDefaults, so each test starts from RAID 5, 4 × 4 TB.
    @MainActor
    private func launchApp(level: String = "R 5", drives: Int = 4, groups: Int = 1, language: String = "en", locale: String = "en_US", contentSize: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-selectedLevel", level,
            "-driveCount", "\(drives)",
            "-driveSize", "4",
            "-groups", "\(groups)",
            "-unit", "TB",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        app.launch()
        return app
    }

    /// Opens the NAS tab with known drives. An empty current setup means
    /// “nothing saved yet”: the app takes the launch setup (whatever the
    /// system) as current, so no comparison row appears until something changes.
    @MainActor
    private func launchNAS(system: String = "synology", bays: String = "[4,4,8,8]", bayCount: Int = 4) -> XCUIApplication {
        let hex = bays.data(using: .utf8)!.map { String(format: "%02x", $0) }.joined()
        let app = XCUIApplication()
        app.launchArguments += [
            "-selectedTab", "nas",
            "-nas.system", system,
            "-nas.bayCount", "\(bayCount)",
            "-synology.bays", "<\(hex)>",
            "-nas.settings", "",
            "-nas.currentSetup", "",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launch()
        return app
    }

    /// At the largest text size a rating row still reads as one phrase and
    /// stacks title, stars and word, one line each. Squeezed beside the title,
    /// the old row wrapped its word and measured about 410 pt; stacked is about 220.
    @MainActor
    func testRatingRowStacksAtAccessibilitySize() throws {
        func speedRow(_ app: XCUIApplication) -> XCUIElement {
            let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Speed, '")).firstMatch
            reveal(row, in: app)
            return row
        }
        let normal = speedRow(launchApp())
        let normalHeight = normal.frame.height
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        let row = speedRow(app)
        XCTAssertTrue(row.label.hasPrefix("Speed, 3 of 5, "), row.label)
        XCTAssertGreaterThan(row.frame.height, normalHeight * 3, "title, stars and word are all at the large size")
        XCTAssertLessThan(row.frame.height, 300, "stacked rows don't wrap inside a squeezed column")
    }

    /// The combined VoiceOver element for the answer, which reads
    /// “Usable Capacity, 12 TB, of 16 TB raw · 75% efficient”.
    @MainActor
    private func capacity(_ app: XCUIApplication) -> String {
        app.staticTexts.matching(identifier: "usableCapacity").firstMatch.label
    }

    /// The stepper reads “Number of Drives, 5”; the count is the last component.
    @MainActor
    private func driveCount(_ app: XCUIApplication) -> String {
        let label = app.staticTexts.matching(identifier: "driveCount").firstMatch.label
        return label.components(separatedBy: ", ").last ?? label
    }

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

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["RAID Calculator"].waitForExistence(timeout: 5))
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 12 TB,"), capacity(app))
        XCTAssertTrue(app.staticTexts["Number of Drives"].exists)
        XCTAssertTrue(app.staticTexts["Drive Size"].exists)
    }

    @MainActor
    func testRaidLevelSelection() throws {
        let app = launchApp()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))

        let raid1 = picker.buttons.element(boundBy: 1)
        raid1.tap()
        XCTAssertTrue(raid1.isSelected)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 4 TB,"), capacity(app))

        let raid0 = picker.buttons.element(boundBy: 0)
        raid0.tap()
        XCTAssertTrue(raid0.isSelected)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 16 TB,"), capacity(app))
    }

    @MainActor
    func testDriveCountStepper() throws {
        let app = launchApp()
        let stepper = app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))

        stepper.buttons["Increment"].tap()
        XCTAssertEqual(driveCount(app), "5")

        stepper.buttons["Decrement"].tap()
        XCTAssertEqual(driveCount(app), "4")
    }

    @MainActor
    func testDriveSizeInput() throws {
        let app = launchApp()
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.clearAndEnterText(text: "8")
        XCTAssertEqual(sizeField.value as? String, "8")
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 24 TB,"), capacity(app))
    }

    /// A person taps wherever their thumb lands, not the field's right edge.
    /// Wherever the tap lands, deleting and retyping must replace the size.
    @MainActor
    func testDriveSizeReplacedAfterTappingMiddle() throws {
        let app = launchApp()
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue + "8")
        XCTAssertEqual(sizeField.value as? String, "8")
    }

    /// Deleting every digit leaves the field empty instead of restoring the
    /// old size.
    @MainActor
    func testDriveSizeCanBeCleared() throws {
        let app = launchApp()
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue)
        let value = sizeField.value as? String ?? ""
        XCTAssertTrue(value.isEmpty || value == sizeField.placeholderValue, "field still shows “\(value)”")
    }

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
        // The card can sit under the keyboard; the section footer is beside the field.
        let footerPrompt = app.staticTexts["enterDriveSizeFooter"]
        XCTAssertTrue(footerPrompt.waitForExistence(timeout: 2))
        XCTAssertTrue(footerPrompt.isHittable, "the footer prompt shows above the keyboard")
        field.typeText("0")
        XCTAssertTrue(prompt.exists, "0 isn't a drive size")
        app.toolbars.buttons["Done"].tap()
        // The app drops the prompt within milliseconds of Done, but while the
        // keyboard animates away a slow CI simulator can take over a second to
        // answer one accessibility snapshot, and retries it. A 2 s predicate
        // expectation then never sees a single answer (iOS 26.5, CI), so wait
        // the way the other disappearance checks here do.
        XCTAssertTrue(prompt.waitForNonExistence(timeout: 5), "the prompt goes once editing ends")
        XCTAssertFalse(footerPrompt.exists)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 12 TB,"), capacity(app))
    }

    /// A size too small to show at three decimals reads “0” once editing
    /// ends; that's the shown value, not an empty field, so the prompt goes.
    @MainActor
    func testTinyDriveSizeClearsPromptOnDone() throws {
        let app = launchApp()
        let field = app.textFields["driveSizeField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(XCUIKeyboardKey.delete.rawValue + "0.0004")
        app.toolbars.buttons["Done"].tap()
        let prompt = app.descendants(matching: .any).matching(identifier: "enterDriveSize").firstMatch
        // Same budget as testEmptyDriveSizeShowsPrompt, for the same reason.
        XCTAssertTrue(prompt.waitForNonExistence(timeout: 5), "no prompt is left after Done")
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

    /// Leaving the field empty and tapping Done brings the last size back
    /// rather than leaving a blank field beside a stale result.
    @MainActor
    func testEmptyDriveSizeRestoredOnDone() throws {
        let app = launchApp()
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue)
        app.buttons["Done"].tap()
        XCTAssertEqual(sizeField.value as? String, "4")
    }

    /// Spanish, French and Italian type decimals with a comma. If “12,5”
    /// didn't parse, Done would bring back the old 4.
    @MainActor
    func testDriveSizeAcceptsDecimalCommaInSpanish() throws {
        let app = launchApp(language: "es", locale: "es_ES")
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue + "12,5")
        app.buttons["Hecho"].tap()
        XCTAssertEqual(sizeField.value as? String, "12,5")
    }

    /// A decimal survives being typed one keystroke at a time; reformatting
    /// on every keystroke would drop the trailing point of “12.”.
    @MainActor
    func testDriveSizeAcceptsDecimal() throws {
        let app = launchApp()
        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))

        sizeField.clearAndEnterText(text: "12.5")
        XCTAssertEqual(sizeField.value as? String, "12.5")
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 37.5 TB,"), capacity(app))
    }

    @MainActor
    func testInvalidConfigurationOffersFix() throws {
        let app = launchApp(level: "R 10", drives: 5)
        let fix = app.buttons["applySuggestedDriveCount"]
        XCTAssertTrue(fix.waitForExistence(timeout: 5))
        fix.tap()

        XCTAssertEqual(driveCount(app), "6")
        XCTAssertFalse(app.buttons["applySuggestedDriveCount"].exists)
    }

    @MainActor
    func testInfoSheetPresentation() throws {
        let app = launchApp()
        let infoButton = app.buttons["raidInfo"]
        XCTAssertTrue(infoButton.waitForExistence(timeout: 5))
        infoButton.tap()

        XCTAssertTrue(app.navigationBars["RAID 5"].waitForExistence(timeout: 5))

        app.buttons["closeInfo"].tap()
        XCTAssertTrue(app.navigationBars["RAID Calculator"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testUnitSelection() throws {
        let app = launchApp()
        let gbButton = app.buttons["GB"]
        let tbButton = app.buttons["TB"]
        XCTAssertTrue(gbButton.waitForExistence(timeout: 5))

        gbButton.tap()
        XCTAssertTrue(gbButton.isSelected)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 12 GB,"), capacity(app))

        tbButton.tap()
        XCTAssertTrue(tbButton.isSelected)
    }

    /// Nested levels live in the More Levels menu; RAID 60 needs two groups,
    /// and the one-tap fix applies them.
    @MainActor
    func testNestedLevelFromMenu() throws {
        let app = launchApp(drives: 12)
        let menu = app.buttons["moreLevels"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["RAID 60"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["configurationWarning"].waitForExistence(timeout: 5))
        let fix = app.buttons["applySuggestedGroups"]
        XCTAssertTrue(fix.waitForExistence(timeout: 2))
        fix.tap()

        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 32 TB,"), capacity(app))  // 2 groups of 6 × 4 TB, 2 parity each
        XCTAssertEqual(app.staticTexts["groupCount"].label.components(separatedBy: ", ").last, "2")
    }

    /// From the defaults (4 drives, one group), RAID 50 needs more drives and a
    /// second group; its single fix applies both in one tap.
    @MainActor
    func testNestedLevelFixFromDefaults() throws {
        let app = launchApp()
        let menu = app.buttons["moreLevels"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["RAID 50"].tap()

        let fix = app.buttons["applySuggestedDriveCount"]
        XCTAssertTrue(fix.waitForExistence(timeout: 5))
        XCTAssertEqual(fix.label, "Use 6 drives in 2 groups")
        XCTAssertFalse(app.buttons["applySuggestedGroups"].exists)
        fix.tap()

        let warning = app.descendants(matching: .any)["configurationWarning"]
        XCTAssertTrue(warning.waitForNonExistence(timeout: 5))
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 16 TB,"), capacity(app))  // 2 groups of 3 × 4 TB, 1 parity each
        XCTAssertEqual(driveCount(app), "6")
    }

    /// Choosing a standard level again from the segmented control clears the
    /// menu's selection and drops the Groups row.
    @MainActor
    func testStandardLevelHidesGroups() throws {
        let app = launchApp(level: "R 60", drives: 12, groups: 2)
        XCTAssertTrue(app.staticTexts["groupCount"].waitForExistence(timeout: 5))
        app.segmentedControls.firstMatch.buttons.element(boundBy: 2).tap()  // RAID 5
        XCTAssertTrue(app.staticTexts["groupCount"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 44 TB,"), capacity(app))
    }

    /// §1.6: within a grouped level VoiceOver reaches each drive
    /// (“Group 2 of 2, drive 1: Data”); an ungrouped level stays a summary.
    @MainActor
    func testDriveStripReadsEachDrive() throws {
        let app = launchApp(level: "R 60", drives: 12, groups: 2)
        XCTAssertTrue(app.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        let groupTwo = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Group 2 of 2, drive "))
        XCTAssertEqual(groupTwo.count, 6)
        XCTAssertTrue(app.staticTexts["Group 2 of 2, drive 1: Data"].exists || app.staticTexts["Group 2 of 2, drive 1: Parity"].exists)
        app.terminate()

        let raid5 = launchApp()
        XCTAssertTrue(raid5.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(raid5.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", ", drive ")).count, 0)
    }

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
        // The summary is still read, ahead of the groups.
        XCTAssertTrue(app.staticTexts["12 drives in 2 groups: 8 Data, 4 Parity"].exists)

        // An ungrouped level reads the summary alone.
        let ungrouped = launchApp()
        XCTAssertTrue(ungrouped.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(ungrouped.staticTexts["4 drives: 3 Data, 1 Parity"].exists)
        XCTAssertFalse(ungrouped.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Group ")).firstMatch.exists)
    }

    /// RAID-Z shows what ZFS will report, labeled as an estimate.
    @MainActor
    func testZFSEstimateShown() throws {
        let app = launchApp(level: "Z2", drives: 6)
        let note = app.staticTexts["zfsReportedNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue(note.label.contains("as ZFS reports it (estimate)"), note.label)
    }

    /// A RAID-Z group wider than 12 drives gets the slow-rebuild caution.
    @MainActor
    func testWideRaidZGroupCaution() throws {
        let app = launchApp(level: "Z2", drives: 14)
        XCTAssertTrue(app.staticTexts["wideGroupCaution"].waitForExistence(timeout: 5))
    }

    /// RAID-Z's info sheet explains the estimate in its “How the App
    /// Calculates This” section, near the bottom.
    @MainActor
    func testRaidZInfoSheetExplainsEstimate() throws {
        let app = launchApp(level: "Z2", drives: 6)
        app.buttons["raidInfo"].tap()
        XCTAssertTrue(app.navigationBars["RAID-Z2"].waitForExistence(timeout: 5))
        let section = app.staticTexts["howCalculated"]
        for _ in 0..<5 where !section.exists {
            app.swipeUp()
        }
        XCTAssertTrue(section.waitForExistence(timeout: 2))
        XCTAssertTrue(section.label.contains("128 GiB"), section.label)
    }

    /// RAID 5's info sheet has no such section: it shows only the formula.
    @MainActor
    func testRaid5InfoSheetHasNoEstimateSection() throws {
        let app = launchApp()
        app.buttons["raidInfo"].tap()
        XCTAssertTrue(app.navigationBars["RAID 5"].waitForExistence(timeout: 5))
        for _ in 0..<5 {
            app.swipeUp()
        }
        // The ratings are the sheet's last section, so the whole sheet has been seen.
        XCTAssertTrue(app.staticTexts["Performance Ratings"].exists || app.otherElements["Performance Ratings"].exists)
        XCTAssertFalse(app.staticTexts["howCalculated"].exists)
    }

    /// The form loads its rows lazily, so a row below the fold isn't in the
    /// hierarchy until it's scrolled to.
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, scrollingDown: Bool = true) {
        for _ in 0..<6 where !(element.exists && element.isHittable) {
            scrollingDown ? app.swipeUp() : app.swipeDown()
        }
        // The floating tab bar covers the last rows, which still report hittable.
        if element.exists, element.frame.intersects(app.tabBars.firstMatch.frame) {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "not revealed: \(element)")
    }

    /// Capacities join number and unit with a no-break space.
    private func tb(_ value: Int) -> String { "\(value)\u{00A0}TB" }

    /// The summary's combined VoiceOver element, which reads
    /// “Usable Capacity, 16 TB, of 24 TB raw · 67% efficient”. The large
    /// figure inside it carries the same identifier.
    @MainActor
    private func nasCapacity(_ app: XCUIApplication) -> String {
        let summary = app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch
        return summary.label.components(separatedBy: ", ").dropFirst().first ?? summary.label
    }

    /// Each bay's VoiceOver frame is its own column, so exploring by touch
    /// lands on the bay under the finger. Bay 1 of [16, 8, 8, 4] carries
    /// hatched unused space, whose lines used to reach far past the column
    /// and stretch its frame across bays 2 and 3.
    @MainActor
    func testBayDiagramColumnsKeepTheirOwnFrames() throws {
        let app = launchNAS(bays: "[16,8,8,4]")
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 5))
        func column(_ bay: Int) -> XCUIElement {
            app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Bay \(bay), ")).firstMatch
        }
        for bay in 1...3 {
            let this = column(bay).frame, next = column(bay + 1).frame
            XCTAssertLessThanOrEqual(this.maxX, next.minX + 1, "bay \(bay) \(this) overlaps bay \(bay + 1) \(next)")
            XCTAssertLessThan(this.width, 100, "bay \(bay) frame \(this)")
        }
    }

    /// The same drives under every system. [4, 4, 8, 8] is SHR 16 TB,
    /// Unraid 16 TB (parity 8), RAID-Z1 12 TB and Btrfs RAID1 12 TB.
    @MainActor
    func testNASSwitchSystem() throws {
        let app = launchNAS()
        let usable = app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))
        XCTAssertEqual(nasCapacity(app), tb(16))
        XCTAssertTrue(app.navigationBars["NAS Calculator"].exists)

        // The picker sits above every section that comes and goes, so it
        // stays put (and on screen) as the system changes.
        for (name, expected) in [("Unraid", tb(16)), ("ZFS", tb(12)), ("Btrfs RAID1", tb(12)), ("Synology", tb(16))] {
            app.buttons["nasSystem"].tap()
            app.buttons[name].tap()
            XCTAssertTrue(usable.waitForExistence(timeout: 2))
            XCTAssertEqual(nasCapacity(app), expected, name)
        }
    }

    /// Only the setting that system has is shown.
    @MainActor
    func testNASSettingsPerSystem() throws {
        let app = launchNAS(system: "unraid")
        XCTAssertTrue(app.buttons["nasInfo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["parityCount"].exists)
        XCTAssertFalse(app.buttons["zfsLevel"].exists)
        reveal(app.staticTexts["parityPromotionNote"], in: app)
        XCTAssertTrue(app.staticTexts["parityPromotionNote"].exists)

        reveal(app.buttons["nasSystem"], in: app, scrollingDown: false)
        app.buttons["nasSystem"].tap()
        app.buttons["ZFS"].tap()
        XCTAssertTrue(app.buttons["zfsLevel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["parityCount"].waitForNonExistence(timeout: 2))
        reveal(app.staticTexts["zfsReportedNote"], in: app, scrollingDown: false)
        XCTAssertTrue(app.staticTexts["zfsReportedNote"].exists)
    }

    /// Seven drives in SnapRAID with one parity drive: 6 data drives, and
    /// SnapRAID recommends 2 parity.
    @MainActor
    func testSnapRAIDParityHint() throws {
        let app = launchNAS(system: "snapraid", bays: "[8,8,8,8,8,8,8]", bayCount: 7)
        let hint = app.staticTexts["nasHint"]
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.label.contains("recommends 2 parity drives"), hint.label)
    }

    /// Unraid's info sheet carries its trademark line.
    @MainActor
    func testNASInfoSheetHasTrademarkLine() throws {
        let app = launchNAS(system: "unraid")
        app.buttons["nasInfo"].tap()
        let footnote = app.staticTexts["infoFootnote"]
        for _ in 0..<5 where !footnote.exists { app.swipeUp() }
        XCTAssertTrue(footnote.label.contains("Lime Technology"), footnote.label)
    }

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
        XCTAssertTrue(ratingsNote.exists)
        XCTAssertLessThan(footnote.frame.minY - ratingsNote.frame.maxY, 24, "no empty section between them")
    }

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

    /// A stored value from 1.5 ("synology") opens the RAID tab. (Review Focus 5)
    @MainActor
    func testUnknownStoredTabOpensRaidTab() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-selectedTab", "synology", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.segmentedControls.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["RAID"].isSelected)
    }

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
        // A Stepper's label text reports not-hittable (the stepper owns the touch), so check on-screen by frame.
        XCTAssertTrue(app.windows.firstMatch.frame.contains(count.frame), "inputs should be on screen without scrolling")
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

    /// FR-14: 30 bays stay legible on iPad, in rows, with no scrolling.
    @MainActor
    func testIPadShowsThirtyBaysWithoutScrolling() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let bays = "[" + Array(repeating: "8", count: 30).joined(separator: ",") + "]"
        let app = launchNAS(system: "snapraid", bays: bays, bayCount: 30)
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 5))
        func column(_ bay: Int) -> XCUIElement {
            app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Bay \(bay), ")).firstMatch
        }
        for bay in [1, 15, 16, 30] {
            XCTAssertTrue(column(bay).exists, "bay \(bay)")
            XCTAssertTrue(column(bay).isHittable, "bay \(bay) should be on screen without scrolling")
        }
        XCTAssertGreaterThan(column(16).frame.minY, column(15).frame.maxY, "bay 16 should start a second row")
    }

    /// FR-13 on iPad: columns beside the results, no sheet.
    @MainActor
    func testIPadComparesSystemsInColumns() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        try assertComparesSystemsInColumns()
    }

    /// FR-13 in portrait on a large iPad, where the results column is
    /// narrower than five systems: they wrap into rows of columns rather
    /// than stacking into a list. Skips where portrait is a single column.
    @MainActor
    func testIPadComparesSystemsInColumnsInPortrait() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .portrait
        try assertComparesSystemsInColumns()
    }

    @MainActor
    private func assertComparesSystemsInColumns() throws {
        let app = launchNAS()
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 5))
        try XCTSkipIf(app.windows.firstMatch.frame.width < 800, "a single column at this width")
        let unraid = app.buttons["compare_unraid"]
        XCTAssertTrue(unraid.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["compareSystems"].exists)
        // Synology and Unraid tie on 16 TB and lead the sort, so they share
        // the first row: side by side, not one under the other.
        let synology = app.buttons["compare_synology"]
        XCTAssertEqual(unraid.frame.minY, synology.frame.minY, accuracy: 2, "Unraid should sit beside Synology")
        XCTAssertGreaterThan(unraid.frame.minX, synology.frame.maxX)
        app.buttons["compare_zfs"].tap()
        XCTAssertEqual(nasCapacity(app), tb(12))
    }

    /// Switching from 30 Unraid bays to Synology shrinks the drive list to 12
    /// rows. It used to crash: the list still drew the old rows' indices into
    /// the shorter array. Covers both the comparison columns and the picker.
    @MainActor
    func testIPadSwitchToSynologyFromThirtyBays() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad layout")
        XCUIDevice.shared.orientation = .landscapeLeft
        let bays = "[" + Array(repeating: "8", count: 30).joined(separator: ",") + "]"
        let app = launchNAS(system: "unraid", bays: bays, bayCount: 30)
        let usable = app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))

        // The drive list is lazy: on a shorter iPad (the mini in landscape)
        // bay 12 isn't built until the inputs column scrolls to it.
        func dragInputs(up: Bool) {
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: up ? 0.75 : 0.3))
            from.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: up ? 0.3 : 0.75)))
        }
        func show(_ element: XCUIElement, up: Bool) {
            for _ in 0..<6 where !(element.exists && element.isHittable) { dragInputs(up: up) }
        }

        func assertTwelveBays(_ route: String) {
            XCTAssertTrue(usable.waitForExistence(timeout: 2), "still running after switching via \(route)")
            XCTAssertEqual(app.state, .runningForeground, route)
            show(app.buttons["bay12"], up: true)
            XCTAssertTrue(app.buttons["bay12"].waitForExistence(timeout: 2), route)
            XCTAssertFalse(app.buttons["bay13"].exists, route)
        }

        app.buttons["compare_synology"].tap()
        assertTwelveBays("comparison columns")

        app.buttons["compare_unraid"].tap()
        show(app.buttons["bay13"], up: true)
        XCTAssertTrue(app.buttons["bay13"].waitForExistence(timeout: 2), "Unraid keeps all 30 bays")
        show(app.buttons["nasSystem"], up: false)
        app.buttons["nasSystem"].tap()
        app.buttons["Synology"].tap()
        assertTwelveBays("system picker")
    }

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
        reveal(app.staticTexts.matching(identifier: "usableCapacity").firstMatch, in: app, scrollingDown: false)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 24 TB,"), capacity(app))
    }
}

@MainActor
extension XCUIElement {
    func clearAndEnterText(text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        // The field is trailing-aligned: tap its right edge so the cursor lands after the text.
        coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
