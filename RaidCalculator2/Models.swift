//
//  Models.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

/// Which part of the level picker a level lives in. The segmented control shows
/// the standard levels; the rest sit in a sectioned menu beside it.
enum RaidFamily: CaseIterable {
    case standard
    case nested
    case zfs
}

enum RaidLevel: String, CaseIterable, Identifiable {
    case raid0 = "R 0"
    case raid1 = "R 1"
    case raid5 = "R 5"
    case raid6 = "R 6"
    case raid10 = "R 10"
    case jbod = "JBOD"
    case raid50 = "R 50"
    case raid60 = "R 60"
    case raidz1 = "Z1"
    case raidz2 = "Z2"
    case raidz3 = "Z3"

    var id: String { rawValue }

    /// Full name for headings, VoiceOver and the info sheet. The raw value stays
    /// "R 5" etc. because it's what UserDefaults has persisted since 1.0.
    var displayName: String {
        switch self {
        case .raid0: "RAID 0"
        case .raid1: "RAID 1"
        case .raid5: "RAID 5"
        case .raid6: "RAID 6"
        case .raid10: "RAID 10"
        case .jbod: "JBOD"
        case .raid50: "RAID 50"
        case .raid60: "RAID 60"
        case .raidz1: "RAID-Z1"
        case .raidz2: "RAID-Z2"
        case .raidz3: "RAID-Z3"
        }
    }

    /// Segment label. The section header already says “RAID Level”, so the
    /// numerals alone are enough and six of them fit on the narrowest iPhone.
    var shortLabel: String {
        switch self {
        case .raid0: "0"
        case .raid1: "1"
        case .raid5: "5"
        case .raid6: "6"
        case .raid10: "10"
        case .jbod: "JBOD"
        case .raid50: "50"
        case .raid60: "60"
        case .raidz1: "Z1"
        case .raidz2: "Z2"
        case .raidz3: "Z3"
        }
    }

    /// Prefix for this level's keys in Localizable.xcstrings (raid5_description…).
    var stringKeyPrefix: String {
        switch self {
        case .raid0: "raid0"
        case .raid1: "raid1"
        case .raid5: "raid5"
        case .raid6: "raid6"
        case .raid10: "raid10"
        case .jbod: "jbod"
        case .raid50: "raid50"
        case .raid60: "raid60"
        case .raidz1: "raidz1"
        case .raidz2: "raidz2"
        case .raidz3: "raidz3"
        }
    }

    var family: RaidFamily {
        switch self {
        case .raid0, .raid1, .raid5, .raid6, .raid10, .jbod: .standard
        case .raid50, .raid60: .nested
        case .raidz1, .raidz2, .raidz3: .zfs
        }
    }

    /// Levels in a family, in picker order.
    static func levels(in family: RaidFamily) -> [RaidLevel] {
        allCases.filter { $0.family == family }
    }

    var isZFS: Bool { family == .zfs }

    /// Parity drives in each group, for the levels built from striped groups;
    /// nil for the standard levels, which have no Groups input.
    var parityPerGroup: Int? {
        switch self {
        case .raid50, .raidz1: 1
        case .raid60, .raidz2: 2
        case .raidz3: 3
        default: nil
        }
    }

    var usesGroups: Bool { parityPerGroup != nil }

    /// Fewest drives one group can have.
    var minimumGroupWidth: Int {
        switch self {
        case .raid50: 3
        case .raid60: 4
        case .raidz1: 2
        case .raidz2: 3
        case .raidz3: 4
        default: 1
        }
    }

    /// RAID 50 and 60 need two groups; with one they're just RAID 5 and 6.
    /// A single RAID-Z group is a normal pool.
    var minimumGroups: Int {
        switch self {
        case .raid50, .raid60: 2
        default: 1
        }
    }

    /// What a nested level is when it has only one group.
    var singleGroupEquivalent: RaidLevel? {
        switch self {
        case .raid50: .raid5
        case .raid60: .raid6
        default: nil
        }
    }
}

/// What each physical drive contributes to the array, for the drive strip.
enum DriveRole {
    case data
    case parity
    case mirror
}

enum CapacityUnit: String, CaseIterable, Identifiable {
    case gb = "GB"
    case tb = "TB"
    
    var id: String { rawValue }
}

struct RaidConfiguration {
    var level: RaidLevel
    var driveCount: Int
    var driveSize: Double
    var unit: CapacityUnit
    /// Striped groups for RAID 50/60 and RAID-Z; ignored by the standard levels.
    var groups: Int = 1
}

struct RaidResult {
    var usableCapacity: Double     // normalized to selected unit
    var rawCapacity: Double        // driveCount × driveSize, same unit
    var failuresTolerated: String  // string to allow "up to 3"
    var speedRating: Int           // 1–5
    var availabilityRating: Int    // 1–5
    var warningMessage: String?    // for invalid configs
    var suggestedDriveCount: Int?  // nearest valid count when the count is the problem
    var driveRoles: [DriveRole]    // one entry per drive, in display order
    var groupSize: Int? = nil       // drives per group, for gaps in the strip; nil unless grouped and valid
    var suggestedGroups: Int? = nil // a group count that makes the current drive count valid
    /// What ZFS will report, for the RAID-Z levels; nil otherwise or when invalid.
    var zfsEstimate: ZFSEstimate? = nil

    var efficiency: Double { rawCapacity > 0 ? usableCapacity / rawCapacity : 0 }
}
