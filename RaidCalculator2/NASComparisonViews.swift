//
//  NASComparisonViews.swift
//  RaidCalculator2
//
//  “Same drives, every system” (FR-13): a sheet of rows on iPhone, columns
//  beside the results on iPad. Tapping a system switches the tab to it.
//

import SwiftUI

/// One system's answer. A setup that can't work shows its warning, not a number.
struct NASComparisonCell: View {
    let comparison: NASComparison
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(comparison.system.displayName)
                    .font(.headline)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            if comparison.isValid {
                Text(NASView.tb(comparison.usableCapacity))
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Group {
                    Text(String(format: "compare_failures".localized(), comparison.failuresTolerated))
                    if comparison.unusedCapacity > 0 {
                        Text(String(format: "compare_unused".localized(), NASView.tb(comparison.unusedCapacity)))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else if let warning = comparison.warningMessage {
                Text(warning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let limit = comparison.bayLimit {
                Text(String(format: "compare_first_bays".localized(), limit))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let all = comparison.readsAllBays {
                Text(String(format: "compare_all_bays".localized(), all))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        // Tapping the current system changes nothing, so only the others say what a tap does.
        .accessibilityHint(isCurrent ? "" : "compare_hint".localized())
    }
}

/// iPhone: rows in a sheet. The choice is applied after the sheet closes,
/// so the user sees the bays re-split.
struct NASComparisonSheet: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var detent: PresentationDetent = .large

    var body: some View {
        NavigationStack {
            List(comparison) { row in
                Button {
                    select(row.system)
                    dismiss()
                } label: {
                    NASComparisonCell(comparison: row, isCurrent: row.system == current)
                }
                .tint(.primary)
                .accessibilityIdentifier("compare_\(row.system.rawValue)")
            }
            .navigationTitle("compare_systems".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                        .accessibilityIdentifier("closeCompare")
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
    }
}

/// iPad: the systems side by side, wrapping onto further rows when the
/// column is too narrow for all five (portrait), and one per row at
/// accessibility text sizes, where the scaled minimum outgrows the column.
struct NASComparisonColumns: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void
    /// Narrowest a system's column gets. Scales with the text, so a cell's
    /// name and number stay readable and the grid reflows instead.
    @ScaledMetric(relativeTo: .headline) private var column: CGFloat = 96
    @State private var geometry = FoldGeometry()

    /// Today's adaptive grid, unless iPhone Duo's fold runs through it: then
    /// an even number of fixed columns, half each side, with the fold in the
    /// gap between the halves (`AdaptiveLayout.foldGrid`).
    private var columns: [GridItem] {
        guard let grid = AdaptiveLayout.foldGrid(width: geometry.width, minColumn: column, spacing: 12, fold: geometry.fold) else {
            return [GridItem(.adaptive(minimum: column), spacing: 12, alignment: .top)]
        }
        return (0..<grid.columns).map { index in
            GridItem(.fixed(grid.columnWidth), spacing: index == grid.columns / 2 - 1 ? grid.foldGap : 12, alignment: .top)
        }
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: 14
        ) {
            ForEach(comparison) { row in
                Button {
                    select(row.system)
                } label: {
                    NASComparisonCell(comparison: row, isCurrent: row.system == current)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("compare_\(row.system.rawValue)")
            }
        }
        // Measures the width on offer, and pins fixed columns to the leading
        // edge, where the fold's x span is measured from.
        .frame(maxWidth: .infinity, alignment: .leading)
        .onFoldGeometryChange { geometry = $0 }
    }
}
