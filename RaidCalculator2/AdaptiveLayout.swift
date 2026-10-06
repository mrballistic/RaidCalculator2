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
}
