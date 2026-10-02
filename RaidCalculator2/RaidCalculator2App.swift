//
//  RaidCalculator2App.swift
//  RaidCalculator2
//
//  Created by todd.greco on 11/22/25.
//

import SwiftUI

@main
struct RaidCalculator2App: App {
    @AppStorage("selectedTab") private var selectedTab = "raid"

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Tab("tab_raid".localized(), systemImage: "square.stack.3d.up", value: "raid") {
                    NavigationStack {
                        ContentView()
                    }
                }
                Tab("tab_synology".localized(), systemImage: "externaldrive.connected.to.line.below", value: "synology") {
                    NavigationStack {
                        SynologyView()
                    }
                }
            }
        }
    }
}
