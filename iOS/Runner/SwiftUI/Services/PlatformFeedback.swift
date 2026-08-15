import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Cross-platform tactile feedback engine
public enum PlatformFeedback {
    public static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
        #endif
    }

    public static func impact(_ style: ImpactStyle = .medium) {
        #if os(iOS)
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: feedbackStyle = .light
        case .medium: feedbackStyle = .medium
        case .heavy: feedbackStyle = .heavy
        case .rigid: feedbackStyle = .rigid
        case .soft: feedbackStyle = .soft
        }
        let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
        generator.prepare()
        generator.impactOccurred()
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
        #endif
    }

    public static func warning() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
        #endif
    }

    public enum ImpactStyle {
        case light, medium, heavy, rigid, soft
    }
}
