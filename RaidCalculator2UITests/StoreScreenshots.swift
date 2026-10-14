//
//  StoreScreenshots.swift
//  RaidCalculator2UITests
//
//  Raw App Store captures in any language, for scripts/store-assets/compose.py.
//  Skipped unless STORE_SHOTS_DIR is set, so CI and the normal suite never run
//  it. scripts/store-assets/capture_localized.sh sets it (as
//  TEST_RUNNER_STORE_SHOTS_DIR), with the language, the appearance and the
//  status bar already set on the Simulator.
//

import XCTest

final class StoreScreenshots: XCTestCase {
    private let env = ProcessInfo.processInfo.environment
    private var directory: String { env["STORE_SHOTS_DIR"] ?? "" }
    private var language: String { env["STORE_LANG"] ?? "en" }
    private var locale: String { env["STORE_LOCALE"] ?? "en_US" }
    /// "light" or "dark": the Simulator's appearance, which only names the file.
    private var mode: String { env["STORE_MODE"] ?? "light" }

    override func setUpWithError() throws {
        try XCTSkipIf(directory.isEmpty, "Set TEST_RUNNER_STORE_SHOTS_DIR to capture App Store screenshots.")
        continueAfterFailure = false
    }

    // MARK: Scenes. The names match the 1.7.0 raws, so compose.py's shot list applies.

    @MainActor
    func test01UsableSpace() throws {
        let app = launchNAS(bays: [4, 4, 8, 8])
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 10))
        save("01-usable-space", app)
    }

    @MainActor
    func test02CompareSystems() throws {
        try XCTSkipIf(isPad, "iPad shows the comparison inline; its set has no Compare Systems image.")
        let app = launchNAS(bays: [4, 4, 8, 8])
        let compare = app.buttons["compareSystems"]
        XCTAssertTrue(compare.waitForExistence(timeout: 10))
        compare.tap()
        XCTAssertTrue(app.buttons["compare_zfs"].waitForExistence(timeout: 5))
        save("02-compare-systems", app)
    }

    @MainActor
    func test03SavedSetup() throws {
        // The website's iPad shot is this scene; the store's iPad set isn't.
        try XCTSkipIf(isPad && env["STORE_WEB"] == nil, "Not in the iPad set.")
        let app = launchNAS(bays: [8, 4, 8, 8], current: [4, 4, 8, 8])
        let delta = app.descendants(matching: .any).matching(identifier: "usableDelta").firstMatch
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 10))
        for _ in 0..<4 where !(delta.exists && delta.isHittable) { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(delta.isHittable, "the comparison should be on screen")
        save("03-saved-setup", app)
    }

    /// iPad's set names this one 02, as 1.7.0's did.
    @MainActor
    func test04RebuildCaution() throws {
        let app = launchRAID(level: "R 5", drives: 8, size: 20)
        XCTAssertTrue(app.buttons["applyRebuildSuggestion"].waitForExistence(timeout: 10))
        save(isPad ? "02-rebuild-caution" : "04-rebuild-caution", app)
    }

    @MainActor
    func test05InvalidFix() throws {
        try XCTSkipIf(isPad, "Not in the iPad set.")
        let app = launchRAID(level: "R 6", drives: 3, size: 12)
        XCTAssertTrue(app.buttons["applySuggestedDriveCount"].waitForExistence(timeout: 10))
        save("05-invalid-fix", app)
    }

    @MainActor
    func test06ThirtyBays() throws {
        // 270 TB on 30 bays, two 20 TB parity drives: 230 TB usable, and the
        // biggest upgrade replaces bay 23, the first 4 TB drive.
        let bays: [Double] = [20, 20, 16, 16, 16, 12, 12, 12, 12]
            + Array(repeating: 10, count: 6) + Array(repeating: 6, count: 7) + Array(repeating: 4, count: 8)
        let app = launchNAS(system: "unraid", bays: bays, settings: #"{"synologyType":"SHR","unraidParity":2,"snapraidParity":1,"zfsParity":1}"#)
        XCTAssertTrue(app.staticTexts.matching(identifier: "nasUsableCapacity").firstMatch.waitForExistence(timeout: 10))
        save("06-thirty-bays", app)
    }

    /// The website's RAID 10 shot: mirrored pairs, “Up to 4”.
    @MainActor
    func test07Raid10() throws {
        let app = launchRAID(level: "R 10", drives: 8, size: 12)
        XCTAssertTrue(app.staticTexts.matching(identifier: "usableCapacity").firstMatch.waitForExistence(timeout: 10))
        save("07-raid10", app)
    }

    // MARK: Helpers

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var common: [String] {
        ["-AppleLanguages", "(\(language))", "-AppleLocale", locale, "-unit", "TB"]
    }

    @MainActor
    private func launchRAID(level: String, drives: Int, size: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-selectedTab", "raid", "-selectedLevel", level, "-driveCount", "\(drives)",
                                "-driveSize", "\(size)", "-groups", "1"] + common
        app.launch()
        return app
    }

    /// The NAS tab with these drives. With `current`, those drives are the
    /// saved setup it compares against.
    @MainActor
    private func launchNAS(system: String = "synology", bays: [Double], current: [Double]? = nil,
                           settings: String = #"{"synologyType":"SHR","unraidParity":1,"snapraidParity":1,"zfsParity":1}"#) -> XCUIApplication {
        func plistData(_ json: String) -> String { "<" + json.utf8.map { String(format: "%02x", $0) }.joined() + ">" }
        func list(_ values: [Double]) -> String { "[" + values.map { String(Int($0)) }.joined(separator: ",") + "]" }
        let app = XCUIApplication()
        var args = ["-selectedTab", "nas", "-nas.system", system, "-nas.bayCount", "\(bays.count)",
                    "-synology.bays", plistData(list(bays)), "-nas.settings", plistData(settings)]
        if let current {
            let setup = #"{"system":"\#(system)","bays":\#(list(current)),"settings":\#(settings)}"#
            args += ["-nas.currentSetup", plistData(setup), "-nas.hasSavedCurrent", "YES"]
        } else {
            args += ["-nas.currentSetup", "", "-nas.hasSavedCurrent", "NO"]
        }
        app.launchArguments += args + common
        app.launch()
        return app
    }

    @MainActor
    private func save(_ scene: String, _ app: XCUIApplication) {
        // Let transitions and number animations finish.
        Thread.sleep(forTimeInterval: 1.5)
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(scene)-\(mode).png")
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
        } catch {
            XCTFail("couldn’t write \(url.path): \(error)")
        }
    }
}
