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
    private func launchApp(level: String = "R 5", drives: Int = 4, size: Int = 4, language: String = "en", locale: String = "en_US", contentSize: String? = nil, showNotice: Bool = false, now: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-selectedLevel", level,
            "-driveCount", "\(drives)",
            "-driveSize", "\(size)",
            "-unit", "TB",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        // Every other test starts with the notice already seen. Showing it
        // removes the saved flag instead of overriding it, so Not Now can
        // still save it during the test.
        app.launchArguments += showNotice ? ["-legacy.resetNotice", "YES"] : ["-legacy.hasSeenRetirementNotice", "YES"]
        if let now { app.launchArguments += ["-legacy.now", now] }
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

    /// VoiceOver reads each segment as the full level name, not “5”.
    @MainActor
    func testSegmentsReadFullLevelNames() throws {
        let app = launchApp()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertEqual(picker.buttons.allElementsBoundByIndex.map(\.label),
                       ["RAID 0", "RAID 1", "RAID 5", "RAID 6", "RAID 10", "JBOD"])
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

    // MARK: Retirement notice (RAID Calc2 1.8.0)

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

    /// At accessibility sizes the sheet opens at full height, so its copy
    /// isn't squeezed behind the buttons.
    @MainActor
    func testRetirementSheetOpensFullHeightAtAccessibilitySizes() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL", showNotice: true)
        let title = app.staticTexts["retirementTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch.frame
        XCTAssertLessThan(title.frame.minY, window.minY + window.height * 0.3, "the sheet should open at full height")
    }

    /// At the largest size the banner drops its symbols, so its words get the
    /// whole width and don't break mid-word, and it leaves room for the answer.
    @MainActor
    func testBannerStaysCompactAtLargestTextSize() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        let banner = app.buttons["retirementBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch.frame
        XCTAssertLessThan(banner.frame.height, window.height * 0.4, "banner is \(banner.frame.height) of \(window.height)")
    }

    /// French and German have the longest notice copy. At the largest size
    /// both sheet buttons must still be reachable, and the banner too.
    @MainActor
    func testRetirementNoticeFitsLongLanguagesAtLargestTextSize() throws {
        for (language, locale) in [("fr", "fr_FR"), ("de", "de_DE")] {
            let app = launchApp(language: language, locale: locale, contentSize: "UICTContentSizeCategoryAccessibilityXXXL", showNotice: true)
            let notNow = app.buttons["retirementNotNow"]
            XCTAssertTrue(notNow.waitForExistence(timeout: 5), language)
            XCTAssertTrue(notNow.isHittable, language)
            XCTAssertTrue(app.buttons["retirementGet"].isHittable, language)
            notNow.tap()
            let banner = app.buttons["retirementBanner"]
            XCTAssertTrue(banner.waitForExistence(timeout: 5), language)
            XCTAssertTrue(banner.isHittable, language)
            XCTAssertLessThan(banner.frame.height, app.windows.firstMatch.frame.height * 0.5, language)
            app.terminate()
        }
    }

    /// The Simulator has no App Store, so the in-app product page can't load:
    /// it must close and hand over to the App Store web page in Safari, from
    /// the banner and from the sheet, and the sheet must still be there after.
    @MainActor
    func testStorePageFallsBackToTheWebWhenItCantLoad() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("A device can load the real product page.")
        #else
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        let app = launchApp(showNotice: true)
        let get = app.buttons["retirementGet"]
        XCTAssertTrue(get.waitForExistence(timeout: 5))
        get.tap()
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15), "Safari didn’t open the App Store page")
        safari.terminate()

        app.activate()
        let notNow = app.buttons["retirementNotNow"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5), "the sheet should still be there")
        notNow.tap()

        let banner = app.buttons["retirementBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        banner.tap()
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15), "Safari didn’t open from the banner")
        safari.terminate()
        app.activate()
        XCTAssertTrue(banner.waitForExistence(timeout: 5), "no store modal should be left over the form")
        XCTAssertTrue(banner.isHittable)
        #endif
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
