import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum PlatformFeedback {
    public static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        #endif
    }

    public static func impact(style: Int = 0) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
    }

    public static func warning() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
    }
}

public extension Color {
    static var appBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var appGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var appSecondaryGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var appTertiaryGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }

    static var appSystemGray6: Color {
        #if os(iOS)
        return Color(uiColor: .systemGray6)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
