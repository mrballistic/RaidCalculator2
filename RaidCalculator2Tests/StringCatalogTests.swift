//
//  StringCatalogTests.swift
//  RaidCalculator2Tests
//

import Foundation
import Testing
@testable import RAID_Calc

struct StringCatalogTests {
    /// A literal “50%” can't follow each language's number style (“50 %” in
    /// French, German and Russian), and Xcode flags it in the catalog. Copy
    /// that needs a percentage formats it in code, with FormatStyle.
    @Test func noStringHardCodesAPercentage() {
        // The unit tests run inside the app, so its bundle is the main one.
        let app = Bundle.main
        #expect(app.localizations.count >= 11, "\(app.localizations)")
        var offenders: [String] = []
        var checked = 0
        for language in app.localizations where language != "Base" {
            guard let path = app.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language),
                  let table = NSDictionary(contentsOfFile: path) as? [String: String] else { continue }
            checked += 1
            for (key, value) in table where value.range(of: #"\d\s?%(?!\d*\$|[@dlfsu])"#, options: .regularExpression) != nil {
                offenders.append("\(language): \(key)")
            }
        }
        // A table that never loaded would make the check pass vacuously.
        #expect(checked == app.localizations.filter { $0 != "Base" }.count, "checked \(checked) of \(app.localizations)")
        #expect(offenders.isEmpty, "\(offenders.sorted())")
    }
}
