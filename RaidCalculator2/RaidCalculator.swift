//
//  RaidCalculator.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

struct RaidCalculator {

    static let driveCountRange = 1...24

    func validate(_ config: RaidConfiguration) -> String? {
        if let message = groupedValidationMessage(config) {
            return message
        }
        if let count = invalidDriveCountKey(config) {
            return count.localized()
        }
        if !(config.driveSize > 0) {
            return "drive_size_invalid".localized()
        }
        return nil
    }

    /// Nearest valid drive count, when the count is what makes the configuration
    /// invalid: the smallest at or above the current one, or for a grouped level
    /// at the 24-drive limit, the largest below it. Drives the one-tap fix.
    func suggestedDriveCount(for config: RaidConfiguration) -> Int? {
        if config.level.usesGroups { return groupedDriveCountFix(config)?.drives }
        let n = config.driveCount
        guard invalidDriveCountKey(config) != nil else { return nil }
        switch config.level {
        case .raid0, .jbod: return max(n, 1)
        case .raid1: return max(n, 2)
        case .raid5: return max(n, 3)
        case .raid6: return max(n, 4)
        case .raid10: return max(n + n % 2, 4)
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil
        }
    }

    /// The groups the drive-count fix assumes, when they differ from the
    /// current ones. Applied together with the count, so one tap is enough.
    func suggestedDriveCountGroups(for config: RaidConfiguration) -> Int? {
        guard let fix = groupedDriveCountFix(config) else { return nil }
        return fix.groups == groupCount(config) ? nil : fix.groups
    }

    /// The drive count and groups for a grouped level's drive-count fix. Groups
    /// rise to the level's minimum, and fall to as many as fit within 24
    /// drives. The count is the smallest that fills every group at or above
    /// the current one; when that's over 24, the largest below it. Nil when
    /// the count wouldn't change, since then only the groups need to.
    private func groupedDriveCountFix(_ config: RaidConfiguration) -> (drives: Int, groups: Int)? {
        let level = config.level
        guard groupedValidationMessage(config) != nil else { return nil }
        let n = config.driveCount
        let limit = Self.driveCountRange.upperBound
        let groups = min(max(groupCount(config), level.minimumGroups), limit / level.minimumGroupWidth)
        let upward = groups * max(level.minimumGroupWidth, (n + groups - 1) / groups)
        // Over the limit only when n doesn't divide evenly and each group is
        // already past its minimum, so rounding down still leaves wide enough groups.
        let count = upward <= limit ? upward : (n / groups) * groups
        return count == n ? nil : (count, groups)
    }

    /// The valid group count for the current drive count nearest the current
    /// one (ties go to fewer, wider groups). Drives the “Use N groups” fix.
    func suggestedGroups(for config: RaidConfiguration) -> Int? {
        guard config.level.usesGroups, groupedValidationMessage(config) != nil else { return nil }
        let n = config.driveCount
        let current = groupCount(config)
        let candidates = (config.level.minimumGroups...max(config.level.minimumGroups, n)).filter {
            n % $0 == 0 && n / $0 >= config.level.minimumGroupWidth
        }
        let best = candidates.min { (abs($0 - current), $0) < (abs($1 - current), $1) }
        return best == current ? nil : best
    }

    /// Single-parity layouts on drives of 8 TB or more: a rebuild takes days,
    /// and a second failure during it loses the array. Returns the dual-parity
    /// level to suggest instead.
    func rebuildCautionSuggestion(for config: RaidConfiguration) -> RaidLevel? {
        guard validate(config) == nil else { return nil }
        let terabytes = config.unit == .tb ? config.driveSize : config.driveSize / 1000
        guard terabytes >= 8 else { return nil }
        let safer: RaidLevel
        switch config.level {
        case .raid5: return .raid6
        case .raid50: safer = .raid60
        case .raidz1: safer = .raidz2
        default: return nil
        }
        // Only a level the current groups are wide enough to become.
        return config.driveCount / groupCount(config) >= safer.minimumGroupWidth ? safer : nil
    }

    /// Group width when a RAID-Z group is wider than 12 drives, which rebuilds slowly.
    func wideZFSGroupWidth(for config: RaidConfiguration) -> Int? {
        guard config.level.isZFS, validate(config) == nil else { return nil }
        let width = config.driveCount / groupCount(config)
        return width > 12 ? width : nil
    }

    private func groupCount(_ config: RaidConfiguration) -> Int { max(config.groups, 1) }

    private func groupedValidationMessage(_ config: RaidConfiguration) -> String? {
        let level = config.level
        guard level.usesGroups else { return nil }
        let n = config.driveCount
        let groups = groupCount(config)
        if groups < level.minimumGroups, let single = level.singleGroupEquivalent {
            return String(format: "nested_needs_two_groups".localized(), level.displayName, single.displayName)
        }
        if n % groups != 0 {
            return String(format: "groups_uneven".localized(), n, groups)
        }
        if n / groups < level.minimumGroupWidth {
            return String(format: "group_too_narrow".localized(), level.displayName, level.minimumGroupWidth)
        }
        return nil
    }

    private func invalidDriveCountKey(_ config: RaidConfiguration) -> String? {
        let n = config.driveCount
        switch config.level {
        case .raid0: return n < 1 ? "raid0_validation" : nil
        case .raid1: return n < 2 ? "raid1_validation" : nil
        case .raid5: return n < 3 ? "raid5_validation" : nil
        case .raid6: return n < 4 ? "raid6_validation" : nil
        case .raid10: return n < 4 || n % 2 != 0 ? "raid10_validation" : nil
        case .jbod: return n < 1 ? "jbod_validation" : nil
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3: return nil
        }
    }

    func calculate(config: RaidConfiguration) -> RaidResult {
        let n = config.driveCount
        let size = config.driveSize  // assume already in chosen unit
        let warning = validate(config)

        var usable: Double
        var failures: String
        var roles: [DriveRole]
        var groupSize: Int?
        var zfsEstimate: ZFSEstimate?

        switch config.level {
        case .raid0:
            usable = Double(n) * size
            failures = "raid0_failures".localized()
            roles = Array(repeating: .data, count: n)
        case .raid1:
            usable = size
            failures = String(format: "raid1_failures".localized(), max(0, n - 1))
            roles = [.data] + Array(repeating: .mirror, count: max(0, n - 1))
        case .raid5:
            usable = Double(max(0, n - 1)) * size
            failures = "raid5_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 1)) + [.parity]
        case .raid6:
            usable = Double(max(0, n - 2)) * size
            failures = "raid6_failures".localized()
            roles = Array(repeating: .data, count: max(0, n - 2)) + Array(repeating: .parity, count: min(2, n))
        case .raid10:
            usable = Double(n / 2) * size
            failures = String(format: "raid10_failures".localized(), n / 2)
            // Mirrored pairs, striped: data, copy, data, copy…
            roles = (0..<n).map { $0.isMultiple(of: 2) ? .data : .mirror }
        case .jbod:
            usable = Double(n) * size
            failures = "jbod_failures".localized()
            roles = Array(repeating: .data, count: n)
        case .raid50, .raid60, .raidz1, .raidz2, .raidz3:
            let parity = config.level.parityPerGroup ?? 1
            let groups = groupCount(config)
            let width = n / groups
            usable = Double(groups * max(0, width - parity)) * size
            failures = groups > 1
                ? String(format: "grouped_failures".localized(), parity, groups * parity)
                : String(parity)
            // Each group's data drives, then its parity: data, data, parity | data, data, parity…
            roles = (0..<groups).flatMap { _ in
                Array(repeating: DriveRole.data, count: max(0, width - parity)) + Array(repeating: .parity, count: min(parity, width))
            }
            if warning == nil {
                if groups > 1 { groupSize = width }
                if config.level.isZFS {
                    let bytesPerUnit = config.unit == .tb ? 1e12 : 1e9
                    zfsEstimate = ZFSEstimate(groups: groups, width: width, parity: parity, driveBytes: size * bytesPerUnit)
                }
            }
        }

        // One bar per drive even when the drives don't divide into groups.
        if roles.count < n { roles += Array(repeating: .data, count: n - roles.count) }

        return RaidResult(
            usableCapacity: usable,
            rawCapacity: Double(n) * size,
            failuresTolerated: failures,
            speedRating: speedRating(for: config.level),
            availabilityRating: availabilityRating(for: config.level),
            warningMessage: warning,
            suggestedDriveCount: suggestedDriveCount(for: config),
            suggestedDriveCountGroups: suggestedDriveCountGroups(for: config),
            driveRoles: Array(roles.prefix(n)),
            groupSize: groupSize,
            suggestedGroups: suggestedGroups(for: config),
            zfsEstimate: zfsEstimate
        )
    }

    func speedRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0: return 5
        case .raid10, .raid50: return 4
        case .raid5, .raid60, .raidz1: return 3
        case .raid6, .raid1, .jbod, .raidz2, .raidz3: return 2
        }
    }

    func availabilityRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0, .jbod: return 1
        case .raid5, .raid50, .raidz1: return 3
        case .raid6, .raid60, .raidz2: return 4
        case .raid1, .raid10, .raidz3: return 5
        }
    }

    /// Word for a 1–5 rating, shared by the results and the info sheet.
    static func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "very_high".localized()
        case 4: return "high".localized()
        case 3: return "medium".localized()
        case 2: return "low".localized()
        case 1: return "very_low".localized()
        default: return ""
        }
    }
}
