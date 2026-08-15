import SwiftUI

public enum TabSelection: Int, CaseIterable, Identifiable {
    case overview = 0
    case categories = 1
    case insights = 2
    case settings = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .overview: return "Overview"
        case .categories: return "Categories"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    public var icon: String {
        switch self {
        case .overview: return "house"
        case .categories: return "square.grid.2x2"
        case .insights: return "chart.bar"
        case .settings: return "gearshape"
        }
    }

    public var activeIcon: String {
        switch self {
        case .overview: return "house.fill"
        case .categories: return "square.grid.2x2.fill"
        case .insights: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct DualIslandTabBar: View {
    @EnvironmentObject var store: ExpenseStore
    @Binding var selectedTab: TabSelection
    var onAddTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme

    // ── Interactive State ──────────────────────────────────────────────────
    @State private var isLongPressing: Bool = false
    @State private var pressedTab: TabSelection? = nil
    @State private var dragOffset: CGFloat = 0.0

    public var body: some View {
        HStack(spacing: 10) {
            // ── Left Island: 62pt Floating Capsule with Segmented Control Sliding Track ──
            GeometryReader { geo in
                let tabCount = CGFloat(TabSelection.allCases.count)
                let availableWidth = geo.size.width - 8
                let itemWidth = availableWidth / tabCount
                let selectedIndex = CGFloat(selectedTab.rawValue)

                ZStack(alignment: .leading) {
                    // 1. Outer Liquid Glass Capsule
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.42 : 0.75),
                                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25),
                                            Color.clear,
                                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.9
                                )
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.55 : 0.08), radius: 18, x: 0, y: 5)

                    // 2. Liquid Glass Interactive Glow Aura (Under Selected Tab)
                    RadialGradient(
                        colors: [
                            store.accentColor.opacity(isLongPressing ? 0.55 : 0.30),
                            store.accentColor.opacity(isLongPressing ? 0.20 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: isLongPressing ? 46 : 32
                    )
                    .frame(width: itemWidth + 24, height: 64)
                    .offset(x: (4 + selectedIndex * itemWidth) - 12)
                    .animation(.spring(response: 0.34, dampingFraction: 0.70, blendDuration: 0.2), value: selectedTab)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isLongPressing)

                    // 3. Sliding Liquid Water Bubble Thumb with Refraction Lens & Elastic Squish
                    ZStack {
                        Capsule()
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(isLongPressing ? 0.24 : 0.16)
                                    : Color.black.opacity(isLongPressing ? 0.10 : 0.06)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(colorScheme == .dark ? 0.55 : 0.8),
                                                Color.white.opacity(0.1),
                                                store.accentColor.opacity(isLongPressing ? 0.6 : 0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isLongPressing ? 1.4 : 0.8
                                    )
                            )
                            .shadow(color: store.accentColor.opacity(isLongPressing ? 0.45 : 0.15), radius: isLongPressing ? 10 : 4, x: 0, y: 2)
                    }
                    .frame(width: itemWidth, height: 54)
                    .scaleEffect(isLongPressing ? CGSize(width: 1.12, height: 1.08) : CGSize(width: 1.0, height: 1.0))
                    .offset(x: 4 + selectedIndex * itemWidth)
                    .animation(.spring(response: 0.32, dampingFraction: 0.70, blendDuration: 0.2), value: selectedTab)
                    .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isLongPressing)

                    // 4. Interactive Tab Buttons with Liquid Long-Press & Tap Response
                    HStack(spacing: 0) {
                        ForEach(TabSelection.allCases) { tab in
                            let isSelected = selectedTab == tab
                            let isTarget = pressedTab == tab

                            tabButton(for: tab, itemWidth: itemWidth, isSelected: isSelected, isTarget: isTarget)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 62)

            // ── Right Island: 62pt Detached Action Pod with Glowing Corona ─────
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onAddTapped()
            }) {
                ZStack {
                    // Liquid Glass Corona Glow
                    Circle()
                        .fill(store.accentColor)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .shadow(color: store.accentColor.opacity(0.55), radius: 14, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 62, height: 62)
            }
            .buttonStyle(SquishButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private func tabButton(for tab: TabSelection, itemWidth: CGFloat, isSelected: Bool, isTarget: Bool) -> some View {
        Button(action: {
            if selectedTab != tab {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.70, blendDuration: 0.2)) {
                    selectedTab = tab
                }
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? store.accentColor : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.11, green: 0.11, blue: 0.12)))
                    .scaleEffect(isSelected && isLongPressing ? 1.15 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isLongPressing)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? store.accentColor : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.11, green: 0.11, blue: 0.12)))
                    .lineLimit(1)
            }
            .frame(width: itemWidth, height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in
                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.impactOccurred(intensity: 0.85)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                        selectedTab = tab
                        isLongPressing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isLongPressing = false
                        }
                    }
                }
        )
    }

    private func getDisplayCornerRadius() -> CGFloat {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }),
           let radius = window.screen.value(forKey: "_displayCornerRadius") as? CGFloat, radius > 0 {
            return radius
        }
        return 47.0 // Fallback to iPhone 14 Pro / 15 / 16 / 17 curvature
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
