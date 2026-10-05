//
//  BtrfsRaid1CalculatorTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct BtrfsRaid1CalculatorTests {

    let calculator = BtrfsRaid1Calculator()

    @Test func halfTheTotalWhenBalanced() {
        let r = calculator.calculate(bays: [16, 8, 8, 4])
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 18)
        #expect(r.unusedCapacity == 0)
        #expect(r.failuresTolerated == 1)
        #expect(r.bays[0] == [BaySegment(role: .data, size: 8), BaySegment(role: .mirror, size: 8)])
    }

    @Test func oneOversizedDriveCantBeFullyMirrored() {
        // 20 + 4 + 4: only 8 TB can be paired, so 12 TB of the 20 TB is unused.
        let r = calculator.calculate(bays: [20, 4, 4])
        #expect(r.usableCapacity == 8)
        #expect(r.unusedCapacity == 12)
        #expect(r.bays[0] == [BaySegment(role: .data, size: 4), BaySegment(role: .mirror, size: 4), BaySegment(role: .unused, size: 12)])
        #expect(r.bays[1] == [BaySegment(role: .data, size: 2), BaySegment(role: .mirror, size: 2)])
    }

    @Test func twoEqualDrives() {
        let r = calculator.calculate(bays: [8, nil, 8])
        #expect(r.usableCapacity == 8)
        #expect(r.bays[1] == nil)
    }

    @Test func oneDriveWarns() {
        let r = calculator.calculate(bays: [8, nil])
        #expect(r.warningMessage == "Btrfs RAID1 needs at least 2 drives.")
        #expect(r.usableCapacity == 0)
    }

    @Test func noDrivesWarns() {
        #expect(calculator.calculate(bays: [nil, nil]).warningMessage == "Add a drive to a bay to get started.")
    }
}
