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
                    .navigationTitle {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 20))
                            Text("app_title".localized())
                        }
                    }
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}
