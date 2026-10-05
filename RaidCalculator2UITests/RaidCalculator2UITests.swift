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

    /// Launches with a known configuration. Launch arguments override the
    /// persisted UserDefaults, so each test starts from RAID 5, 4 × 4 TB.
    @MainActor
    private func launchApp(level: String = "R 5", drives: Int = 4, groups: Int = 1, language: String = "en", locale: String = "en_US") -> XCUIApplication {
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

    /// The same drives under every system. [4, 4, 8, 8] is SHR 16 TB,
    /// Unraid 16 TB (parity 8), RAID-Z1 12 TB and Btrfs RAID1 12 TB.
    @MainActor
    func testNASSwitchSystem() throws {
        let app = launchNAS()
        let usable = app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))
        XCTAssertEqual(nasCapacity(app), tb(16))

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
