//
//  RetirementNotice.swift
//  RaidCalculator2
//

import SwiftUI

/// Shown once, on the first launch of 1.8.0: RAID Calc2 is retiring, and
/// RAID Calculator is where to go next.
struct RetirementSheet: View {
    let phase: Retirement.Phase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // The copy and buttons as one centred stack when they fit, so there's
        // no gap above the buttons on iPad; otherwise the copy scrolls and
        // both buttons stay on screen below it.
        ViewThatFits(in: .vertical) {
            VStack(spacing: 0) {
                copy
                buttons
            }
            ScrollView { copy }
                .safeAreaInset(edge: .bottom) {
                    // Keeps the scrolling copy from showing through.
                    buttons.background(.bar)
                }
        }
        // At accessibility sizes the copy needs the whole screen.
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
    }

    private var copy: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("retirement_title".localized())
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("retirementTitle")
            Text(Retirement.body(phase))
            Text("retirement_pitch".localized())
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 480)
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            Button {
                AppStorePage.open(fallback: openURL)
            } label: {
                Text("retirement_get".localized())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityIdentifier("retirementGet")

            Button("retirement_not_now".localized()) { dismiss() }
                .controlSize(.large)
                .accessibilityIdentifier("retirementNotNow")
        }
        .frame(maxWidth: 480)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }
}

/// A permanent row at the top of the form: the date, or that the app is gone,
/// and a way to RAID Calculator. It wraps at large sizes rather than truncating.
struct RetirementBanner: View {
    let phase: Retirement.Phase
    @Environment(\.openURL) private var openURL
    /// At accessibility sizes the symbols go, so the words get the whole
    /// width and never break mid-word.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            AppStorePage.open(fallback: openURL)
        } label: {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(Retirement.bannerTitle(phase))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("retirement_get".localized())
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityIdentifier("retirementBanner")
    }
}

#Preview("Sheet") {
    Color.clear.sheet(isPresented: .constant(true)) { RetirementSheet(phase: .retiring) }
}

#Preview("Banner") {
    Form {
        Section { RetirementBanner(phase: .retiring) }
        Section { RetirementBanner(phase: .retired) }
    }
}
