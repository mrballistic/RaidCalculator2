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

    /// Each pane's margin at the split, from the system container margins.
    @State private var innerMargin: CGFloat = 16

    var body: some View {
        columns
            // The fold strip, the gap between panes and the band under the
            // navigation bar (tab picker and info button) show the grouped
            // gray behind both Forms, not the white window background.
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            //
            // The split gives the panes no margin where they meet: flat, the
            // cards butt together; at a fold, the results run up to its
            // edge. No split modifier sets pane margins, so each pane takes
            // the system's container margin (ContentMarginGuide.container)
            // on its inner edge. Outer edges keep the Form's own margin and
            // safe area, which keeps them clear of a vertical bar. The
            // margin is applied unconditionally rather than gated on
            // `splitArrangementAxis`, which reads nil inside these panes
            // on the 27.1 simulator.
            ArrangementView {
                results
                    .contentMargins(.trailing, innerMargin, for: .scrollContent)
            } secondary: {
                inputs
                    .contentMargins(.leading, innerMargin, for: .scrollContent)
            }
            .arrangementViewStyle(.split)
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.contentMargins(for: .container, edges: .horizontal)
            } action: { margins in
                innerMargin = AdaptiveLayout.splitInnerMargin(leading: margins.leading, trailing: margins.trailing)
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                results
                Divider()
                inputs
            }
        }
    }
}
