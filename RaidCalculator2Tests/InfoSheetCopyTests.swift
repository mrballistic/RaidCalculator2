//
//  InfoSheetCopyTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct InfoSheetCopyTests {

    @Test(arguments: RaidLevel.allCases)
    func everyLevelHasItsSheetCopy(level: RaidLevel) {
        for field in ["description", "pros", "cons", "use_cases"] {
            let key = "\(level.stringKeyPrefix)_\(field)"
            #expect(key.localized() != key, "missing \(key)")
        }
    }

    @Test(arguments: [RaidLevel.raidz1, .raidz2, .raidz3])
    func zfsLevelsExplainTheEstimate(level: RaidLevel) {
        let key = "\(level.stringKeyPrefix)_calculation"
        #expect(key.localized().contains("128 GiB"), "missing or wrong \(key)")
    }
}
