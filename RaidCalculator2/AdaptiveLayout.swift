//
//  AdaptiveLayout.swift
//  RaidCalculator2
//
//  Size-class decisions both tabs share, kept pure so they can be tested.
//

import CoreGraphics

enum AdaptiveLayout {
    /// Narrowest window that puts results and inputs side by side. A regular
    /// size class alone isn't enough: iPad mini in portrait (744 points) and
    /// half of a 13-inch iPad are regular, but two columns there would each
    /// be narrower than an iPhone.
    static let twoColumnMinWidth: CGFloat = 800

    static func usesTwoColumns(isRegularWidth: Bool, width: CGFloat) -> Bool {
        isRegularWidth && width >= twoColumnMinWidth
    }

    /// The bays in each row of a bay diagram. One row when the bays fit at
    /// `minColumn` each, when wrapping is off, or before the width is known
    /// (zero, or not a finite number); otherwise as few rows as fit, with the
    /// bays shared out evenly.
    static func bayRows(count: Int, width: CGFloat, minColumn: CGFloat, spacing: CGFloat, wrap: Bool) -> [Range<Int>] {
        guard count > 0 else { return [] }
        guard wrap, width.isFinite, width > 0 else { return [0..<count] }
        let perRow = max(1, Int((width + spacing) / (minColumn + spacing)))
        guard count > perRow else { return [0..<count] }
        let rowCount = (count + perRow - 1) / perRow
        let size = (count + rowCount - 1) / rowCount
        return stride(from: 0, to: count, by: size).map { $0..<min($0 + size, count) }
    }

    /// Whether the RAID tab's drive strip gives each group its own row: at
    /// regular width, for two to six groups. Past six the rows stack too tall
    /// (twelve groups is about 420 points), so the strip stays inline.
    static func groupsAsRows(isRegularWidth: Bool, groupCount: Int) -> Bool {
        isRegularWidth && (2...6).contains(groupCount)
    }

    // MARK: Fold
    //
    // iPhone Duo's fold reaches SwiftUI (iOS 27.1) as a `.division` reserved
    // region whose frame is already in the querying view's own coordinate
    // space, mirrored for right-to-left. The views read it and hand these
    // helpers plain x spans, so the decisions test on any OS. Every helper
    // returns nil for "lay out as today".

    /// The x span of the first region that runs top to bottom through a view
    /// `width` points wide: it must start or end strictly inside the view. A
    /// region that misses the view, or spans its whole width (a horizontal
    /// fold, which splits rows rather than columns), is not a fold here.
    /// Nonisolated: it runs in the geometry reader, off the main actor.
    nonisolated static func foldSpan(in frames: [CGRect], width: CGFloat) -> ClosedRange<CGFloat>? {
        guard width.isFinite, width > 0 else { return nil }
        for frame in frames where frame.width.isFinite && frame.width >= 0 {
            let splits = (frame.minX > 0 && frame.minX < width) || (frame.maxX > 0 && frame.maxX < width)
            if splits { return frame.minX...frame.maxX }
        }
        return nil
    }

    /// The most columns that divide evenly at a fold: 4 or 2, nil below 2.
    /// HIG: “In a grid-style layout, prefer an even number of columns so
    /// content divides cleanly.” Four is enough for the five systems.
    static func evenColumns(maxFitting: Int) -> Int? {
        if maxFitting >= 4 { return 4 }
        if maxFitting >= 2 { return 2 }
        return nil
    }

    /// A grid split by a fold: `columns` of `columnWidth`, half on each side,
    /// with `foldGap` (in place of the usual spacing) after the leading half.
    struct FoldGrid: Equatable {
        var columns: Int
        var columnWidth: CGFloat
        var foldGap: CGFloat
    }

    /// Fixed columns for a grid `width` points wide with a fold at `fold`
    /// (local x), laid out from the leading edge. The columns take the
    /// narrower side's width, so the leading half ends at or before the fold
    /// and the gap always starts the trailing half at the fold's far edge.
    /// Nil, for today's adaptive grid, with no fold through the grid or too
    /// little room for a `minColumn` column on either side.
    static func foldGrid(width: CGFloat, minColumn: CGFloat, spacing: CGFloat, fold: ClosedRange<CGFloat>?) -> FoldGrid? {
        guard let side = sides(width: width, fold: fold), minColumn > 0 else { return nil }
        let perSide = Int((min(side.leading, side.trailing) + spacing) / (minColumn + spacing))
        guard let columns = evenColumns(maxFitting: 2 * perSide), let fold else { return nil }
        let half = CGFloat(columns / 2)
        let columnWidth = (min(side.leading, side.trailing) - (half - 1) * spacing) / half
        let leadingHalf = half * columnWidth + (half - 1) * spacing
        return FoldGrid(columns: columns, columnWidth: columnWidth, foldGap: fold.upperBound - leadingHalf)
    }

    /// Bay rows split at a fold: the leading half's rows (indices from 0) sit
    /// before the fold, the trailing half's after it.
    struct FoldBays: Equatable {
        var leading: [Range<Int>]
        var trailing: [Range<Int>]
    }

    /// Splits `count` bays into two halves around `fold`, the odd one going
    /// first, and wraps each half within its own side with `bayRows`. Nil, for
    /// today's rows, with no fold through the diagram, fewer than two bays,
    /// no room for a bay on one side, or (without wrapping) a half that would
    /// overflow its side and need to scroll.
    static func foldBays(count: Int, width: CGFloat, minColumn: CGFloat, spacing: CGFloat, wrap: Bool, fold: ClosedRange<CGFloat>?) -> FoldBays? {
        guard count >= 2, let side = sides(width: width, fold: fold),
              min(side.leading, side.trailing) >= minColumn else { return nil }
        let leadingCount = (count + 1) / 2
        func fits(_ bays: Int, in room: CGFloat) -> Bool {
            CGFloat(bays) * (minColumn + spacing) - spacing <= room
        }
        if !wrap, !fits(leadingCount, in: side.leading) || !fits(count - leadingCount, in: side.trailing) { return nil }
        let leading = bayRows(count: leadingCount, width: side.leading, minColumn: minColumn, spacing: spacing, wrap: wrap)
        let trailing = bayRows(count: count - leadingCount, width: side.trailing, minColumn: minColumn, spacing: spacing, wrap: wrap)
            .map { ($0.lowerBound + leadingCount)..<($0.upperBound + leadingCount) }
        return FoldBays(leading: leading, trailing: trailing)
    }

    /// Room before and after a fold that passes through a view `width` wide.
    private static func sides(width: CGFloat, fold: ClosedRange<CGFloat>?) -> (leading: CGFloat, trailing: CGFloat)? {
        guard let fold, width.isFinite, width > 0,
              fold.upperBound > 0, fold.lowerBound < width else { return nil }
        return (max(0, fold.lowerBound), max(0, width - fold.upperBound))
    }
}
