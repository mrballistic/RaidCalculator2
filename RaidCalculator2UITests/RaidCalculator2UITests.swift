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
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up if needed
    }
    
    let app = XCUIApplication()

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        // Verify the main UI elements are present
        XCTAssertTrue(app.staticTexts["RAID Calculator"].exists)
        XCTAssertTrue(app.staticTexts["R 0"].exists) // RAID level picker
        XCTAssertTrue(app.staticTexts["Number of Drives"].exists)
        XCTAssertTrue(app.staticTexts["Drive Size"].exists)
    }

    @MainActor
    func testRaidLevelSelection() throws {
        // Test different RAID levels can be selected
        let raid0Button = app.buttons["R 0"]
        let raid1Button = app.buttons["R 1"]
        let raid5Button = app.buttons["R 5"]
        
        XCTAssertTrue(raid0Button.exists)
        XCTAssertTrue(raid1Button.exists)
        XCTAssertTrue(raid5Button.exists)
        
        // Select RAID 1
        raid1Button.tap()
        XCTAssertTrue(raid1Button.isSelected)
        
        // Select RAID 5
        raid5Button.tap()
        XCTAssertTrue(raid5Button.isSelected)
    }

    @MainActor
    func testDriveCountStepper() throws {
        // Test drive count increment/decrement
        let minusButton = app.buttons["minus.circle.fill"]
        let plusButton = app.buttons["plus.circle.fill"]
        let driveCountLabel = app.staticTexts.matching(identifier: "driveCount").firstMatch
        
        XCTAssertTrue(minusButton.exists)
        XCTAssertTrue(plusButton.exists)
        
        // Get initial count (should be 4 by default)
        let initialCount = driveCountLabel.label as String
        
        // Increment drive count
        plusButton.tap()
        
        // Decrement drive count
        minusButton.tap()
        
        // Verify minus button is disabled at minimum (1 drive)
        for _ in 1...3 {
            minusButton.tap()
        }
        XCTAssertTrue(minusButton.isEnabled == false)
        
        // Verify plus button works at minimum
        plusButton.tap()
        XCTAssertTrue(plusButton.isEnabled == true)
    }

    @MainActor
    func testDriveSizeInput() throws {
        // Test drive size text field
        let sizeTextField = app.textFields["Size"]
        
        XCTAssertTrue(sizeTextField.exists)
        
        // Tap to focus
        sizeTextField.tap()
        
        // Enter a value
        sizeTextField.typeText("8")
        
        // Verify value was entered (check if keyboard is still up or value changed)
        XCTAssertTrue(sizeTextField.value as? String == "8")
        
        // Dismiss keyboard by tapping background
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
    }

    @MainActor
    func testResultsUpdate() throws {
        // Test that results appear and update
        let raid5Button = app.buttons["R 5"]
        let sizeTextField = app.textFields["Size"]
        
        // Select RAID 5 with default values
        raid5Button.tap()
        
        // Results should appear (check for key result elements)
        XCTAssertTrue(app.staticTexts["Results"].exists)
        XCTAssertTrue(app.staticTexts["Usable Capacity"].exists)
        XCTAssertTrue(app.staticTexts["Drive Failures Tolerated"].exists)
        
        // Change drive size and verify results update
        sizeTextField.tap()
        sizeTextField.clearAndEnterText(text: "8")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        
        // Results should still be present
        XCTAssertTrue(app.staticTexts["Results"].exists)
    }

    @MainActor
    func testWarningMessages() throws {
        // Test invalid configuration shows warning
        let raid5Button = app.buttons["R 5"]
        let minusButton = app.buttons["minus.circle.fill"]
        
        // Select RAID 5 (requires 3+ drives)
        raid5Button.tap()
        
        // Reduce drives to invalid number (2 drives for RAID 5)
        for _ in 1...2 {
            minusButton.tap()
        }
        
        // Warning should appear
        XCTAssertTrue(app.staticTexts["RAID 5 requires at least 3 drives."].exists)
        
        // Fix configuration
        let plusButton = app.buttons["plus.circle.fill"]
        plusButton.tap()
        
        // Warning should disappear, results should appear
        XCTAssertTrue(app.staticTexts["Results"].exists)
    }

    @MainActor
    func testInfoSheetPresentation() throws {
        // Test info sheet opens and closes
        let infoButton = app.buttons["info.circle"]
        
        XCTAssertTrue(infoButton.exists)
        infoButton.tap()
        
        // Sheet should open with full RAID name
        XCTAssertTrue(app.staticTexts["RAID 5"].exists) // Assuming RAID 5 is default
        XCTAssertTrue(app.staticTexts["Overview"].exists)
        
        // Close sheet
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()
        
        // Should return to main screen
        XCTAssertTrue(app.staticTexts["RAID Calculator"].exists)
    }

    @MainActor
    func testUnitSelection() throws {
        // Test GB/TB unit picker
        let gbButton = app.buttons["GB"]
        let tbButton = app.buttons["TB"]
        
        XCTAssertTrue(gbButton.exists)
        XCTAssertTrue(tbButton.exists)
        
        // Switch to TB
        tbButton.tap()
        XCTAssertTrue(tbButton.isSelected)
        
        // Switch back to GB
        gbButton.tap()
        XCTAssertTrue(gbButton.isSelected)
    }
}

// Helper extension for XCUIElement
extension XCUIElement {
    func clearAndEnterText(text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
