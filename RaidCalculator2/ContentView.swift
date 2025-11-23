//
//  ContentView.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RaidCalculatorViewModel()
    @State private var showingInfoSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width > 700 {
                    // iPad Layout - Two columns
                    ipadLayout
                } else {
                    // iPhone Layout - Single column
                    iphoneLayout
                }
            }
        }
        .background(
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.15),
                    .blue.opacity(0.2), 
                    .purple.opacity(0.15)
                ],
                center: .topLeading,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        )
        .onTapGesture {
            hideKeyboard()
        }
        .onChange(of: viewModel.selectedLevel) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.driveCount) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.driveSize) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.unit) { _, _ in viewModel.recalculate() }
        .sheet(isPresented: $showingInfoSheet) {
            RaidInfoSheet(level: viewModel.selectedLevel)
        }
    }
    
    private var iphoneLayout: some View {
        VStack(spacing: 24) {
            headerSection
            raidLevelSelector
            driveConfiguration
            if let result = viewModel.result {
                if result.warningMessage != nil {
                    warningCard(result.warningMessage!)
                } else {
                    resultsCard(result)
                }
            }
        }
        .padding()
    }
    
    private var ipadLayout: some View {
        VStack(spacing: 32) {
            headerSection
            
            HStack(alignment: .top, spacing: 24) {
                // Left column - Input controls
                VStack(spacing: 24) {
                    raidLevelSelector
                    driveConfiguration
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right column - Results
                VStack(spacing: 24) {
                    if let result = viewModel.result {
                        if result.warningMessage != nil {
                            warningCard(result.warningMessage!)
                        } else {
                            resultsCard(result)
                        }
                    } else {
                        // Placeholder card for consistent layout
                        placeholderResultsCard
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(32)
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 4)
            Text("RAID Calculator")
                .font(.title.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private var raidLevelSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("raid_level".localized())
                    .font(.headline)
                Spacer()
                Button(action: { showingInfoSheet = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            
            Picker("RAID Level", selection: $viewModel.selectedLevel) {
                ForEach(RaidLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var driveConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("drive_configuration".localized())
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    Text("number_of_drives".localized())
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: { 
                            if viewModel.driveCount > 1 {
                                viewModel.driveCount -= 1 
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.accentColor)
                        }
                        .disabled(viewModel.driveCount <= 1)
                        
                        Text("\(viewModel.driveCount)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(minWidth: 30)
                            .accessibilityIdentifier("driveCount")
                        
                        Button(action: { 
                            if viewModel.driveCount < 24 {
                                viewModel.driveCount += 1 
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.accentColor)
                        }
                        .disabled(viewModel.driveCount >= 24)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("drive_size".localized())
                        .font(.subheadline)
                    Spacer()
                    HStack {
                        TextField("Size", value: $viewModel.driveSize, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        
                        Picker("Unit", selection: $viewModel.unit) {
                            ForEach(CapacityUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func resultsCard(_ result: RaidResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("results".localized())
                .font(.headline)
            
            VStack(spacing: 12) {
                ResultRow(
                    title: "usable_capacity".localized(),
                    value: "\(String(format: "%.1f", result.usableCapacity)) \(viewModel.unit.rawValue)",
                    icon: "externaldrive.fill"
                )
                
                ResultRow(
                    title: "drive_failures_tolerated".localized(),
                    value: result.failuresTolerated,
                    icon: "shield.fill"
                )
                
                ResultRow(
                    title: "speed".localized(),
                    value: starRating(result.speedRating),
                    icon: "speedometer",
                    subtitle: speedLabel(result.speedRating)
                )
                
                ResultRow(
                    title: "availability".localized(),
                    value: starRating(result.availabilityRating),
                    icon: "checkmark.shield.fill",
                    subtitle: availabilityLabel(result.availabilityRating)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func warningCard(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private func starRating(_ rating: Int) -> String {
        let filledStars = String(repeating: "★", count: rating)
        let emptyStars = String(repeating: "☆", count: 5 - rating)
        return filledStars + emptyStars
    }
    
    private func speedLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "very_high".localized()
        case 4: return "high".localized()
        case 3: return "medium".localized()
        case 2: return "low".localized()
        case 1: return "very_low".localized()
        default: return ""
        }
    }
    
    private func availabilityLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "very_high".localized()
        case 4: return "high".localized()
        case 3: return "medium".localized()
        case 2: return "low".localized()
        case 1: return "very_low".localized()
        default: return ""
        }
    }
    
    private var placeholderResultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("results".localized())
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("usable_capacity".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("drive_failures_tolerated".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("minimum_drives".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("storage_efficiency".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let icon: String
    let subtitle: String?
    
    init(title: String, value: String, icon: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body.weight(.medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
