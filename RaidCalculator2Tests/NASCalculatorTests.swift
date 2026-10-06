//
//  NASCalculatorTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct NASCalculatorTests {

    let calculator = NASCalculator()

    private func setup(_ system: NASSystem, _ bays: [Double?], parity: Int = 1, type: SynologyRaidType = .shr1) -> NASSetup {
        var settings = NASSettings(synologyType: type)
        settings.setParity(parity, for: system)
        return NASSetup(system: system, bays: bays, settings: settings)
    }

    @Test func dispatchesToEachSystem() {
        let bays: [Double?] = [16, 8, 8, 4]
        #expect(calculator.calculate(setup(.synology, bays)).usableCapacity == 20)   // SHR
        #expect(calculator.calculate(setup(.unraid, bays)).usableCapacity == 20)     // parity 16; 8 + 8 + 4
        #expect(calculator.calculate(setup(.snapraid, bays)).usableCapacity == 20)
        #expect(calculator.calculate(setup(.zfs, bays)).usableCapacity == 12)        // (4 − 1) × 4
        #expect(calculator.calculate(setup(.btrfs, bays)).usableCapacity == 18)
        #expect(calculator.calculate(setup(.synology, bays, type: .raid5)).usableCapacity == 12)
    }

    // Review Focus 3
    @Test func everySystemWarnsWithNoDrives() {
        for system in NASSystem.allCases {
            let r = calculator.calculate(setup(system, [nil, nil, nil]))
            #expect(r.warningMessage == "Add a drive to a bay to get started.", "\(system)")
            #expect(r.usableCapacity == 0)
            #expect(calculator.suggestion(setup(system, [nil, nil, nil])) == nil)
        }
    }

    @Test func synologySuggestionUnchanged() {
        #expect(calculator.suggestion(setup(.synology, [16, 8, 8, 4]))
                == BaySuggestion(kind: .replace(bay: 3, currentSize: 4), size: 16, gain: 12))
    }

    @Test func unraidAddsADataDriveAtParitySize() {
        #expect(calculator.suggestion(setup(.unraid, [16, 16, 8, 8, 4, nil]))
                == BaySuggestion(kind: .add(bay: 5), size: 16, gain: 16))
    }

    @Test func unraidReplacesTheSmallestDataDriveWhenFull() {
        #expect(calculator.suggestion(setup(.unraid, [16, 16, 8, 8, 4]))
                == BaySuggestion(kind: .replace(bay: 4, currentSize: 4), size: 16, gain: 12))
    }

    @Test func unraidHasNothingToSuggestWhenEveryDriveMatchesParity() {
        #expect(calculator.suggestion(setup(.unraid, [8, 8, 8])) == nil)
    }

    @Test func zfsReplacesTheUniqueSmallestWithTheNextSizeUp() {
        // 16, 8, 8, 4 in RAID-Z1: an 8 TB in bay 4 lifts the floor to 8: 3 × 8 − 12 = +12.
        #expect(calculator.suggestion(setup(.zfs, [16, 8, 8, 4]))
                == BaySuggestion(kind: .replace(bay: 3, currentSize: 4), size: 8, gain: 12))
    }

    @Test func zfsHasNothingToSuggestWhenTheSmallestIsShared() {
        #expect(calculator.suggestion(setup(.zfs, [8, 8, 4, 4])) == nil)
    }

    @Test func zfsNeverSuggestsAddingADrive() {
        #expect(calculator.suggestion(setup(.zfs, [8, 8, 8, nil])) == nil)
    }

    @Test func btrfsAddsTheLargestSizeInAnEmptyBay() {
        // 20, 4, 4 + 20: total 48, largest 20 → 24 usable, from 8.
        #expect(calculator.suggestion(setup(.btrfs, [20, 4, 4, nil]))
                == BaySuggestion(kind: .add(bay: 3), size: 20, gain: 16))
    }

    @Test func btrfsReplacesTheSmallestWhenFull() {
        // 20, 20, 4: total 44, largest 20 → 22, from 8.
        #expect(calculator.suggestion(setup(.btrfs, [20, 4, 4]))
                == BaySuggestion(kind: .replace(bay: 1, currentSize: 4), size: 20, gain: 14))
    }

    @Test func noSuggestionWhenInvalid() {
        #expect(calculator.suggestion(setup(.unraid, [8, 8], parity: 2)) == nil)
        #expect(calculator.suggestion(setup(.zfs, [8, 4], parity: 2)) == nil)
    }

    @Test func snapraidParityHint() {
        // 7 drives, 1 parity → 6 data drives; SnapRAID recommends 2.
        let hints = calculator.hints(setup(.snapraid, [8, 8, 8, 8, 8, 8, 8]))
        #expect(hints == [.snapraidParity(recommended: 2, dataDrives: 5...14)])
        #expect(calculator.hints(setup(.snapraid, [8, 8, 8, 8, 8, 8, 8], parity: 2)).isEmpty)
        #expect(calculator.hints(setup(.unraid, [8, 8, 8, 8, 8, 8, 8])).isEmpty)   // Unraid caps at 2 parity; no SnapRAID advice
    }

    @Test func wideZFSGroupHint() {
        let fourteen = Array(repeating: Double?(8), count: 14)
        #expect(calculator.hints(setup(.zfs, fourteen, parity: 2)) == [.wideZFSGroup(width: 14)])
        #expect(calculator.hints(setup(.zfs, Array(fourteen.prefix(12)), parity: 2)).isEmpty)
    }

    // Final review I1: Unraid's array is at most 28 data drives plus 2 parity.
    @Test func unraidHoldsAtMost28DataDrives() {
        let bays: [Double?] = Array(repeating: 8, count: 30)
        let over = calculator.calculate(setup(.unraid, bays, parity: 1))
        #expect(over.warningMessage == "Unraid arrays hold up to 28 data drives plus 2 parity drives.")
        #expect(over.usableCapacity == 0)
        #expect(over.failuresTolerated == 0)

        let full = calculator.calculate(setup(.unraid, bays, parity: 2))
        #expect(full.warningMessage == nil)
        #expect(full.usableCapacity == 224)   // 28 data drives × 8 TB
        #expect(full.failuresTolerated == 2)
    }

    @Test func snapraidHasNoDataDriveLimit() {
        let r = calculator.calculate(setup(.snapraid, Array(repeating: 8, count: 30), parity: 1))
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 232)      // 29 data drives × 8 TB
    }

    // Same drives, every system (FR-13). Synology, Unraid and SnapRAID tie
    // at 20 TB, so the picker's order decides between them.
    @Test func compareSortsByUsableThenPickerOrder() {
        let bays: [Double?] = [16, 8, 8, 4]
        let rows = NASCalculator().compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: bays, settings: NASSettings()) },
            requestedBayCount: 4,
            shownBayCount: 4
        )
        #expect(rows.map(\.system) == [.synology, .unraid, .snapraid, .btrfs, .zfs])
        #expect(rows.map(\.usableCapacity) == [20, 20, 20, 18, 12])
        #expect(rows.allSatisfy { $0.isValid && $0.failuresTolerated == 1 && $0.bayLimit == nil })
        #expect(rows.last?.unusedCapacity == 20)
    }

    // Review Focus 2: a system that can't use the drives sorts below every one that can.
    @Test func invalidSetupsSortLast() throws {
        var settings = NASSettings()
        settings.snapraidParity = 2
        let rows = NASCalculator().compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: [8, 8], settings: settings) },
            requestedBayCount: 2,
            shownBayCount: 2
        )
        let firstInvalid = try #require(rows.firstIndex { !$0.isValid })
        #expect(firstInvalid > 0)
        #expect(rows[firstInvalid...].allSatisfy { !$0.isValid })
        #expect(rows[..<firstInvalid].allSatisfy { $0.isValid })
        #expect(rows.first { $0.system == .snapraid }?.isValid == false)
        #expect(rows.first { $0.system == .snapraid }?.warningMessage != nil)
    }
}
