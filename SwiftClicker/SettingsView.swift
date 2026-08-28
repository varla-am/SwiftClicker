//
//  SettingsView.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 440, height: 260)
        .padding(.bottom, 8)
    }
}

struct GeneralTab: View {
    @AppStorage("customCode") private var customCode = "123"
    @AppStorage("backgroundImagePath") private var backgroundImagePath = ""
    @State private var showFileImporter = false

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Background Image")
                    .gridColumnAlignment(.trailing)
                HStack(spacing: 8) {
                    if !backgroundImagePath.isEmpty {
                        Text(URL(fileURLWithPath: backgroundImagePath).lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Button("Choose...") { showFileImporter = true }
                    if !backgroundImagePath.isEmpty {
                        Button("Reset") { backgroundImagePath = "" }
                            .foregroundStyle(.red)
                    }
                }
            }
            GridRow {
                Text("Custom Mode Code")
                    .gridColumnAlignment(.trailing)
                TextField("", text: $customCode)
                    .frame(width: 120)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                backgroundImagePath = url.path
            }
        }
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 10) {
            Image("AppIconDisplay")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(18)

            Text("SwiftClicker v3.0")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Text("by Varlaam (varla-am)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text("Source Code:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link("https://github.com/varla-am/SwiftClicker",
                     destination: URL(string: "https://github.com/varla-am/SwiftClicker")!)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
