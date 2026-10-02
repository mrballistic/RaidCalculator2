//
//  SynologyViewModel.swift
//  RaidCalculator2
//

import Foundation
import SwiftUI

@Observable
final class SynologyViewModel {
    /// Sizes offered in each bay's menu, in TB. NAS drives are sold in these.
    static let commonSizes: [Double] = [1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]

    var modelID: String = "DS925+" { didSet { fitBaysToModel(); save() } }
    var customBayCount: Int = 4 { didSet { fitBaysToModel(); save() } }
    var bays: [Double?] = [4, 4, 8, 8] { didSet { save() } }
    var raidType: SynologyRaidType = .shr1 { didSet { save() } }

    /// The setup the owner has today. Every change is compared against it, so
    /// “what if I buy this drive?” reads as a difference, not a new total.
    private(set) var currentBays: [Double?] = [4, 4, 8, 8]
    private(set) var currentRaidType: SynologyRaidType = .shr1

    var bayCount: Int {
        if modelID == SynologyModel.custom { return customBayCount }
        return SynologyModel.presets.first { $0.id == modelID }?.bays ?? 4
    }

    var result: SynologyResult { calculator.calculate(bays: bays, type: raidType) }
    var suggestion: SynologySuggestion? { calculator.suggestion(bays: bays, type: raidType) }

    var differsFromCurrent: Bool { bays != currentBays || raidType != currentRaidType }

    /// Usable-capacity change against the current setup; nil when nothing changed.
    var usableDelta: Double? {
        guard differsFromCurrent else { return nil }
        let before = calculator.calculate(bays: currentBays, type: currentRaidType)
        return result.usableCapacity - before.usableCapacity
    }

    @ObservationIgnored private let calculator = SynologyCalculator()
    @ObservationIgnored private let userDefaults = UserDefaults.standard
    @ObservationIgnored private var isLoading = false

    private enum Keys {
        static let model = "synology.model"
        static let customBayCount = "synology.customBayCount"
        static let bays = "synology.bays"
        static let raidType = "synology.raidType"
        static let currentBays = "synology.currentBays"
        static let currentRaidType = "synology.currentRaidType"
    }

    init() {
        load()
        fitBaysToModel()
    }

    func setSize(_ size: Double?, forBay index: Int) {
        guard bays.indices.contains(index) else { return }
        bays[index] = size.map { min(max($0, 0.1), 999) }
    }

    func applySuggestion() {
        guard let suggestion else { return }
        switch suggestion.kind {
        case .add(let bay), .replace(let bay, _):
            setSize(suggestion.size, forBay: bay)
        }
    }

    func revertToCurrent() {
        isLoading = true
        raidType = currentRaidType
        bays = currentBays
        isLoading = false
        fitBaysToModel()
        save()
    }

    func saveAsCurrent() {
        currentBays = bays
        currentRaidType = raidType
        save()
    }

    private func fitBaysToModel() {
        guard !isLoading else { return }
        let count = bayCount
        if bays.count < count {
            bays += Array(repeating: nil, count: count - bays.count)
        } else if bays.count > count {
            bays = Array(bays.prefix(count))
        }
        if currentBays.count != count {
            currentBays = currentBays.count < count
                ? currentBays + Array(repeating: nil, count: count - currentBays.count)
                : Array(currentBays.prefix(count))
        }
    }

    private func save() {
        guard !isLoading else { return }
        userDefaults.set(modelID, forKey: Keys.model)
        userDefaults.set(customBayCount, forKey: Keys.customBayCount)
        userDefaults.set(raidType.rawValue, forKey: Keys.raidType)
        userDefaults.set(currentRaidType.rawValue, forKey: Keys.currentRaidType)
        userDefaults.set(try? JSONEncoder().encode(bays), forKey: Keys.bays)
        userDefaults.set(try? JSONEncoder().encode(currentBays), forKey: Keys.currentBays)
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        if let model = userDefaults.string(forKey: Keys.model) { modelID = model }
        let custom = userDefaults.integer(forKey: Keys.customBayCount)
        if SynologyModel.customBayRange.contains(custom) { customBayCount = custom }
        if let type = userDefaults.string(forKey: Keys.raidType).flatMap(SynologyRaidType.init) { raidType = type }
        if let type = userDefaults.string(forKey: Keys.currentRaidType).flatMap(SynologyRaidType.init) { currentRaidType = type }
        if let data = userDefaults.data(forKey: Keys.bays),
           let saved = try? JSONDecoder().decode([Double?].self, from: data) { bays = saved }
        if let data = userDefaults.data(forKey: Keys.currentBays),
           let saved = try? JSONDecoder().decode([Double?].self, from: data) { currentBays = saved }
    }
}
