//
//  RaidCalculator2App.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

@main
struct RaidCalculator2App: App {
    init() {
        #if DEBUG
        // UI tests and screenshots: show the first-launch notice again.
        if UserDefaults.standard.bool(forKey: "legacy.resetNotice") {
            UserDefaults.standard.removeObject(forKey: Retirement.seenKey)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
