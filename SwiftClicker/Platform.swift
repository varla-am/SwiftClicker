//
//  Platform.swift
//  SwiftClicker
//
//  Thin compatibility layer so the same views build on macOS and iOS.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

extension Image {
    /// Loads an image from a file path on either platform.
    init?(contentsOfFile path: String) {
        guard let image = PlatformImage(contentsOfFile: path) else { return nil }
        #if canImport(AppKit)
        self.init(nsImage: image)
        #else
        self.init(uiImage: image)
        #endif
    }
}

/// Extracts sRGB components from a SwiftUI Color on either platform.
func rgbComponents(of color: Color) -> (red: Double, green: Double, blue: Double)? {
    #if canImport(AppKit)
    guard let c = NSColor(color).usingColorSpace(.sRGB) else { return nil }
    return (Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent))
    #else
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    return (Double(r), Double(g), Double(b))
    #endif
}

extension View {
    /// Centres content in the scroll container: a fixed height on the Mac's
    /// fixed-size window, the visible area's height on iOS.
    @ViewBuilder
    func fillScrollContainer() -> some View {
        #if os(macOS)
        self.frame(maxWidth: .infinity, minHeight: Layout.minContentHeight)
        #else
        self.frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
        #endif
    }
}

enum AppInfo {
    /// One place to bump the version shown in the UI and written into config.plist.
    static let version = "7.0"
    static let sourceURL = "https://github.com/varla-am/SwiftClicker"
}

enum Layout {
    /// The Mac window is a fixed 390x680; on iOS the content fills the screen.
    #if os(macOS)
    static let minContentHeight: CGFloat? = 680
    static let windowSize = CGSize(width: 390, height: 560)
    static let gameWindowSize = CGSize(width: 390, height: 680)
    #else
    static let minContentHeight: CGFloat? = nil
    #endif

    /// Hover effects only mean anything where there is a pointer.
    static var hasPointer: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    // Typography and spacing: compact for the small Mac window,
    // roomier and larger for a full iPhone screen.
    #if os(macOS)
    static let contentSpacing: CGFloat = 5
    static let titleFont: Font = .title2
    static let counterFont: Font = .body
    static let fieldWidth: CGFloat = 220
    static let horizontalPadding: CGFloat = 26
    #else
    static let contentSpacing: CGFloat = 16
    static let titleFont: Font = .largeTitle
    static let counterFont: Font = .title3
    static let fieldWidth: CGFloat = 300
    static let horizontalPadding: CGFloat = 32
    #endif
}
