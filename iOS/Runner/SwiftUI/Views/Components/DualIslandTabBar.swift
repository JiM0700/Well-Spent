import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// ── Tab Selection Enum (SF Symbols Hierarchical & Fill Variants) ──────────────

public enum TabSelection: Int, CaseIterable {
    case overview = 0
    case categories = 1
    case insights = 2
    case settings = 3

    public var title: String {
        switch self {
        case .overview: return "Home"
        case .categories: return "Budgets"
        case .insights: return "Trends"
        case .settings: return "Settings"
        }
    }

    public var activeIcon: String {
        switch self {
        case .overview: return "house.fill"
        case .categories: return "square.grid.2x2.fill"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }

    public var inactiveIcon: String {
        switch self {
        case .overview: return "house"
        case .categories: return "square.grid.2x2"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}

// ── Apple HIG Liquid Glass Floating Dock (Full Height 62pt) ──────────────────

public struct DualIslandTabBar: View {
    @Binding var selectedTab: TabSelection
    var onAddTapped: () -> Void
    @EnvironmentObject var store: ExpenseStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(
        selectedTab: Binding<TabSelection>,
        onAddTapped: @escaping () -> Void
    ) {
        self._selectedTab = selectedTab
        self.onAddTapped = onAddTapped
    }

    public var body: some View {
        GeometryReader { geo in
            let dockHeight: CGFloat = 62
            let podSize: CGFloat = 62
            let gap: CGFloat = 12
            let horizontalMargin: CGFloat = 16
            let totalAvailableWidth = geo.size.width - (horizontalMargin * 2)
            let navCapsuleWidth = totalAvailableWidth - podSize - gap
            let tabCount: CGFloat = 4
            let slotWidth = navCapsuleWidth / tabCount
            let bubbleInset: CGFloat = 4.5
            let bubbleWidth = slotWidth - (bubbleInset * 2)
            let bubbleHeight = dockHeight - (bubbleInset * 2)

            VStack {
                Spacer()

                HStack(spacing: gap) {
                    // ── Island 1: Navigation Liquid Glass Capsule ───────────────
                    ZStack(alignment: .leading) {
                        // 1. Inherent Optical Glass Substrate
                        if reduceTransparency {
                            Capsule(style: .continuous)
                                .fill(colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.94))
                        } else {
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)
                        }

                        // 2. Uniform 0.5pt Specular Meniscus Rim
                        Capsule(style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.30) : Color.white.opacity(0.85), location: 0.0),
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.25), location: 0.35),
                                        .init(color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04), location: 0.75),
                                        .init(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.08), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                            .shadow(
                                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                                radius: 14,
                                x: 0,
                                y: 5
                            )

                        // 3. Stained Liquid Glass Active Droplet Lens
                        ZStack {
                            if reduceTransparency {
                                RoundedRectangle(cornerRadius: bubbleHeight / 2, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.08))
                            } else {
                                RoundedRectangle(cornerRadius: bubbleHeight / 2, style: .continuous)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: bubbleHeight / 2, style: .continuous)
                                            .fill(
                                                store.accentColor.opacity(colorScheme == .dark ? 0.14 : 0.10)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: bubbleHeight / 2, style: .continuous)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.25))
                                    )
                            }

                            // Specular Top Glint on Active Droplet
                            RoundedRectangle(cornerRadius: bubbleHeight / 2, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        stops: [
                                            .init(color: colorScheme == .dark ? Color.white.opacity(0.40) : Color.white.opacity(0.95), location: 0.0),
                                            .init(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .frame(width: bubbleWidth, height: bubbleHeight)
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                        .offset(x: bubbleInset + CGFloat(selectedTab.rawValue) * slotWidth, y: 0)
                        .animation(
                            reduceMotion
                                ? .none
                                : .spring(response: 0.28, dampingFraction: 0.72, blendDuration: 0.15),
                            value: selectedTab
                        )

                        // 4. Tab Navigation Items
                        HStack(spacing: 0) {
                            ForEach(TabSelection.allCases, id: \.self) { tab in
                                tabButton(for: tab, slotWidth: slotWidth, height: dockHeight)
                            }
                        }
                    }
                    .frame(width: navCapsuleWidth, height: dockHeight)

                    // ── Island 2: Detached Quick Action Pure Glass Pod (62pt) ─
                    Button(action: {
                        PlatformFeedback.impact()
                        onAddTapped()
                    }) {
                        ZStack {
                            if reduceTransparency {
                                Circle()
                                    .fill(colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.94))
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }

                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        stops: [
                                            .init(color: colorScheme == .dark ? Color.white.opacity(0.30) : Color.white.opacity(0.85), location: 0.0),
                                            .init(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.25), location: 0.35),
                                            .init(color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04), location: 0.75),
                                            .init(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.08), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                                .shadow(
                                    color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                                    radius: 14,
                                    x: 0,
                                    y: 5
                                )

                            Image(systemName: "plus")
                                .font(.system(size: 21, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                        }
                        .frame(width: podSize, height: podSize)
                    }
                    .buttonStyle(SquishButtonStyle())
                }
                .padding(.horizontal, horizontalMargin)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 88)
    }

    // ── Tab Item Button with SF Symbols HIG ───────────────────────────────

    private func tabButton(for tab: TabSelection, slotWidth: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedTab == tab
        let activeColor = store.accentColor

        return Button(action: {
            if selectedTab != tab {
                PlatformFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72, blendDuration: 0.15)) {
                    selectedTab = tab
                }
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.activeIcon : tab.inactiveIcon)
                    .font(.system(size: 18.5, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(isSelected ? .hierarchical : .monochrome)
                    .symbolEffect(.bounce.byLayer, value: isSelected)
                    .foregroundStyle(
                        isSelected
                            ? activeColor
                            : (colorScheme == .dark ? Color.white.opacity(0.72) : Color.primary.opacity(0.60))
                    )
                    .frame(height: 24)
                    .scaleEffect(isSelected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isSelected)

                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(
                        isSelected
                            ? activeColor
                            : (colorScheme == .dark ? Color.white.opacity(0.72) : Color.primary.opacity(0.60))
                    )
                    .lineLimit(1)
            }
            .frame(width: slotWidth, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ── Physical Squish Button Physics ───────────────────────────────────────────

public struct SquishButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
