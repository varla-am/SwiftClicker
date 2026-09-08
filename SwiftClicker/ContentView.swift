//
//  ContentView.swift
//  SwiftClicker v4.0
//
//  Created by Varlaam on 07/08/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var config: ConfigManager

    @State private var numberper = 1
    @State private var numbernum = 0
    @State private var numberpercost = 10
    @State private var incode = ""
    @State private var developeractive = false
    @State private var showsDeveloperCodeField = false
    @State private var numberadd = ""
    @State private var errorMessage = ""
    @State private var showsSettings = false

    // Animation state
    @State private var gains: [FloatingGain] = []
    @State private var clickTick = 0
    @State private var shakeTick = 0
    @State private var gearAngle: Double = 0
    @State private var counterPop: CGFloat = 1
    @State private var settingsHovering = false
    @State private var hasAppeared = false
    @State private var bgDrift: CGFloat = 1.0

    private var canAfford: Bool { numbernum >= numberpercost }

    var body: some View {
        ZStack {
            backgroundView

            ScrollView {
            VStack(spacing: 5) {
                Image(systemName: "gearshape")
                    .imageScale(.large)
                    .foregroundStyle(config.textColor)
                    .rotationEffect(.degrees(gearAngle))
                    .entrance(0, active: hasAppeared)

                Text("SwiftClicker v4.0")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(config.textColor)
                    .entrance(1, active: hasAppeared)

                Text("")

                Text("Clicks: \(numbernum)")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(numbernum)))
                    .foregroundStyle(config.textColor)
                    .scaleEffect(counterPop)
                    .entrance(2, active: hasAppeared)

                Text("Per Click: \(numberper)")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(numberper)))
                    .foregroundStyle(config.textColor)
                    .entrance(3, active: hasAppeared)

                Button("Click") {
                    registerClick()
                }
                .buttonStyle(.glass(.clear))
                .controlSize(.extraLarge)
                .overlay { RippleOverlay(trigger: clickTick, tint: config.textColor) }
                .keyframeAnimator(initialValue: CGFloat(1), trigger: clickTick) { view, scale in
                    view.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(0.90, duration: 0.10, spring: .snappy)
                        SpringKeyframe(1.07, duration: 0.16, spring: .bouncy)
                        SpringKeyframe(1.00, duration: 0.20, spring: .snappy)
                    }
                }
                .overlay(alignment: .top) {
                    ZStack {
                        ForEach(gains) { gain in
                            FloatingGainView(gain: gain, tint: config.textColor)
                        }
                    }
                    .frame(height: 0)
                }
                .entrance(4, active: hasAppeared)

                Button("+1 per click. Cost \(numberpercost) Clicks") {
                    buyUpgrade()
                }
                .disabled(numbernum < numberpercost)
                .contentTransition(.numericText(value: Double(numberpercost)))
                .phaseAnimator([false, true]) { view, glow in
                    view
                        .scaleEffect(canAfford && glow ? 1.045 : 1.0)
                        .shadow(color: .accentColor.opacity(canAfford && glow ? 0.55 : 0),
                                radius: canAfford && glow ? 11 : 0)
                } animation: { _ in .easeInOut(duration: 1.15) }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: canAfford)
                .entrance(5, active: hasAppeared)

                if !developeractive {
                    Button("Custom mode") {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                            showsDeveloperCodeField = true
                        }
                    }
                    .font(.caption)
                    .controlSize(.small)
                    .hoverLift(1.08)
                    .entrance(6, active: hasAppeared)

                    if showsDeveloperCodeField {
                        TextField("Code for custom mode", text: $incode)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                            .padding(.vertical, 8)
                            .shake(shakeTick)
                            .onSubmit {
                                if incode == config.customCode {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        developeractive = true
                                        showsDeveloperCodeField = false
                                        errorMessage = ""
                                    }
                                } else {
                                    flashError("Error: Invalid code")
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .push(from: .top).combined(with: .opacity),
                                removal: .scale(scale: 0.92).combined(with: .opacity)))
                    }
                }

                if developeractive {
                    Text("Custom mode active")
                        .transition(.scale(scale: 0.9).combined(with: .opacity))

                    TextField("Add clicks", text: $numberadd)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .padding(.vertical, 8)
                        .shake(shakeTick)
                        .onSubmit {
                            if let clicksToAdd = Int(numberadd) {
                                let (result, overflow) = numbernum.addingReportingOverflow(clicksToAdd)
                                withAnimation(.snappy(duration: 0.45)) {
                                    numbernum = overflow ? Int.max : result
                                    errorMessage = ""
                                }
                                popCounter()
                            } else {
                                flashError("Error: Not a number")
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .push(from: .bottom).combined(with: .opacity),
                            removal: .opacity))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: developeractive)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showsDeveloperCodeField)
            .overlay(alignment: .bottom) {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, -24)
                        .shake(shakeTick)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 56)
            .frame(maxWidth: .infinity, minHeight: 680)
            } // ScrollView
            .scrollIndicators(.never)
        }
        .overlay(alignment: .bottomLeading) {
            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .rotationEffect(.degrees(settingsHovering ? 120 : 0))
            }
            .buttonStyle(.glass)
            .scaleEffect(settingsHovering ? 1.1 : 1.0)
            .padding(.leading, 18)
            .padding(.bottom, 18)
            .onHover { hovering in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    settingsHovering = hovering
                }
            }
            .entrance(7, active: hasAppeared)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
                .environmentObject(config)
        }
        .preferredColorScheme(config.preferredColorScheme)
        .onAppear { hasAppeared = true }
    }

    // MARK: - Actions

    private func registerClick() {
        let (result, overflow) = numbernum.addingReportingOverflow(numberper)
        withAnimation(.snappy(duration: 0.3)) {
            numbernum = overflow ? Int.max : result
        }

        let gain = FloatingGain.random(amount: numberper)
        gains.append(gain)
        clickTick &+= 1

        withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) {
            gearAngle += 45
        }
        popCounter()

        Task {
            try? await Task.sleep(for: .milliseconds(950))
            gains.removeAll { $0.id == gain.id }
        }
    }

    private func buyUpgrade() {
        withAnimation(.snappy(duration: 0.35)) {
            numbernum -= numberpercost
            numberpercost *= 2
            numberper += 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.4)) {
            gearAngle += 180
        }
        popCounter()
    }

    private func popCounter() {
        withAnimation(.spring(response: 0.16, dampingFraction: 0.4)) {
            counterPop = 1.18
        }
        Task {
            try? await Task.sleep(for: .milliseconds(130))
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                counterPop = 1
            }
        }
    }

    private func flashError(_ message: String) {
        withAnimation(.snappy(duration: 0.25)) { errorMessage = message }
        shakeTick &+= 1
        Task {
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.easeOut(duration: 0.3)) { errorMessage = "" }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if !config.backgroundImagePath.isEmpty,
           let nsImage = NSImage(contentsOfFile: config.backgroundImagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 8, opaque: true)
                .scaleEffect(bgDrift)
                .ignoresSafeArea()
                .transition(.opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 26).repeatForever(autoreverses: true)) {
                        bgDrift = 1.14
                    }
                }
        } else {
            AuraBackground()
                .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
}
