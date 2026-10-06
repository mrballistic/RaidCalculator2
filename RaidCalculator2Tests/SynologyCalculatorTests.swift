//
//  SynologyCalculatorTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct SynologyCalculatorTests {

    let calculator = SynologyCalculator()

    @Test func shr1MixedPairsUsesEverything() {
        // 2 × 4 TB + 2 × 8 TB: classic RAID 5 gives 12 TB; SHR gives 16.
        let result = calculator.calculate(bays: [4, 4, 8, 8], type: .shr1)
        #expect(result.usableCapacity == 16)
        #expect(result.unusedCapacity == 0)
        #expect(result.failuresTolerated == 1)
        #expect(result.warningMessage == nil)
    }

    @Test func classicRaid5TreatsDrivesAsSmallest() {
        let result = calculator.calculate(bays: [4, 4, 8, 8], type: .raid5)
        #expect(result.usableCapacity == 12)
        #expect(result.unusedCapacity == 8)
    }

    @Test func shr1LoneLargestDriveIsPartlyUnused() {
        // Upgrading one 4 TB to 16 TB: +4 TB now, 8 TB waits for a second big drive.
        let result = calculator.calculate(bays: [16, 8, 8, 4], type: .shr1)
        #expect(result.usableCapacity == 20)
        #expect(result.unusedCapacity == 8)
    }

    @Test func shr1EqualsTotalMinusLargest() {
        let bays: [Double?] = [2, 6, 10, 10, 14]
        let result = calculator.calculate(bays: bays, type: .shr1)
        #expect(result.usableCapacity == 42 - 14)
        #expect(result.unusedCapacity == 4)
    }

    @Test func shr2EqualsTotalMinusTwoLargest() {
        let result = calculator.calculate(bays: [4, 4, 8, 8, 16], type: .shr2)
        #expect(result.usableCapacity == 40 - 16 - 8)
        #expect(result.failuresTolerated == 2)
    }

    @Test func shr2NeedsFourDrives() {
        let result = calculator.calculate(bays: [8, 8, 8, nil], type: .shr2)
        #expect(result.warningMessage == "SHR-2 needs at least 4 drives.")
        #expect(result.usableCapacity == 0)
    }

    @Test func singleDriveIsUnprotectedButUsable() {
        let result = calculator.calculate(bays: [12, nil], type: .shr1)
        #expect(result.usableCapacity == 12)
        #expect(result.failuresTolerated == 0)
    }

    @Test func emptyBaysAreIgnored() {
        let result = calculator.calculate(bays: [8, nil, 8, nil], type: .shr1)
        #expect(result.usableCapacity == 8)
        #expect(result.bays[1] == nil)
        #expect(result.rawCapacity == 16)
    }

    @Test func noDrivesWarns() {
        let result = calculator.calculate(bays: [nil, nil], type: .shr1)
        #expect(result.warningMessage == "Add a drive to a bay to get started.")
    }

    @Test func suggestionReplacesSmallestWhenFull() {
        let suggestion = calculator.suggestion(bays: [16, 8, 8, 4], type: .shr1)
        #expect(suggestion == BaySuggestion(kind: .replace(bay: 3, currentSize: 4), size: 16, gain: 12))
    }

    @Test func suggestionPrefersEmptyBay() {
        let suggestion = calculator.suggestion(bays: [16, 8, 8, nil], type: .shr1)
        #expect(suggestion?.kind == .add(bay: 3))
        #expect(suggestion?.gain == 16)
    }

    @Test func noSuggestionWithoutUnusedCapacity() {
        #expect(calculator.suggestion(bays: [4, 4, 8, 8], type: .shr1) == nil)
    }
}
