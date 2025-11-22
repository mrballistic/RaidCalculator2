//
//  RaidCalculator2Tests.swift
//  RaidCalculator2Tests
//
//  Created by todd.greco on 11/22/25.
//

import Testing
@testable import RaidCalculator2

struct RaidCalculator2Tests {

    let calculator = RaidCalculator()

    @Test func testRAID0Calculations() async throws {
        let config = RaidConfiguration(
            level: .raid0,
            driveCount: 4,
            driveSize: 2,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 8.0)
        #expect(result.failuresTolerated == "0")
        #expect(result.speedRating == 5)
        #expect(result.availabilityRating == 1)
        #expect(result.warningMessage == nil)
    }

    @Test func testRAID1Calculations() async throws {
        let config = RaidConfiguration(
            level: .raid1,
            driveCount: 4,
            driveSize: 2,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 2.0)
        #expect(result.failuresTolerated == "3")
        #expect(result.speedRating == 2)
        #expect(result.availabilityRating == 5)
        #expect(result.warningMessage == nil)
    }

    @Test func testRAID5Calculations() async throws {
        let config = RaidConfiguration(
            level: .raid5,
            driveCount: 5,
            driveSize: 4,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 16.0)
        #expect(result.failuresTolerated == "1")
        #expect(result.speedRating == 3)
        #expect(result.availabilityRating == 3)
        #expect(result.warningMessage == nil)
    }

    @Test func testRAID6Calculations() async throws {
        let config = RaidConfiguration(
            level: .raid6,
            driveCount: 6,
            driveSize: 3,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 12.0)
        #expect(result.failuresTolerated == "2")
        #expect(result.speedRating == 2)
        #expect(result.availabilityRating == 4)
        #expect(result.warningMessage == nil)
    }

    @Test func testRAID10Calculations() async throws {
        let config = RaidConfiguration(
            level: .raid10,
            driveCount: 8,
            driveSize: 2,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 8.0)
        #expect(result.failuresTolerated == "Up to 4 (depends on which drives fail)")
        #expect(result.speedRating == 4)
        #expect(result.availabilityRating == 5)
        #expect(result.warningMessage == nil)
    }

    @Test func testJBODCalculations() async throws {
        let config = RaidConfiguration(
            level: .jbod,
            driveCount: 3,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 3.0)
        #expect(result.failuresTolerated == "0 (you lose data on any failed drive)")
        #expect(result.speedRating == 2)
        #expect(result.availabilityRating == 1)
        #expect(result.warningMessage == nil)
    }

    @Test func testValidationRAID0Invalid() async throws {
        let config = RaidConfiguration(
            level: .raid0,
            driveCount: 0,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 0 requires at least 1 drive.")
    }

    @Test func testValidationRAID1Invalid() async throws {
        let config = RaidConfiguration(
            level: .raid1,
            driveCount: 1,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 1 requires at least 2 drives.")
    }

    @Test func testValidationRAID5Invalid() async throws {
        let config = RaidConfiguration(
            level: .raid5,
            driveCount: 2,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 5 requires at least 3 drives.")
    }

    @Test func testValidationRAID6Invalid() async throws {
        let config = RaidConfiguration(
            level: .raid6,
            driveCount: 3,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 6 requires at least 4 drives.")
    }

    @Test func testValidationRAID10InvalidOddDrives() async throws {
        let config = RaidConfiguration(
            level: .raid10,
            driveCount: 5,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 10 requires an even number of drives (4 or more).")
    }

    @Test func testValidationRAID10InvalidTooFew() async throws {
        let config = RaidConfiguration(
            level: .raid10,
            driveCount: 2,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "RAID 10 requires an even number of drives (4 or more).")
    }

    @Test func testValidationJBODInvalid() async throws {
        let config = RaidConfiguration(
            level: .jbod,
            driveCount: 0,
            driveSize: 1,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.warningMessage == "JBOD requires at least 1 drive.")
    }

    @Test func testDecimalDriveSizes() async throws {
        let config = RaidConfiguration(
            level: .raid5,
            driveCount: 4,
            driveSize: 2.5,
            unit: .tb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 7.5)
        #expect(result.warningMessage == nil)
    }

    @Test func testGBUnits() async throws {
        let config = RaidConfiguration(
            level: .raid0,
            driveCount: 3,
            driveSize: 500,
            unit: .gb
        )
        
        let result = calculator.calculate(config: config)
        
        #expect(result.usableCapacity == 1500.0)
        #expect(result.warningMessage == nil)
    }

    @Test func testMinimumValidConfigurations() async throws {
        let raid0Config = RaidConfiguration(level: .raid0, driveCount: 1, driveSize: 1, unit: .tb)
        let raid1Config = RaidConfiguration(level: .raid1, driveCount: 2, driveSize: 1, unit: .tb)
        let raid5Config = RaidConfiguration(level: .raid5, driveCount: 3, driveSize: 1, unit: .tb)
        let raid6Config = RaidConfiguration(level: .raid6, driveCount: 4, driveSize: 1, unit: .tb)
        let raid10Config = RaidConfiguration(level: .raid10, driveCount: 4, driveSize: 1, unit: .tb)
        let jbodConfig = RaidConfiguration(level: .jbod, driveCount: 1, driveSize: 1, unit: .tb)
        
        let raid0Result = calculator.calculate(config: raid0Config)
        let raid1Result = calculator.calculate(config: raid1Config)
        let raid5Result = calculator.calculate(config: raid5Config)
        let raid6Result = calculator.calculate(config: raid6Config)
        let raid10Result = calculator.calculate(config: raid10Config)
        let jbodResult = calculator.calculate(config: jbodConfig)
        
        #expect(raid0Result.warningMessage == nil)
        #expect(raid1Result.warningMessage == nil)
        #expect(raid5Result.warningMessage == nil)
        #expect(raid6Result.warningMessage == nil)
        #expect(raid10Result.warningMessage == nil)
        #expect(jbodResult.warningMessage == nil)
    }
}
