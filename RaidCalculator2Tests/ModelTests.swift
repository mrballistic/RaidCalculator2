//
//  ModelTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ModelTests {

    @Test func persistedRawValuesNeverChange() {
        #expect(RaidLevel.raid0.rawValue == "R 0")
        #expect(RaidLevel.raid10.rawValue == "R 10")
        #expect(RaidLevel.jbod.rawValue == "JBOD")
        #expect(RaidLevel.raid50.rawValue == "R 50")
        #expect(RaidLevel.raid60.rawValue == "R 60")
        #expect(RaidLevel.raidz1.rawValue == "Z1")
        #expect(RaidLevel.raidz2.rawValue == "Z2")
        #expect(RaidLevel.raidz3.rawValue == "Z3")
    }

    @Test func familiesKeepTheSegmentedLevelsInOrder() {
        #expect(RaidLevel.levels(in: .standard) == [.raid0, .raid1, .raid5, .raid6, .raid10, .jbod])
        #expect(RaidLevel.levels(in: .nested) == [.raid50, .raid60])
        #expect(RaidLevel.levels(in: .zfs) == [.raidz1, .raidz2, .raidz3])
    }

    @Test func groupRules() {
        #expect(RaidLevel.raid50.parityPerGroup == 1)
        #expect(RaidLevel.raid60.parityPerGroup == 2)
        #expect(RaidLevel.raidz1.parityPerGroup == 1)
        #expect(RaidLevel.raidz2.parityPerGroup == 2)
        #expect(RaidLevel.raidz3.parityPerGroup == 3)
        #expect(RaidLevel.raid5.parityPerGroup == nil)
        #expect(RaidLevel.raid5.usesGroups == false)
        #expect(RaidLevel.raid60.usesGroups)

        #expect(RaidLevel.raid50.minimumGroupWidth == 3)
        #expect(RaidLevel.raid60.minimumGroupWidth == 4)
        #expect(RaidLevel.raidz1.minimumGroupWidth == 2)
        #expect(RaidLevel.raidz2.minimumGroupWidth == 3)
        #expect(RaidLevel.raidz3.minimumGroupWidth == 4)

        #expect(RaidLevel.raid50.minimumGroups == 2)
        #expect(RaidLevel.raid60.minimumGroups == 2)
        #expect(RaidLevel.raidz2.minimumGroups == 1)

        #expect(RaidLevel.raid50.singleGroupEquivalent == .raid5)
        #expect(RaidLevel.raid60.singleGroupEquivalent == .raid6)
        #expect(RaidLevel.raidz1.singleGroupEquivalent == nil)

        #expect(RaidLevel.raidz2.isZFS)
        #expect(!RaidLevel.raid60.isZFS)
    }

    @Test func namesAndKeys() {
        #expect(RaidLevel.raid50.displayName == "RAID 50")
        #expect(RaidLevel.raidz2.displayName == "RAID-Z2")
        #expect(RaidLevel.raidz3.shortLabel == "Z3")
        #expect(RaidLevel.raid60.stringKeyPrefix == "raid60")
        #expect(RaidLevel.raidz1.stringKeyPrefix == "raidz1")
    }

    @Test func configurationDefaultsToOneGroup() {
        let config = RaidConfiguration(level: .raid5, driveCount: 4, driveSize: 4, unit: .tb)
        #expect(config.groups == 1)
    }
}
