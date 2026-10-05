//
//  NASView.swift
//  RaidCalculator2
//

import SwiftUI

struct NASView: View {
    @State private var viewModel = NASViewModel()
    @State private var contentWidth: CGFloat = 0
    @State private var customSizeBay: Int?
    @State private var customSize: Double = 8
    @State private var showingInfo = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motion: Animation? { reduceMotion ? nil : .snappy }

    private let readableWidth: CGFloat = 720

    var body: some View {
        let result = viewModel.result

        Form {
            Section {
                NASSummary(result: result, system: viewModel.system)
            }

            Section("nas_setup".localized()) {
                Picker("nas_system".localized(), selection: Binding(
                    get: { viewModel.system },
                    set: { value in withAnimation(motion) { viewModel.system = value } }
                )) {
                    ForEach(NASSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("nasSystem")
                .sensoryFeedback(.selection, trigger: viewModel.system)

                CountStepper(
                    title: "bay_count".localized(),
                    value: Binding(get: { viewModel.bayCount }, set: { value in withAnimation(motion) { viewModel.setBayCount(value) } }),
                    range: viewModel.system.bayRange,
                    identifier: "bayCount"
                )
                .sensoryFeedback(.selection, trigger: viewModel.bayCount)

                switch viewModel.system {
                case .synology:
                    Picker("raid_type".localized(), selection: Binding(
                        get: { viewModel.settings.synologyType },
                        set: { value in withAnimation(motion) { viewModel.settings.synologyType = value } }
                    )) {
                        ForEach(SynologyRaidType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: viewModel.settings.synologyType)
                case .unraid, .snapraid:
                    CountStepper(
                        title: "parity_drives".localized(),
                        value: Binding(
                            get: { viewModel.settings.parity(for: viewModel.system) ?? 1 },
                            set: { value in withAnimation(motion) { viewModel.settings.setParity(value, for: viewModel.system) } }
                        ),
                        range: viewModel.system.parityRange ?? 1...1,
                        identifier: "parityCount"
                    )
                    // Keyed on both systems' values, so switching between
                    // Unraid and SnapRAID isn't felt as a parity change.
                    .sensoryFeedback(.selection, trigger: [viewModel.settings.unraidParity, viewModel.settings.snapraidParity])
                case .zfs:
                    Picker("nas_zfs_level".localized(), selection: Binding(
                        get: { viewModel.settings.zfsParity },
                        set: { value in withAnimation(motion) { viewModel.settings.setParity(value, for: .zfs) } }
                    )) {
                        ForEach(1...3, id: \.self) { parity in
                            Text(ZFSMixedCalculator.level(parity: parity).displayName).tag(parity)
                        }
                    }
                    .accessibilityIdentifier("zfsLevel")
                    .sensoryFeedback(.selection, trigger: viewModel.settings.zfsParity)
                case .btrfs:
                    EmptyView()
                }
            }

            if let warning = result.warningMessage {
                Section {
                    Label {
                        Text(warning)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            } else if let suggestion = viewModel.suggestion {
                Section("suggestion_header".localized()) {
                    Button {
                        withAnimation(motion) { viewModel.applySuggestion() }
                    } label: {
                        LabeledContent {
                            Text(Self.signed(suggestion.gain))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .foregroundStyle(.tint)
                        } label: {
                            Label(Self.describe(suggestion), systemImage: "plus.circle.fill")
                        }
                    }
                    .accessibilityIdentifier("applySuggestion")
                }
            }

            if !viewModel.hints.isEmpty {
                Section {
                    ForEach(viewModel.hints, id: \.self) { hint in
                        Label {
                            Text(Self.text(for: hint))
                                .font(.subheadline)
                                .accessibilityIdentifier("nasHint")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                }
                .transition(.opacity)
            }

            if let delta = viewModel.usableDelta {
                Section("compared_header".localized()) {
                    LabeledContent("usable_capacity".localized()) {
                        Text(Self.signed(delta))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(delta > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }
                    .accessibilityIdentifier("usableDelta")
                    Button("save_as_current".localized()) {
                        withAnimation(motion) { viewModel.saveAsCurrent() }
                    }
                    Button("revert".localized(), role: .destructive) {
                        withAnimation(motion) { viewModel.revertToCurrent() }
                    }
                }
            }

            Section {
                ForEach(viewModel.bays.indices, id: \.self) { index in
                    bayRow(index)
                }
            } header: {
                Text("drives_section".localized())
            } footer: {
                if viewModel.system == .unraid || viewModel.system == .snapraid {
                    Text("parity_promotion_note".localized())
                        .accessibilityIdentifier("parityPromotionNote")
                }
            }
        }
        .sensoryFeedback(.success, trigger: result.warningMessage == nil) { wasValid, isValid in !wasValid && isValid }
        .navigationTitle("tab_nas".localized())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info")
                }
                .accessibilityLabel(String(format: "about_level".localized(), viewModel.system.displayName))
                .accessibilityIdentifier("nasInfo")
            }
        }
        .sheet(isPresented: $showingInfo) {
            InfoSheet(topic: .system(viewModel.system))
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
        .contentMargins(
            .horizontal,
            contentWidth > readableWidth + 40 ? (contentWidth - readableWidth) / 2 : nil,
            for: .scrollContent
        )
        .alert(
            "custom_size".localized(),
            isPresented: Binding(get: { customSizeBay != nil }, set: { if !$0 { customSizeBay = nil } })
        ) {
            TextField("TB", value: $customSize, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
            Button("cancel".localized(), role: .cancel) {}
            Button("done".localized()) {
                if let bay = customSizeBay, customSize > 0 {
                    withAnimation(motion) { viewModel.setSize(customSize, forBay: bay) }
                }
            }
        }
    }

    private func bayRow(_ index: Int) -> some View {
        let size = viewModel.bays[index]
        return Menu {
            ForEach(NASViewModel.commonSizes, id: \.self) { option in
                Button {
                    withAnimation(motion) { viewModel.setSize(option, forBay: index) }
                } label: {
                    if size == option {
                        Label(Self.tb(option), systemImage: "checkmark")
                    } else {
                        Text(Self.tb(option))
                    }
                }
            }
            Divider()
            Button("custom_size".localized()) {
                customSize = size ?? 8
                customSizeBay = index
            }
            if size != nil {
                Button("remove_drive".localized(), role: .destructive) {
                    withAnimation(motion) { viewModel.setSize(nil, forBay: index) }
                }
            }
        } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    Text(size.map(Self.tb) ?? "empty_bay".localized())
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } label: {
                Text(String(format: "bay_n".localized(), index + 1))
                    .foregroundStyle(.primary)
            }
        }
        .tint(.primary)
        .accessibilityIdentifier("bay\(index + 1)")
    }

    static func text(for hint: NASHint) -> String {
        switch hint {
        case .snapraidParity(let recommended, let range):
            // Word joiners keep “5–14” on one line.
            String(format: "snapraid_parity_hint".localized(), recommended, "\(range.lowerBound)\u{2060}–\u{2060}\(range.upperBound)")
        case .wideZFSGroup(let width):
            String(format: "wide_zfs_group_caution_single".localized(), width)
        }
    }

    /// A no-break space keeps “4 TB” from wrapping between number and unit.
    static func tb(_ value: Double) -> String {
        CapacitySummary.capacity(value, unit: CapacityUnit.tb.rawValue).replacingOccurrences(of: " ", with: "\u{00A0}")
    }

    /// The sign goes on the amount, inside the phrase, so Japanese reads
    /// “使用可能容量 +12 TB” rather than “+使用可能容量 12 TB”.
    static func signed(_ value: Double) -> String {
        String(format: "delta_usable".localized(), (value < 0 ? "−" : "+") + tb(abs(value)))
    }

    static func describe(_ suggestion: BaySuggestion) -> String {
        switch suggestion.kind {
        case .add(let bay):
            String(format: "suggest_add".localized(), tb(suggestion.size), bay + 1)
        case .replace(let bay, let currentSize):
            String(format: "suggest_replace".localized(), bay + 1, tb(currentSize), tb(suggestion.size))
        }
    }
}

/// The answer for any NAS system: usable space, what it costs, the bay
/// diagram, and the space this mix of drives leaves unused.
struct NASSummary: View {
    let result: BayResult
    let system: NASSystem

    private var isValid: Bool { result.warningMessage == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("usable_capacity".localized())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(NASView.tb(result.usableCapacity))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("nasUsableCapacity")
                if result.rawCapacity > 0 {
                    Text(String(
                        format: "raw_and_efficiency".localized(),
                        NASView.tb(result.rawCapacity),
                        result.efficiency.formatted(.percent.precision(.fractionLength(0)))
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            BayDiagram(bays: result.bays, system: system)

            if isValid {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("drive_failures_tolerated".localized())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(result.failuresTolerated, format: .number)
                            .font(.body.weight(.semibold))
                            .contentTransition(.numericText())
                    }
                } icon: {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(.tint)
                }
                .accessibilityElement(children: .combine)
            }

            if isValid, result.unusedCapacity > 0 {
                // An HStack, not a Label: at accessibility sizes a Label here
                // left the card's other text one line tall, so it truncated.
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    SegmentSwatch(role: .unused)
                        .frame(width: 14, height: 14)
                        .accessibilityHidden(true)
                    Text(String(format: "unused_summary".localized(), NASView.tb(result.unusedCapacity)))
                        .font(.subheadline.weight(.medium))
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("unusedSummary")
            }

            if isValid, result.usableCapacity > 0 {
                if let estimate = result.zfsEstimate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "zfs_reported_note".localized(), CapacitySummary.binaryBytes(estimate.reportedBytes, unit: .tb)))
                            .accessibilityIdentifier("zfsReportedNote")
                            .accessibilityHint("zfs_estimate_hint".localized())
                        if estimate.paddingLoss > 0.01 {
                            Text(String(format: "zfs_padding_note".localized(), estimate.paddingLoss.formatted(.percent.precision(.fractionLength(0)))))
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "binary_capacity_note".localized(), CapacitySummary.binaryCapacity(result.usableCapacity, unit: .tb)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(isValid ? 1 : 0.4)
        .animation(.default, value: isValid)
    }
}

/// Each bay drawn to scale: column height is the drive's size against the
/// largest drive, split into the layers SHR (or classic RAID) builds. Unused
/// capacity is hatched so it reads as unavailable, not as another colour.
struct BayDiagram: View {
    let bays: [[BaySegment]?]
    var system: NASSystem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var scaledHeight: CGFloat = 132
    /// Grows with Dynamic Type, but not so far that it pushes the controls off screen.
    private var maxHeight: CGFloat { min(scaledHeight, 190) }

    private var largest: Double {
        max(bays.compactMap { $0?.reduce(0) { $0 + $1.size } }.max() ?? 1, 0.001)
    }

    private var presentRoles: [SegmentRole] {
        let all = Set(bays.compactMap { $0 }.flatMap { $0.map(\.role) })
        return [.data, .parity, .mirror, .unused].filter(all.contains)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Under full motion the same bays animate their segments in place
            // with .snappy, whatever changed. Under Reduce Motion nothing moves:
            // every change (system, a bay's size, bay or parity count) is a new
            // diagram that crossfades over the old one; the ZStack overlaps them.
            Group {
                if bays.count > 12 {
                    ScrollView(.horizontal, showsIndicators: false) { columns }
                } else {
                    columns
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: bays)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
    }

    private var columns: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(alignment: .bottom, spacing: bays.count > 8 ? 4 : 8) {
                ForEach(Array(bays.enumerated()), id: \.offset) { index, segments in
                    VStack(spacing: 4) {
                        column(segments)
                            .frame(minWidth: bays.count > 12 ? 24 : nil, maxWidth: 72)
                            .frame(height: maxHeight, alignment: .bottom)
                        Text(segments.map { NASView.tb(total($0)) } ?? "empty_bay".localized())
                            .font(bays.count > 6 ? .caption2 : .caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            // Scrolling columns are 24 points wide; “20 TB” needs to shrink further to fit.
                            .minimumScaleFactor(bays.count > 12 ? 0.6 : 0.8)
                            .fixedSize(horizontal: bays.count <= 6, vertical: false)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(bay: index, segments: segments))
                }
            }
            // Keyed on the whole diagram under Reduce Motion, so any change swaps
            // the view instead of resizing its bars. The transition carries its
            // own animation because the change itself arrives unanimated.
            .id(reduceMotion ? AnyHashable([AnyHashable(system), AnyHashable(bays)]) : AnyHashable(0))
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }

    @ViewBuilder
    private func column(_ segments: [BaySegment]?) -> some View {
        if let segments {
            let height = maxHeight * total(segments) / largest
            VStack(spacing: 1.5) {
                ForEach(Array(segments.enumerated().reversed()), id: \.offset) { _, segment in
                    SegmentSwatch(role: segment.role)
                        .frame(height: max(2, height * segment.size / max(total(segments), 0.001) - 1.5))
                }
            }
            .frame(height: height, alignment: .bottom)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: maxHeight * 0.18)
        }
    }

    @ViewBuilder
    private var legend: some View {
        ForEach(presentRoles, id: \.self) { role in
            HStack(spacing: 5) {
                SegmentSwatch(role: role)
                    .frame(width: 10, height: 10)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                Text(SegmentSwatch.name(of: role))
            }
        }
    }

    private func total(_ segments: [BaySegment]) -> Double {
        segments.reduce(0) { $0 + $1.size }
    }

    private func accessibilityLabel(bay index: Int, segments: [BaySegment]?) -> String {
        let name = String(format: "bay_n".localized(), index + 1)
        guard let segments else { return "\(name), \("empty_bay".localized())" }
        var amounts: [SegmentRole: Double] = [:]
        for segment in segments { amounts[segment.role, default: 0] += segment.size }
        let parts = [SegmentRole.data, .parity, .mirror, .unused].compactMap { role in
            amounts[role].flatMap { $0 > 0 ? String(format: "role_amount".localized(), NASView.tb($0), SegmentSwatch.name(of: role)) : nil }
        }
        return String(format: "bay_accessibility".localized(), index + 1, NASView.tb(total(segments)), parts.joined(separator: ", "))
    }
}

/// Fill for one slice of a drive. Matches the RAID tab's drive strip: data is
/// the tint, parity indigo, mirrors an outlined tint, unused a grey hatch.
struct SegmentSwatch: View {
    let role: SegmentRole

    var body: some View {
        Rectangle()
            .fill(fill)
            .overlay(Rectangle().strokeBorder(stroke, lineWidth: 1.5))
            .overlay(Hatch().stroke(Color.secondary.opacity(role == .unused ? 0.55 : 0), lineWidth: 1))
            .clipped()
    }

    private var fill: Color {
        switch role {
        case .data: .accentColor
        case .parity: .indigo
        case .mirror: .accentColor.opacity(0.22)
        case .unused: .secondary.opacity(0.12)
        }
    }

    /// Mirrors are outlined so the distinction doesn't rest on colour alone.
    private var stroke: Color { role == .mirror ? .accentColor : .clear }

    static func name(of role: SegmentRole) -> String {
        switch role {
        case .data: "role_data".localized()
        case .parity: "role_parity".localized()
        case .mirror: "role_mirror".localized()
        case .unused: "role_unused".localized()
        }
    }
}

/// Diagonal lines across the rect, for unused capacity.
nonisolated struct Hatch: Shape {
    var spacing: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var offset = -rect.height
        while offset < rect.width {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.minY))
            offset += spacing
        }
        return path
    }
}

#Preview {
    NavigationStack {
        NASView()
    }
}
