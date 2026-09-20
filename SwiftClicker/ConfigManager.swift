//
//  ConfigManager.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI
import Combine

class ConfigManager: ObservableObject {
    // Clicker
    @Published var clicksPerSecond: Double = 10
    @Published var clickTarget: Int = 0          // 0 = follow the cursor, 1 = fixed point
    @Published var fixedPointX: Double = 0
    @Published var fixedPointY: Double = 0
    @Published var startDelay: Double = 3        // countdown before clicking starts
    @Published var hotkeyKeyCode: Int = 97       // F6; -1 disables the hotkey

    // Overlay
    @Published var overlayStyle: Int = 0         // 0 = pill, 1 = circle, 2 = bar
    @Published var overlayVisible: Bool = true
    @Published var overlayX: Double = -1         // -1 = not positioned yet
    @Published var overlayY: Double = -1

    // Game
    @Published var customCode: String = "123"
    @Published var backgroundImagePath: String = ""

    // Appearance
    @Published var appTheme: Int = 0
    @Published var textColorR: Double = 1.0
    @Published var textColorG: Double = 1.0
    @Published var textColorB: Double = 1.0

    private var cancellables = Set<AnyCancellable>()
    private var isLoading = false

    var textColor: Color {
        Color(red: textColorR, green: textColorG, blue: textColorB)
    }

    var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    /// Clicks are sent this far apart.
    var clickInterval: Double {
        1.0 / max(1.0, clicksPerSecond)
    }

    var fixedPoint: CGPoint {
        CGPoint(x: fixedPointX, y: fixedPointY)
    }

    private var appSupportDir: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("SwiftClicker")
    }

    private var configURL: URL? {
        appSupportDir?.appendingPathComponent("config.plist")
    }

    private func setupDirectory() {
        guard let dir = appSupportDir else {
            print("[ConfigManager] Cannot resolve Application Support directory")
            return
        }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            print("[ConfigManager] Directory ready: \(dir.path)")
        } catch {
            print("[ConfigManager] Failed to create directory: \(error)")
        }
    }

    init() {
        setupDirectory()
        load()

        // objectWillChange fires before the change; with debounce the save runs
        // after values have already updated
        objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isLoading else { return }
                self.save()
            }
            .store(in: &cancellables)
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        guard let url = configURL,
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return }

        if let v = plist["clicksPerSecond"] as? Double      { clicksPerSecond = v }
        if let v = plist["clickTarget"] as? Int             { clickTarget = v }
        if let v = plist["fixedPointX"] as? Double          { fixedPointX = v }
        if let v = plist["fixedPointY"] as? Double          { fixedPointY = v }
        if let v = plist["startDelay"] as? Double           { startDelay = v }
        if let v = plist["hotkeyKeyCode"] as? Int           { hotkeyKeyCode = v }
        if let v = plist["overlayStyle"] as? Int            { overlayStyle = v }
        if let v = plist["overlayVisible"] as? Bool         { overlayVisible = v }
        if let v = plist["overlayX"] as? Double             { overlayX = v }
        if let v = plist["overlayY"] as? Double             { overlayY = v }
        if let v = plist["customCode"] as? String           { customCode = v }
        if let v = plist["backgroundImagePath"] as? String  { backgroundImagePath = v }
        if let v = plist["appTheme"] as? Int                { appTheme = v }
        if let v = plist["textColorR"] as? Double           { textColorR = v }
        if let v = plist["textColorG"] as? Double           { textColorG = v }
        if let v = plist["textColorB"] as? Double           { textColorB = v }
    }

    func save() {
        guard let url = configURL else { return }
        let plist: [String: Any] = [
            "version": AppInfo.version,
            "clicksPerSecond": clicksPerSecond,
            "clickTarget": clickTarget,
            "fixedPointX": fixedPointX,
            "fixedPointY": fixedPointY,
            "startDelay": startDelay,
            "hotkeyKeyCode": hotkeyKeyCode,
            "overlayStyle": overlayStyle,
            "overlayVisible": overlayVisible,
            "overlayX": overlayX,
            "overlayY": overlayY,
            "customCode": customCode,
            "backgroundImagePath": backgroundImagePath,
            "appTheme": appTheme,
            "textColorR": textColorR,
            "textColorG": textColorG,
            "textColorB": textColorB
        ]
        let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try? data?.write(to: url)
    }
}
