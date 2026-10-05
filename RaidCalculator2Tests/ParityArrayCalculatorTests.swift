//
//  ParityArrayCalculatorTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ParityArrayCalculatorTests {

    let unraid = ParityArrayCalculator(systemName: "Unraid")
    let snapraid = ParityArrayCalculator(systemName: "SnapRAID")

    @Test func unraidSumsDataDrives() {
        // Parity 16; data 16, 8, 8, 4.
        let r = unraid.calculate(bays: [16, 16, 8, 8, 4], parity: 1)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 36)
        #expect(r.rawCapacity == 52)
        #expect(r.unusedCapacity == 0)
        #expect(r.failuresTolerated == 1)
        #expect(r.bays[0] == [BaySegment(role: .parity, size: 16)])
        #expect(r.bays[1] == [BaySegment(role: .data, size: 16)])
        #expect(r.bays[4] == [BaySegment(role: .data, size: 4)])
    }

    @Test func largestDriveBecomesParity() {
        // Bay 1 holds 12 TB and bay 2 a larger 16 TB: the 16 TB is parity.
        let r = unraid.calculate(bays: [12, 16], parity: 1)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 12)
        #expect(r.bays[1] == [BaySegment(role: .parity, size: 16)])
        #expect(r.bays[0] == [BaySegment(role: .data, size: 12)])
    }

    @Test func tiesGoToTheLowerBay() {
        #expect(ParityArrayCalculator.parityBays(bays: [8, 8, 8], parity: 1) == [0])
        #expect(ParityArrayCalculator.parityBays(bays: [4, 8, nil, 8], parity: 2) == [1, 3])
    }

    @Test func snapraidTwoParity() {
        let r = snapraid.calculate(bays: [20, 20, 16, 12, 8], parity: 2)
        #expect(r.usableCapacity == 36)
        #expect(r.failuresTolerated == 2)
    }

    @Test func emptyBaysAreSkipped() {
        let r = unraid.calculate(bays: [8, nil, 4], parity: 1)
        #expect(r.usableCapacity == 4)
        #expect(r.bays[1] == nil)
    }

    @Test func noDrivesWarns() {
        let r = unraid.calculate(bays: [nil, nil], parity: 1)
        #expect(r.warningMessage == "Add a drive to a bay to get started.")
        #expect(r.usableCapacity == 0)
    }

    // Review Focus 2
    @Test func parityWithoutDataDriveWarns() {
        let r = unraid.calculate(bays: [8, 8], parity: 2)
        #expect(r.warningMessage == "Unraid needs at least one data drive besides its parity drives.")
        #expect(r.usableCapacity == 0)
        #expect(r.failuresTolerated == 0)
        #expect(r.bays[0] == [BaySegment(role: .parity, size: 8)])   // still drawn
    }

    @Test func snapraidRecommendations() {
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 1) == nil)
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 4)! == (1, 2...4))
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 6)! == (2, 5...14))
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 15)! == (3, 15...21))
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 28)! == (4, 22...28))
        #expect(ParityArrayCalculator.snapraidRecommendation(dataDrives: 29)! == (5, 29...35))
    }
}
