//
//  ZFSEstimate.swift
//  RaidCalculator2
//

import Foundation

/// What ZFS will report as usable for a RAID-Z pool, for OpenZFS defaults:
/// 4K sectors (ashift=12) and 128K records.
///
/// Two effects make it lower than the textbook (width − parity) × drives:
/// - RAID-Z rounds every allocation up to a multiple of parity + 1 sectors, so
///   some group widths waste a slice of each record (padding).
/// - ZFS holds back slop space: 1/32 of the pool, at most 128 GiB and at
///   least 128 MiB. Verified against `spa_get_slop_space()` in OpenZFS
///   2.1.0–2.4.4 (module/zfs/spa_misc.c) on 2026-10-02. The embedded-log
///   space it subtracts is also excluded from the pool's free space, so the two
///   cancel and aren't modeled.
struct ZFSEstimate: Equatable {
    /// Share of raw space that holds data once parity and padding are counted.
    let dataFraction: Double
    /// Bytes ZFS reports as usable: data space minus slop space.
    let reportedBytes: Double
    /// Space lost to padding, as a share of the textbook usable space; 0 when none.
    let paddingLoss: Double

    static let sectorsPerRecord = 32                       // 128K record ÷ 4K sectors
    static let maxSlopBytes = 128.0 * 1_073_741_824        // 128 GiB
    static let minSlopBytes = 128.0 * 1_048_576            // 128 MiB

    /// Sectors one 128K record occupies in a group of `width` drives.
    static func allocatedSectors(width: Int, parity: Int) -> Int {
        let dataPerRow = width - parity
        let rows = (sectorsPerRecord + dataPerRow - 1) / dataPerRow
        let total = sectorsPerRecord + parity * rows
        let multiple = parity + 1
        return (total + multiple - 1) / multiple * multiple
    }

    init(groups: Int, width: Int, parity: Int, driveBytes: Double) {
        let allocated = Self.allocatedSectors(width: width, parity: parity)
        dataFraction = Double(Self.sectorsPerRecord) / Double(allocated)

        let dataBytes = Double(groups * width) * driveBytes * dataFraction
        let slop = max(min(dataBytes / 32, Self.maxSlopBytes), min(dataBytes / 2, Self.minSlopBytes))
        reportedBytes = max(0, dataBytes - slop)

        let textbookFraction = Double(width - parity) / Double(width)
        paddingLoss = max(0, 1 - dataFraction / textbookFraction)
    }
}
