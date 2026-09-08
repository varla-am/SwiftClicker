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
        .frame(width: 440, height: 300)
        .padding(.bottom, 8)
    }
}

struct GeneralTab: View {
    @EnvironmentObject var config: ConfigManager
    @State private var showFileImporter = false
    @State private var hasAppeared = false

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(red: config.textColorR, green: config.textColorG, blue: config.textColorB) },
            set: { color in
                if let components = NSColor(color).usingColorSpace(.sRGB) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        config.textColorR = components.redComponent
                        config.textColorG = components.greenComponent
                        config.textColorB = components.blueComponent
                    }
                }
            }
        )
    }

    private var currentColor: Color {
        Color(red: config.textColorR, green: config.textColorG, blue: config.textColorB)
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Background Image")
                    .gridColumnAlignment(.trailing)
                HStack(spacing: 8) {
                    if !config.backgroundImagePath.isEmpty {
                        Text(URL(fileURLWithPath: config.backgroundImagePath).lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .transition(.asymmetric(
                                insertion: .push(from: .leading).combined(with: .opacity),
                                removal: .scale(scale: 0.85).combined(with: .opacity)))
                    }
                    Button("Choose...") { showFileImporter = true }
                        .hoverLift(1.05)
                    if !config.backgroundImagePath.isEmpty {
                        Button("Reset") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                config.backgroundImagePath = ""
                            }
                        }
                        .foregroundStyle(.red)
                        .hoverLift(1.05)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.78),
                           value: config.backgroundImagePath)
            }
            .entrance(0, active: hasAppeared)

            GridRow {
                Text("Custom Mode Code")
                    .gridColumnAlignment(.trailing)
                TextField("", text: $config.customCode)
                    .frame(width: 120)
            }
            .entrance(1, active: hasAppeared)

            GridRow {
                Text("Theme")
                    .gridColumnAlignment(.trailing)
                Picker("", selection: $config.appTheme.animation(.snappy(duration: 0.3))) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .entrance(2, active: hasAppeared)

            GridRow {
                Text("Text Color")
                    .gridColumnAlignment(.trailing)
                HStack(spacing: 8) {
                    ColorPicker("", selection: textColorBinding, supportsOpacity: false)
                        .labelsHidden()
                        .hoverLift(1.12)

                    Circle()
                        .fill(currentColor)
                        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                        .frame(width: 14, height: 14)
                        .shadow(color: currentColor.opacity(0.7), radius: 5)
                        .animation(.easeOut(duration: 0.3), value: currentColor)

                    Button("Reset") {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                            config.textColorR = 1.0
                            config.textColorG = 1.0
                            config.textColorB = 1.0
                        }
                    }
                    .foregroundStyle(.secondary)
                    .hoverLift(1.05)
                }
            }
            .entrance(3, active: hasAppeared)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { hasAppeared = true }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    config.backgroundImagePath = url.path
                }
            }
        }
    }
}

struct AboutTab: View {
    @State private var hasAppeared = false
    @State private var linkHovering = false

    var body: some View {
        VStack(spacing: 10) {
            Image("AppIconDisplay")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                .phaseAnimator([false, true]) { view, up in
                    view
                        .scaleEffect(up ? 1.04 : 1.0)
                        .offset(y: up ? -3 : 3)
                } animation: { _ in .easeInOut(duration: 2.4) }
                .entrance(0, active: hasAppeared)

            Text("SwiftClicker v4.0")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .entrance(1, active: hasAppeared)

            Text("by Varlaam (varla-am)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .entrance(2, active: hasAppeared)

            HStack(spacing: 4) {
                Text("Source Code:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link("https://github.com/varla-am/SwiftClicker",
                     destination: URL(string: "https://github.com/varla-am/SwiftClicker")!)
                    .font(.subheadline)
                    .underline(linkHovering)
                    .scaleEffect(linkHovering ? 1.05 : 1.0)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            linkHovering = hovering
                        }
                    }
            }
            .entrance(3, active: hasAppeared)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { hasAppeared = true }
    }
}
