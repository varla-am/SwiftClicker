//
//  OverlayView.swift
//  SwiftClicker
//
//  The always-on-top control. Press it to arm the clicker, press again to stop.
//

#if os(macOS)

import SwiftUI

enum OverlayStyle: Int, CaseIterable, Identifiable {
    case pill = 0, circle = 1, bar = 2

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .pill:   return "Pill"
        case .circle: return "Circle"
        case .bar:    return "Bar"
        }
    }

    var size: CGSize {
        switch self {
        case .pill:   return CGSize(width: 182, height: 62)
        case .circle: return CGSize(width: 86, height: 86)
        case .bar:    return CGSize(width: 230, height: 46)
        }
    }
}

struct OverlayView: View {
    @ObservedObject var engine: ClickerEngine
    @ObservedObject var config: ConfigManager

    private var style: OverlayStyle {
        OverlayStyle(rawValue: config.overlayStyle) ?? .pill
    }

    private var accent: Color {
        switch engine.phase {
        case .idle:    return config.textColor
        case .arming:  return .orange
        case .running: return .green
        }
    }

    private var symbol: String {
        switch engine.phase {
        case .idle:    return "cursorarrow.click"
        case .arming:  return "timer"
        case .running: return "stop.fill"
        }
    }

    private var label: String {
        switch engine.phase {
        case .idle:              return "Start"
        case .arming(let left):  return "\(left)"
        case .running:           return "Stop"
        }
    }

    var body: some View {
        Button(action: { engine.toggle() }) {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!engine.isTrusted)
        .opacity(engine.isTrusted ? 1 : 0.55)
        .help(engine.isTrusted
              ? "Click to start, click again to stop"
              : "Grant Accessibility access in the main window first")
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: engine.phase)
        .preferredColorScheme(config.preferredColorScheme)
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .pill:   pill
        case .circle: circle
        case .bar:    bar
        }
    }

    private var pill: some View {
        HStack(spacing: 10) {
            icon(size: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(config.textColor)
                Text("\(Int(config.clicksPerSecond)) CPS")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(width: style.size.width, height: style.size.height)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(accent.opacity(0.55), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
    }

    private var circle: some View {
        icon(size: 30)
            .frame(width: style.size.width, height: style.size.height)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(accent.opacity(0.6), lineWidth: 2))
            .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
    }

    private var bar: some View {
        HStack(spacing: 10) {
            icon(size: 17)
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(config.textColor)
            Spacer(minLength: 0)
            Text("\(engine.clicksSent)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(engine.clicksSent)))
        }
        .padding(.horizontal, 14)
        .frame(width: style.size.width, height: style.size.height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
            .strokeBorder(accent.opacity(0.55), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
    }

    private func icon(size: CGFloat) -> some View {
        ZStack {
            if case .arming(let left) = engine.phase {
                Text("\(left)")
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size, weight: .semibold))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(accent)
        .symbolEffect(.pulse, isActive: engine.phase == .running)
        .shadow(color: accent.opacity(0.6), radius: engine.phase == .running ? 8 : 0)
    }
}

#endif
