//
//  ZFSMixedCalculatorTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ZFSMixedCalculatorTests {

    let calculator = ZFSMixedCalculator()

    @Test func everyDriveCountsAsTheSmallest() {
        // RAID-Z1 on 16, 8, 8, 4 TB: (4 − 1) × 4 = 12; 12 + 4 + 4 unused.
        let r = calculator.calculate(bays: [16, 8, 8, 4], parity: 1)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 12)
        #expect(r.unusedCapacity == 20)
        #expect(r.rawCapacity == 36)
        #expect(r.failuresTolerated == 1)
        #expect(r.bays[0] == [BaySegment(role: .data, size: 3), BaySegment(role: .parity, size: 1), BaySegment(role: .unused, size: 12)])
        #expect(r.bays[3] == [BaySegment(role: .data, size: 3), BaySegment(role: .parity, size: 1)])
        let estimate = try! #require(r.zfsEstimate)
        #expect(abs(estimate.dataFraction - 32.0 / 44.0) < 1e-12)
    }

    @Test func matchedDrivesLeaveNothingUnused() {
        let r = calculator.calculate(bays: [8, 8, 8, 8, 8, 8], parity: 2)
        #expect(r.usableCapacity == 32)
        #expect(r.unusedCapacity == 0)
        #expect(r.failuresTolerated == 2)
    }

    @Test func tooFewDrivesForTheLevel() {
        let r = calculator.calculate(bays: [8, 8, nil], parity: 2)
        #expect(r.warningMessage == "Each RAID-Z2 group needs at least 3 drives.")
        #expect(r.usableCapacity == 0)
        #expect(r.zfsEstimate == nil)
    }

    @Test func noDrivesWarns() {
        #expect(calculator.calculate(bays: [nil, nil], parity: 1).warningMessage == "Add a drive to a bay to get started.")
    }

    @Test func levelForParity() {
        #expect(ZFSMixedCalculator.level(parity: 1) == .raidz1)
        #expect(ZFSMixedCalculator.level(parity: 2) == .raidz2)
        #expect(ZFSMixedCalculator.level(parity: 3) == .raidz3)
    }
}
