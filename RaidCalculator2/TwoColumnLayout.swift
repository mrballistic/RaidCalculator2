//
//  TwoColumnLayout.swift
//  RaidCalculator2
//
//  Results beside inputs, shared by both tabs once the window is wide
//  enough (`AdaptiveLayout.usesTwoColumns`).
//

import SwiftUI

struct TwoColumnLayout<Results: View, Inputs: View, Info: View>: View {
    /// Show `info` in place of the inputs (iPhone Duo; see `readsFold`).
    var showsInfo = false
    @ViewBuilder var results: Results
    @ViewBuilder var inputs: Inputs
    @ViewBuilder var info: Info

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
                inputsPane
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
                inputsPane
            }
        }
    }

    /// The inputs, or the info over them in the same place. The inputs stay
    /// underneath, hidden, so their scroll position survives.
    private var inputsPane: some View {
        ZStack {
            inputs
                .opacity(showsInfo ? 0 : 1)
                .allowsHitTesting(!showsInfo)
                .accessibilityHidden(showsInfo)
            if showsInfo {
                info
                    .environment(\.infoInPane, true)
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    /// Keeps `fold` true while the device has a fold region (iPhone Duo, flat
    /// or folded; never iPad). A hardware feature rather than the idiom, so
    /// the info goes in the inputs pane only where a system sheet would land
    /// over the results. Always false before iOS 27.1.
    func readsFold(_ fold: Binding<Bool>) -> some View {
        modifier(FoldReader(fold: fold))
    }
}

private struct FoldReader: ViewModifier {
    @Binding var fold: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.background {
                GeometryReader { proxy in
                    let hasFold = !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty
                    Color.clear
                        .onChange(of: hasFold, initial: true) { _, now in fold = now }
                }
                .accessibilityHidden(true)
            }
        } else {
            content
        }
    }
}
