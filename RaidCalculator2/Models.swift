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
    var failuresTolerated: String  // string to allow "up to 3"
    var speedRating: Int           // 1–5
    var availabilityRating: Int    // 1–5
    var warningMessage: String?    // for invalid configs
}
