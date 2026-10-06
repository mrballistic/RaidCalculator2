//
//  TwoColumnLayout.swift
//  RaidCalculator2
//
//  Results beside inputs, shared by both tabs once the window is wide
//  enough (`AdaptiveLayout.usesTwoColumns`).
//

import SwiftUI

struct TwoColumnLayout<Results: View, Inputs: View>: View {
    /// A fold runs across the screen: stack results above it, inputs below.
    var stacksForFold = false
    @ViewBuilder var results: Results
    @ViewBuilder var inputs: Inputs

    /// Each pane's margin at the split, from the system container margins.
    @State private var innerMargin: CGFloat = 16

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
            //
            // The split gives the panes no margin where they meet: flat, the
            // cards butt together; at a fold, the results run up to its
            // edge. No split modifier sets pane margins, so each pane takes
            // the system's container margin (ContentMarginGuide.container)
            // on its inner edge. Outer edges keep the Form's own margin and
            // safe area, which keeps them clear of a vertical bar.
            ArrangementView {
                results
                    .modifier(SplitPaneMargin(edge: .trailing, margin: innerMargin))
            } secondary: {
                inputs
                    .modifier(SplitPaneMargin(edge: .leading, margin: innerMargin))
            }
            // Across a fold the split stacks, so the fold falls between
            // results and inputs rather than through a Form.
            .arrangementViewStyle(stacksForFold ? .split.axes(.vertical) : .split)
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.contentMargins(for: .container, edges: .horizontal)
            } action: { margins in
                innerMargin = AdaptiveLayout.splitInnerMargin(leading: margins.leading, trailing: margins.trailing)
            }
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

/// A pane's margin at the split's inner edge, applied only while the panes
/// sit side by side; stacked, the Forms' own top and bottom insets separate them.
@available(iOS 27.1, *)
private struct SplitPaneMargin: ViewModifier {
    let edge: Edge.Set
    let margin: CGFloat
    @Environment(\.splitArrangementAxis) private var axis

    func body(content: Content) -> some View {
        content.contentMargins(edge, axis == .horizontal ? margin : nil, for: .scrollContent)
    }
}

extension View {
    /// Keeps `fold` true while an active fold region runs across this view
    /// (iPhone Duo in book portrait). Always false before iOS 27.1.
    func readsHorizontalFold(_ fold: Binding<Bool>) -> some View {
        modifier(HorizontalFoldReader(fold: fold))
    }
}

private struct HorizontalFoldReader: ViewModifier {
    @Binding var fold: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.background { FoldRegionReader(fold: $fold) }
        } else {
            content
        }
    }
}

/// Reads the division regions in a GeometryReader. Folding from flat to
/// book doesn't change the view's size, so the reader is also rebuilt on
/// every hinge change, which makes it read the regions again.
@available(iOS 27.1, *)
private struct FoldRegionReader: View {
    @Binding var fold: Bool
    @State private var hinge: DeviceHinge?

    var body: some View {
        GeometryReader { proxy in
            let regions = proxy.reservedRegions(kind: .division)
            let across = AdaptiveLayout.hasActiveHorizontalFold(regions.map { (frame: $0.frame, isActive: $0.isActive) })
            Color.clear
                .onChange(of: across, initial: true) { _, now in fold = now }
        }
        .id(hinge?.status)
        .onHingeChange { _, new in hinge = new.hinge }
        .accessibilityHidden(true)
    }
}
