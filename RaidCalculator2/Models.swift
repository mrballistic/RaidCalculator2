//
//  Models.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

enum RaidLevel: String, CaseIterable, Identifiable {
    case raid0 = "R 0"
    case raid1 = "R 1"
    case raid5 = "R 5"
    case raid6 = "R 6"
    case raid10 = "R 10"
    case jbod = "JBOD"

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

    var efficiency: Double { rawCapacity > 0 ? usableCapacity / rawCapacity : 0 }
}
