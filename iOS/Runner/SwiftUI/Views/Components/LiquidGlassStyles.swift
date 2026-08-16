import SwiftUI

// ── Apple Liquid Glass Card Modifier ──────────────────────────────────────────

public struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var cornerRadius: CGFloat
    var interactiveHover: Bool
    @State private var isHovered: Bool = false

    public init(cornerRadius: CGFloat = 20, interactiveHover: Bool = true) {
        self.cornerRadius = cornerRadius
        self.interactiveHover = interactiveHover
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.95, green: 0.95, blue: 0.97))
                    } else {
                        // Base Glass Blur Substrate
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.65))
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }

                    // Muted Ambient Hover Highlight (macOS/iPadOS pointer)
                    if interactiveHover && isHovered && !reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                            .transition(.opacity)
                    }

                    // Uniform Apple 0.5pt Hairline Glass Rim
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark
                                ? Color.white.opacity(isHovered ? 0.18 : 0.10)
                                : Color.black.opacity(isHovered ? 0.08 : 0.05),
                            lineWidth: 0.5
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? (isHovered ? 0.28 : 0.15) : (isHovered ? 0.06 : 0.03)),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
            #if os(macOS)
            .onHover { hovering in
                if interactiveHover {
                    if reduceMotion {
                        isHovered = hovering
                    } else {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            isHovered = hovering
                        }
                    }
                }
            }
            #endif
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20, interactiveHover: Bool = true) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, interactiveHover: interactiveHover))
    }
}

// ── Apple Liquid Glass Standard Button Styles ────────────────────────────────

public struct LiquidGlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    var cornerRadius: CGFloat = 14

    public init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06),
                            lineWidth: 0.5
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public struct LiquidGlassProminentButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var tintColor: Color? = nil
    var cornerRadius: CGFloat = 14

    public init(tintColor: Color? = nil, cornerRadius: CGFloat = 14) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        let accent = tintColor ?? Color.accentColor

        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(accent)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.35),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.10), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

public struct LiquidGlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var size: CGFloat = 40

    public init(size: CGFloat = 40) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.40))
                        )

                    Circle()
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06),
                            lineWidth: 0.5
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

// ── Liquid Glass Toggle Style ────────────────────────────────────────────────

public struct LiquidGlassToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
        }
        .toggleStyle(.switch)
        .tint(.accentColor)
    }
}
