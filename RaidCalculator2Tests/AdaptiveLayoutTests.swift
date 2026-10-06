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

    // MARK: Fold (iPhone Duo's division region), in the view's own x coordinates

    // Only a fold that runs top to bottom through the view splits it; one that
    // misses the view, or spans its whole width (a horizontal fold), doesn't.
    @Test func foldSpanIsAVerticalRegionInsideTheView() {
        #expect(AdaptiveLayout.foldSpan(in: [], width: 600) == nil)
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: 290, y: -40, width: 20, height: 900)], width: 600) == 290...310)
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: 700, y: 0, width: 20, height: 900)], width: 600) == nil)
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: -30, y: 0, width: 20, height: 900)], width: 600) == nil)
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: -10, y: 300, width: 620, height: 20)], width: 600) == nil)
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: 290, y: 0, width: 20, height: 900)], width: 0) == nil)
        // The first region that splits the view wins.
        #expect(AdaptiveLayout.foldSpan(in: [CGRect(x: 900, y: 0, width: 20, height: 900),
                                             CGRect(x: 100, y: 0, width: 24, height: 900)], width: 600) == 100...124)
    }

    // HIG: prefer an even number of columns so content divides cleanly.
    @Test func evenColumnsAreTwoOrFour() {
        #expect(AdaptiveLayout.evenColumns(maxFitting: 0) == nil)
        #expect(AdaptiveLayout.evenColumns(maxFitting: 1) == nil)
        #expect(AdaptiveLayout.evenColumns(maxFitting: 2) == 2)
        #expect(AdaptiveLayout.evenColumns(maxFitting: 3) == 2)
        #expect(AdaptiveLayout.evenColumns(maxFitting: 4) == 4)
        #expect(AdaptiveLayout.evenColumns(maxFitting: 9) == 4)
    }

    @Test func noFoldKeepsTodaysGrid() {
        #expect(AdaptiveLayout.foldGrid(width: 600, minColumn: 96, spacing: 12, fold: nil) == nil)
    }

    @Test func foldOutsideTheGridKeepsTodaysGrid() {
        #expect(AdaptiveLayout.foldGrid(width: 600, minColumn: 96, spacing: 12, fold: 620...640) == nil)
        #expect(AdaptiveLayout.foldGrid(width: 600, minColumn: 96, spacing: 12, fold: -40 ... -20) == nil)
    }

    // 470 a side fits four 96-point columns, so two a side; the split gap
    // lands the right half exactly at the fold's far edge.
    @Test func foldThroughTheGridSplitsAnEvenCount() throws {
        let grid = try #require(AdaptiveLayout.foldGrid(width: 960, minColumn: 96, spacing: 12, fold: 470...490))
        #expect(grid.columns == 4)
        #expect(grid.foldGap >= 20)
        let leftHalf = 2 * grid.columnWidth + 12
        #expect(leftHalf <= 470)
        #expect(leftHalf + grid.foldGap == 490)
        #expect(leftHalf + grid.foldGap + leftHalf <= 960)
    }

    // 200 a side fits one column each: two columns, still even.
    @Test func narrowFoldedGridHasTwoColumns() throws {
        let grid = try #require(AdaptiveLayout.foldGrid(width: 420, minColumn: 96, spacing: 12, fold: 200...220))
        #expect(grid.columns == 2)
        #expect(grid.columnWidth == 200)
        #expect(grid.foldGap == 20)
    }

    // Off-centre fold: columns sized by the narrower side, gap still covers the fold.
    @Test func offCentreFoldSizesColumnsByTheNarrowerSide() throws {
        let grid = try #require(AdaptiveLayout.foldGrid(width: 700, minColumn: 96, spacing: 12, fold: 400...420))
        #expect(grid.columns == 4)
        #expect(grid.columnWidth == 134)   // (280 - 12) / 2
        #expect(grid.foldGap == 140)   // the fold's far edge (420) less the 280-point leading half
        #expect(grid.foldGap >= 20)
    }

    @Test func foldLeavingNoRoomOnOneSideKeepsTodaysGrid() {
        #expect(AdaptiveLayout.foldGrid(width: 600, minColumn: 96, spacing: 12, fold: 50...70) == nil)
        #expect(AdaptiveLayout.foldGrid(width: 600, minColumn: 96, spacing: 12, fold: 530...550) == nil)
    }

    @Test func noFoldKeepsTodaysBays() {
        #expect(AdaptiveLayout.foldBays(count: 12, width: 600, minColumn: 24, spacing: 4, wrap: true, fold: nil) == nil)
        #expect(AdaptiveLayout.foldBays(count: 12, width: 600, minColumn: 24, spacing: 4, wrap: true, fold: 700...720) == nil)
    }

    @Test func evenBaysSplitInHalfAtTheFold() {
        #expect(AdaptiveLayout.foldBays(count: 12, width: 600, minColumn: 24, spacing: 4, wrap: true, fold: 290...310)
                == .init(leading: [0..<6], trailing: [6..<12]))
    }

    // The odd bay goes to the leading half.
    @Test func oddBaysPutTheExtraOneFirst() {
        #expect(AdaptiveLayout.foldBays(count: 5, width: 600, minColumn: 24, spacing: 4, wrap: false, fold: 290...310)
                == .init(leading: [0..<3], trailing: [3..<5]))
    }

    // Each half wraps within its own side: 150 points fits five 24-point bays.
    @Test func eachHalfWrapsWithinItsSide() {
        #expect(AdaptiveLayout.foldBays(count: 24, width: 320, minColumn: 24, spacing: 4, wrap: true, fold: 150...170)
                == .init(leading: [0..<4, 4..<8, 8..<12], trailing: [12..<16, 16..<20, 20..<24]))
    }

    @Test func foldLeavingTooLittleRoomKeepsTodaysBays() {
        // Nothing fits left of the fold.
        #expect(AdaptiveLayout.foldBays(count: 12, width: 600, minColumn: 24, spacing: 4, wrap: true, fold: 10...30) == nil)
        // Without wrapping, a half that overflows its side would have to scroll.
        #expect(AdaptiveLayout.foldBays(count: 30, width: 320, minColumn: 24, spacing: 4, wrap: false, fold: 150...170) == nil)
        // One bay can't be split.
        #expect(AdaptiveLayout.foldBays(count: 1, width: 600, minColumn: 24, spacing: 4, wrap: true, fold: 290...310) == nil)
    }
}
