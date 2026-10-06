//
//  TwoColumnLayout.swift
//  RaidCalculator2
//
//  Results beside inputs, shared by both tabs once the window is wide
//  enough (`AdaptiveLayout.usesTwoColumns`).
//

import SwiftUI

struct TwoColumnLayout<Results: View, Inputs: View>: View {
    @ViewBuilder var results: Results
    @ViewBuilder var inputs: Inputs

    var body: some View {
        columns
            // UI tests detect the two-column layout by this identifier.
            // Keep it on whatever container holds the columns.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("twoColumnLayout")
    }

    @ViewBuilder private var columns: some View {
        if #available(iOS 27.1, *) {
            // A split arrangement is meant to keep iPhone Duo's fold in the
            // gap between the columns (not yet seen on a folded device). Results are the primary view, so they lead in
            // reading and VoiceOver order as in the stacked layout.
            //
            // The axes are deliberately left open. On the 27.1 simulator a
            // split limited to `.axes(.horizontal)` that finds too little
            // room for side by side shows only the primary view, hiding
            // every input; unconstrained, it stacks results over inputs
            // instead. This view is only chosen at regular width and 800+
            // points, where the split is expected to go side by side, so
            // leaving the axes open can't lose the inputs; if it ever
            // stacks there, the testIPad*Beside* UI tests fail.
            ArrangementView {
                results
            } secondary: {
                inputs
            }
            .arrangementViewStyle(.split)
            // The split leaves a strip at the fold and a gap between the
            // panes; without this they show the white window background
            // instead of the grouped gray behind both Forms.
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        } else {
            HStack(alignment: .top, spacing: 0) {
                results
                Divider()
                inputs
            }
        }
    }
}
