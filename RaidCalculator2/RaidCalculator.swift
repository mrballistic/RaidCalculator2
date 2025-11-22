//
//  RaidCalculator.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation

struct RaidCalculator {
    
    func validate(_ config: RaidConfiguration) -> String? {
        let n = config.driveCount

        switch config.level {
        case .raid0:
            if n < 1 { return "RAID 0 requires at least 1 drive." }
        case .raid1:
            if n < 2 { return "RAID 1 requires at least 2 drives." }
        case .raid5:
            if n < 3 { return "RAID 5 requires at least 3 drives." }
        case .raid6:
            if n < 4 { return "RAID 6 requires at least 4 drives." }
        case .raid10:
            if n < 4 || n % 2 != 0 { return "RAID 10 requires an even number of drives (4 or more)." }
        case .jbod:
            if n < 1 { return "JBOD requires at least 1 drive." }
        }
        return nil
    }
    
    func calculate(config: RaidConfiguration) -> RaidResult {
        let n = config.driveCount
        let size = config.driveSize  // assume already in chosen unit

        var usable: Double
        var failures: String

        switch config.level {
        case .raid0:
            usable = Double(n) * size
            failures = "0"
        case .raid1:
            usable = size
            failures = "\(max(0, n - 1))"
        case .raid5:
            usable = Double(max(0, n - 1)) * size
            failures = "1"
        case .raid6:
            usable = Double(max(0, n - 2)) * size
            failures = "2"
        case .raid10:
            usable = Double(n / 2) * size
            failures = "Up to \(n / 2) (depends on which drives fail)"
        case .jbod:
            usable = Double(n) * size
            failures = "0 (you lose data on any failed drive)"
        }

        let speed = speedRating(for: config.level)
        let availability = availabilityRating(for: config.level)

        return RaidResult(
            usableCapacity: usable,
            failuresTolerated: failures,
            speedRating: speed,
            availabilityRating: availability,
            warningMessage: validate(config)
        )
    }
    
    private func speedRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0: return 5
        case .raid10: return 4
        case .raid5: return 3
        case .raid6, .raid1, .jbod: return 2
        }
    }

    private func availabilityRating(for level: RaidLevel) -> Int {
        switch level {
        case .raid0, .jbod: return 1
        case .raid5: return 3
        case .raid6: return 4
        case .raid1, .raid10: return 5
        }
    }
}
