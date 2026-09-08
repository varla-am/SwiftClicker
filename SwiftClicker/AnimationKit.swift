//
//  AnimationKit.swift
//  SwiftClicker
//
//  Reusable animation pieces: floating "+N" labels, the ripple that spreads from
//  the click button, an error shake, staggered entrances and a living background.
//

import SwiftUI

// MARK: - Floating "+N"

struct FloatingGain: Identifiable, Equatable {
    let id = UUID()
    let amount: Int
    let xOffset: CGFloat
    let tilt: Double

    static func random(amount: Int) -> FloatingGain {
        FloatingGain(amount: amount,
                     xOffset: .random(in: -38...38),
                     tilt: .random(in: -16...16))
    }
}

private struct GainPhase {
    var y: CGFloat = 0
    var scale: CGFloat = 0.55
    var opacity: Double = 0
    var tilt: Double = 0
}

struct FloatingGainView: View {
    let gain: FloatingGain
    var tint: Color

    var body: some View {
        Text("+\(gain.amount)")
            .font(.system(size: 19, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(tint)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            .keyframeAnimator(initialValue: GainPhase(), repeating: false) { view, phase in
                view
                    .offset(x: gain.xOffset, y: phase.y)
                    .scaleEffect(phase.scale)
                    .rotationEffect(.degrees(gain.tilt * phase.tilt))
                    .opacity(phase.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    SpringKeyframe(-30, duration: 0.30, spring: .snappy)
                    LinearKeyframe(-82, duration: 0.60)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.28, duration: 0.16, spring: .bouncy)
                    SpringKeyframe(1.00, duration: 0.22, spring: .snappy)
                    LinearKeyframe(0.82, duration: 0.52)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1.0, duration: 0.10)
                    LinearKeyframe(1.0, duration: 0.42)
                    LinearKeyframe(0.0, duration: 0.38)
                }
                KeyframeTrack(\.tilt) {
                    LinearKeyframe(1.0, duration: 0.90)
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Ripple spreading from the button

private struct RipplePhase {
    var scale: CGFloat = 1.0
    var opacity: Double = 0.0
}

struct RippleOverlay: View {
    var trigger: Int
    var tint: Color

    var body: some View {
        Capsule()
            .stroke(tint.opacity(0.7), lineWidth: 2)
            .keyframeAnimator(initialValue: RipplePhase(), trigger: trigger) { view, phase in
                view.scaleEffect(phase.scale).opacity(phase.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.00, duration: 0.001)
                    CubicKeyframe(1.55, duration: 0.55)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.80, duration: 0.06)
                    LinearKeyframe(0.00, duration: 0.50)
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Shake on error

struct Shake: ViewModifier {
    var trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-10, duration: 0.06)
                CubicKeyframe(9, duration: 0.08)
                CubicKeyframe(-6, duration: 0.08)
                CubicKeyframe(4, duration: 0.08)
                CubicKeyframe(0, duration: 0.08)
            }
        }
    }
}

// MARK: - Staggered entrance

struct Entrance: ViewModifier {
    var index: Int
    var active: Bool

    func body(content: Content) -> some View {
        content
            .opacity(active ? 1 : 0)
            .offset(y: active ? 0 : 16)
            .blur(radius: active ? 0 : 6)
            .scaleEffect(active ? 1 : 0.96, anchor: .top)
            .animation(.spring(response: 0.55, dampingFraction: 0.78)
                .delay(Double(index) * 0.06), value: active)
    }
}

// MARK: - Hover response

struct HoverLift: ViewModifier {
    var scale: CGFloat = 1.06
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? scale : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.6), value: hovering)
            .onHover { hovering = $0 }
    }
}

extension View {
    func shake(_ trigger: Int) -> some View { modifier(Shake(trigger: trigger)) }
    func entrance(_ index: Int, active: Bool) -> some View {
        modifier(Entrance(index: index, active: active))
    }
    func hoverLift(_ scale: CGFloat = 1.06) -> some View {
        modifier(HoverLift(scale: scale))
    }
}

// MARK: - Living background used when no custom image is set

struct AuraBackground: View {
    @Environment(\.colorScheme) private var scheme
    @State private var drift = false

    private var base: [Color] {
        scheme == .dark
            ? [Color(red: 0.05, green: 0.06, blue: 0.12), Color(red: 0.10, green: 0.05, blue: 0.17)]
            : [Color(red: 0.90, green: 0.93, blue: 0.99), Color(red: 0.95, green: 0.91, blue: 0.99)]
    }

    private var intensity: Double { scheme == .dark ? 0.55 : 0.40 }

    var body: some View {
        ZStack {
            LinearGradient(colors: base, startPoint: .topLeading, endPoint: .bottomTrailing)

            aura(.blue, size: 380, opacity: intensity)
                .offset(x: drift ? -95 : 75, y: drift ? -160 : -45)
            aura(.purple, size: 430, opacity: intensity * 0.92)
                .offset(x: drift ? 115 : -65, y: drift ? 190 : 95)
            aura(.teal, size: 300, opacity: intensity * 0.7)
                .offset(x: drift ? -45 : 125, y: drift ? 70 : 245)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func aura(_ color: Color, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(opacity), .clear],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 45)
    }
}
