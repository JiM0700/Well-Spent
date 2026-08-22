import SwiftUI

#if os(iOS)
import AudioToolbox
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Dynamic Haptic & Acoustic Sound Feedback Profiles for Apple Hardware
public enum PlatformFeedback {
    public static var isHapticsEnabled: Bool = true
    public static var isSoundsEnabled: Bool = true

    /// Subtle tick for category selection and segment switches
    public static func selection() {
        #if os(iOS)
        if isHapticsEnabled {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
        if isSoundsEnabled {
            AudioServicesPlaySystemSound(1104) // subtle system tick
        }
        #elseif os(macOS)
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
        }
        #endif
    }

    /// Tactile impact feedback (rigid for numpad, soft for backspace, medium for buttons)
    public static func impact(_ style: ImpactStyle = .medium) {
        #if os(iOS)
        if isHapticsEnabled {
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
        }
        #elseif os(macOS)
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .levelChange,
                performanceTime: .default
            )
        }
        #endif
    }

    /// Apple Pay style acoustic sound + soft double-pulse on saving transactions, goals, or settings
    public static func success() {
        #if os(iOS)
        if isHapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        if isSoundsEnabled {
            AudioServicesPlaySystemSound(1057) // Apple Pay style chime
        }
        #elseif os(macOS)
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .levelChange,
                performanceTime: .default
            )
        }
        #endif
    }

    /// Warning pulse for destructive actions (deleting transaction/goal/data)
    public static func warning() {
        #if os(iOS)
        if isHapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
        if isSoundsEnabled {
            AudioServicesPlaySystemSound(1053) // warning beep
        }
        #elseif os(macOS)
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .generic,
                performanceTime: .default
            )
        }
        #endif
    }

    public enum ImpactStyle {
        case light, medium, heavy, rigid, soft
    }
}

// ── 120Hz ProMotion Spring Physics ───────────────────────────────────────────

public extension Animation {
    /// Native 120Hz Apple ProMotion spring interpolation for tabs, filters, and sheets
    static var appleSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// Crisp micro-interaction spring for buttons and numpad keys
    static var appleSnap: Animation {
        .spring(response: 0.22, dampingFraction: 0.72)
    }
}

// ── Kinetic Apple Scale Button Style ─────────────────────────────────────────

public struct AppleScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == AppleScaleButtonStyle {
    static var appleScale: AppleScaleButtonStyle {
        AppleScaleButtonStyle()
    }
}

// ── True Pitch Black OLED & Native Cross-Platform Color System ───────────────

public extension Color {
    /// True Pitch Black (`#000000`) in dark mode on OLED Super Retina XDR displays; system background in light mode
    static var appBackground: Color {
        #if os(iOS)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.black
                : UIColor.systemBackground
        })
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// True Pitch Black (`#000000`) grouped canvas background
    static var appGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.black
                : UIColor.systemGroupedBackground
        })
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Subtle elevated translucent dark card (`#121214` in dark OLED mode; pure `#FFFFFF` in light mode)
    static var appSecondaryGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
                : UIColor.secondarySystemGroupedBackground
        })
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Elevated tertiary surface (`#1A1A1E` in dark mode)
    static var appTertiaryGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
                : UIColor.tertiarySystemGroupedBackground
        })
        #elseif os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }

    static var appSystemGray6: Color {
        #if os(iOS)
        return Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0)
                : UIColor.systemGray6
        })
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var appOverBudget: Color {
        Color.red
    }

    static var appOnTrack: Color {
        Color.green
    }
}

#if os(iOS)
public extension UIApplication {
    static func dismissKeyboard() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

public struct AppListStyleModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        #if os(iOS)
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appGroupedBackground.ignoresSafeArea())
        #else
        content.listStyle(.inset)
        #endif
    }
}

public extension View {
    func appListStyle() -> some View {
        self.modifier(AppListStyleModifier())
    }

    /// Dismiss keyboard when tapping anywhere outside interactive controls on iOS
    func dismissKeyboardOnTap() -> some View {
        #if os(iOS)
        return self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.dismissKeyboard()
                }
        )
        #else
        return self
        #endif
    }

    /// Attach a native 'Done' accessory button to the keyboard
    func keyboardDismissToolbar() -> some View {
        #if os(iOS)
        return self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.dismissKeyboard()
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        #else
        return self
        #endif
    }
}
