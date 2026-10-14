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
