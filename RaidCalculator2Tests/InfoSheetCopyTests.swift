//
//  InfoSheetCopyTests.swift
//  RaidCalculator2Tests
//

import Testing
@testable import RAID_Calc

struct InfoSheetCopyTests {

    @Test(arguments: RaidLevel.allCases)
    func everyLevelHasItsSheetCopy(level: RaidLevel) {
        for field in ["description", "pros", "cons", "use_cases"] {
            let key = "\(level.stringKeyPrefix)_\(field)"
            #expect(key.localized() != key, "missing \(key)")
        }
    }

    @Test(arguments: [RaidLevel.raidz1, .raidz2, .raidz3])
    func zfsLevelsExplainTheEstimate(level: RaidLevel) {
        let key = "\(level.stringKeyPrefix)_calculation"
        #expect(key.localized().contains("128 GiB"), "missing or wrong \(key)")
    }

    @Test(arguments: [NASSystem.synology, .unraid, .zfs, .snapraid, .btrfs])
    func everySystemHasItsSheetCopy(system: NASSystem) {
        for field in ["description", "pros", "cons", "use_cases", "calculation"] {
            let key = "\(system.stringKeyPrefix)_\(field)"
            #expect(key.localized() != key, "missing \(key)")
        }
        if let footnote = system.notAffiliatedKey {
            #expect(footnote.localized() != footnote, "missing \(footnote)")
        }
    }

    @Test func snapraidSheetSaysProtectionIsOnlyAsCurrentAsTheLastSync() {
        #expect("snapraid_cons".localized().contains("last sync"))
    }

    // Final review M7
    @Test func zfsSheetExplainsTheReservation() {
        #expect("zfs_calculation".localized().contains("128 GiB"))
    }
}
