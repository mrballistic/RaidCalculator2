//
//  ZFSMixedCalculator.swift
//  RaidCalculator2
//
//  One ZFS RAID-Z group (vdev) built from the drives in these bays. Every drive
//  counts only up to the smallest drive's size; the rest is unused.
//

import Foundation

struct ZFSMixedCalculator {

    static func level(parity: Int) -> RaidLevel {
        switch parity {
        case 3: .raidz3
        case 2: .raidz2
        default: .raidz1
        }
    }

    func calculate(bays: [Double?], parity: Int) -> BayResult {
        let installed = bays.compactMap { $0 }
        let n = installed.count
        let raw = installed.reduce(0, +)
        let level = Self.level(parity: parity)

        var warning: String?
        if n == 0 {
            warning = "no_drives".localized()
        } else if n < level.minimumGroupWidth {
            warning = String(format: "group_too_narrow".localized(), level.displayName, level.minimumGroupWidth)
        }

        let smallest = installed.min() ?? 0
        // Parity is spread across every drive; each drive's slice up to the
        // smallest size splits into data and parity in proportion.
        let dataShare = n > 0 ? smallest * Double(n - parity) / Double(n) : 0
        let parityShare = n > 0 ? smallest * Double(parity) / Double(n) : 0

        let segments: [[BaySegment]?] = bays.map { size in
            size.map { size in
                var slices = [BaySegment(role: .data, size: dataShare), BaySegment(role: .parity, size: parityShare)]
                if size > smallest { slices.append(BaySegment(role: .unused, size: size - smallest)) }
                return slices
            }
        }

        let valid = warning == nil
        return BayResult(
            usableCapacity: valid ? Double(n - parity) * smallest : 0,
            rawCapacity: raw,
            unusedCapacity: valid ? raw - Double(n) * smallest : 0,
            failuresTolerated: valid ? parity : 0,
            warningMessage: warning,
            bays: segments,
            zfsEstimate: valid ? ZFSEstimate(groups: 1, width: n, parity: parity, driveBytes: smallest * 1e12) : nil
        )
    }
}
