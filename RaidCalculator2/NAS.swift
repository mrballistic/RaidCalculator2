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

/// Advice shown under the results; never a block.
enum NASHint: Equatable, Hashable {
    /// SnapRAID recommends more parity for this many data drives.
    case snapraidParity(recommended: Int, dataDrives: ClosedRange<Int>)
    /// A RAID-Z group wider than 12 drives rebuilds slowly.
    case wideZFSGroup(width: Int)
}

struct NASCalculator {
    private let synology = SynologyCalculator()
    private let zfs = ZFSMixedCalculator()
    private let btrfs = BtrfsRaid1Calculator()

    func calculate(_ setup: NASSetup) -> BayResult {
        let parity = setup.settings.parity(for: setup.system) ?? 0
        switch setup.system {
        case .synology: return synology.calculate(bays: setup.bays, type: setup.settings.synologyType)
        case .unraid: return ParityArrayCalculator(systemName: setup.system.displayName, maxDataDrives: 28).calculate(bays: setup.bays, parity: parity)
        case .snapraid: return ParityArrayCalculator(systemName: setup.system.displayName).calculate(bays: setup.bays, parity: parity)
        case .zfs: return zfs.calculate(bays: setup.bays, parity: parity)
        case .btrfs: return btrfs.calculate(bays: setup.bays)
        }
    }

    /// The single purchase that unlocks the most space, per system:
    /// - Synology: unchanged (a drive the size of the largest, into an empty bay
    ///   or in place of the smallest, only when space is unused).
    /// - Unraid, SnapRAID: a data drive the size of the smallest parity drive,
    ///   into an empty bay or in place of the smallest data drive. A bigger new
    ///   parity drive never adds more right away: data drives are capped at
    ///   parity size, so its gain equals this one's.
    /// - ZFS: replace the uniquely smallest drive with the next size up already
    ///   in the group, the cheapest drive that lifts the floor. Adding a drive
    ///   needs RAID-Z expansion (OpenZFS 2.3+), so it isn't suggested.
    /// - Btrfs RAID1: a drive the size of the largest, into an empty bay or in
    ///   place of the smallest.
    func suggestion(_ setup: NASSetup) -> BaySuggestion? {
        if setup.system == .synology {
            return synology.suggestion(bays: setup.bays, type: setup.settings.synologyType)
        }
        let current = calculate(setup)
        guard current.warningMessage == nil else { return nil }

        let sizes = setup.bays.compactMap { $0 }
        let emptyBay = setup.bays.firstIndex { $0 == nil }
        var candidate: (kind: BaySuggestion.Kind, size: Double)?

        switch setup.system {
        case .synology:
            return nil
        case .unraid, .snapraid:
            let parityBays = ParityArrayCalculator.parityBays(bays: setup.bays, parity: setup.settings.parity(for: setup.system) ?? 1)
            guard let paritySize = parityBays.compactMap({ setup.bays[$0] }).min() else { return nil }
            if let empty = emptyBay {
                candidate = (.add(bay: empty), paritySize)
            } else if let smallest = setup.bays.indices.filter({ !parityBays.contains($0) }).min(by: { (setup.bays[$0] ?? 0, $0) < (setup.bays[$1] ?? 0, $1) }),
                      let size = setup.bays[smallest], size < paritySize {
                candidate = (.replace(bay: smallest, currentSize: size), paritySize)
            }
        case .zfs:
            guard let smallest = sizes.min(), sizes.filter({ $0 == smallest }).count == 1,
                  let next = Set(sizes).filter({ $0 > smallest }).min(),
                  let index = setup.bays.firstIndex(where: { $0 == smallest }) else { return nil }
            candidate = (.replace(bay: index, currentSize: smallest), next)
        case .btrfs:
            guard let largest = sizes.max() else { return nil }
            if let empty = emptyBay {
                candidate = (.add(bay: empty), largest)
            } else if let smallest = sizes.min(), smallest < largest, let index = setup.bays.firstIndex(where: { $0 == smallest }) {
                candidate = (.replace(bay: index, currentSize: smallest), largest)
            }
        }

        guard let candidate else { return nil }
        var upgraded = setup
        switch candidate.kind {
        case .add(let bay), .replace(let bay, _): upgraded.bays[bay] = candidate.size
        }
        let gain = calculate(upgraded).usableCapacity - current.usableCapacity
        return gain > 0 ? BaySuggestion(kind: candidate.kind, size: candidate.size, gain: gain) : nil
    }

    func hints(_ setup: NASSetup) -> [NASHint] {
        guard calculate(setup).warningMessage == nil else { return [] }
        let installed = setup.bays.compactMap { $0 }.count
        switch setup.system {
        case .snapraid:
            let parity = setup.settings.snapraidParity
            if let recommendation = ParityArrayCalculator.snapraidRecommendation(dataDrives: installed - parity),
               recommendation.parity > parity {
                return [.snapraidParity(recommended: recommendation.parity, dataDrives: recommendation.range)]
            }
            return []
        case .zfs:
            return installed > 12 ? [.wideZFSGroup(width: installed)] : []
        case .synology, .unraid, .btrfs:
            return []
        }
    }
}

/// One system's answer for the same drives, for “compare systems” (FR-13).
struct NASComparison: Identifiable, Equatable {
    let system: NASSystem
    let usableCapacity: Double
    let unusedCapacity: Double
    let failuresTolerated: Int
    let warningMessage: String?
    /// How many bays this system reads, when that's fewer than the user set
    /// up (Synology stops at 12); nil when it reads them all.
    let bayLimit: Int?
    /// How many bays this system reads, when that's more than the current
    /// system shows (Synology hides bays past 12); nil otherwise.
    let readsAllBays: Int?

    var id: NASSystem { system }
    var isValid: Bool { warningMessage == nil }
}

extension NASCalculator {
    /// The same drives under every system, most usable first. Setups that
    /// don't work sort last; ties keep the picker's order.
    func compare(_ setups: [NASSetup], requestedBayCount: Int, shownBayCount: Int) -> [NASComparison] {
        let order = Dictionary(uniqueKeysWithValues: NASSystem.allCases.enumerated().map { ($1, $0) })
        return setups.map { setup in
            let result = calculate(setup)
            return NASComparison(
                system: setup.system,
                usableCapacity: result.usableCapacity,
                unusedCapacity: result.unusedCapacity,
                failuresTolerated: result.failuresTolerated,
                warningMessage: result.warningMessage,
                bayLimit: setup.bays.count < requestedBayCount ? setup.bays.count : nil,
                readsAllBays: setup.bays.count > shownBayCount ? setup.bays.count : nil
            )
        }
        .sorted { a, b in
            if a.isValid != b.isValid { return a.isValid }
            if a.usableCapacity != b.usableCapacity { return a.usableCapacity > b.usableCapacity }
            return order[a.system, default: 0] < order[b.system, default: 0]
        }
    }
}
