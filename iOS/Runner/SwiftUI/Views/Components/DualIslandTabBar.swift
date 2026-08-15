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
    @Binding var selectedTab: TabSelection
    var onAddTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        HStack(spacing: 10) {
            // ── Left Island: 62pt Floating Capsule with Segmented Control Sliding Track ──
            GeometryReader { geo in
                let tabCount = CGFloat(TabSelection.allCases.count)
                let availableWidth = geo.size.width - 8
                let itemWidth = availableWidth / tabCount
                let selectedIndex = CGFloat(selectedTab.rawValue)

                ZStack(alignment: .leading) {
                    // Outer Frosted Glass Capsule
                    Capsule()
                        .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.92) : Color.white.opacity(0.94))
                        .overlay(
                            Capsule()
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.08), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08), radius: 20, x: 0, y: 6)

                    // Continuous Sliding Thumb Pill (Matching UISegmentedControl Physics)
                    Capsule()
                        .fill(colorScheme == .dark ? Color(red: 0.17, green: 0.20, blue: 0.28) : Color(red: 0.929, green: 0.929, blue: 0.929))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 6, x: 0, y: 2)
                        .frame(width: itemWidth, height: 54)
                        .offset(x: 4 + selectedIndex * itemWidth)
                        .animation(.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.2), value: selectedTab)

                    // Interactive Tab Buttons
                    HStack(spacing: 0) {
                        ForEach(TabSelection.allCases) { tab in
                            let isSelected = selectedTab == tab

                            Button(action: {
                                if selectedTab != tab {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0.2)) {
                                        selectedTab = tab
                                    }
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.green : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.11, green: 0.11, blue: 0.12)))

                                    Text(tab.title)
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Color.green : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.11, green: 0.11, blue: 0.12)))
                                        .lineLimit(1)
                                }
                                .frame(width: itemWidth, height: 54)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 62)

            // ── Right Island: 62pt Detached Action Pod (Dedicated Solid Color) ──────
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onAddTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.0)
                        )
                        .shadow(color: Color.green.opacity(0.45), radius: 14, x: 0, y: 5)

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
}

struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
