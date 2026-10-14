//
//  RaidCalculatorViewModel.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation
import SwiftUI

@Observable
final class RaidCalculatorViewModel {
    static let driveCountRange = RaidCalculator.driveCountRange
    /// Upper bound for a single drive, in either unit. Keeps a stray paste from
    /// producing a capacity no layout can hold.
    static let maxDriveSize = 999_999.0

    var selectedLevel: RaidLevel = .raid5 { didSet { saveConfiguration() } }
    var driveCount: Int = 4 {
        didSet {
            let clamped = min(max(driveCount, Self.driveCountRange.lowerBound), Self.driveCountRange.upperBound)
            if clamped != driveCount { driveCount = clamped } else { saveConfiguration() }
        }
    }
    var driveSize: Double = 4 {
        didSet {
            if driveSize > Self.maxDriveSize { driveSize = Self.maxDriveSize } else { saveConfiguration() }
        }
    }
    var unit: CapacityUnit = .tb { didSet { saveConfiguration() } }

    private var configuration: RaidConfiguration {
        RaidConfiguration(level: selectedLevel, driveCount: driveCount, driveSize: driveSize, unit: unit)
    }

    /// Recomputed whenever an input changes; Observation tracks the reads.
    var result: RaidResult { calculator.calculate(config: configuration) }

    /// RAID 5 on drives of 8 TB or more: a suggested level, or a bare warning.
    var rebuildCaution: RebuildCaution? { calculator.rebuildCaution(for: configuration) }

    @ObservationIgnored private let calculator = RaidCalculator()
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var isLoading = false

    private struct Keys {
        static let selectedLevel = "selectedLevel"
        static let driveCount = "driveCount"
        static let driveSize = "driveSize"
        static let unit = "unit"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadConfiguration()
    }

    func applySuggestedDriveCount() {
        if let suggested = result.suggestedDriveCount {
            driveCount = suggested
        }
    }

    private func saveConfiguration() {
        guard !isLoading else { return }
        userDefaults.set(selectedLevel.rawValue, forKey: Keys.selectedLevel)
        userDefaults.set(driveCount, forKey: Keys.driveCount)
        userDefaults.set(driveSize, forKey: Keys.driveSize)
        userDefaults.set(unit.rawValue, forKey: Keys.unit)
    }

    private func loadConfiguration() {
        isLoading = true
        defer { isLoading = false }

        // A level a newer build saved (RAID 50, RAID-Z…) matches nothing here,
        // so the default, RAID 5, stays.
        if let levelString = userDefaults.string(forKey: Keys.selectedLevel),
           let level = RaidLevel.allCases.first(where: { $0.rawValue == levelString }) {
            selectedLevel = level
        }

        driveCount = userDefaults.integer(forKey: Keys.driveCount)
        if driveCount == 0 { driveCount = 4 }

        driveSize = userDefaults.double(forKey: Keys.driveSize)
        if driveSize == 0 { driveSize = 4 }

        if let unitString = userDefaults.string(forKey: Keys.unit),
           let loadedUnit = CapacityUnit.allCases.first(where: { $0.rawValue == unitString }) {
            unit = loadedUnit
        }
    }
}
