//
//  FoldReader.swift
//  RaidCalculator2
//
//  Reads iPhone Duo's fold (a `.division` reserved region, iOS 27.1) for
//  the views that keep content out of it. The decisions themselves are
//  pure helpers in AdaptiveLayout.
//

import SwiftUI

/// A view's width and the x span of an active fold through it, in the
/// view's own coordinates. `fold` is nil before iOS 27.1, on devices
/// without a fold, and whenever no fold runs top to bottom through the view.
nonisolated struct FoldGeometry: Equatable, Sendable {
    var width: CGFloat = 0
    var fold: ClosedRange<CGFloat>?
}

extension View {
    /// Reports this view's `FoldGeometry` as it changes. Measures the view
    /// itself, so put it on a container that takes the width on offer.
    func onFoldGeometryChange(_ action: @escaping (FoldGeometry) -> Void) -> some View {
        onGeometryChange(for: FoldGeometry.self) { proxy in
            var frames: [CGRect] = []
            if #available(iOS 27.1, *) {
                // A region's frame is already in this view's coordinate space
                // (mirrored for right-to-left, the default), margins included.
                frames = proxy.reservedRegions(kind: .division)
                    .filter(\.isActive)
                    .map(\.frame)
            }
            let width = proxy.size.width
            return FoldGeometry(width: width, fold: AdaptiveLayout.foldSpan(in: frames, width: width))
        } action: { geometry in
            action(geometry)
        }
    }
}
