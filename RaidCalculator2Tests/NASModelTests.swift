//
//  NASModelTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

struct NASModelTests {

    @Test func systemsInPickerOrder() {
        #expect(NASSystem.allCases == [.synology, .unraid, .zfs, .snapraid, .btrfs])
        #expect(NASSystem.allCases.map(\.rawValue) == ["synology", "unraid", "zfs", "snapraid", "btrfs"])
    }

    @Test func namesAndKeys() {
        #expect(NASSystem.synology.displayName == "Synology")
        #expect(NASSystem.unraid.displayName == "Unraid")
        #expect(NASSystem.zfs.displayName == "ZFS")
        #expect(NASSystem.snapraid.displayName == "SnapRAID")
        #expect(NASSystem.btrfs.displayName == "Btrfs RAID1")
        #expect(NASSystem.btrfs.stringKeyPrefix == "btrfs")
        #expect(NASSystem.synology.notAffiliatedKey == "not_affiliated")
        #expect(NASSystem.unraid.notAffiliatedKey == "unraid_not_affiliated")
        #expect(NASSystem.zfs.notAffiliatedKey == "zfs_not_affiliated")
        #expect(NASSystem.snapraid.notAffiliatedKey == nil)
        #expect(NASSystem.btrfs.notAffiliatedKey == nil)
    }

    @Test func bayAndParityRanges() {
        #expect(NASSystem.synology.bayRange == 2...12)
        for system in [NASSystem.unraid, .zfs, .snapraid, .btrfs] {
            #expect(system.bayRange == 2...30)
        }
        #expect(NASSystem.synology.parityRange == nil)
        #expect(NASSystem.unraid.parityRange == 1...2)
        #expect(NASSystem.snapraid.parityRange == 1...6)
        #expect(NASSystem.zfs.parityRange == 1...3)
        #expect(NASSystem.btrfs.parityRange == nil)
    }

    @Test func settingsParityPerSystem() {
        var settings = NASSettings()
        #expect(settings.synologyType == .shr1)
        #expect(settings.parity(for: .unraid) == 1)
        settings.setParity(2, for: .unraid)
        settings.setParity(4, for: .snapraid)
        settings.setParity(3, for: .zfs)
        settings.setParity(9, for: .btrfs)   // ignored: no parity setting
        #expect(settings.unraidParity == 2)
        #expect(settings.snapraidParity == 4)
        #expect(settings.zfsParity == 3)
        #expect(settings.parity(for: .btrfs) == nil)
        #expect(settings.parity(for: .synology) == nil)
    }

    @Test func setupRoundTripsThroughJSON() throws {
        let setup = NASSetup(system: .snapraid, bays: [20, 20, nil, 8], settings: NASSettings(snapraidParity: 2))
        let decoded = try JSONDecoder().decode(NASSetup.self, from: JSONEncoder().encode(setup))
        #expect(decoded == setup)
    }

    @Test func equivalenceIgnoresOtherSystemsSettings() {
        let base = NASSetup(system: .unraid, bays: [8, 8, 4], settings: NASSettings())
        var other = base
        other.settings.setParity(3, for: .zfs)          // irrelevant to Unraid
        other.settings.synologyType = .raid5            // irrelevant to Unraid
        #expect(base.isEquivalent(to: other))
        other.settings.setParity(2, for: .unraid)
        #expect(!base.isEquivalent(to: other))
        var synology = base
        synology.system = .synology
        #expect(!base.isEquivalent(to: synology))
    }

    // Different drives are a different setup, whatever the system.
    @Test func differentBaysAreNotEquivalent() {
        let base = NASSetup(system: .zfs, bays: [8, 8, 4], settings: NASSettings())
        var other = base
        other.bays = [8, 8, 8]
        #expect(!base.isEquivalent(to: other))
    }

    // Synology compares its RAID type, not a parity setting.
    @Test func synologyTypeMatters() {
        let base = NASSetup(system: .synology, bays: [8, 8, 4], settings: NASSettings(synologyType: .shr1))
        var other = base
        other.settings.synologyType = .raid5
        #expect(!base.isEquivalent(to: other))
    }

    // Btrfs has no setting of its own, so every other setting is ignored.
    @Test func btrfsIgnoresEverySetting() {
        let base = NASSetup(system: .btrfs, bays: [8, 8, 4], settings: NASSettings())
        var other = base
        other.settings.synologyType = .raid5
        other.settings.setParity(3, for: .zfs)
        other.settings.setParity(2, for: .unraid)
        #expect(base.isEquivalent(to: other))
    }
}
