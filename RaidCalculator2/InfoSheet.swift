//
//  InfoSheet.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

/// What an info sheet is about: a RAID level on the RAID tab, or a NAS system.
struct InfoTopic {
    let title: String
    /// Copy lives in Localizable.xcstrings as <prefix>_description, _pros,
    /// _cons, _use_cases and, optionally, _calculation.
    let keyPrefix: String
    /// Speed and availability, for RAID levels; NAS systems have none.
    let ratings: (speed: Int, availability: Int)?
    /// A closing line, such as a trademark notice.
    let footnoteKey: String?

    static func level(_ level: RaidLevel) -> InfoTopic {
        let calculator = RaidCalculator()
        return InfoTopic(
            title: level.displayName,
            keyPrefix: level.stringKeyPrefix,
            ratings: (calculator.speedRating(for: level), calculator.availabilityRating(for: level)),
            footnoteKey: level.isZFS ? "zfs_not_affiliated" : nil
        )
    }

    static func system(_ system: NASSystem) -> InfoTopic {
        InfoTopic(title: system.displayName, keyPrefix: system.stringKeyPrefix, ratings: nil, footnoteKey: system.notAffiliatedKey)
    }
}

struct InfoSheet: View {
    let topic: InfoTopic
    @Environment(\.dismiss) private var dismiss
    /// Shown in place of the inputs pane rather than as a sheet: no
    /// navigation bar of its own, so the title and Close are its first row.
    @Environment(\.infoInPane) private var inPane
    @Environment(\.closeInfo) private var closeInfo
    /// VoiceOver moves to the title when the pane opens; a sheet gets this
    /// from the system.
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        if inPane {
            list
                .task {
                    // After the cross-fade, or VoiceOver keeps its place.
                    try? await Task.sleep(for: .milliseconds(300))
                    titleFocused = true
                }
        } else {
            NavigationStack {
                list
                    .navigationTitle(topic.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(role: .close) { dismiss() }
                                .accessibilityIdentifier("closeInfo")
                        }
                    }
            }
        }
    }

    private var list: some View {
        List {
            if inPane {
                HStack(alignment: .firstTextBaseline) {
                    Text(topic.title)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titleFocused)
                        .accessibilityIdentifier("infoTitle")
                    Spacer()
                    Button(role: .close) { closeInfo?() }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .labelStyle(.iconOnly)
                        .accessibilityIdentifier("closeInfo")
                }
                .listRowBackground(Color.clear)
            }

            Section("overview".localized()) {
                Text(text("description"))
                    .listRowBackground(Color.clear)
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

            if let calculation = optionalText("calculation") {
                Section {
                    Text(calculation)
                        .accessibilityIdentifier("howCalculated")
                        .listRowBackground(Color.clear)
                } header: {
                    Text("how_calculated".localized())
                } footer: {
                    if topic.ratings == nil, let footnote { footnoteText(footnote) }
                }
            }

            if let ratings = topic.ratings {
                Section {
                    RatingRow(title: "speed".localized(), rating: ratings.speed)
                    RatingRow(title: "availability".localized(), rating: ratings.availability)
                } header: {
                    Text("performance_ratings".localized())
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ratings_footnote".localized())
                        if let footnote { footnoteText(footnote) }
                    }
                }
            }

            if topic.ratings == nil, optionalText("calculation") == nil, let footnote {
                Section {
                } footer: {
                    footnoteText(footnote)
                }
            }
        }
    }

    private var footnote: String? { topic.footnoteKey.flatMap { optionalKey($0) } }

    private func footnoteText(_ text: String) -> some View {
        Text(text)
            .accessibilityIdentifier("infoFootnote")
    }

    private func text(_ field: String) -> String {
        "\(topic.keyPrefix)_\(field)".localized()
    }

    /// Pros, cons and use cases are stored one per line.
    private func lines(_ field: String) -> [String] {
        text(field).split(separator: "\n").map { String($0) }
    }

    /// Copy some topics have and others don't; nil when the key isn't in the
    /// catalog. `strings.py check` requires all five languages, so a key never
    /// exists in one language only.
    private func optionalText(_ field: String) -> String? {
        optionalKey("\(topic.keyPrefix)_\(field)")
    }

    private func optionalKey(_ key: String) -> String? {
        let value = key.localized()
        return value == key ? nil : value
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
    InfoSheet(topic: .level(.raid5))
}

extension EnvironmentValues {
    /// Set by TwoColumnLayout when InfoSheet stands in for the inputs pane.
    @Entry var infoInPane = false
    /// Closes the info shown in the inputs pane.
    @Entry var closeInfo: (@MainActor () -> Void)? = nil
}
