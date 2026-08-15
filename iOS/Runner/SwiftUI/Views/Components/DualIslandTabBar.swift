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

    public init(selectedTab: Binding<TabSelection>, onAddTapped: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onAddTapped = onAddTapped
    }

    public var body: some View {
        HStack(spacing: 8) {
            // ── Primary 56pt Liquid Glass Dock with Optical Corner Refraction ──
            GeometryReader { geo in
                let totalSlots: CGFloat = 5 // 4 tabs + 1 center action button
                let availableWidth = geo.size.width - 8
                let slotWidth = availableWidth / totalSlots

                // Calculate visual thumb offset based on selected tab index
                let thumbSlotIndex: CGFloat = {
                    switch selectedTab {
                    case .overview: return 0
                    case .categories: return 1
                    case .insights: return 3
                    case .settings: return 4
                    }
                }()

                ZStack(alignment: .leading) {
                    // 1. Base Liquid Glass Capsule with Authentic Apple Optics
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            // Inset Caustic Refraction Line (Inner Surface)
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.55),
                                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.10),
                                            Color.clear,
                                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.7
                                )
                                .padding(0.7)
                        )
                        .overlay(
                            // Outer Specular Meniscus Highlight Rim
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.75 : 0.95),
                                            Color.white.opacity(colorScheme == .dark ? 0.20 : 0.40),
                                            Color.clear,
                                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.30)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.9
                                )
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.55 : 0.10), radius: 18, x: 0, y: 5)

                    // 2. Dynamic Liquid Light Aura under Active Selection
                    RadialGradient(
                        colors: [
                            store.accentColor.opacity(isLongPressing ? 0.50 : 0.28),
                            store.accentColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: isLongPressing ? 44 : 30
                    )
                    .frame(width: slotWidth + 20, height: 56)
                    .offset(x: (4 + thumbSlotIndex * slotWidth) - 10)
                    .animation(.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.2), value: selectedTab)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isLongPressing)

                    // 3. Sliding Liquid Water Droplet Lens Thumb
                    ZStack {
                        Capsule()
                            .fill(
                                store.accentColor.opacity(isLongPressing ? 0.24 : 0.15)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(colorScheme == .dark ? 0.70 : 0.90),
                                                store.accentColor.opacity(0.40),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.9
                                    )
                            )
                    }
                    .frame(width: slotWidth - 4, height: 46)
                    .scaleEffect(isLongPressing ? CGSize(width: 1.10, height: 1.06) : CGSize(width: 1.0, height: 1.0))
                    .offset(x: 6 + thumbSlotIndex * slotWidth)
                    .animation(.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.2), value: selectedTab)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isLongPressing)

                    // 4. Tab Items & Centered Quick Add Action
                    HStack(spacing: 0) {
                        tabButton(for: .overview, slotWidth: slotWidth)
                        tabButton(for: .categories, slotWidth: slotWidth)

                        // Center Floating Action Pod
                        centerAddButton(slotWidth: slotWidth)

                        tabButton(for: .insights, slotWidth: slotWidth)
                        tabButton(for: .settings, slotWidth: slotWidth)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 56)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, -8)
    }

    // ── Tab Item Button ───────────────────────────────────────────────────

    private func tabButton(for tab: TabSelection, slotWidth: CGFloat) -> some View {
        let isSelected = selectedTab == tab

        return Button(action: {
            if selectedTab != tab {
                PlatformFeedback.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.2)) {
                    selectedTab = tab
                }
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? store.accentColor : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.15, green: 0.15, blue: 0.17)))
                    .scaleEffect(isSelected && isLongPressing ? 1.12 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isLongPressing)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? store.accentColor : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.15, green: 0.15, blue: 0.17)))
                    .lineLimit(1)
            }
            .frame(width: slotWidth, height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.25)
                .onEnded { _ in
                    PlatformFeedback.impact()
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                        selectedTab = tab
                        isLongPressing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isLongPressing = false
                        }
                    }
                }
        )
    }

    // ── Center Quick Add Action Button ────────────────────────────────────

    private func centerAddButton(slotWidth: CGFloat) -> some View {
        Button(action: {
            PlatformFeedback.impact()
            onAddTapped()
        }) {
            ZStack {
                Circle()
                    .fill(store.accentColor)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.65),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(color: store.accentColor.opacity(0.45), radius: 8, x: 0, y: 2)

                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)
            .frame(width: slotWidth, height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(SquishButtonStyle())
    }
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
