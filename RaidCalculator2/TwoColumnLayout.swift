//
//  TwoColumnLayout.swift
//  RaidCalculator2
//
//  Results beside inputs, shared by both tabs once the window is wide
//  and tall enough (`AdaptiveLayout.usesTwoColumns`).
//

import SwiftUI

struct TwoColumnLayout<Results: View, Inputs: View, Info: View>: View {
    /// The device has a fold (iPhone Duo; see `readsFold`). Only then do
    /// the columns use a split arrangement.
    var hasFold = false
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
        if #available(iOS 27.1, *), hasFold {
            // A split arrangement keeps iPhone Duo's fold in the gap between
            // the columns. Results are the primary view, so they lead in
            // reading and VoiceOver order as in the stacked layout.
            //
            // Only with a fold: the store-assets brief calls for a split
            // arrangement only where a fold divides the view, and no
            // Simulator can check one on iPad or an iPhone Pro Max on 27.1,
            // so everything without a fold keeps the plain columns below.
            //
            // The axes are deliberately left open. On the 27.1 simulator a
            // split limited to `.axes(.horizontal)` that finds too little
            // room for side by side shows only the primary view, hiding
            // every input; unconstrained, it stacks results over inputs
            // instead. This view is only chosen at regular width, 800+
            // points wide and 600+ tall, where the split is expected to go
            // side by side, so leaving the axes open can't lose the inputs.
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
