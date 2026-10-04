//
//  SynologyView.swift
//  RaidCalculator2
//

import SwiftUI

struct SynologyView: View {
    @State private var viewModel = SynologyViewModel()
    @State private var contentWidth: CGFloat = 0
    @State private var customSizeBay: Int?
    @State private var customSize: Double = 8

    private let readableWidth: CGFloat = 720

    var body: some View {
        let result = viewModel.result

        Form {
            Section {
                SynologySummary(result: result)
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
                        withAnimation(.snappy) { viewModel.applySuggestion() }
                    } label: {
                        LabeledContent {
                            Text(Self.signed(suggestion.gain))
                                .monospacedDigit()
                                .foregroundStyle(.tint)
                        } label: {
                            Label(Self.describe(suggestion), systemImage: "plus.circle.fill")
                        }
                    }
                    .accessibilityIdentifier("applySuggestion")
                }
            }

            if let delta = viewModel.usableDelta {
                Section("compared_header".localized()) {
                    LabeledContent("usable_capacity".localized()) {
                        Text(Self.signed(delta))
                            .monospacedDigit()
                            .foregroundStyle(delta > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }
                    .accessibilityIdentifier("usableDelta")
                    Button("save_as_current".localized()) {
                        withAnimation { viewModel.saveAsCurrent() }
                    }
                    Button("revert".localized(), role: .destructive) {
                        withAnimation(.snappy) { viewModel.revertToCurrent() }
                    }
                }
            }

            Section("nas_setup".localized()) {
                Picker("model".localized(), selection: $viewModel.modelID) {
                    ForEach(SynologyModel.presets) { model in
                        Text("\(model.id) · \(String(format: "bay_count_value".localized(), model.bays))")
                            .tag(model.id)
                    }
                    Text("custom_model".localized()).tag(SynologyModel.custom)
                }
                if viewModel.modelID == SynologyModel.custom {
                    Stepper(value: $viewModel.customBayCount, in: SynologyModel.customBayRange) {
                        LabeledContent("bay_count".localized()) {
                            Text(viewModel.customBayCount, format: .number).monospacedDigit()
                        }
                    }
                }
                Picker("raid_type".localized(), selection: $viewModel.raidType) {
                    ForEach(SynologyRaidType.allCases) { type in
                        Text(type.rawValue).tag(type)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("shr_footnote".localized())
                    Text("not_affiliated".localized())
                }
            }
        }
        .navigationTitle("tab_synology".localized())
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
                    withAnimation(.snappy) { viewModel.setSize(customSize, forBay: bay) }
                }
            }
        }
    }

    private func bayRow(_ index: Int) -> some View {
        let size = viewModel.bays[index]
        return Menu {
            ForEach(SynologyViewModel.commonSizes, id: \.self) { option in
                Button {
                    withAnimation(.snappy) { viewModel.setSize(option, forBay: index) }
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
                    withAnimation(.snappy) { viewModel.setSize(nil, forBay: index) }
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

    static func tb(_ value: Double) -> String {
        CapacitySummary.capacity(value, unit: CapacityUnit.tb.rawValue)
    }

    static func signed(_ value: Double) -> String {
        let magnitude = String(format: "delta_usable".localized(), tb(abs(value)))
        return (value < 0 ? "−" : "+") + magnitude
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

/// The answer for a Synology: usable space, what it costs, the bay diagram,
/// and the space this mix of drives leaves unused.
struct SynologySummary: View {
    let result: BayResult

    private var isValid: Bool { result.warningMessage == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("usable_capacity".localized())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(SynologyView.tb(result.usableCapacity))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("synologyUsableCapacity")
                if result.rawCapacity > 0 {
                    Text(String(
                        format: "raw_and_efficiency".localized(),
                        SynologyView.tb(result.rawCapacity),
                        result.efficiency.formatted(.percent.precision(.fractionLength(0)))
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            BayDiagram(bays: result.bays)

            if isValid {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("drive_failures_tolerated".localized())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(result.failuresTolerated, format: .number)
                            .font(.body.weight(.semibold))
                    }
                } icon: {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(.tint)
                }
                .accessibilityElement(children: .combine)
            }

            if isValid, result.unusedCapacity > 0 {
                Label {
                    Text(String(format: "unused_summary".localized(), SynologyView.tb(result.unusedCapacity)))
                        .font(.subheadline.weight(.medium))
                } icon: {
                    SegmentSwatch(role: .unused)
                        .frame(width: 14, height: 14)
                }
                .accessibilityIdentifier("unusedSummary")
            }

            if isValid, result.usableCapacity > 0 {
                Text(String(format: "binary_capacity_note".localized(), CapacitySummary.binaryCapacity(result.usableCapacity, unit: .tb)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
            HStack(alignment: .bottom, spacing: bays.count > 8 ? 4 : 8) {
                ForEach(Array(bays.enumerated()), id: \.offset) { index, segments in
                    VStack(spacing: 4) {
                        column(segments)
                            .frame(maxWidth: 72)
                            .frame(height: maxHeight, alignment: .bottom)
                        Text(segments.map { SynologyView.tb(total($0)) } ?? "empty_bay".localized())
                            .font(bays.count > 6 ? .caption2 : .caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: bays.count <= 6, vertical: false)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(bay: index, segments: segments))
                }
            }
            .animation(.snappy, value: bays)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { legend }
                VStack(alignment: .leading, spacing: 4) { legend }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
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
            amounts[role].map { String(format: "role_amount".localized(), SynologyView.tb($0), SegmentSwatch.name(of: role)) }
        }
        return String(format: "bay_accessibility".localized(), index + 1, SynologyView.tb(total(segments)), parts.joined(separator: ", "))
    }
}

/// Fill for one slice of a drive. Matches the RAID tab's drive strip: data is
/// the tint, parity indigo, mirrors an outlined tint, unused a grey hatch.
struct SegmentSwatch: View {
    let role: SegmentRole

    var body: some View {
        switch role {
        case .data:
            Rectangle().fill(Color.accentColor)
        case .parity:
            Rectangle().fill(Color.indigo)
        case .mirror:
            Rectangle().fill(Color.accentColor.opacity(0.22))
                .overlay(Rectangle().strokeBorder(Color.accentColor, lineWidth: 1.5))
        case .unused:
            Rectangle().fill(Color.secondary.opacity(0.12))
                .overlay(Hatch().stroke(Color.secondary.opacity(0.55), lineWidth: 1))
                .clipped()
        }
    }

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
        SynologyView()
    }
}
