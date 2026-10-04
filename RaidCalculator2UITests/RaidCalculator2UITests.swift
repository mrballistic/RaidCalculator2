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

        XCTAssertTrue(app.staticTexts["configurationWarning"].exists || app.otherElements["configurationWarning"].exists)
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
        XCTAssertFalse(app.staticTexts["groupCount"].exists)
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

    /// RAID-Z's info sheet explains the estimate; RAID 5's has no such section.
    @MainActor
    func testRaidZInfoSheetExplainsEstimate() throws {
        let app = launchApp(level: "Z2", drives: 6)
        app.buttons["raidInfo"].tap()
        app.swipeUp()
        let section = app.staticTexts["howCalculated"]
        XCTAssertTrue(section.waitForExistence(timeout: 5))
        XCTAssertTrue(section.label.contains("128 GiB"), section.label)
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
