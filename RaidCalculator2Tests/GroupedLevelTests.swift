//
//  GroupedLevelTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct GroupedLevelTests {

    let calculator = RaidCalculator()

    private func result(_ level: RaidLevel, drives: Int, size: Double = 8, unit: CapacityUnit = .tb, groups: Int) -> RaidResult {
        calculator.calculate(config: RaidConfiguration(level: level, driveCount: drives, driveSize: size, unit: unit, groups: groups))
    }

    @Test func raid50ThreeGroups() {
        let r = result(.raid50, drives: 12, groups: 3)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 72)
        #expect(r.failuresTolerated == "1, up to 3 (depends on which drives fail)")
        #expect(r.groupSize == 4)
        #expect(r.driveRoles == Array(repeating: [.data, .data, .data, .parity], count: 3).flatMap { $0 })
        #expect(r.speedRating == 4)
        #expect(r.availabilityRating == 3)
        #expect(r.zfsEstimate == nil)
    }

    @Test func raid60TwoGroups() {
        let r = result(.raid60, drives: 12, groups: 2)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 64)
        #expect(r.failuresTolerated == "2, up to 4 (depends on which drives fail)")
        #expect(r.groupSize == 6)
        #expect(r.speedRating == 3)
        #expect(r.availabilityRating == 4)
    }

    @Test func unevenGroupsOfferBothFixes() {
        let r = result(.raid60, drives: 12, groups: 5)
        #expect(r.warningMessage == "The number of drives (12) doesn’t divide evenly into 5 groups.")
        #expect(r.suggestedDriveCount == 20)    // 5 groups × the 4-drive minimum
        #expect(r.suggestedGroups == 3)         // valid: 2 (width 6) or 3 (width 4); 3 is nearer 5
        #expect(r.driveRoles.count == 12)       // one bar per drive even when invalid
        #expect(r.groupSize == nil)
    }

    @Test func nestedLevelNeedsTwoGroups() {
        let r = result(.raid50, drives: 6, groups: 1)
        #expect(r.warningMessage == "RAID 50 needs at least two groups. With one group, it’s RAID 5.")
        #expect(r.suggestedGroups == 2)
        #expect(r.suggestedDriveCount == nil)   // already enough drives; only the groups change
    }

    // The defaults are 4 drives in one group; picking a nested level from there
    // needs more drives and a second group, in one tap.
    @Test func nestedFixFromDefaultsAddsDrivesAndGroups() {
        let r50 = result(.raid50, drives: 4, groups: 1)
        #expect(r50.suggestedDriveCount == 6)
        #expect(r50.suggestedDriveCountGroups == 2)
        #expect(r50.suggestedGroups == nil)

        for drives in [4, 6] {
            let r60 = result(.raid60, drives: drives, groups: 1)
            #expect(r60.suggestedDriveCount == 8)
            #expect(r60.suggestedDriveCountGroups == 2)
        }
    }

    @Test func driveCountFixKeepsGroupsWhenTheyAlreadyFit() {
        let r = result(.raid60, drives: 12, groups: 5)
        #expect(r.suggestedDriveCount == 20)
        #expect(r.suggestedDriveCountGroups == nil)
    }

    // Review Minor 5: 23 drives in 5 groups would need 25, so the fix goes down.
    @Test func driveCountFixGoesBelowAtTheCeiling() {
        let r = result(.raid50, drives: 23, groups: 5)
        #expect(r.suggestedDriveCount == 20)
        #expect(r.suggestedDriveCountGroups == nil)
    }

    private func isValid(_ level: RaidLevel, drives: Int, groups: Int) -> Bool {
        calculator.validate(RaidConfiguration(level: level, driveCount: drives, driveSize: 8, unit: .tb, groups: groups)) == nil
    }

    /// Every invalid grouped configuration offers a one-tap fix, and every fix
    /// it offers is valid. The one exception would be a level with no valid
    /// configuration at all within 24 drives, which could offer nothing; the
    /// first expectation shows no grouped level is such a level.
    @Test(arguments: [RaidLevel.raid50, .raid60, .raidz1, .raidz2, .raidz3])
    func everyInvalidGroupedConfigurationHasAWorkingFix(level: RaidLevel) {
        let range = RaidCalculator.driveCountRange
        let anyValid = range.contains { n in (1...n).contains { isValid(level, drives: n, groups: $0) } }
        #expect(anyValid, "\(level.displayName) has no valid configuration within 24 drives")

        for drives in range {
            for groups in 1...6 {
                let config = RaidConfiguration(level: level, driveCount: drives, driveSize: 8, unit: .tb, groups: groups)
                let r = calculator.calculate(config: config)
                guard r.warningMessage != nil else { continue }
                let label = "\(level.displayName), \(drives) drives, \(groups) groups"

                var fixes: [RaidConfiguration] = []
                if let count = r.suggestedDriveCount {
                    #expect(range.contains(count), "\(label): \(count) drives")
                    #expect(count != drives, "\(label): no-op drive fix")
                    if let fixGroups = r.suggestedDriveCountGroups {
                        #expect(fixGroups != groups, "\(label): no-op groups in drive fix")
                    }
                    var fixed = config
                    fixed.driveCount = count
                    fixed.groups = r.suggestedDriveCountGroups ?? groups
                    fixes.append(fixed)
                }
                if let fixGroups = r.suggestedGroups {
                    var fixed = config
                    fixed.groups = fixGroups
                    fixes.append(fixed)
                }

                if anyValid { #expect(!fixes.isEmpty, "\(label): no fix offered") }
                for fix in fixes {
                    #expect(calculator.validate(fix) == nil, "\(label): fix \(fix.driveCount) drives in \(fix.groups) groups is still invalid")
                }
            }
        }
    }

    @Test(arguments: [RaidLevel.raid50, .raid60, .raidz1, .raidz2, .raidz3])
    func validGroupedConfigurationsOfferNoFix(level: RaidLevel) {
        for drives in RaidCalculator.driveCountRange {
            for groups in 1...6 where isValid(level, drives: drives, groups: groups) {
                let r = result(level, drives: drives, groups: groups)
                #expect(r.suggestedDriveCount == nil, "\(level.displayName), \(drives)×\(groups)")
                #expect(r.suggestedGroups == nil, "\(level.displayName), \(drives)×\(groups)")
            }
        }
    }

    @Test func groupTooNarrow() {
        let r = result(.raidz2, drives: 6, groups: 3)
        #expect(r.warningMessage == "Each RAID-Z2 group needs at least 3 drives.")
        #expect(r.suggestedGroups == 2)
        #expect(r.suggestedDriveCount == 9)
    }

    @Test func singleRaidZGroup() {
        let r = result(.raidz1, drives: 4, groups: 1)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 24)
        #expect(r.failuresTolerated == "1")
        #expect(r.groupSize == nil)
        #expect(r.zfsEstimate != nil)
        #expect(r.speedRating == 3)
        #expect(r.availabilityRating == 3)
    }

    @Test func raidZ3Ratings() {
        let r = result(.raidz3, drives: 8, groups: 1)
        #expect(r.failuresTolerated == "3")
        #expect(r.usableCapacity == 40)
        #expect(r.speedRating == 2)
        #expect(r.availabilityRating == 5)
    }

    @Test func zfsEstimateMatchesWorkedExample() {
        let r = result(.raidz2, drives: 6, size: 16, groups: 1)
        let reported = try! #require(r.zfsEstimate).reportedBytes / 1_099_511_627_776
        #expect(abs(reported - 58.0827) < 0.001)
    }

    @Test func noEstimateWhenInvalid() {
        #expect(result(.raidz2, drives: 6, groups: 3).zfsEstimate == nil)
    }

    @Test func rebuildCautionSuggestsDualParity() {
        func caution(_ level: RaidLevel, size: Double, groups: Int = 1, drives: Int = 8) -> RaidLevel? {
            calculator.rebuildCautionSuggestion(for: RaidConfiguration(level: level, driveCount: drives, driveSize: size, unit: .tb, groups: groups))
        }
        #expect(caution(.raid5, size: 8) == .raid6)
        #expect(caution(.raid50, size: 8, groups: 2) == .raid60)
        #expect(caution(.raidz1, size: 10) == .raidz2)
        #expect(caution(.raid5, size: 4) == nil)
        #expect(caution(.raidz2, size: 20) == nil)
        #expect(caution(.raid50, size: 8, groups: 1) == nil)   // invalid configurations get no caution
    }

    // Review Minor 6: only suggest a level the current group width can be.
    @Test func rebuildCautionOnlySuggestsAReachableLevel() {
        func caution(_ level: RaidLevel, drives: Int, groups: Int) -> RaidLevel? {
            calculator.rebuildCautionSuggestion(for: RaidConfiguration(level: level, driveCount: drives, driveSize: 8, unit: .tb, groups: groups))
        }
        #expect(caution(.raid50, drives: 6, groups: 2) == nil)    // 3-wide groups; RAID 60 needs 4
        #expect(caution(.raidz1, drives: 4, groups: 2) == nil)    // 2-wide groups; RAID-Z2 needs 3
        #expect(caution(.raid50, drives: 8, groups: 2) == .raid60)
        #expect(caution(.raidz1, drives: 6, groups: 2) == .raidz2)
    }

    @Test func wideRaidZGroup() {
        func width(_ drives: Int, groups: Int, level: RaidLevel = .raidz2) -> Int? {
            calculator.wideZFSGroupWidth(for: RaidConfiguration(level: level, driveCount: drives, driveSize: 8, unit: .tb, groups: groups))
        }
        #expect(width(14, groups: 1) == 14)
        #expect(width(12, groups: 1) == nil)
        #expect(width(24, groups: 2) == nil)
        #expect(width(14, groups: 1, level: .raid60) == nil)
    }

    // Review Focus 1
    @Test func driveCountChangeLeavesUnevenGroupsWithFixes() {
        let r = result(.raidz2, drives: 10, groups: 3)
        #expect(r.warningMessage == "The number of drives (10) doesn’t divide evenly into 3 groups.")
        #expect(r.suggestedDriveCount == 12)
        #expect(r.suggestedGroups == 2)
    }

    // Review Focus 1
    @Test func zeroGroupsIsTreatedAsOne() {
        let r = result(.raidz1, drives: 4, groups: 0)
        #expect(r.warningMessage == nil)
        #expect(r.usableCapacity == 24)
    }

    // Review Focus 2
    @Test func standardLevelsIgnoreGroups() {
        let grouped = result(.raid5, drives: 6, groups: 3)
        let plain = result(.raid5, drives: 6, groups: 1)
        #expect(grouped.usableCapacity == plain.usableCapacity)
        #expect(grouped.warningMessage == nil)
        #expect(grouped.groupSize == nil)
        #expect(grouped.suggestedGroups == nil)
    }

    // Review Focus 3
    @Test func zfsEstimateInGigabytes() {
        let tb = result(.raidz2, drives: 6, size: 16, unit: .tb, groups: 1)
        let gb = result(.raidz2, drives: 6, size: 16_000, unit: .gb, groups: 1)
        #expect(abs(try! #require(gb.zfsEstimate).reportedBytes - (try! #require(tb.zfsEstimate)).reportedBytes) < 1)
    }

    // Review Focus 4
    @Test func fixesNeverExceedTwentyFourDrives() {
        let r = result(.raidz3, drives: 24, groups: 7)
        #expect(r.suggestedDriveCount == nil)   // 7 × 4 = 28 is over the limit
        #expect(r.suggestedGroups == 6)         // divisors of 24 with 4+ drives each: 1, 2, 3, 4, 6
    }
}
