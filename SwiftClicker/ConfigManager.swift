//
//  ConfigManager.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI
import Combine

class ConfigManager: ObservableObject {
    @Published var customCode: String = "123"
    @Published var backgroundImagePath: String = ""
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

        if let v = plist["customCode"] as? String         { customCode = v }
        if let v = plist["backgroundImagePath"] as? String { backgroundImagePath = v }
        if let v = plist["appTheme"] as? Int              { appTheme = v }
        if let v = plist["textColorR"] as? Double         { textColorR = v }
        if let v = plist["textColorG"] as? Double         { textColorG = v }
        if let v = plist["textColorB"] as? Double         { textColorB = v }
    }

    func save() {
        guard let url = configURL else { return }
        let plist: [String: Any] = [
            "version": "4.0",
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
