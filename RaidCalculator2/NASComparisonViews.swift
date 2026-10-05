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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint("compare_hint".localized())
    }
}

/// iPhone: rows in a sheet. The choice is applied after the sheet closes,
/// so the user sees the bays re-split.
struct NASComparisonSheet: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void
    @Environment(\.dismiss) private var dismiss

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
        .presentationDetents([.medium, .large])
    }
}

/// iPad: the systems side by side, or stacked when the column is too narrow
/// (accessibility text sizes).
struct NASComparisonColumns: View {
    let comparison: [NASComparison]
    let current: NASSystem
    let select: (NASSystem) -> Void
    /// ViewThatFits compares ideal widths, and a cell's ideal is its longest
    /// unwrapped line, so five never fit. A scaled ideal width lets them fit
    /// (and wrap) at default sizes, and still stack at accessibility sizes.
    @ScaledMetric(relativeTo: .headline) private var column: CGFloat = 96

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                cells.frame(minWidth: column, idealWidth: column, maxWidth: .infinity, alignment: .topLeading)
            }
            VStack(alignment: .leading, spacing: 14) { cells }
        }
    }

    private var cells: some View {
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
}
