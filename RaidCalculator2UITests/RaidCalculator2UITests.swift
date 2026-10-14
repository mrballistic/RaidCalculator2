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
    private func launchApp(level: String = "R 5", drives: Int = 4, size: Int = 4, groups: Int = 1, language: String = "en", locale: String = "en_US", contentSize: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-selectedLevel", level,
            "-driveCount", "\(drives)",
            "-driveSize", "\(size)",
            "-groups", "\(groups)",
            "-unit", "TB",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        app.launch()
        return app
    }

    /// The two-column layout appears at regular width, at least 800 points
    /// wide and 600 tall (AdaptiveLayout.twoColumnMinWidth and
    /// twoColumnMinHeight), on iPad and on iPhone Duo's inner
    /// display alike. The app marks that layout with an identifier, so skip
    /// unless it is actually showing.
    @MainActor
    private func skipUnlessTwoColumns(_ app: XCUIApplication) throws {
        try XCTSkipUnless(app.otherElements["twoColumnLayout"].waitForExistence(timeout: 3), "two-column layout not showing")
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
        XCTAssertLessThan(row.frame.height, normalHeight * 4.5, "stacked rows don't wrap inside a squeezed column")
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
        XCTAssertTrue(app.navigationBars["RAID Calc2"].waitForExistence(timeout: 5))
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

    // MARK: Added languages (1.6.5): each launches with its own labels (the title, “RAID Calc2”, isn’t translated); de and pt-BR also take a decimal comma.

    @MainActor
    func testLaunchesInGerman() throws {
        let app = launchApp(language: "de", locale: "de_DE")
        XCTAssertTrue(app.staticTexts["Anzahl Laufwerke"].waitForExistence(timeout: 5), app.debugDescription)

        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))
        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue + "2,5")
        app.buttons["Fertig"].tap()
        XCTAssertEqual(sizeField.value as? String, "2,5")
        XCTAssertTrue(capacity(app).contains("7,5"), capacity(app))
    }

    @MainActor
    func testLaunchesInTraditionalChinese() throws {
        let app = launchApp(language: "zh-Hant", locale: "zh_TW")
        XCTAssertTrue(app.staticTexts["硬碟數量"].waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    func testLaunchesInSimplifiedChinese() throws {
        let app = launchApp(language: "zh-Hans", locale: "zh_CN")
        XCTAssertTrue(app.staticTexts["硬盘数量"].waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    func testLaunchesInKorean() throws {
        let app = launchApp(language: "ko", locale: "ko_KR")
        XCTAssertTrue(app.staticTexts["드라이브 수"].waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    func testLaunchesInBrazilianPortuguese() throws {
        let app = launchApp(language: "pt-BR", locale: "pt_BR")
        XCTAssertTrue(app.staticTexts["Número de unidades"].waitForExistence(timeout: 5), app.debugDescription)

        let sizeField = app.textFields["driveSizeField"]
        XCTAssertTrue(sizeField.waitForExistence(timeout: 5))
        sizeField.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).tap()
        sizeField.typeText(XCUIKeyboardKey.delete.rawValue + "2,5")
        app.buttons["OK"].tap()
        XCTAssertEqual(sizeField.value as? String, "2,5")
        XCTAssertTrue(capacity(app).contains("7,5"), capacity(app))
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
    func testInvalidSetupIsAnnounced() throws {
        let app = launchApp(level: "R 10", drives: 5)
        XCTAssertTrue(app.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(capacity(app).hasPrefix("Not a valid setup."), capacity(app))
        XCTAssertTrue(capacity(app).contains("Usable Capacity"), capacity(app))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "failuresTolerated").firstMatch.exists)
    }

    @MainActor
    func testInfoSheetPresentation() throws {
        let app = launchApp()
        let infoButton = app.buttons["raidInfo"]
        XCTAssertTrue(infoButton.waitForExistence(timeout: 5))
        infoButton.tap()

        XCTAssertTrue(app.navigationBars["RAID 5"].waitForExistence(timeout: 5))

        app.buttons["closeInfo"].tap()
        XCTAssertTrue(app.navigationBars["RAID Calc2"].waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["Group 2 of 2, drive 1: Data"].exists)
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

    /// RAID 5 on 20 TB drives gets the rebuild caution, and its button
    /// switches to the suggested RAID 6, which needs no caution.
    @MainActor
    func testRebuildCautionOffersSaferLevel() throws {
        let app = launchApp(level: "R 5", drives: 8, size: 20)
        let fix = app.buttons["applyRebuildSuggestion"]
        XCTAssertTrue(fix.waitForExistence(timeout: 5))
        XCTAssertEqual(fix.label, "Use RAID 6")
        fix.tap()

        XCTAssertTrue(app.segmentedControls.firstMatch.buttons["RAID 6"].isSelected)
        XCTAssertTrue(fix.waitForNonExistence(timeout: 5))
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 120 TB,"), capacity(app))
    }

    /// Narrow RAID 50 groups on large drives warn, but offer no level to move to.
    @MainActor
    func testNarrowGroupsWarnWithoutSuggestion() throws {
        let app = launchApp(level: "R 50", drives: 6, size: 12, groups: 2)
        XCTAssertTrue(app.staticTexts["narrowGroupCaution"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["applyRebuildSuggestion"].exists)
    }

    /// Three-drive RAID 5 can't become RAID 6, so the caution asks for a
    /// fourth drive and offers no level to switch to.
    @MainActor
    func testThreeDriveRaid5CautionAsksForAFourthDrive() throws {
        let app = launchApp(level: "R 5", drives: 3, size: 20)
        let caution = app.staticTexts["narrowGroupCaution"]
        XCTAssertTrue(caution.waitForExistence(timeout: 5))
        XCTAssertTrue(caution.label.contains("A fourth drive would allow RAID 6."), caution.label)
        XCTAssertFalse(app.buttons["applyRebuildSuggestion"].exists)
    }

    /// Segmented controls stay near 13 pt at accessibility sizes, so both
    /// pickers become menus there.
    @MainActor
    func testPickersBecomeMenusAtAccessibilitySize() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        let level = app.buttons["levelPicker"]
        reveal(level, in: app)
        XCTAssertEqual(app.segmentedControls.count, 0)

        level.tap()
        XCTAssertTrue(app.buttons["RAID 5"].waitForExistence(timeout: 5))
        app.buttons["RAID 6"].tap()
        XCTAssertTrue(app.buttons["levelPicker"].label.contains("RAID 6"), app.buttons["levelPicker"].label)
        XCTAssertTrue(capacity(app).hasPrefix("Usable Capacity, 8 TB,"), capacity(app))

        let unit = app.buttons["unitPicker"]
        reveal(unit, in: app)
        unit.tap()
        app.buttons["GB"].tap()
        XCTAssertTrue(app.buttons["unitPicker"].label.contains("GB"), app.buttons["unitPicker"].label)
    }

    /// At accessibility sizes one menu holds every level, so a nested level
    /// shows its name there instead of an empty row.
    @MainActor
    func testAccessibilityLevelMenuShowsNestedLevel() throws {
        let app = launchApp(level: "R 50", drives: 6, groups: 2, contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        let level = app.buttons["levelPicker"]
        reveal(level, in: app)
        XCTAssertTrue(level.label.contains("RAID 50"), level.label)
        XCTAssertFalse(app.buttons["moreLevels"].exists)
    }

    /// VoiceOver reads each segment as the full level name, not “5”.
    @MainActor
    func testSegmentsReadFullLevelNames() throws {
        let app = launchApp()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertEqual(picker.buttons.allElementsBoundByIndex.map(\.label),
                       ["RAID 0", "RAID 1", "RAID 5", "RAID 6", "RAID 10", "JBOD"])
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
        // Swiping the app element itself does nothing once the device is in
        // landscape, so in landscape swipe the scrolling list directly.
        func scroll(down: Bool) {
            // iPad landscape shows two lists, so only a single-column
            // landscape window (iPhone) swipes the list directly.
            let window = app.windows.firstMatch.frame
            let singleList = window.width > window.height && !app.otherElements["twoColumnLayout"].exists && app.collectionViews.firstMatch.exists
            let target = singleList ? app.collectionViews.firstMatch : app
            down ? target.swipeUp() : target.swipeDown()
        }
        for _ in 0..<6 where !(element.exists && element.isHittable) {
            scroll(down: scrollingDown)
        }
        XCTAssertTrue(element.isHittable, "not revealed: \(element)")
    }

    /// FR-14: on a wide iPad the answer sits beside the inputs, so both are
    /// on screen without scrolling. Skips unless the two-column layout is showing.
    @MainActor
    func testIPadPutsResultsBesideInputs() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchApp()
        try skipUnlessTwoColumns(app)
        let usable = app.staticTexts.matching(identifier: "usableCapacity").firstMatch
        XCTAssertTrue(usable.waitForExistence(timeout: 5))
        let count = app.staticTexts.matching(identifier: "driveCount").firstMatch
        // A Stepper's label text reports not-hittable (the stepper owns the touch), so check on-screen by frame.
        XCTAssertTrue(app.windows.firstMatch.frame.contains(count.frame), "inputs should be on screen without scrolling")
        XCTAssertLessThan(usable.frame.maxX, count.frame.minX, "results should lead, inputs follow")
    }

    /// iPhone rotates (the app no longer locks to portrait): the answer shows
    /// and the drive-size field can still be reached.
    @MainActor
    func testLandscapeShowsTheAnswer() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchApp()
        XCTAssertTrue(app.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height, "the app should be in landscape")
        reveal(app.textFields["driveSizeField"], in: app)
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
