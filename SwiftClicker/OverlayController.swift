//
//  OverlayController.swift
//  SwiftClicker
//
//  Hosts OverlayView in a floating, non-activating panel that stays above other
//  apps, survives Space switches and remembers where it was dragged to.
//

#if os(macOS)

import AppKit
import Combine
import SwiftUI

/// A borderless panel still has to accept clicks, hence the override.
private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class OverlayController: ObservableObject {
    @Published private(set) var isVisible = false

    private let config: ConfigManager
    private let engine: ClickerEngine
    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    init(config: ConfigManager, engine: ClickerEngine) {
        self.config = config
        self.engine = engine

        // Changing the style in Settings resizes the panel in place.
        config.$overlayStyle
            .removeDuplicates()
            .sink { [weak self] style in
                guard let self, let panel = self.panel else { return }
                let size = (OverlayStyle(rawValue: style) ?? .pill).size
                panel.setContentSize(size)
            }
            .store(in: &cancellables)
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.orderFrontRegardless()
        isVisible = true
        config.overlayVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
        config.overlayVisible = false
    }

    private func makePanel() -> NSPanel {
        let style = OverlayStyle(rawValue: config.overlayStyle) ?? .pill
        let panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: style.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow

        let root = OverlayView(engine: engine, config: config)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: style.size)
        panel.contentView = hosting

        if config.overlayX >= 0, config.overlayY >= 0 {
            panel.setFrameOrigin(NSPoint(x: config.overlayX, y: config.overlayY))
        } else if let screen = NSScreen.main {
            // First run: sit near the bottom-right corner, clear of the Dock.
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.maxX - style.size.width - 28,
                                         y: frame.minY + 28))
        }

        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: panel)
            .sink { [weak self] _ in
                guard let self, let panel = self.panel else { return }
                self.config.overlayX = Double(panel.frame.origin.x)
                self.config.overlayY = Double(panel.frame.origin.y)
            }
            .store(in: &cancellables)

        return panel
    }
}

#endif
