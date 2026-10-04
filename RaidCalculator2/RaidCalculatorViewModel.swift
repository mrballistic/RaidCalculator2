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

    /// Striped groups for RAID 50/60 and RAID-Z. Kept when switching to a
    /// standard level, which ignores it, so switching back restores the layout.
    var groups: Int = 1 {
        didSet {
            let clamped = min(max(groups, 1), Self.driveCountRange.upperBound)
            if clamped != groups { groups = clamped } else { saveConfiguration() }
        }
    }

    private var configuration: RaidConfiguration {
        RaidConfiguration(level: selectedLevel, driveCount: driveCount, driveSize: driveSize, unit: unit, groups: groups)
    }

    /// Recomputed whenever an input changes; Observation tracks the reads.
    var result: RaidResult { calculator.calculate(config: configuration) }

    /// Single parity on drives of 8 TB or more; the dual-parity level to suggest.
    var rebuildCautionSuggestion: RaidLevel? { calculator.rebuildCautionSuggestion(for: configuration) }

    /// Width of a RAID-Z group wider than 12 drives; nil otherwise.
    var wideZFSGroupWidth: Int? { calculator.wideZFSGroupWidth(for: configuration) }

    @ObservationIgnored private let calculator = RaidCalculator()
    @ObservationIgnored private let userDefaults = UserDefaults.standard
    @ObservationIgnored private var isLoading = false

    private struct Keys {
        static let selectedLevel = "selectedLevel"
        static let driveCount = "driveCount"
        static let driveSize = "driveSize"
        static let unit = "unit"
        static let groups = "groups"
    }

    init() {
        loadConfiguration()
    }

    /// Applies the drive-count fix, with the groups it assumes when those
    /// change too, in one change so it animates as one transition.
    func applySuggestedDriveCount() {
        let result = result
        guard let suggested = result.suggestedDriveCount else { return }
        driveCount = suggested
        if let groups = result.suggestedDriveCountGroups {
            self.groups = groups
        }
    }

    func applySuggestedGroups() {
        if let suggested = result.suggestedGroups {
            groups = suggested
        }
    }

    private func saveConfiguration() {
        guard !isLoading else { return }
        userDefaults.set(selectedLevel.rawValue, forKey: Keys.selectedLevel)
        userDefaults.set(driveCount, forKey: Keys.driveCount)
        userDefaults.set(driveSize, forKey: Keys.driveSize)
        userDefaults.set(unit.rawValue, forKey: Keys.unit)
        userDefaults.set(groups, forKey: Keys.groups)
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

        groups = userDefaults.integer(forKey: Keys.groups)
        if groups == 0 { groups = 1 }
    }
}
