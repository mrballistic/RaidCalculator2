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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                            withAnimation(motion) { viewModel.applySuggestedDriveCount() }
                        }
                        .accessibilityIdentifier("applySuggestedDriveCount")
                    }

                    if let suggested = result.suggestedGroups, suggested != viewModel.groups {
                        Button(suggested == 1 ? "use_one_group".localized() : String(format: "use_group_count".localized(), suggested)) {
                            withAnimation(motion) { viewModel.applySuggestedGroups() }
                        }
                        .accessibilityIdentifier("applySuggestedGroups")
                    }
                }
            } else if viewModel.rebuildCautionSuggestion != nil || viewModel.wideZFSGroupWidth != nil {
                Section {
                    if let safer = viewModel.rebuildCautionSuggestion {
                        caution(String(format: "rebuild_caution_level".localized(), viewModel.selectedLevel.displayName, safer.displayName))
                    }
                    if let width = viewModel.wideZFSGroupWidth {
                        caution(String(format: "wide_zfs_group_caution".localized(), width))
                            .accessibilityIdentifier("wideGroupCaution")
                    }
                }
                .transition(.opacity)
            }

            Section("raid_level".localized()) {
                Picker("raid_level".localized(), selection: standardLevelSelection) {
                    ForEach(RaidLevel.levels(in: .standard)) { level in
                        Text(level.shortLabel)
                            .accessibilityLabel(level.displayName)
                            .tag(Optional(level))
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Menu {
                    Section("nested_levels".localized()) {
                        ForEach(RaidLevel.levels(in: .nested)) { levelButton($0) }
                    }
                    Section("zfs_levels".localized()) {
                        ForEach(RaidLevel.levels(in: .zfs)) { levelButton($0) }
                    }
                } label: {
                    LabeledContent("more_levels".localized()) {
                        HStack(spacing: 6) {
                            if viewModel.selectedLevel.family != .standard {
                                Text(viewModel.selectedLevel.displayName)
                                    .foregroundStyle(.tint)
                            }
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .tint(.primary)
                .accessibilityIdentifier("moreLevels")
            }

            Section {
                Stepper(value: $viewModel.driveCount, in: RaidCalculatorViewModel.driveCountRange) {
                    LabeledContent("number_of_drives".localized()) {
                        Text(viewModel.driveCount, format: .number)
                            .monospacedDigit()
                            .accessibilityIdentifier("driveCount")
                    }
                }

                if viewModel.selectedLevel.usesGroups {
                    Stepper(value: Binding(
                        get: { viewModel.groups },
                        set: { value in withAnimation(motion) { viewModel.groups = value } }
                    ), in: 1...max(1, viewModel.driveCount)) {
                        LabeledContent("groups".localized()) {
                            Text(viewModel.groups, format: .number)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .accessibilityIdentifier("groupCount")
                        }
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.groups)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }

                LabeledContent("drive_size".localized()) {
                    HStack(spacing: 12) {
                        DriveSizeField(value: $viewModel.driveSize, focus: $sizeFieldFocused)
                            .frame(minWidth: 56, maxWidth: 140)

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
            } header: {
                Text("drive_configuration".localized())
            } footer: {
                if viewModel.selectedLevel.usesGroups, viewModel.result.warningMessage == nil {
                    let groups = max(viewModel.groups, 1)
                    let width = viewModel.driveCount / groups
                    Text(groups == 1
                         ? String(format: "group_layout_single".localized(), width)
                         : String(format: "group_layout".localized(), groups, width))
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
        .sensoryFeedback(.success, trigger: result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }
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

    /// The segmented control shows only the standard levels; with a nested or
    /// ZFS level chosen, nothing in it is highlighted.
    private var standardLevelSelection: Binding<RaidLevel?> {
        Binding(
            get: { viewModel.selectedLevel.family == .standard ? viewModel.selectedLevel : nil },
            set: { if let level = $0 { withAnimation(motion) { viewModel.selectedLevel = level } } }
        )
    }

    private func levelButton(_ level: RaidLevel) -> some View {
        Button {
            withAnimation(motion) { viewModel.selectedLevel = level }
        } label: {
            if viewModel.selectedLevel == level {
                Label(level.displayName, systemImage: "checkmark")
            } else {
                Text(level.displayName)
            }
        }
    }

    /// Movement for layout changes; a plain fade when Reduce Motion is on.
    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : .snappy }

    private func caution(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
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
                DriveStrip(roles: result.driveRoles, groupSize: result.groupSize)
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
                if let estimate = result.zfsEstimate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "zfs_reported_note".localized(), Self.binaryBytes(estimate.reportedBytes, unit: unit)))
                            .accessibilityIdentifier("zfsReportedNote")
                        if estimate.paddingLoss > 0.01 {
                            Text(String(format: "zfs_padding_note".localized(), estimate.paddingLoss.formatted(.percent.precision(.fractionLength(0)))))
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                } else {
                    Text(String(format: "binary_capacity_note".localized(), Self.binaryCapacity(result.usableCapacity, unit: unit)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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

    /// A byte count in the binary unit matching the chosen decimal one.
    static func binaryBytes(_ bytes: Double, unit: CapacityUnit) -> String {
        switch unit {
        case .tb: capacity(bytes / 1_099_511_627_776, unit: "TiB", maxFractionDigits: 1)
        case .gb: capacity(bytes / 1_073_741_824, unit: "GiB", maxFractionDigits: 1)
        }
    }
}

/// One bar per physical drive, showing which hold data and which hold
/// redundancy. Mirrors are outlined rather than filled, so the distinction
/// doesn't rest on colour alone. Grouped levels show a wider gap between
/// groups, so a change of groups visibly regroups the same drives.
struct DriveStrip: View {
    let roles: [DriveRole]
    var groupSize: Int? = nil
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 26
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var barSpacing: CGFloat { roles.count > 12 ? 3 : 5 }

    /// Drive indices per group; one group when the level isn't grouped.
    private var groups: [Range<Int>] {
        guard let size = groupSize, size > 0, roles.count > size else { return [roles.indices] }
        return stride(from: 0, to: roles.count, by: size).map { $0..<min($0 + size, roles.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: groups.count > 1 ? barSpacing * 3 : barSpacing) {
                ForEach(groups, id: \.lowerBound) { group in
                    HStack(spacing: barSpacing) {
                        ForEach(group, id: \.self) { index in
                            bar(for: roles[index])
                                .frame(maxWidth: 44)
                                .frame(height: barHeight)
                        }
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: roles)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: groupSize)

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
        }.joined(separator: ", ")
        if groups.count > 1 {
            return String(format: "drive_strip_groups_accessibility".localized(), roles.count, groups.count, parts)
        }
        return String(format: "drive_strip_accessibility".localized(), roles.count, parts)
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

/// The drive-size entry. It's trailing-aligned in a frame much wider than a
/// short number like “4”, so a tap left of the digits would otherwise put the
/// cursor before them, where backspace deletes nothing. On focus the cursor
/// moves to the end, wherever the tap landed.
///
/// That needs `selection:`, which SwiftUI only offers on text-bound fields, so
/// the field edits its own text and pushes each value that parses. An empty or
/// unparseable field leaves the last value in place and shows it again when
/// editing ends, as the value-bound field did.
struct DriveSizeField: View {
    @Binding var value: Double
    var focus: FocusState<Bool>.Binding

    @State private var text = ""
    @State private var selection: TextSelection?

    private static let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...3))

    var body: some View {
        TextField("drive_size".localized(), text: $text, selection: $selection)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused(focus)
            .monospacedDigit()
            .accessibilityIdentifier("driveSizeField")
            .onAppear { text = value.formatted(Self.format) }
            .onChange(of: text) {
                // Parsing follows the current locale, so “12,5” works in Spanish, French and Italian.
                if let parsed = try? Self.format.parseStrategy.parse(text) { value = parsed }
            }
            .onChange(of: value) {
                // Changes from elsewhere (loading, clamping) show once editing is done.
                if !focus.wrappedValue { text = value.formatted(Self.format) }
            }
            .onChange(of: focus.wrappedValue) { _, focused in
                if focused {
                    // Runs after the tap has placed the cursor, so this placement wins.
                    Task { @MainActor in selection = TextSelection(insertionPoint: text.endIndex) }
                } else {
                    text = value.formatted(Self.format)
                }
            }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
