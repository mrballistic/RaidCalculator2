//
//  AdaptiveLayoutTests.swift
//  RaidCalculator2Tests
//

import CoreGraphics
import Testing
@testable import RAID_Calc

struct AdaptiveLayoutTests {

    // Review Focus 3: regular width alone isn't enough room for two columns.
    @Test func twoColumnsNeedRegularWidthAndRoom() {
        #expect(AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 1032))   // 13-inch iPad, portrait
        #expect(AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 800))
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 744))   // iPad mini, portrait
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: true, width: 678))   // half of a 13-inch iPad
        #expect(!AdaptiveLayout.usesTwoColumns(isRegularWidth: false, width: 1200))
    }

    @Test func baysThatFitStayInOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 12, width: 480, minColumn: 24, spacing: 4, wrap: true) == [0..<12])
    }

    // 17 columns of 24 points fit in 480; 30 bays become two balanced rows of 15.
    @Test func tooManyBaysWrapIntoBalancedRows() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 480, minColumn: 24, spacing: 4, wrap: true) == [0..<15, 15..<30])
        #expect(AdaptiveLayout.bayRows(count: 13, width: 300, minColumn: 24, spacing: 4, wrap: true) == [0..<7, 7..<13])
        // One more than fits in a row (17) still splits evenly, not 17 and 1.
        #expect(AdaptiveLayout.bayRows(count: 18, width: 480, minColumn: 24, spacing: 4, wrap: true) == [0..<9, 9..<18])
    }

    @Test func withoutWrappingEveryBayIsOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 480, minColumn: 24, spacing: 4, wrap: false) == [0..<30])
    }

    // Review Focus 4: before layout the width is 0; never one bay per row.
    @Test func unknownWidthIsOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: 0, minColumn: 24, spacing: 4, wrap: true) == [0..<30])
    }

    // A width that isn't a number (an unbounded proposal) is one row, not a trap.
    @Test func nonFiniteWidthIsOneRow() {
        #expect(AdaptiveLayout.bayRows(count: 30, width: .infinity, minColumn: 24, spacing: 4, wrap: true) == [0..<30])
        #expect(AdaptiveLayout.bayRows(count: 30, width: .nan, minColumn: 24, spacing: 4, wrap: true) == [0..<30])
    }

    // A row per group only while the rows stay few; more groups keep one strip.
    @Test func driveGroupsBecomeRowsOnlyWhenFew() {
        #expect(!AdaptiveLayout.groupsAsRows(isRegularWidth: true, groupCount: 1))
        #expect(AdaptiveLayout.groupsAsRows(isRegularWidth: true, groupCount: 2))
        #expect(AdaptiveLayout.groupsAsRows(isRegularWidth: true, groupCount: 6))
        #expect(!AdaptiveLayout.groupsAsRows(isRegularWidth: true, groupCount: 7))
        #expect(!AdaptiveLayout.groupsAsRows(isRegularWidth: true, groupCount: 12))
        #expect(!AdaptiveLayout.groupsAsRows(isRegularWidth: false, groupCount: 3))
    }

    @Test func noBaysNoRows() {
        #expect(AdaptiveLayout.bayRows(count: 0, width: 480, minColumn: 24, spacing: 4, wrap: true).isEmpty)
    }
}
