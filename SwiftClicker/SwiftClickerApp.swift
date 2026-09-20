//
//  SwiftClickerApp.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI

@main
struct SwiftClickerApp: App {
    @StateObject private var config: ConfigManager
    #if os(macOS)
    @StateObject private var engine: ClickerEngine
    @StateObject private var overlay: OverlayController
    private let hotkeys = HotkeyMonitor()
    #endif

    init() {
        let config = ConfigManager()
        _config = StateObject(wrappedValue: config)
        #if os(macOS)
        let engine = ClickerEngine(config: config)
        _engine = StateObject(wrappedValue: engine)
        _overlay = StateObject(wrappedValue: OverlayController(config: config, engine: engine))
        #endif
    }

    var body: some Scene {
        mainScene
        #if os(macOS)
        gameScene
        #endif
    }

    private var mainScene: some Scene {
        #if os(macOS)
        WindowGroup {
            mainContent
        }
        .windowResizability(.contentSize)
        #else
        WindowGroup {
            mainContent
        }
        #endif
    }

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        ContentView()
            .environmentObject(config)
            .environmentObject(engine)
            .environmentObject(overlay)
            .frame(width: Layout.windowSize.width, height: Layout.windowSize.height)
            .onAppear {
                if config.overlayVisible { overlay.show() }
                hotkeys.update(keyCode: config.hotkeyKeyCode) { engine.toggle() }
            }
            .onChange(of: config.hotkeyKeyCode) { _, code in
                hotkeys.update(keyCode: code) { engine.toggle() }
            }
        #else
        ContentView()
            .environmentObject(config)
        #endif
    }

    #if os(macOS)
    /// The game keeps its own window, sized the way it always was.
    private var gameScene: some Scene {
        Window("SwiftClicker Game", id: "game") {
            GameView()
                .environmentObject(config)
                .frame(width: Layout.gameWindowSize.width, height: Layout.gameWindowSize.height)
        }
        .windowResizability(.contentSize)
    }
    #endif
}
