//
//  SettingsView.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    #if os(macOS)
    @State private var tab = 0
    #endif

    var body: some View {
        #if os(macOS)
        VStack(spacing: 18) {
            Picker("", selection: $tab.animation(.snappy(duration: 0.25))) {
                Text("General").tag(0)
                Text("Game").tag(1)
                Text("About").tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 280)

            Group {
                switch tab {
                case 0:  GeneralTab()
                case 1:  GameTab()
                default: AboutTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
        .frame(width: 500, height: 380)
        #else
        NavigationStack {
            Form {
                Section("General") { GeneralTab() }
                Section("Game") { GameTab() }
                Section("About") { AboutTab() }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #endif
    }
}

// MARK: - General: the autoclicker and how the app looks

struct GeneralTab: View {
    @EnvironmentObject var config: ConfigManager
    @State private var hasAppeared = false

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(red: config.textColorR, green: config.textColorG, blue: config.textColorB) },
            set: { color in
                if let c = rgbComponents(of: color) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        config.textColorR = c.red
                        config.textColorG = c.green
                        config.textColorB = c.blue
                    }
                }
            }
        )
    }

    private var currentColor: Color {
        Color(red: config.textColorR, green: config.textColorG, blue: config.textColorB)
    }

    private var themePicker: some View {
        Picker("", selection: $config.appTheme.animation(.snappy(duration: 0.3))) {
            Text("System").tag(0)
            Text("Light").tag(1)
            Text("Dark").tag(2)
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
    }

    private var textColorControls: some View {
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

    #if os(macOS)
    private var frequencyControls: some View {
        HStack(spacing: 10) {
            Slider(value: $config.clicksPerSecond, in: 1...50, step: 1)
                .frame(width: 170)
            Text("\(Int(config.clicksPerSecond)) CPS")
                .monospacedDigit()
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
        }
    }

    private var delayControls: some View {
        HStack(spacing: 10) {
            Stepper(value: $config.startDelay, in: 0...10, step: 1) {
                Text("\(Int(config.startDelay)) s")
                    .monospacedDigit()
                    .font(.callout)
            }
            .frame(width: 110)
            Text("before clicking starts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var overlayStylePicker: some View {
        Picker("", selection: $config.overlayStyle.animation(.snappy(duration: 0.3))) {
            ForEach(OverlayStyle.allCases) { style in
                Text(style.name).tag(style.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
    }

    private var hotkeyPicker: some View {
        Picker("", selection: $config.hotkeyKeyCode) {
            ForEach(Hotkey.choices, id: \.code) { choice in
                Text(choice.name).tag(choice.code)
            }
        }
        .labelsHidden()
        .frame(width: 100)
    }
    #endif

    var body: some View {
        content.onAppear { hasAppeared = true }
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Click Speed").gridColumnAlignment(.trailing)
                frequencyControls
            }
            .entrance(0, active: hasAppeared)

            GridRow {
                Text("Start Delay").gridColumnAlignment(.trailing)
                delayControls
            }
            .entrance(1, active: hasAppeared)

            GridRow {
                Text("Hotkey").gridColumnAlignment(.trailing)
                hotkeyPicker
            }
            .entrance(2, active: hasAppeared)

            GridRow {
                Text("Overlay Style").gridColumnAlignment(.trailing)
                overlayStylePicker
            }
            .entrance(3, active: hasAppeared)

            GridRow {
                Text("Theme").gridColumnAlignment(.trailing)
                themePicker
            }
            .entrance(4, active: hasAppeared)

            GridRow {
                Text("Text Color").gridColumnAlignment(.trailing)
                textColorControls
            }
            .entrance(5, active: hasAppeared)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        // iOS cannot send clicks to other apps, so only the looks are configurable.
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
            themePicker.frame(maxWidth: .infinity)
        }
        .entrance(0, active: hasAppeared)
        LabeledContent("Text Color") { textColorControls }
            .entrance(1, active: hasAppeared)
        #endif
    }
}

// MARK: - Game

struct GameTab: View {
    @EnvironmentObject var config: ConfigManager
    @State private var showFileImporter = false
    @State private var hasAppeared = false

    private var backgroundControls: some View {
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
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: config.backgroundImagePath)
    }

    var body: some View {
        content
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

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Custom Mode Code").gridColumnAlignment(.trailing)
                TextField("", text: $config.customCode).frame(width: 120)
            }
            .entrance(0, active: hasAppeared)

            GridRow {
                Text("Background Image").gridColumnAlignment(.trailing)
                backgroundControls
            }
            .entrance(1, active: hasAppeared)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        LabeledContent("Custom Mode Code") {
            TextField("", text: $config.customCode)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
        .entrance(0, active: hasAppeared)
        LabeledContent("Background Image") { backgroundControls }
            .entrance(1, active: hasAppeared)
        #endif
    }
}

// MARK: - About

struct AboutTab: View {
    @State private var hasAppeared = false
    @State private var linkHovering = false

    private var icon: some View {
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
    }

    private var sourceLink: some View {
        Link(AppInfo.sourceURL, destination: URL(string: AppInfo.sourceURL)!)
            .font(.subheadline)
            .underline(linkHovering)
            .scaleEffect(linkHovering ? 1.05 : 1.0)
            .onHover { hovering in
                guard Layout.hasPointer else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    linkHovering = hovering
                }
            }
    }

    var body: some View {
        content.onAppear { hasAppeared = true }
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        VStack(spacing: 10) {
            icon
            Text("SwiftClicker v\(AppInfo.version)")
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
                sourceLink
            }
            .entrance(3, active: hasAppeared)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        HStack(spacing: 14) {
            icon
            VStack(alignment: .leading, spacing: 4) {
                Text("SwiftClicker v\(AppInfo.version)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("by Varlaam (varla-am)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .entrance(1, active: hasAppeared)
        }
        .padding(.vertical, 4)
        LabeledContent("Source Code") { sourceLink }
            .entrance(3, active: hasAppeared)
        #endif
    }
}
