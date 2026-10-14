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
        if let count = invalidDriveCountKey(config) {
            return count.localized()
        }
        if !(config.driveSize > 0) {
            return "drive_size_invalid".localized()
        }
        return nil
    }

    /// Nearest valid drive count at or above the current one, when the count
    /// is what makes the configuration invalid. Drives the one-tap fix.
    func suggestedDriveCount(for config: RaidConfiguration) -> Int? {
        let n = config.driveCount
        guard invalidDriveCountKey(config) != nil else { return nil }
        switch config.level {
        case .raid0, .jbod: return max(n, 1)
        case .raid1: return max(n, 2)
        case .raid5: return max(n, 3)
        case .raid6: return max(n, 4)
        case .raid10: return max(n + n % 2, 4)
        }
    }

    /// RAID 5 on drives of 8 TB or more: a rebuild takes days, and a second
    /// failure during it loses the array.
    func rebuildCaution(for config: RaidConfiguration) -> RebuildCaution? {
        guard validate(config) == nil, config.level == .raid5 else { return nil }
        let terabytes = config.unit == .tb ? config.driveSize : config.driveSize / 1000
        guard terabytes >= 8 else { return nil }
        // RAID 6 needs a fourth drive; below that, warn without a level to move to.
        var raid6 = config
        raid6.level = .raid6
        return validate(raid6) == nil ? .suggest(.raid6) : .warnOnly
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
        }
    }

    func calculate(config: RaidConfiguration) -> RaidResult {
        let n = config.driveCount
        let size = config.driveSize  // assume already in chosen unit

        var usable: Double
        var failures: String
        var roles: [DriveRole]

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
        }

        return RaidResult(
            usableCapacity: usable,
            rawCapacity: Double(n) * size,
            failuresTolerated: failures,
            speedRating: speedRating(for: config.level),
            availabilityRating: availabilityRating(for: config.level),
            warningMessage: validate(config),
            suggestedDriveCount: suggestedDriveCount(for: config),
            driveRoles: Array(roles.prefix(n))
        )
    }

    func speedRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0: return 5
        case .raid10: return 4
        case .raid5: return 3
        case .raid6, .raid1, .jbod: return 2
        }
    }

    func availabilityRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0, .jbod: return 1
        case .raid5: return 3
        case .raid6: return 4
        case .raid1, .raid10: return 5
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

enum RebuildCaution: Equatable {
    /// RAID 6, which this setup has the drives for.
    case suggest(RaidLevel)
    /// RAID 5 on three large drives: one short of RAID 6, so warn without a suggestion.
    case warnOnly
}
