//
//  NAS.swift
//  RaidCalculator2
//
//  The NAS tab's model: which system reads the drives, its settings, and the
//  setup a user saves to compare against. The drives are shared by every
//  system; the system is a lens on them.
//

import Foundation

enum NASSystem: String, CaseIterable, Identifiable, Codable {
    case synology
    case unraid
    case zfs
    case snapraid
    case btrfs

    var id: String { rawValue }

    /// Product names stay untranslated in every language.
    var displayName: String {
        switch self {
        case .synology: "Synology"
        case .unraid: "Unraid"
        case .zfs: "ZFS"
        case .snapraid: "SnapRAID"
        case .btrfs: "Btrfs RAID1"
        }
    }

    /// Desktop DiskStations top out at 12 bays; Unraid's array holds 30
    /// (28 data + 2 parity), which also bounds the rest.
    var bayRange: ClosedRange<Int> {
        switch self {
        case .synology: 2...12
        case .unraid, .zfs, .snapraid, .btrfs: 2...30
        }
    }

    /// Parity drives (Unraid, SnapRAID) or RAID-Z level (ZFS); nil when the
    /// system has no parity setting.
    var parityRange: ClosedRange<Int>? {
        switch self {
        case .unraid: 1...2
        case .snapraid: 1...6
        case .zfs: 1...3
        case .synology, .btrfs: nil
        }
    }

    /// Prefix for this system's info-sheet keys (unraid_description…).
    var stringKeyPrefix: String { rawValue }

    /// The trademark line its info sheet ends with, if it needs one.
    var notAffiliatedKey: String? {
        switch self {
        case .synology: "not_affiliated"
        case .unraid: "unraid_not_affiliated"
        case .zfs: "zfs_not_affiliated"
        case .snapraid, .btrfs: nil
        }
    }
}

/// Each system's own setting, kept for all of them so switching systems and
/// back restores what the user chose.
struct NASSettings: Codable, Equatable {
    var synologyType: SynologyRaidType = .shr1
    var unraidParity: Int = 1
    var snapraidParity: Int = 1
    var zfsParity: Int = 1

    func parity(for system: NASSystem) -> Int? {
        switch system {
        case .unraid: unraidParity
        case .snapraid: snapraidParity
        case .zfs: zfsParity
        case .synology, .btrfs: nil
        }
    }

    mutating func setParity(_ value: Int, for system: NASSystem) {
        switch system {
        case .unraid: unraidParity = value
        case .snapraid: snapraidParity = value
        case .zfs: zfsParity = value
        case .synology, .btrfs: break
        }
    }
}

/// Everything a calculation depends on.
struct NASSetup: Codable, Equatable {
    var system: NASSystem
    var bays: [Double?]
    var settings: NASSettings

    /// Same system, same drives and the same setting for that system; other
    /// systems' settings don't count as a change.
    func isEquivalent(to other: NASSetup) -> Bool {
        guard system == other.system, bays == other.bays else { return false }
        switch system {
        case .synology: return settings.synologyType == other.settings.synologyType
        case .btrfs: return true
        case .unraid, .zfs, .snapraid: return settings.parity(for: system) == other.settings.parity(for: system)
        }
    }
}
