//
//  BtrfsRaid1Calculator.swift
//  RaidCalculator2
//
//  Btrfs RAID1: two copies of every block, on two different drives. Usable
//  space is half the total, unless one drive is larger than all the others
//  combined; then its excess has nothing to pair with.
//

import Foundation

struct BtrfsRaid1Calculator {

    func calculate(bays: [Double?]) -> BayResult {
        let installed = bays.compactMap { $0 }
        let total = installed.reduce(0, +)
        let largest = installed.max() ?? 0
        let largestIndex = bays.firstIndex { $0 == largest }

        var warning: String?
        if installed.isEmpty {
            warning = "no_drives".localized()
        } else if installed.count < 2 {
            warning = "btrfs_raid1_validation".localized()
        }

        // The largest drive can only hold as much as the others can mirror.
        let largestUsed = min(largest, total - largest)
        let segments: [[BaySegment]?] = bays.enumerated().map { index, size in
            size.map { size in
                let used = index == largestIndex ? largestUsed : size
                var slices = [BaySegment(role: .data, size: used / 2), BaySegment(role: .mirror, size: used / 2)]
                if size > used { slices.append(BaySegment(role: .unused, size: size - used)) }
                return slices
            }
        }

        let valid = warning == nil
        return BayResult(
            usableCapacity: valid ? min(total / 2, total - largest) : 0,
            rawCapacity: total,
            unusedCapacity: valid ? largest - largestUsed : 0,
            failuresTolerated: valid ? 1 : 0,
            warningMessage: warning,
            bays: segments.withoutEmptySlices
        )
    }
}
