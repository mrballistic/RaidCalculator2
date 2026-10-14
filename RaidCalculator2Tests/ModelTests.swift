//
//  ModelTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ModelTests {

    @Test func persistedRawValuesNeverChange() {
        #expect(RaidLevel.raid0.rawValue == "R 0")
        #expect(RaidLevel.raid1.rawValue == "R 1")
        #expect(RaidLevel.raid5.rawValue == "R 5")
        #expect(RaidLevel.raid6.rawValue == "R 6")
        #expect(RaidLevel.raid10.rawValue == "R 10")
        #expect(RaidLevel.jbod.rawValue == "JBOD")
    }

    @Test func classicLevelsOnlyInPickerOrder() {
        #expect(RaidLevel.allCases == [.raid0, .raid1, .raid5, .raid6, .raid10, .jbod])
    }

    @Test func namesAndKeys() {
        #expect(RaidLevel.raid10.displayName == "RAID 10")
        #expect(RaidLevel.jbod.shortLabel == "JBOD")
        #expect(RaidLevel.raid6.stringKeyPrefix == "raid6")
    }
}
