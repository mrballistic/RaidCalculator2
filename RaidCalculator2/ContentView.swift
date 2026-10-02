//
//  ContentView.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = RaidCalculatorViewModel()
    @State private var showingInfoSheet = false
    @State private var contentWidth: CGFloat = 0
    @FocusState private var sizeFieldFocused: Bool

    /// Widest the form grows on iPad before it centers instead of stretching.
    private let readableWidth: CGFloat = 720

    var body: some View {
        let result = viewModel.result

        Form {
            // The answer comes first, so it stays on screen at every text size.
            Section {
                CapacitySummary(result: result, unit: viewModel.unit)
            }

            if let warning = result.warningMessage {
                Section {
                    Label {
                        Text(warning)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                    .accessibilityIdentifier("configurationWarning")

                    if let suggested = result.suggestedDriveCount, suggested != viewModel.driveCount {
                        Button(String(format: "use_drive_count".localized(), suggested)) {
                            withAnimation { viewModel.applySuggestedDriveCount() }
                        }
                        .accessibilityIdentifier("applySuggestedDriveCount")
                    }
                }
            } else if viewModel.showsRebuildCaution {
                Section {
                    Label {
                        Text("rebuild_caution".localized())
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            }

            Section("raid_level".localized()) {
                Picker("raid_level".localized(), selection: $viewModel.selectedLevel) {
                    ForEach(RaidLevel.allCases) { level in
                        Text(level.shortLabel)
                            .accessibilityLabel(level.displayName)
                            .tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("drive_configuration".localized()) {
                Stepper(value: $viewModel.driveCount, in: RaidCalculatorViewModel.driveCountRange) {
                    LabeledContent("number_of_drives".localized()) {
                        Text(viewModel.driveCount, format: .number)
                            .monospacedDigit()
                            .accessibilityIdentifier("driveCount")
                    }
                }

                LabeledContent("drive_size".localized()) {
                    HStack(spacing: 12) {
                        TextField(
                            "drive_size".localized(),
                            value: $viewModel.driveSize,
                            format: .number.precision(.fractionLength(0...3))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($sizeFieldFocused)
                        .monospacedDigit()
                        .frame(minWidth: 56, maxWidth: 140)
                        .accessibilityIdentifier("driveSizeField")

                        Picker(selection: $viewModel.unit) {
                            ForEach(CapacityUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        } label: {
                            Text("drive_size".localized())
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                    }
                }
            }

            Section {
                RatingRow(title: "speed".localized(), rating: result.speedRating)
                RatingRow(title: "availability".localized(), rating: result.availabilityRating)
            } header: {
                Text("ratings".localized())
            } footer: {
                Text("ratings_footnote".localized())
            }
        }
        .navigationTitle("app_title".localized())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingInfoSheet = true
                } label: {
                    Image(systemName: "info")
                }
                .accessibilityLabel(String(format: "about_level".localized(), viewModel.selectedLevel.displayName))
                .accessibilityIdentifier("raidInfo")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("done".localized()) { sizeFieldFocused = false }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
        .contentMargins(
            .horizontal,
            contentWidth > readableWidth + 40 ? (contentWidth - readableWidth) / 2 : nil,
            for: .scrollContent
        )
        .sensoryFeedback(.selection, trigger: viewModel.selectedLevel)
        .sheet(isPresented: $showingInfoSheet) {
            RaidInfoSheet(level: viewModel.selectedLevel)
        }
    }
}

/// The answer: usable capacity, what it costs, which drives do what, and how
/// many can fail. Dims when the configuration is invalid so the numbers stay
/// readable for context without reading as a result.
struct CapacitySummary: View {
    let result: RaidResult
    let unit: CapacityUnit

    private var isValid: Bool { result.warningMessage == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("usable_capacity".localized())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Self.capacity(result.usableCapacity, unit: unit.rawValue))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("usableCapacity")
                Text(String(
                    format: "raw_and_efficiency".localized(),
                    Self.capacity(result.rawCapacity, unit: unit.rawValue),
                    result.efficiency.formatted(.percent.precision(.fractionLength(0)))
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            if !result.driveRoles.isEmpty {
                DriveStrip(roles: result.driveRoles)
            }

            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("drive_failures_tolerated".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(result.failuresTolerated)
                        .font(.body.weight(.semibold))
                }
            } icon: {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.tint)
            }
            .accessibilityElement(children: .combine)

            if isValid, result.usableCapacity > 0 {
                Text(String(format: "binary_capacity_note".localized(), Self.binaryCapacity(result.usableCapacity, unit: unit)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .opacity(isValid ? 1 : 0.4)
        .animation(.default, value: isValid)
    }

    static func capacity(_ value: Double, unit: String, maxFractionDigits: Int = 2) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...maxFractionDigits)))) \(unit)"
    }

    /// Drive makers sell decimal units; most NAS operating systems report binary
    /// ones, which is why a “16 TB” drive shows up as 14.6.
    static func binaryCapacity(_ value: Double, unit: CapacityUnit) -> String {
        switch unit {
        case .tb: capacity(value * 1e12 / 1_099_511_627_776, unit: "TiB", maxFractionDigits: 1)
        case .gb: capacity(value * 1e9 / 1_073_741_824, unit: "GiB", maxFractionDigits: 1)
        }
    }
}

/// One bar per physical drive, showing which hold data and which hold
/// redundancy. Mirrors are outlined rather than filled, so the distinction
/// doesn't rest on colour alone.
struct DriveStrip: View {
    let roles: [DriveRole]
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: roles.count > 12 ? 3 : 5) {
                ForEach(Array(roles.enumerated()), id: \.offset) { _, role in
                    bar(for: role)
                        .frame(maxWidth: 44)
                        .frame(height: barHeight)
                }
            }
            .animation(.snappy, value: roles)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var presentRoles: [DriveRole] {
        [.data, .parity, .mirror].filter(roles.contains)
    }

    @ViewBuilder
    private var legend: some View {
        ForEach(presentRoles, id: \.self) { role in
            HStack(spacing: 5) {
                bar(for: role)
                    .frame(width: 10, height: 10)
                Text(Self.name(of: role))
            }
        }
    }

    @ViewBuilder
    private func bar(for role: DriveRole) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        switch role {
        case .data:
            shape.fill(Color.accentColor)
        case .parity:
            shape.fill(Color.indigo)
        case .mirror:
            shape.fill(Color.accentColor.opacity(0.22))
                .overlay(shape.strokeBorder(Color.accentColor, lineWidth: 1.5))
        }
    }

    private var accessibilitySummary: String {
        let parts = presentRoles.map { role in
            String(format: "role_count".localized(), roles.filter { $0 == role }.count, Self.name(of: role))
        }
        return String(format: "drive_strip_accessibility".localized(), roles.count, parts.joined(separator: ", "))
    }

    static func name(of role: DriveRole) -> String {
        switch role {
        case .data: "role_data".localized()
        case .parity: "role_parity".localized()
        case .mirror: "role_mirror".localized()
        }
    }
}

/// Five stars plus the word for the rating, read by VoiceOver as one phrase
/// (“Speed, 3 of 5, Medium”). Shared with the info sheet.
struct RatingRow: View {
    let title: String
    let rating: Int

    private var label: String { RaidCalculator.ratingLabel(rating) }

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(star <= rating ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    }
                }
                .font(.footnote)
                Text(label)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "rating_accessibility".localized(), title, rating, label))
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
