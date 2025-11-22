//
//  RaidCalculator2App.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

@main
struct RaidCalculator2App: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .navigationTitle("app_title".localized())
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}
