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
}
