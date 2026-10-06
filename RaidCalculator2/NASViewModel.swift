//
//  NASViewModel.swift
//  RaidCalculator2
//

import Foundation
import SwiftUI

@Observable
final class NASViewModel {
    /// Sizes offered in each bay's menu, in TB. NAS drives are sold in these.
    static let commonSizes: [Double] = [1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]

    /// The system reading the drives. Switching never deletes drives: a system
    /// with fewer bays shows the first ones and hides the rest until you switch back.
    var system: NASSystem = .synology { didSet { save() } }
    var settings = NASSettings() { didSet { save() } }

    /// Every bay the user has set up, including any the current system hides.
    private var allBays: [Double?] = [4, 4, 8, 8] { didSet { save() } }
    /// Bays the user asked for, before the system's limit applies.
    private var requestedBayCount = 4 { didSet { save() } }

    /// The setup the owner has today. Every change is compared against it, so
    /// “what if I buy this drive?” reads as a difference, not a new total.
    private(set) var current = NASSetup(system: .synology, bays: [4, 4, 8, 8], settings: NASSettings())

    var bayCount: Int { min(max(requestedBayCount, system.bayRange.lowerBound), system.bayRange.upperBound) }
    var bays: [Double?] { bays(for: system) }

    /// What `system` reads of the drives: the first bays up to its limit, the
    /// same rule as switching to it.
    func bays(for system: NASSystem) -> [Double?] {
        let count = min(max(requestedBayCount, system.bayRange.lowerBound), system.bayRange.upperBound)
        return Array(allBays.prefix(count)) + Array(repeating: nil, count: max(0, count - allBays.count))
    }
    var setup: NASSetup { NASSetup(system: system, bays: bays, settings: settings) }

    var result: BayResult { calculator.calculate(setup) }
    var suggestion: BaySuggestion? { calculator.suggestion(setup) }
    var hints: [NASHint] { calculator.hints(setup) }

    /// The same drives under every system, each with its own setting (FR-13).
    var comparison: [NASComparison] {
        calculator.compare(
            NASSystem.allCases.map { NASSetup(system: $0, bays: bays(for: $0), settings: settings) },
            requestedBayCount: requestedBayCount,
            shownBayCount: bayCount
        )
    }

    var differsFromCurrent: Bool { !setup.isEquivalent(to: current) }

    /// Usable-capacity change against the current setup; nil when nothing changed.
    var usableDelta: Double? {
        guard differsFromCurrent else { return nil }
        return result.usableCapacity - calculator.calculate(current).usableCapacity
    }

    @ObservationIgnored private let calculator = NASCalculator()
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var isLoading = false

    private enum Keys {
        static let bays = "synology.bays"
        static let system = "nas.system"
        static let bayCount = "nas.bayCount"
        static let settings = "nas.settings"
        static let currentSetup = "nas.currentSetup"
        // Read only as fallbacks, from before the NAS tab.
        static let legacyRaidType = "synology.raidType"
        static let legacyCurrentBays = "synology.currentBays"
        static let legacyCurrentRaidType = "synology.currentRaidType"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    /// Lowering the count trims bays from the end; it's an explicit choice,
    /// unlike switching systems.
    func setBayCount(_ count: Int) {
        let clamped = min(max(count, system.bayRange.lowerBound), system.bayRange.upperBound)
        if clamped < allBays.count { allBays = Array(allBays.prefix(clamped)) }
        requestedBayCount = clamped
    }

    func setSize(_ size: Double?, forBay index: Int) {
        guard index >= 0, index < bayCount else { return }
        if allBays.count <= index { allBays += Array(repeating: nil, count: index + 1 - allBays.count) }
        allBays[index] = size.map { min(max($0, 0.1), 999) }
    }

    func applySuggestion() {
        guard let suggestion else { return }
        switch suggestion.kind {
        case .add(let bay), .replace(let bay, _):
            setSize(suggestion.size, forBay: bay)
        }
    }

    func saveAsCurrent() {
        current = setup
        save()
    }

    func revertToCurrent() {
        isLoading = true
        system = current.system
        settings = current.settings
        allBays = current.bays
        requestedBayCount = current.bays.count
        isLoading = false
        save()
    }

    private func save() {
        guard !isLoading else { return }
        userDefaults.set(try? JSONEncoder().encode(allBays), forKey: Keys.bays)
        userDefaults.set(system.rawValue, forKey: Keys.system)
        userDefaults.set(requestedBayCount, forKey: Keys.bayCount)
        userDefaults.set(try? JSONEncoder().encode(settings), forKey: Keys.settings)
        userDefaults.set(try? JSONEncoder().encode(current), forKey: Keys.currentSetup)
    }

    /// Stored parity can be out of range if the data was corrupted or edited;
    /// pull each back into its system's range so the calculator never sees it.
    private static func clamped(_ settings: NASSettings) -> NASSettings {
        var result = settings
        for system in NASSystem.allCases {
            guard let range = system.parityRange, let value = result.parity(for: system) else { continue }
            result.setParity(min(max(value, range.lowerBound), range.upperBound), for: system)
        }
        return result
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        if let data = userDefaults.data(forKey: Keys.bays),
           let saved = try? JSONDecoder().decode([Double?].self, from: data) { allBays = saved }
        if let raw = userDefaults.string(forKey: Keys.system), let saved = NASSystem(rawValue: raw) { system = saved }

        if let data = userDefaults.data(forKey: Keys.settings),
           let saved = try? JSONDecoder().decode(NASSettings.self, from: data) {
            settings = Self.clamped(saved)
        } else if let type = userDefaults.string(forKey: Keys.legacyRaidType).flatMap(SynologyRaidType.init) {
            settings.synologyType = type
        }

        let storedCount = userDefaults.integer(forKey: Keys.bayCount)
        requestedBayCount = storedCount > 0 ? storedCount : allBays.count

        if let data = userDefaults.data(forKey: Keys.currentSetup),
           let saved = try? JSONDecoder().decode(NASSetup.self, from: data) {
            current = saved
            current.settings = Self.clamped(saved.settings)
        } else {
            var legacy = NASSetup(system: system, bays: bays, settings: settings)
            if let data = userDefaults.data(forKey: Keys.legacyCurrentBays),
               let saved = try? JSONDecoder().decode([Double?].self, from: data) { legacy.bays = saved }
            if let type = userDefaults.string(forKey: Keys.legacyCurrentRaidType).flatMap(SynologyRaidType.init) {
                legacy.settings.synologyType = type
            }
            current = legacy
        }
    }
}
