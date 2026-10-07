//
//  Colors.swift
//  RaidCalculator2
//

import SwiftUI

extension Color {
    /// Fill color for data marks (bars, swatches, stars, the shield). Kept apart from the
    /// tint, which is darkened for text contrast; fills don't need 4.5:1.
    static let dataFill = Color("DataColor")
}
