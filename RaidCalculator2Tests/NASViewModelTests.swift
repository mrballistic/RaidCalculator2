//
//  NASViewModelTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

struct NASViewModelTests {

    /// A throwaway defaults domain per test, so tests never touch the app's.
    private func freshDefaults() -> UserDefaults {
        let name = "NASViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func upgradersDefaultToSynologyWithTheirBays() throws {
        let defaults = freshDefaults()
        defaults.set(try JSONEncoder().encode([16, 8, 8, 4] as [Double?]), forKey: "synology.bays")
        defaults.set("SHR-2", forKey: "synology.raidType")
        let model = NASViewModel(userDefaults: defaults)
        #expect(model.system == .synology)
        #expect(model.bays == [16, 8, 8, 4])
        #expect(model.bayCount == 4)
        #expect(model.settings.synologyType == .shr2)
        #expect(!model.differsFromCurrent)
    }

    @Test func freshInstallDefaults() {
        let model = NASViewModel(userDefaults: freshDefaults())
        #expect(model.system == .synology)
        #expect(model.bays == [4, 4, 8, 8])
        // Nothing saved yet: the launch setup is current, so there's no comparison.
        #expect(model.usableDelta == nil)
    }

    // Review Focus 1
    @Test func switchingSystemHidesButKeepsDrives() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.system = .unraid
        model.setBayCount(14)
        model.setSize(20, forBay: 13)
        #expect(model.bays.count == 14)
        model.system = .synology
        #expect(model.bays.count == 12)
        #expect(model.bayCount == 12)
        model.system = .unraid
        #expect(model.bays.count == 14)
        #expect(model.bays[13] == 20)
    }

    @Test func loweringTheBayCountTrims() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.system = .unraid
        model.setBayCount(6)
        model.setSize(12, forBay: 5)
        model.setBayCount(5)
        model.setBayCount(6)
        #expect(model.bays[5] == nil)
    }

    @Test func bayCountClampsToTheSystemRange() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.setBayCount(40)
        #expect(model.bayCount == 12)     // Synology
        model.system = .btrfs
        model.setBayCount(40)
        #expect(model.bayCount == 30)
        model.setBayCount(1)
        #expect(model.bayCount == 2)
    }

    // Review Focus 4
    @Test func currentSetupComparisonIncludesSystem() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.saveAsCurrent()
        #expect(model.usableDelta == nil)
        model.system = .unraid                                    // [4, 4, 8, 8]: SHR 16 → Unraid 16; same total, still a change
        #expect(model.differsFromCurrent)
        #expect(model.usableDelta == 0)
        model.system = .btrfs                                     // 12
        #expect(model.usableDelta == -4)
        model.system = .synology
        #expect(model.usableDelta == nil)
    }

    @Test func revertRestoresSystemDrivesAndSettings() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.saveAsCurrent()
        model.system = .zfs
        model.settings.setParity(2, for: .zfs)
        model.setSize(16, forBay: 0)
        model.revertToCurrent()
        #expect(model.system == .synology)
        #expect(model.bays == [4, 4, 8, 8])
        #expect(!model.differsFromCurrent)
    }

    @Test func everythingPersists() {
        let defaults = freshDefaults()
        let first = NASViewModel(userDefaults: defaults)
        first.system = .snapraid
        first.settings.setParity(3, for: .snapraid)
        first.setBayCount(8)
        first.setSize(18, forBay: 7)
        first.saveAsCurrent()
        let second = NASViewModel(userDefaults: defaults)
        #expect(second.system == .snapraid)
        #expect(second.settings.snapraidParity == 3)
        #expect(second.bayCount == 8)
        #expect(second.bays[7] == 18)
        #expect(!second.differsFromCurrent)
    }

    @Test func applySuggestionUsesTheSystemsUpgrade() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.system = .zfs
        model.setSize(16, forBay: 0)   // [16, 4, 8, 8] in RAID-Z1: floor 4
        let suggestion = model.suggestion
        #expect(suggestion?.size == 8)
        model.applySuggestion()
        #expect(model.bays == [16, 8, 8, 8])
    }

    // Review Focus 1: Synology reads the first 12 of 14 bays; the rest read all 14.
    @Test func comparisonNotesSynologysBayLimit() {
        let model = NASViewModel(userDefaults: freshDefaults())
        model.system = .unraid
        model.setBayCount(14)
        for bay in 0..<14 { model.setSize(8, forBay: bay) }
        let rows = model.comparison
        #expect(rows.count == 5)
        #expect(rows.first { $0.system == .synology }?.bayLimit == 12)
        #expect(rows.filter { $0.system != .synology }.allSatisfy { $0.bayLimit == nil })
        let unraid = rows.first { $0.system == .unraid }
        #expect(unraid?.usableCapacity == 104)    // 14 bays × 8 TB, one parity
        #expect(model.bays(for: .synology).count == 12)
        #expect(model.bays.count == 14)
    }
}
