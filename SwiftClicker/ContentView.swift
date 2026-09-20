//
//  ContentView.swift
//  SwiftClicker
//
//  Created by Varlaam on 07/08/2026.
//
//  macOS: the autoclicker control panel. iOS: the game, since a phone cannot
//  send clicks to other apps.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        ClickerPanel()
        #else
        GameView()
        #endif
    }
}

#if os(macOS)

struct ClickerPanel: View {
    @EnvironmentObject var config: ConfigManager
    @EnvironmentObject var engine: ClickerEngine
    @EnvironmentObject var overlay: OverlayController
    @Environment(\.openWindow) private var openWindow

    @State private var showsSettings = false
    @State private var settingsHovering = false
    @State private var hasAppeared = false

    private var overlayBinding: Binding<Bool> {
        Binding(get: { overlay.isVisible },
                set: { $0 ? overlay.show() : overlay.hide() })
    }

    private var statusText: String {
        switch engine.phase {
        case .idle:             return "Ready"
        case .arming(let left): return "Starting in \(left)..."
        case .running:          return "Clicking"
        }
    }

    var body: some View {
        ZStack {
            AuraBackground()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    if !engine.isTrusted { permissionCard }
                    startButton
                    counters
                    controlsCard
                    gameButton
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 68)
                .fillScrollContainer()
            }
            .scrollIndicators(.never)
        }
        .overlay(alignment: .bottomLeading) { settingsButton }
        .sheet(isPresented: $showsSettings) {
            SettingsView().environmentObject(config)
        }
        .preferredColorScheme(config.preferredColorScheme)
        .onAppear { hasAppeared = true }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "cursorarrow.click.2")
                .imageScale(.large)
                .foregroundStyle(config.textColor)
                .entrance(0, active: hasAppeared)

            Text("SwiftClicker v\(AppInfo.version)")
                .font(Layout.titleFont)
                .bold()
                .foregroundStyle(config.textColor)
                .entrance(1, active: hasAppeared)
        }
    }

    private var permissionCard: some View {
        VStack(spacing: 8) {
            Label("Accessibility access needed", systemImage: "lock.shield")
                .font(.subheadline.bold())
            Text("macOS only lets trusted apps send clicks to other apps.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Button("Grant Access") { engine.requestPermission() }
                    .hoverLift(1.05)
                Button("Open Settings") { engine.openAccessibilitySettings() }
                    .hoverLift(1.05)
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(.orange.opacity(0.5), lineWidth: 1))
        .transition(.scale(scale: 0.94).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: engine.isTrusted)
    }

    private var startButton: some View {
        Button { engine.toggle() } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(startTint.opacity(0.6), lineWidth: 3))
                    .frame(width: 128, height: 128)
                    .shadow(color: startTint.opacity(engine.isActive ? 0.55 : 0.2), radius: 18)

                VStack(spacing: 2) {
                    if case .arming(let left) = engine.phase {
                        Text("\(left)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    } else {
                        Image(systemName: engine.isActive ? "stop.fill" : "play.fill")
                            .font(.system(size: 38, weight: .semibold))
                    }
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(startTint)
            }
        }
        .buttonStyle(.plain)
        .disabled(!engine.isTrusted)
        .hoverLift(1.04)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: engine.phase)
        .entrance(2, active: hasAppeared)
    }

    private var startTint: Color {
        switch engine.phase {
        case .idle:    return config.textColor
        case .arming:  return .orange
        case .running: return .green
        }
    }

    private var counters: some View {
        VStack(spacing: 2) {
            Text("Clicks sent: \(engine.clicksSent)")
                .font(Layout.counterFont)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(engine.clicksSent)))
                .foregroundStyle(config.textColor)
            if config.hotkeyKeyCode >= 0 {
                Text("\(Hotkey.name(for: config.hotkeyKeyCode)) toggles from anywhere")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .entrance(3, active: hasAppeared)
    }

    /// Keeps the controls off the window edges and inside a visible frame.
    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            frequencyRow
            Divider().opacity(0.35)
            targetRow
            Divider().opacity(0.35)
            overlayRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(config.textColor.opacity(0.18), lineWidth: 1))
    }

    private var frequencyRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Speed").foregroundStyle(config.textColor)
                Spacer()
                Text("\(Int(config.clicksPerSecond)) CPS")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Slider(value: $config.clicksPerSecond, in: 1...50, step: 1)
        }
        .entrance(4, active: hasAppeared)
    }

    private var targetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("", selection: $config.clickTarget.animation(.snappy(duration: 0.25))) {
                Text("Cursor").tag(0)
                Text("Fixed point").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if config.clickTarget == 1 {
                HStack(spacing: 8) {
                    Text(String(format: "x %.0f, y %.0f", config.fixedPointX, config.fixedPointY))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let left = engine.pointCapture {
                        Text("Move the cursor... \(left)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Button("Cancel") { engine.cancelPointCapture() }
                            .controlSize(.small)
                    } else {
                        Button("Set from cursor") { engine.captureFixedPoint() }
                            .controlSize(.small)
                            .hoverLift(1.05)
                    }
                }
                .transition(.push(from: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: config.clickTarget)
        .animation(.snappy(duration: 0.25), value: engine.pointCapture)
        .entrance(5, active: hasAppeared)
    }

    private var overlayRow: some View {
        Toggle(isOn: overlayBinding.animation(.snappy(duration: 0.25))) {
            Text("Floating overlay").foregroundStyle(config.textColor)
        }
        .font(.subheadline)
        .toggleStyle(.switch)
        .entrance(6, active: hasAppeared)
    }

    private var gameButton: some View {
        Button {
            openWindow(id: "game")
        } label: {
            Label("Play the clicker game", systemImage: "gamecontroller")
        }
        .controlSize(.small)
        .hoverLift(1.05)
        .entrance(7, active: hasAppeared)
    }

    private var settingsButton: some View {
        Button {
            showsSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .rotationEffect(.degrees(settingsHovering ? 120 : 0))
        }
        .buttonStyle(.glass)
        .scaleEffect(settingsHovering ? 1.1 : 1.0)
        .padding(.leading, 22)
        .padding(.bottom, 22)
        .onHover { hovering in
            guard Layout.hasPointer else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                settingsHovering = hovering
            }
        }
        .entrance(8, active: hasAppeared)
    }
}

#endif

#Preview {
    let config = ConfigManager()
    #if os(macOS)
    let engine = ClickerEngine(config: config)
    return ContentView()
        .environmentObject(config)
        .environmentObject(engine)
        .environmentObject(OverlayController(config: config, engine: engine))
    #else
    return ContentView().environmentObject(config)
    #endif
}
