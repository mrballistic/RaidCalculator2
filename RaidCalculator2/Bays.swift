//
//  Bays.swift
//  RaidCalculator2
//
//  Drives bay by bay, as every NAS system's calculator describes them: what
//  each slice of each drive does, and the single purchase worth making next.
//

import Foundation

/// What a slice of one drive does. `unused` is capacity the array can't use
/// with the current mix of drives.
enum SegmentRole: Hashable {
    case data
    case parity
    case mirror
    case unused
}

struct BaySegment: Hashable {
    let role: SegmentRole
    let size: Double
}

struct BaySuggestion: Equatable {
    enum Kind: Equatable {
        case add(bay: Int)
        case replace(bay: Int, currentSize: Double)
    }
    let kind: Kind
    let size: Double
    let gain: Double
}

struct BayResult {
    var usableCapacity: Double
    var rawCapacity: Double
    var unusedCapacity: Double
    var failuresTolerated: Int
    var warningMessage: String?
    /// Segments per bay, bottom layer first; nil for an empty bay.
    var bays: [[BaySegment]?]
    /// What ZFS will report, for the ZFS system; nil otherwise or when invalid.
    var zfsEstimate: ZFSEstimate? = nil

    var efficiency: Double { rawCapacity > 0 ? usableCapacity / rawCapacity : 0 }
}
