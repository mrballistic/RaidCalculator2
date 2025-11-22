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
    
    private var fullRaidName: String {
        switch level {
        case .raid0: return "RAID 0"
        case .raid1: return "RAID 1"
        case .raid5: return "RAID 5"
        case .raid6: return "RAID 6"
        case .raid10: return "RAID 10"
        case .jbod: return "JBOD"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    overviewSection
                    prosConsSection
                    useCasesSection
                    ratingsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle(fullRaidName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            Text(info.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var prosConsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pros & Cons")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pros", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    
                    ForEach(info.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .padding(.top, 2)
                            
                            Text(pro)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cons", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                    
                    ForEach(info.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .padding(.top, 2)
                            
                            Text(con)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
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
    
    private var useCasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Typical Use Cases")
                .font(.headline)
            
            ForEach(info.useCases, id: \.self) { useCase in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 2)
                    
                    Text(useCase)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Ratings")
                .font(.headline)
            
            VStack(spacing: 12) {
                RatingRow(
                    title: "Speed",
                    rating: info.speedRating,
                    label: speedLabel(info.speedRating)
                )
                
                RatingRow(
                    title: "Availability",
                    rating: info.availabilityRating,
                    label: availabilityLabel(info.availabilityRating)
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
    
    private var info: RaidInfo {
        switch level {
        case .raid0:
            return RaidInfo(
                description: "RAID 0 (Striping) splits data across multiple drives for maximum performance, but provides no redundancy. If any drive fails, all data is lost.",
                pros: [
                    "Maximum performance and speed",
                    "Full storage capacity utilization",
                    "Simple to implement"
                ],
                cons: [
                    "No data redundancy or protection",
                    "Single drive failure causes complete data loss",
                    "Not suitable for critical data"
                ],
                useCases: [
                    "Video editing and temporary work files",
                    "Gaming and applications needing fast I/O",
                    "Cache or temporary storage systems"
                ],
                speedRating: 5,
                availabilityRating: 1
            )
        case .raid1:
            return RaidInfo(
                description: "RAID 1 (Mirroring) creates exact copies of data on multiple drives. Provides excellent redundancy but halves the usable capacity.",
                pros: [
                    "Complete data redundancy",
                    "Fast read performance",
                    "Simple recovery from drive failure"
                ],
                cons: [
                    "50% storage capacity efficiency",
                    "Higher cost per usable GB",
                    "Write performance similar to single drive"
                ],
                useCases: [
                    "Boot drives and operating systems",
                    "Critical databases and applications",
                    "Small business servers"
                ],
                speedRating: 2,
                availabilityRating: 5
            )
        case .raid5:
            return RaidInfo(
                description: "RAID 5 (Striping with Parity) distributes data and parity across all drives. Provides good performance and redundancy with minimal capacity overhead.",
                pros: [
                    "Good balance of performance and redundancy",
                    "Efficient use of storage capacity",
                    "Can survive one drive failure"
                ],
                cons: [
                    "Slower write performance due to parity calculation",
                    "Rebuild can be slow with large drives",
                    "Risk of data loss during rebuild if another drive fails"
                ],
                useCases: [
                    "File servers and network attached storage",
                    "General purpose server storage",
                    "Backup and archive systems"
                ],
                speedRating: 3,
                availabilityRating: 3
            )
        case .raid6:
            return RaidInfo(
                description: "RAID 6 (Striping with Dual Parity) similar to RAID 5 but with two parity sets. Can survive two simultaneous drive failures.",
                pros: [
                    "Excellent redundancy (tolerates 2 drive failures)",
                    "Good protection during rebuild operations",
                    "Suitable for large capacity drives"
                ],
                cons: [
                    "Higher capacity overhead than RAID 5",
                    "Slower write performance than RAID 5",
                    "More complex implementation"
                ],
                useCases: [
                    "Large enterprise storage systems",
                    "Critical data archives",
                    "Systems with long rebuild times"
                ],
                speedRating: 2,
                availabilityRating: 4
            )
        case .raid10:
            return RaidInfo(
                description: "RAID 10 (Stripe of Mirrors) combines mirroring and striping. Provides excellent performance and redundancy but requires even number of drives.",
                pros: [
                    "Excellent performance for reads and writes",
                    "High redundancy with fast rebuild",
                    "Can survive multiple drive failures (if in different mirrors)"
                ],
                cons: [
                    "50% storage capacity efficiency",
                    "Requires even number of drives (minimum 4)",
                    "Higher cost per usable GB"
                ],
                useCases: [
                    "High-performance databases",
                    "Virtualization and server clusters",
                    "Critical applications needing both speed and redundancy"
                ],
                speedRating: 4,
                availabilityRating: 5
            )
        case .jbod:
            return RaidInfo(
                description: "JBOD (Just a Bunch Of Disks) combines multiple drives as one large volume without any RAID features. Each drive operates independently.",
                pros: [
                    "Simple and flexible",
                    "Full utilization of all drive capacity",
                    "No performance overhead from RAID calculations"
                ],
                cons: [
                    "No redundancy or data protection",
                    "Drive failure affects only data on that drive",
                    "No performance benefits of striping"
                ],
                useCases: [
                    "Large single-volume storage needs",
                    "Archiving and backup systems",
                    "Media servers and libraries"
                ],
                speedRating: 2,
                availabilityRating: 1
            )
        }
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

struct RatingRow: View {
    let title: String
    let rating: Int
    let label: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            Spacer()
        }
    }
}

struct RaidInfo {
    let description: String
    let pros: [String]
    let cons: [String]
    let useCases: [String]
    let speedRating: Int
    let availabilityRating: Int
}

#Preview {
    RaidInfoSheet(level: .raid5)
}
