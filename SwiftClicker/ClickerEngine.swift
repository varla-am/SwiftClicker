//
//  ClickerEngine.swift
//  SwiftClicker
//
//  The autoclicker itself: permission handling, the arming countdown and the
//  timer that synthesises mouse clicks. macOS only - iOS cannot post events
//  into other apps, so the phone build is the game alone.
//

#if os(macOS)

import AppKit
import ApplicationServices
import Combine

/// Counts clicks off the main thread; the UI reads it a few times a second.
private final class AtomicCounter {
    private var value = 0
    private let lock = NSLock()

    func increment() {
        lock.lock(); value += 1; lock.unlock()
    }

    func read() -> Int {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    func reset() {
        lock.lock(); value = 0; lock.unlock()
    }
}

@MainActor
final class ClickerEngine: ObservableObject {
    enum Phase: Equatable {
        case idle
        case arming(Int)   // seconds left on the countdown
        case running
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var clicksSent = 0
    @Published private(set) var isTrusted = AXIsProcessTrusted()
    /// Seconds left while picking a fixed point with the cursor, nil when not picking.
    @Published private(set) var pointCapture: Int?

    var isActive: Bool { phase != .idle }

    private let config: ConfigManager
    private let queue = DispatchQueue(label: "com.varlaam.SwiftClicker.engine", qos: .userInteractive)
    private let counter = AtomicCounter()
    private var timer: DispatchSourceTimer?
    private var armTask: Task<Void, Never>?
    private var captureTask: Task<Void, Never>?
    private var displayTimer: Timer?
    private var trustTimer: Timer?

    init(config: ConfigManager) {
        self.config = config

        // The permission can be granted while the app is running, so keep checking.
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let trusted = AXIsProcessTrusted()
                if trusted != self.isTrusted { self.isTrusted = trusted }
            }
        }
    }

    // MARK: - Permission

    /// Asks macOS for Accessibility access, showing the system prompt once.
    @discardableResult
    func requestPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        isTrusted = trusted
        return trusted
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url { NSWorkspace.shared.open(url) }
    }

    // MARK: - Start / stop

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        guard requestPermission() else { return }
        stop()
        counter.reset()
        clicksSent = 0

        let delay = max(0, Int(config.startDelay.rounded()))
        guard delay > 0 else { return beginClicking() }

        phase = .arming(delay)
        armTask = Task { [weak self] in
            for remaining in stride(from: delay, through: 1, by: -1) {
                guard let self, case .arming = self.phase else { return }
                self.phase = .arming(remaining)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            guard let self, case .arming = self.phase else { return }
            self.beginClicking()
        }
    }

    func stop() {
        armTask?.cancel(); armTask = nil
        timer?.cancel(); timer = nil
        displayTimer?.invalidate(); displayTimer = nil
        phase = .idle
    }

    private func beginClicking() {
        phase = .running

        // Resolved once: a fixed target stays put, cursor mode reads the pointer each tick.
        let fixedPoint = config.clickTarget == 1 ? config.fixedPoint : nil
        let counter = self.counter

        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: config.clickInterval, leeway: .milliseconds(2))
        source.setEventHandler {
            ClickerEngine.postClick(at: fixedPoint)
            counter.increment()
        }
        timer = source
        source.resume()

        // Publishing every click would thrash SwiftUI at 50 clicks a second.
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let count = self.counter.read()
                if count != self.clicksSent { self.clicksSent = count }
            }
        }
    }

    // MARK: - Clicking

    nonisolated static func postClick(at fixedPoint: CGPoint?) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let location = fixedPoint ?? CGEvent(source: nil)?.location,
              let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                                 mouseCursorPosition: location, mouseButton: .left),
              let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                               mouseCursorPosition: location, mouseButton: .left)
        else { return }

        down.setIntegerValueField(.mouseEventClickState, value: 1)
        up.setIntegerValueField(.mouseEventClickState, value: 1)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    /// Current pointer position in the same coordinates clicks are posted in.
    static var cursorLocation: CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    // MARK: - Picking a fixed point

    /// Counts down, then stores wherever the cursor ended up.
    func captureFixedPoint(after seconds: Int = 3) {
        captureTask?.cancel()
        pointCapture = seconds
        captureTask = Task { [weak self] in
            for remaining in stride(from: seconds, through: 1, by: -1) {
                guard let self, self.pointCapture != nil else { return }
                self.pointCapture = remaining
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            guard let self else { return }
            let point = ClickerEngine.cursorLocation
            self.config.fixedPointX = Double(point.x)
            self.config.fixedPointY = Double(point.y)
            self.config.clickTarget = 1
            self.pointCapture = nil
        }
    }

    func cancelPointCapture() {
        captureTask?.cancel()
        captureTask = nil
        pointCapture = nil
    }
}

// MARK: - Global hotkey

/// Watches for one key everywhere (global) and inside the app (local).
/// The global half needs the same Accessibility permission the clicker does.
@MainActor
final class HotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func update(keyCode: Int, handler: @escaping () -> Void) {
        stop()
        guard keyCode >= 0 else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if Int(event.keyCode) == keyCode { handler() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Int(event.keyCode) == keyCode {
                handler()
                return nil          // swallow it so the app doesn't beep
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }
}

/// The function keys offered in Settings.
enum Hotkey {
    static let choices: [(name: String, code: Int)] = [
        ("Off", -1), ("F5", 96), ("F6", 97), ("F7", 98), ("F8", 100), ("F9", 101), ("F10", 109)
    ]

    static func name(for code: Int) -> String {
        choices.first { $0.code == code }?.name ?? "F6"
    }
}

#endif
