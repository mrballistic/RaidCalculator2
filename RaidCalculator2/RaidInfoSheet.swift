//
//  RaidInfoSheet.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

struct RaidInfoSheet: View {
    let level: RaidLevel
    @Environment(\.dismiss) private var dismiss

    private let calculator = RaidCalculator()

    var body: some View {
        NavigationStack {
            List {
                Section("overview".localized()) {
                    Text(text("description"))
                }

                Section("pros".localized()) {
                    ForEach(lines("pros"), id: \.self) { pro in
                        bullet(pro, systemImage: "checkmark.circle.fill", tint: .green)
                    }
                }

                Section("cons".localized()) {
                    ForEach(lines("cons"), id: \.self) { con in
                        bullet(con, systemImage: "xmark.circle.fill", tint: .red)
                    }
                }

                Section("typical_use_cases".localized()) {
                    ForEach(lines("use_cases"), id: \.self) { useCase in
                        bullet(useCase, systemImage: "arrow.forward.circle.fill", tint: .secondary)
                    }
                }

                Section {
                    // Same ratings the calculator shows, so the two can't drift apart.
                    RatingRow(title: "speed".localized(), rating: calculator.speedRating(for: level))
                    RatingRow(title: "availability".localized(), rating: calculator.availabilityRating(for: level))
                } header: {
                    Text("performance_ratings".localized())
                } footer: {
                    Text("ratings_footnote".localized())
                }
            }
            .navigationTitle(level.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                        .accessibilityIdentifier("closeInfo")
                }
            }
        }
    }

    /// Per-level copy lives in Localizable.xcstrings as raid5_description etc.
    private func text(_ field: String) -> String {
        "\(level.stringKeyPrefix)_\(field)".localized()
    }

    /// Pros, cons and use cases are stored one per line.
    private func lines(_ field: String) -> [String] {
        text(field).split(separator: "\n").map { String($0) }
    }

    private func bullet(_ text: String, systemImage: String, tint: some ShapeStyle) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    RaidInfoSheet(level: .raid5)
}
