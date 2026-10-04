//
//  Synology.swift
//  RaidCalculator2
//
//  Synology mode: per-bay drive sizes, SHR alongside Synology's classic RAID,
//  and the layer math that explains where mixed-size capacity goes.
//

import Foundation

/// A DiskStation model, reduced to what the calculator needs: its bay count.
/// Checked against synology.com's DiskStation lineup in October 2026.
struct SynologyModel: Identifiable, Hashable {
    let id: String
    let bays: Int

    static let custom = "custom"

    static let presets: [SynologyModel] = [
        SynologyModel(id: "DS225+", bays: 2),
        SynologyModel(id: "DS725+", bays: 2),
        SynologyModel(id: "DS223j", bays: 2),
        SynologyModel(id: "DS425+", bays: 4),
        SynologyModel(id: "DS925+", bays: 4),
        SynologyModel(id: "DS423", bays: 4),
        SynologyModel(id: "DS1525+", bays: 5),
        SynologyModel(id: "DS625slim", bays: 6),
        SynologyModel(id: "DS1825+", bays: 8),
        SynologyModel(id: "DS2422+", bays: 12),
    ]

    static let customBayRange = 2...12
}

/// The storage types Synology offers that matter for planning. SHR is the
/// reason this mode exists; the classic levels are here so owners can see
/// what SHR saves them.
enum SynologyRaidType: String, CaseIterable, Identifiable, Codable {
    case shr1 = "SHR"
    case shr2 = "SHR-2"
    case raid1 = "RAID 1"
    case raid5 = "RAID 5"
    case raid6 = "RAID 6"

    var id: String { rawValue }

    /// Fewest installed drives the type accepts.
    var minimumDrives: Int {
        switch self {
        case .shr1: 1
        case .shr2: 4
        case .raid1: 2
        case .raid5: 3
        case .raid6: 4
        }
    }

    var validationKey: String {
        switch self {
        case .shr1: "no_drives"
        case .shr2: "shr2_validation"
        case .raid1: "raid1_validation"
        case .raid5: "raid5_validation"
        case .raid6: "raid6_validation"
        }
    }
}

struct SynologyCalculator {

    func calculate(bays: [Double?], type: SynologyRaidType) -> BayResult {
        let installed = bays.enumerated().compactMap { index, size in size.map { (index: index, size: $0) } }
        let raw = installed.reduce(0) { $0 + $1.size }
        var segments: [[BaySegment]?] = bays.map { $0 == nil ? nil : [] }

        var warning: String?
        if installed.isEmpty {
            warning = "no_drives".localized()
        } else if installed.count < type.minimumDrives {
            warning = type.validationKey.localized()
        }

        switch type {
        case .shr1, .shr2:
            layerSegments(installed: installed, type: type, into: &segments)
        case .raid1, .raid5, .raid6:
            classicSegments(installed: installed, type: type, into: &segments)
        }

        let usable = segments.reduce(0) { total, bay in
            total + (bay ?? []).filter { $0.role == .data }.reduce(0) { $0 + $1.size }
        }
        let unused = segments.reduce(0) { total, bay in
            total + (bay ?? []).filter { $0.role == .unused }.reduce(0) { $0 + $1.size }
        }

        return BayResult(
            usableCapacity: warning == nil ? usable : 0,
            rawCapacity: raw,
            unusedCapacity: warning == nil ? unused : 0,
            failuresTolerated: warning == nil ? failuresTolerated(installedCount: installed.count, type: type) : 0,
            warningMessage: warning,
            bays: segments
        )
    }

    /// SHR splits drives into layers at each distinct drive size and builds
    /// RAID across the drives that reach each layer. A layer reached by too
    /// few drives to protect is unused until a larger drive joins it.
    private func layerSegments(installed: [(index: Int, size: Double)], type: SynologyRaidType, into segments: inout [[BaySegment]?]) {
        let ordered = installed.sorted { ($0.size, $0.index) < ($1.size, $1.index) }
        let redundancy = type == .shr2 ? 2 : 1
        var floor = 0.0

        for ceiling in Set(ordered.map(\.size)).sorted() {
            let height = ceiling - floor
            let members = ordered.filter { $0.size >= ceiling }
            let protectable = members.count > redundancy

            for (position, member) in members.enumerated() {
                let role: SegmentRole
                if installed.count == 1 {
                    role = .data  // A single drive is a basic volume: usable, unprotected.
                } else if !protectable {
                    role = .unused
                } else if position >= members.count - redundancy {
                    // Parity is spread across the layer; drawing it on the
                    // largest drives keeps the picture readable.
                    role = members.count == 2 ? .mirror : .parity
                } else {
                    role = .data
                }
                segments[member.index]?.append(BaySegment(role: role, size: height))
            }
            floor = ceiling
        }
    }

    /// Classic RAID treats every drive as the size of the smallest one.
    private func classicSegments(installed: [(index: Int, size: Double)], type: SynologyRaidType, into segments: inout [[BaySegment]?]) {
        guard let smallest = installed.map(\.size).min() else { return }

        for (position, member) in installed.enumerated() {
            let role: SegmentRole
            switch type {
            case .raid1: role = position == 0 ? .data : .mirror
            case .raid5: role = position == installed.count - 1 ? .parity : .data
            case .raid6: role = position >= installed.count - 2 ? .parity : .data
            case .shr1, .shr2: role = .data
            }
            segments[member.index]?.append(BaySegment(role: role, size: smallest))
            if member.size > smallest {
                segments[member.index]?.append(BaySegment(role: .unused, size: member.size - smallest))
            }
        }
    }

    private func failuresTolerated(installedCount: Int, type: SynologyRaidType) -> Int {
        switch type {
        case .shr1: installedCount >= 2 ? 1 : 0
        case .shr2: 2
        case .raid1: installedCount - 1
        case .raid5: 1
        case .raid6: 2
        }
    }

    /// The single purchase that unlocks the most unused capacity: a drive the
    /// size of the largest one, in an empty bay if there is one, otherwise in
    /// place of the smallest drive.
    func suggestion(bays: [Double?], type: SynologyRaidType) -> BaySuggestion? {
        let current = calculate(bays: bays, type: type)
        guard current.warningMessage == nil, current.unusedCapacity > 0,
              let largest = bays.compactMap({ $0 }).max() else { return nil }

        var candidate = bays
        let kind: BaySuggestion.Kind
        if let empty = bays.firstIndex(where: { $0 == nil }) {
            candidate[empty] = largest
            kind = .add(bay: empty)
        } else if let smallest = bays.compactMap({ $0 }).min(),
                  smallest < largest,
                  let index = bays.firstIndex(where: { $0 == smallest }) {
            candidate[index] = largest
            kind = .replace(bay: index, currentSize: smallest)
        } else {
            return nil
        }

        let gain = calculate(bays: candidate, type: type).usableCapacity - current.usableCapacity
        guard gain > 0 else { return nil }
        return BaySuggestion(kind: kind, size: largest, gain: gain)
    }
}
