//
//  SwiftClickerApp.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI

@main
struct SwiftClickerApp: App {
    @StateObject private var config = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(config)
                .frame(width: 390, height: 680)
        }
        .windowResizability(.contentSize)
    }
}
