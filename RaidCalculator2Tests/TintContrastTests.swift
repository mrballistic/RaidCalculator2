//
//  TintContrastTests.swift
//  RaidCalculator2Tests
//

import Testing
import UIKit
@testable import RAID_Calc

struct TintContrastTests {

    private static func traits(dark: Bool, high: Bool) -> UITraitCollection {
        UITraitCollection { t in
            t.userInterfaceStyle = dark ? .dark : .light
            t.accessibilityContrast = high ? .high : .normal
        }
    }

    private static func rgb(_ color: UIColor, _ traits: UITraitCollection) -> (Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private static func luminance(_ c: (Double, Double, Double)) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
    }

    static func ratio(_ a: UIColor, _ b: UIColor, _ traits: UITraitCollection) -> Double {
        let la = luminance(rgb(a, traits)), lb = luminance(rgb(b, traits))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    @Test func tintMeetsContrast() throws {
        let tint = try #require(UIColor(named: "AccentColor", in: Bundle.main, compatibleWith: nil))
        let backgrounds: [(String, UIColor)] = [
            ("systemBackground", .systemBackground),
            ("secondarySystemGroupedBackground", .secondarySystemGroupedBackground),
            ("systemGroupedBackground", .systemGroupedBackground),
        ]
        for dark in [false, true] {
            for high in [false, true] {
                let t = Self.traits(dark: dark, high: high)
                for (name, bg) in backgrounds {
                    let r = Self.ratio(tint, bg, t)
                    print("CONTRAST dark=\(dark) high=\(high) \(name): \(String(format: "%.2f", r))")
                    #expect(r >= 4.5, "tint on \(name), dark=\(dark) high=\(high): \(r)")
                }
            }
        }
    }
}

