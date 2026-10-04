//
//  ZFSEstimateTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct ZFSEstimateTests {

    private let tebibyte = 1_099_511_627_776.0

    @Test func allocationPadding() {
        // 128K record = 32 data sectors; parity per row; round up to a multiple of parity + 1.
        #expect(ZFSEstimate.allocatedSectors(width: 6, parity: 2) == 48)  // 32 + 16, already a multiple of 3
        #expect(ZFSEstimate.allocatedSectors(width: 7, parity: 2) == 48)  // 32 + 14 = 46 → 48
        #expect(ZFSEstimate.allocatedSectors(width: 4, parity: 1) == 44)  // 32 + 11 = 43 → 44
        #expect(ZFSEstimate.allocatedSectors(width: 2, parity: 1) == 64)  // 32 + 32
    }

    @Test func widthSixRaidZ2HasNoPaddingLoss() {
        let estimate = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.dataFraction - 4.0 / 6.0) < 1e-12)
        #expect(estimate.paddingLoss < 1e-9)
    }

    @Test func widthSevenRaidZ2LosesSpaceToPadding() {
        let estimate = ZFSEstimate(groups: 1, width: 7, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.dataFraction - 2.0 / 3.0) < 1e-12)
        #expect(abs(estimate.paddingLoss - (1 - (2.0 / 3.0) / (5.0 / 7.0))) < 1e-9)  // ≈ 6.7%
    }

    @Test func largePoolSlopIsCappedAt128GiB() {
        // RAID-Z2, 6 × 16 TB: 64 TB of data = 58.21 TiB, minus 128 GiB.
        let estimate = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 16e12)
        #expect(abs(estimate.reportedBytes / tebibyte - 58.0827) < 0.001)
    }

    @Test func smallPoolSlopIsOneThirtySecond() {
        // RAID-Z1, 3 × 2 TB: 4 TB of data; 1/32 of it is under the cap.
        let estimate = ZFSEstimate(groups: 1, width: 3, parity: 1, driveBytes: 2e12)
        #expect(abs(estimate.reportedBytes / tebibyte - 3.5243) < 0.001)
    }

    @Test func groupsMultiplyCapacity() {
        let one = ZFSEstimate(groups: 1, width: 6, parity: 2, driveBytes: 4e12)
        let two = ZFSEstimate(groups: 2, width: 6, parity: 2, driveBytes: 4e12)
        #expect(two.dataFraction == one.dataFraction)
        #expect(two.reportedBytes > one.reportedBytes * 1.9)
    }

    // Review Focus 5
    @Test func raidZ1AtMinimumWidth() {
        let estimate = ZFSEstimate(groups: 1, width: 2, parity: 1, driveBytes: 4e12)
        #expect(abs(estimate.dataFraction - 0.5) < 1e-12)
        #expect(estimate.paddingLoss < 1e-9)
    }
}
