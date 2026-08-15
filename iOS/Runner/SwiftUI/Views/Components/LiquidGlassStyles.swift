import SwiftUI

// ── Liquid Glass Card Modifier ─────────────────────────────────────────────

public struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat
    var interactiveHover: Bool
    @State private var isHovered: Bool = false

    public init(cornerRadius: CGFloat = 18, interactiveHover: Bool = true) {
        self.cornerRadius = cornerRadius
        self.interactiveHover = interactiveHover
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base Glass Blur Material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.7))
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )

                    // Interactive Ambient Hover Glow
                    if interactiveHover && isHovered {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 180
                                )
                            )
                            .transition(.opacity)
                    }

                    // Specular Meniscus Refraction Border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: colorScheme == .dark ? [
                                    Color.white.opacity(isHovered ? 0.28 : 0.18),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(isHovered ? 0.15 : 0.08)
                                ] : [
                                    Color.white.opacity(0.9),
                                    Color.black.opacity(0.05),
                                    Color.white.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isHovered ? 1.2 : 0.9
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? (isHovered ? 0.35 : 0.25) : (isHovered ? 0.08 : 0.04)),
                radius: isHovered ? 14 : 8,
                x: 0,
                y: isHovered ? 6 : 3
            )
            #if os(macOS)
            .onHover { hovering in
                if interactiveHover {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        isHovered = hovering
                    }
                }
            }
            #endif
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 18, interactiveHover: Bool = true) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, interactiveHover: interactiveHover))
    }
}

// ── Liquid Glass Button Style ──────────────────────────────────────────────

public struct LiquidGlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var tintColor: Color? = nil
    var cornerRadius: CGFloat = 12

    public init(tintColor: Color? = nil, cornerRadius: CGFloat = 12) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        LiquidGlassButtonBody(
            configuration: configuration,
            tintColor: tintColor,
            cornerRadius: cornerRadius,
            colorScheme: colorScheme
        )
    }

    private struct LiquidGlassButtonBody: View {
        let configuration: Configuration
        let tintColor: Color?
        let cornerRadius: CGFloat
        let colorScheme: ColorScheme
        @State private var isHovered: Bool = false

        var body: some View {
            let baseTint = tintColor ?? Color.accentColor

            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if tintColor != nil {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(baseTint.opacity(configuration.isPressed ? 0.9 : (isHovered ? 0.85 : 0.75)))
                        } else {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(isHovered ? 0.12 : 0.07) : Color.black.opacity(isHovered ? 0.08 : 0.04))
                                .background(
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                        }

                        // Specular Border
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }
                )
                .foregroundColor(tintColor != nil ? .white : .primary)
                .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
                .shadow(
                    color: (tintColor ?? Color.clear).opacity(isHovered ? 0.35 : 0.15),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: 2
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
                .animation(.spring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
                #if os(macOS)
                .onHover { hovering in
                    isHovered = hovering
                }
                #endif
        }
    }
}

// ── Liquid Glass Toggle Style ──────────────────────────────────────────────

public struct LiquidGlassToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Button(action: {
                PlatformFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    // Pill Track
                    Capsule()
                        .fill(
                            configuration.isOn
                                ? Color.accentColor.opacity(0.85)
                                : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                        )
                        .frame(width: 44, height: 26)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.25 : 0.5),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        )

                    // Glass Knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(2)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
