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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Widest the form grows on iPad before it centers instead of stretching.
    private let readableWidth: CGFloat = 720

    private var twoColumns: Bool {
        AdaptiveLayout.usesTwoColumns(isRegularWidth: horizontalSizeClass == .regular, width: contentWidth)
    }

    /// The answer and anything wrong with it.
    @ViewBuilder private var answerSections: some View {
        // The answer comes first, so it stays on screen at every text size.
        Section {
            CapacitySummary(result: viewModel.result, unit: viewModel.unit)
        }

        if let warning = viewModel.result.warningMessage {
            Section {
                Label {
                    Text(warning)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                }
                .accessibilityIdentifier("configurationWarning")

                if let suggested = viewModel.result.suggestedDriveCount, suggested != viewModel.driveCount {
                    // Names the groups too when the fix changes them, as it does from one group to RAID 50 or 60.
                    Button(viewModel.result.suggestedDriveCountGroups.map { String(format: "use_drive_count_groups".localized(), suggested, $0) }
                           ?? String(format: "use_drive_count".localized(), suggested)) {
                        withAnimation(motion) { viewModel.applySuggestedDriveCount() }
                    }
                    .accessibilityIdentifier("applySuggestedDriveCount")
                }

                if let suggested = viewModel.result.suggestedGroups, suggested != viewModel.groups {
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
                    caution(String(format: (viewModel.groups > 1 ? "wide_zfs_group_caution" : "wide_zfs_group_caution_single").localized(), width))
                        .accessibilityIdentifier("wideGroupCaution")
                }
            }
            .transition(.opacity)
        }
    }

    /// What the user sets: the level, then the drives.
    @ViewBuilder private var inputSections: some View {
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
                // At accessibility sizes the label sits above the selection,
                // so neither has to share the row and break mid-word.
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                    : AnyLayout(HStackLayout())
                layout {
                    Text("more_levels".localized())
                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                    HStack(spacing: 6) {
                        if viewModel.selectedLevel.family != .standard {
                            Text(viewModel.selectedLevel.displayName)
                                .foregroundStyle(.tint)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
            }
            .tint(.primary)
            .accessibilityIdentifier("moreLevels")
        }

        Section {
            CountStepper(
                title: "number_of_drives".localized(),
                value: $viewModel.driveCount,
                range: RaidCalculatorViewModel.driveCountRange,
                identifier: "driveCount"
            )

            if viewModel.selectedLevel.usesGroups {
                CountStepper(
                    title: "groups".localized(),
                    value: Binding(
                        get: { viewModel.groups },
                        set: { value in withAnimation(motion) { viewModel.groups = value } }
                    ),
                    range: 1...max(1, viewModel.driveCount),
                    identifier: "groupCount"
                )
                .sensoryFeedback(.selection, trigger: viewModel.groups)
                // Under Reduce Motion the row change runs without animation
                // (see `motion`), so the row appears in place rather than sliding.
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text("drive_size".localized())
                    driveSizeControls
                }
            } else {
                LabeledContent("drive_size".localized()) { driveSizeControls }
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
    }

    private var driveSizeControls: some View {
        HStack(spacing: 12) {
            DriveSizeField(value: $viewModel.driveSize, focus: $sizeFieldFocused)
                .frame(minWidth: 56, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 140)

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

    @ViewBuilder private var ratingsSection: some View {
        Section {
            RatingRow(title: "speed".localized(), rating: viewModel.result.speedRating)
            RatingRow(title: "availability".localized(), rating: viewModel.result.availabilityRating)
        } header: {
            Text("ratings".localized())
        } footer: {
            Text("ratings_footnote".localized())
        }
    }

    var body: some View {
        Group {
            if twoColumns {
                // Results lead so reading and VoiceOver order match the
                // stacked layout, where the answer comes first.
                HStack(alignment: .top, spacing: 0) {
                    Form {
                        answerSections
                        ratingsSection
                    }
                    Divider()
                    Form { inputSections }
                }
            } else {
                Form {
                    answerSections
                    inputSections
                    ratingsSection
                }
                .contentMargins(
                    .horizontal,
                    contentWidth > readableWidth + 40 ? (contentWidth - readableWidth) / 2 : nil,
                    for: .scrollContent
                )
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }
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
        .sensoryFeedback(.selection, trigger: viewModel.selectedLevel)
        .sheet(isPresented: $showingInfoSheet) {
            InfoSheet(topic: .level(viewModel.selectedLevel))
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
        .accessibilityAddTraits(viewModel.selectedLevel == level ? .isSelected : [])
    }

    /// Animation for layout changes. None under Reduce Motion, so Form rows
    /// appear and go in place instead of sliding the rows around them; the
    /// drive strip and results still crossfade through their own animations.
    private var motion: Animation? { reduceMotion ? nil : .snappy }

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

/// A count with a stepper: the drive count and the groups. Normally the label,
/// count and stepper share one row. At accessibility sizes the label gets its
/// own line above the count and stepper, so a long label (“Nombre de Disques”,
/// “ドライブ数”) never squeezes into a narrow column and breaks mid-word.
struct CountStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    /// On the count, so UI tests can read it at any text size.
    let identifier: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .accessibilityHidden(true)  // the count below carries it
                Stepper(value: $value, in: range) {
                    // Reads “Number of Drives, 12”, as the one-row layout does.
                    count.accessibilityLabel("\(title), \(value.formatted())")
                }
            }
        } else {
            Stepper(value: $value, in: range) {
                LabeledContent(title) { count }
            }
        }
    }

    private var count: some View {
        Text(value, format: .number)
            .monospacedDigit()
            .contentTransition(.numericText())
            .accessibilityIdentifier(identifier)
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
                            // The info sheet's caveat, for VoiceOver users who don't open it.
                            .accessibilityHint("zfs_estimate_hint".localized())
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
/// doesn't rest on colour alone. Grouped levels open a wider gap before the
/// first drive of each group; at regular width each group gets its own row
/// instead. In the single row each bar keeps its identity per drive, so a
/// change of groups slides the same bars into their new groups and recolors
/// them in place. The rows crossfade whenever the grouping or drive count
/// changes, as does a switch between one row and several. Under Reduce Motion
/// nothing moves: any change of grouping, drive count or level replaces the
/// strip, which crossfades instead, and its height jumps.
struct DriveStrip: View {
    let roles: [DriveRole]
    var groupSize: Int? = nil
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 26
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var barSpacing: CGFloat { roles.count > 12 ? 3 : 5 }

    /// On a regular-width layout each group gets its own row, using the extra
    /// width, unless there are so many groups that the rows would stack too tall.
    private var groupsAsRows: Bool {
        AdaptiveLayout.groupsAsRows(isRegularWidth: horizontalSizeClass == .regular, groupCount: groupCount)
    }
    private var rowSpacing: CGFloat { barSpacing * 2 }

    private var rowsHeight: CGFloat {
        CGFloat(groupCount) * barHeight + CGFloat(groupCount - 1) * rowSpacing
    }

    private func groupRange(_ group: Int) -> Range<Int> {
        let size = groupSize ?? roles.count
        return (group * size)..<min((group + 1) * size, roles.count)
    }

    /// Number of groups shown; one when the level isn't grouped.
    private var groupCount: Int {
        guard let size = groupSize, size > 0, roles.count > size else { return 1 }
        return (roles.count + size - 1) / size
    }

    /// Extra space before each group after the first, on top of the spacing.
    private var groupGap: CGFloat { barSpacing * 2 }

    /// Every bar gets the same width, up to 44 points, so the group gaps take
    /// their space from the row rather than from the bars beside them.
    private func barWidth(in available: CGFloat) -> CGFloat {
        guard !roles.isEmpty else { return 0 }
        let gaps = CGFloat(roles.count - 1) * barSpacing + CGFloat(groupCount - 1) * groupGap
        return max(0, min(44, (available - gaps) / CGFloat(roles.count)))
    }

    /// True for the first drive of every group after the first.
    private func isGroupStart(_ index: Int) -> Bool {
        guard let size = groupSize, size > 0, groupCount > 1 else { return false }
        return index > 0 && index % size == 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // A new set of rows, a switch between one row and rows, and under
            // Reduce Motion any new grouping or drive count, is a new view: it
            // fades in whole rather than sliding or resizing its bars, with the
            // old one fading out on top of it.
            GeometryReader { proxy in
                if groupsAsRows {
                    let size = groupSize ?? roles.count
                    let width = max(0, min(44, (proxy.size.width - CGFloat(size - 1) * barSpacing) / CGFloat(size)))
                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(0..<groupCount, id: \.self) { group in
                            HStack(spacing: barSpacing) {
                                ForEach(groupRange(group), id: \.self) { index in
                                    bar(for: roles[index])
                                        .frame(width: width, height: barHeight)
                                }
                            }
                        }
                    }
                    .id("rows-\(groupSize ?? 0)-\(roles.count)")
                    .transition(.opacity)
                } else {
                    let width = barWidth(in: proxy.size.width)
                    ZStack(alignment: .leading) {
                        HStack(spacing: barSpacing) {
                            ForEach(roles.indices, id: \.self) { index in
                                bar(for: roles[index])
                                    .frame(width: width, height: barHeight)
                                    .padding(.leading, isGroupStart(index) ? groupGap : 0)
                            }
                        }
                        .id(reduceMotion ? "\(groupSize ?? 0)-\(roles.count)" : "")
                        .transition(.opacity)
                    }
                }
            }
            // Geometry never interpolates under Reduce Motion: the .id swap
            // replaces the strip whenever its bars would move or resize, and
            // these animations only drive the fade and in-place recoloring.
            // They sit inside ClippedHeight, so they never reach the strip’s
            // height: that follows the caller's transaction, which is no
            // animation under Reduce Motion (the height and the legend jump)
            // and .snappy otherwise (the legend glides with it).
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: roles)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy, value: groupSize)
            .modifier(ClippedHeight(height: groupsAsRows ? rowsHeight : barHeight, overhang: barHeight))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        // The summary, then one element per group, so VoiceOver reads the structure.
        .accessibilityRepresentation {
            VStack {
                Text(accessibilitySummary)
                if groupCount > 1 {
                    ForEach(0..<groupCount, id: \.self) { group in
                        Text(groupAccessibility(group))
                    }
                }
            }
        }
    }

    private func groupAccessibility(_ group: Int) -> String {
        let members = roles[groupRange(group)]
        let parts = presentRoles.compactMap { role -> String? in
            let count = members.filter { $0 == role }.count
            return count > 0 ? String(format: "role_count".localized(), count, Self.name(of: role)) : nil
        }.joined(separator: ", ")
        return String(format: "drive_strip_group_accessibility".localized(), group + 1, groupCount, parts)
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

    /// One view type for every role, so a role change recolors a bar in
    /// place instead of replacing it.
    private func bar(for role: DriveRole) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        let (fill, stroke): (Color, Color) = switch role {
        case .data: (.accentColor, .clear)
        case .parity: (.indigo, .clear)
        case .mirror: (.accentColor.opacity(0.22), .accentColor)
        }
        return shape.fill(fill)
            .overlay(shape.strokeBorder(stroke, lineWidth: 1.5))
    }

    private var accessibilitySummary: String {
        let parts = presentRoles.map { role in
            String(format: "role_count".localized(), roles.filter { $0 == role }.count, Self.name(of: role))
        }.joined(separator: ", ")
        if groupCount > 1 {
            return String(format: "drive_strip_groups_accessibility".localized(), roles.count, groupCount, parts)
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

/// A top-aligned height that animates as layout, frame by frame, and hides
/// whatever hangs below it: rows on their way out stay inside the strip
/// rather than fading over the legend, and new rows are uncovered as the
/// legend moves down. Only the bottom edge clips. At the start of a change the
/// card shifts for a frame or two, and an incoming row can sit a few points
/// above the strip; a clip on the top edge would shave it.
private struct ClippedHeight: ViewModifier, Animatable {
    var height: CGFloat
    /// How far above the strip content may draw.
    var overhang: CGFloat

    nonisolated var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content
            .frame(height: height, alignment: .top)
            .mask(alignment: .bottom) {
                Rectangle().padding(.top, -overhang)
            }
    }
}

/// Five stars plus the word for the rating, read by VoiceOver as one phrase
/// (“Speed, 3 of 5, Medium”). Shared with the info sheet.
struct RatingRow: View {
    let title: String
    let rating: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var label: String { RaidCalculator.ratingLabel(rating) }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Title, stars and word each get their own line, so none breaks mid-word.
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    stars
                    Text(label)
                        .foregroundStyle(.secondary)
                }
            } else {
                LabeledContent {
                    HStack(spacing: 8) {
                        stars
                        Text(label)
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Text(title)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "rating_accessibility".localized(), title, rating, label))
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            }
        }
        .font(.footnote)
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
