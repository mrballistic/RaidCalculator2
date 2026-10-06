//
//  ParityArrayCalculator.swift
//  RaidCalculator2
//
//  Unraid and SnapRAID: each data drive keeps its own file system, protected by
//  dedicated parity drives. Every data drive's full capacity is usable.
//

import Foundation

struct ParityArrayCalculator {
    /// “Unraid” or “SnapRAID”, for messages.
    let systemName: String
    /// Unraid's array holds at most 28 data drives; SnapRAID has no limit.
    var maxDataDrives: Int? = nil

    /// The largest drives are parity (ties go to the lower bay), so parity is
    /// always at least as large as every data drive, which both systems require.
    static func parityBays(bays: [Double?], parity: Int) -> Set<Int> {
        let installed = bays.enumerated().compactMap { index, size in size.map { (index: index, size: $0) } }
        let ordered = installed.sorted { ($0.size, -$0.index) > ($1.size, -$1.index) }
        return Set(ordered.prefix(parity).map(\.index))
    }

    func calculate(bays: [Double?], parity: Int) -> BayResult {
        let parityIndices = Self.parityBays(bays: bays, parity: parity)
        let installedCount = bays.compactMap { $0 }.count
        let raw = bays.compactMap { $0 }.reduce(0, +)

        let segments: [[BaySegment]?] = bays.enumerated().map { index, size in
            size.map { [BaySegment(role: parityIndices.contains(index) ? .parity : .data, size: $0)] }
        }
        let data = bays.enumerated().reduce(0.0) { total, entry in
            parityIndices.contains(entry.offset) ? total : total + (entry.element ?? 0)
        }

        var warning: String?
        if installedCount == 0 {
            warning = "no_drives".localized()
        } else if installedCount <= parity {
            warning = String(format: "parity_needs_data".localized(), systemName)
        } else if let maxDataDrives, installedCount - parityIndices.count > maxDataDrives {
            warning = "unraid_data_limit".localized()
        }

        return BayResult(
            usableCapacity: warning == nil ? data : 0,
            rawCapacity: raw,
            unusedCapacity: 0,
            failuresTolerated: warning == nil ? parity : 0,
            warningMessage: warning,
            bays: segments.withoutEmptySlices
        )
    }

    /// SnapRAID's published recommendation (snapraid.it/faq): parity drives
    /// for a count of data drives, and the data-drive range it covers.
    static func snapraidRecommendation(dataDrives: Int) -> (parity: Int, range: ClosedRange<Int>)? {
        let table: [(Int, ClosedRange<Int>)] = [(1, 2...4), (2, 5...14), (3, 15...21), (4, 22...28), (5, 29...35), (6, 36...42)]
        return table.first { $0.1.contains(dataDrives) }.map { (parity: $0.0, range: $0.1) }
    }
}
