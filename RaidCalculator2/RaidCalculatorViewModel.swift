//
//  RaidCalculatorViewModel.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import Foundation
import SwiftUI

final class RaidCalculatorViewModel: ObservableObject {
    @Published var selectedLevel: RaidLevel = .raid5
    @Published var driveCount: Int = 4
    @Published var driveSize: Double = 4
    @Published var unit: CapacityUnit = .tb

    @Published private(set) var result: RaidResult?

    private let calculator = RaidCalculator()
    private let userDefaults = UserDefaults.standard
    
    private struct Keys {
        static let selectedLevel = "selectedLevel"
        static let driveCount = "driveCount"
        static let driveSize = "driveSize"
        static let unit = "unit"
    }

    init() {
        loadConfiguration()
        recalculate()
    }

    func recalculate() {
        let config = RaidConfiguration(
            level: selectedLevel,
            driveCount: driveCount,
            driveSize: driveSize,
            unit: unit
        )
        result = calculator.calculate(config: config)
        saveConfiguration()
    }
    
    private func saveConfiguration() {
        userDefaults.set(selectedLevel.rawValue, forKey: Keys.selectedLevel)
        userDefaults.set(driveCount, forKey: Keys.driveCount)
        userDefaults.set(driveSize, forKey: Keys.driveSize)
        userDefaults.set(unit.rawValue, forKey: Keys.unit)
    }
    
    private func loadConfiguration() {
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
