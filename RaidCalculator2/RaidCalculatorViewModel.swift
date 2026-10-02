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
    static let driveCountRange = 1...24
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

    /// Recomputed whenever an input changes; Observation tracks the reads.
    var result: RaidResult {
        calculator.calculate(config: RaidConfiguration(
            level: selectedLevel,
            driveCount: driveCount,
            driveSize: driveSize,
            unit: unit
        ))
    }

    /// RAID 5 on big drives: rebuilds take long enough that a second failure
    /// during one is a real risk, which is the caution home-lab builders need.
    var showsRebuildCaution: Bool {
        guard selectedLevel == .raid5, result.warningMessage == nil else { return false }
        let terabytes = unit == .tb ? driveSize : driveSize / 1000
        return terabytes >= 8
    }

    @ObservationIgnored private let calculator = RaidCalculator()
    @ObservationIgnored private let userDefaults = UserDefaults.standard
    @ObservationIgnored private var isLoading = false

    private struct Keys {
        static let selectedLevel = "selectedLevel"
        static let driveCount = "driveCount"
        static let driveSize = "driveSize"
        static let unit = "unit"
    }

    init() {
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
