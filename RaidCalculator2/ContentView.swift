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
        ScrollView {
            LazyVStack(spacing: 24) {
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
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onChange(of: viewModel.selectedLevel) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.driveCount) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.driveSize) { _, _ in viewModel.recalculate() }
        .onChange(of: viewModel.unit) { _, _ in viewModel.recalculate() }
        .sheet(isPresented: $showingInfoSheet) {
            RaidInfoSheet(level: viewModel.selectedLevel)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 32))
                .foregroundStyle(.primary)
            Text("RAID Calculator")
                .font(.title.bold())
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private var raidLevelSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RAID Level")
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var driveConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Drive Configuration")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Number of Drives")
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.driveCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                Stepper("", value: $viewModel.driveCount, in: 1...24)
                    .labelsHidden()
                
                Divider()
                
                HStack {
                    Text("Drive Size")
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func resultsCard(_ result: RaidResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Results")
                .font(.headline)
            
            VStack(spacing: 12) {
                ResultRow(
                    title: "Usable Capacity",
                    value: "\(String(format: "%.1f", result.usableCapacity)) \(viewModel.unit.rawValue)",
                    icon: "externaldrive.fill"
                )
                
                ResultRow(
                    title: "Drive Failures Tolerated",
                    value: result.failuresTolerated,
                    icon: "shield.fill"
                )
                
                ResultRow(
                    title: "Speed",
                    value: starRating(result.speedRating),
                    icon: "speedometer",
                    subtitle: speedLabel(result.speedRating)
                )
                
                ResultRow(
                    title: "Availability",
                    value: starRating(result.availabilityRating),
                    icon: "checkmark.shield.fill",
                    subtitle: availabilityLabel(result.availabilityRating)
                )
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func warningCard(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func starRating(_ rating: Int) -> String {
        let filledStars = String(repeating: "★", count: rating)
        let emptyStars = String(repeating: "☆", count: 5 - rating)
        return filledStars + emptyStars
    }
    
    private func speedLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "Very High"
        case 4: return "High"
        case 3: return "Medium"
        case 2: return "Low"
        case 1: return "Very Low"
        default: return ""
        }
    }
    
    private func availabilityLabel(_ rating: Int) -> String {
        switch rating {
        case 5: return "Very High"
        case 4: return "High"
        case 3: return "Medium"
        case 2: return "Low"
        case 1: return "Very Low"
        default: return ""
        }
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
