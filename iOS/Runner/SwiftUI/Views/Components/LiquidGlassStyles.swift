import SwiftUI

// ── Apple Luxury Glass Card Modifier (Apple Design Award Quality) ────────────

public struct LuxuryGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    var cornerRadius: CGFloat
    var glowColor: Color
    var glowIntensity: Double

    public init(cornerRadius: CGFloat = 22, glowColor: Color = .clear, glowIntensity: Double = 0.12) {
        self.cornerRadius = cornerRadius
        self.glowColor = glowColor
        self.glowIntensity = glowIntensity
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // True OLED dark background substrate
                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(red: 0.07, green: 0.07, blue: 0.08))

                        // Soft ambient atmospheric glow
                        if glowColor != .clear {
                            RadialGradient(
                                colors: [
                                    glowColor.opacity(glowIntensity),
                                    glowColor.opacity(glowIntensity * 0.3),
                                    Color.clear
                                ],
                                center: .topTrailing,
                                startRadius: 10,
                                endRadius: 160
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }

                        // Specular lighting gradient
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    } else {
                        // Light mode frosted pearl
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white)

                        if glowColor != .clear {
                            RadialGradient(
                                colors: [
                                    glowColor.opacity(0.06),
                                    Color.clear
                                ],
                                center: .topTrailing,
                                startRadius: 10,
                                endRadius: 120
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }
                    }

                    // 1px Hairline Specular Border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: colorScheme == .dark ? [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.02)
                                ] : [
                                    Color.black.opacity(0.08),
                                    Color.black.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.35)
                    : Color.black.opacity(0.04),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

public extension View {
    func luxuryCard(cornerRadius: CGFloat = 22, glowColor: Color = .clear, glowIntensity: Double = 0.12) -> some View {
        self.modifier(LuxuryGlassCardModifier(cornerRadius: cornerRadius, glowColor: glowColor, glowIntensity: glowIntensity))
    }

    func liquidGlassCard(cornerRadius: CGFloat = 20, interactiveHover: Bool = true) -> some View {
        self.modifier(LuxuryGlassCardModifier(cornerRadius: cornerRadius, glowColor: .clear))
    }
}

// ── Apple Luxury Button Styles ───────────────────────────────────────────────

public struct LuxuryGlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color.white)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: colorScheme == .dark ? [Color.white.opacity(0.18), Color.white.opacity(0.04)] : [Color.black.opacity(0.10), Color.black.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == LuxuryGlassButtonStyle {
    static var luxuryGlass: LuxuryGlassButtonStyle { LuxuryGlassButtonStyle() }
}
