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
                #if os(macOS)
                .frame(width: Layout.windowSize.width, height: Layout.windowSize.height)
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
