#if os(macOS)
import SwiftUI

public struct MacDesktopRootView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedTab: TabSelection = .overview
    @State private var showQuickAdd: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // ── Apple Music Styled Translucent Sidebar ────────────────────
            sidebarContent
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            // ── Main Content Canvas ───────────────────────────────────────
            ZStack {
                // Background canvas
                (colorScheme == .dark ? Color.black : Color.appBackground)
                    .ignoresSafeArea()

                Group {
                    switch selectedTab {
                    case .overview:
                        OverviewView()
                    case .categories:
                        CategoriesView()
                    case .insights:
                        InsightsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                Button("") {
                    showQuickAdd = true
                }
                .keyboardShortcut("n", modifiers: .command)
                .opacity(0)
            )
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environmentObject(store)
                .frame(minWidth: 460, minHeight: 520)
        }
    }

    // ── Sidebar Content ───────────────────────────────────────────────────

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App Branding Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(store.accentColor.gradient)
                        .frame(width: 28, height: 28)
                        .shadow(color: store.accentColor.opacity(0.4), radius: 6, x: 0, y: 2)

                    Image(systemName: "indianrupeesign")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Well Spent")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Personal Finance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 40) // Space for macOS window traffic lights
            .padding(.bottom, 18)

            Divider()
                .opacity(0.3)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            // Navigation Items List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Pulse / Library
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIBRARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)

                        sidebarItem(
                            title: "Overview",
                            icon: "house.fill",
                            tab: .overview,
                            badge: "\(store.expenses.count)"
                        )

                        sidebarItem(
                            title: "Categories",
                            icon: "square.grid.2x2.fill",
                            tab: .categories,
                            badge: "\(ExpenseCategory.allCases.count)"
                        )

                        sidebarItem(
                            title: "Insights & Charts",
                            icon: "chart.xyaxis.line",
                            tab: .insights,
                            badge: nil
                        )
                    }

                    // Section 2: Management & Preferences
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)

                        sidebarItem(
                            title: "Settings & Backup",
                            icon: "gearshape.fill",
                            tab: .settings,
                            badge: nil
                        )
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            // ── Sidebar Footer: Mini Budget Widget & Quick Add ─────────────
            sidebarFooter
        }
        .background(.ultraThinMaterial)
    }

    private func sidebarItem(title: String, icon: String, tab: TabSelection, badge: String?) -> some View {
        let isSelected = selectedTab == tab

        return Button(action: {
            PlatformFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? store.accentColor : .secondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? store.accentColor : Color.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? store.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(store.accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ── Mini Liquid Glass Sidebar Budget Widget ───────────────────────────

    private var sidebarFooter: some View {
        VStack(spacing: 10) {
            let budget = store.monthlyBudget
            let spent = store.currentPeriodTotal
            let usage = budget > 0 ? min(1.0, spent / budget) : 0.0

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Month Envelope")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(usage * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(usage > 1.0 ? Color.red : store.accentColor)
                }

                // Progress track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: usage > 1.0 ? [Color.orange, Color.red] : [store.accentColor, store.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * CGFloat(usage)), height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("₹\(Int(spent)) spent")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₹\(Int(max(0, budget - spent))) left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 12, interactiveHover: false)

            // Primary "+ New Transaction" Liquid Glass Action Button
            Button(action: {
                PlatformFeedback.impact()
                showQuickAdd = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("New Transaction")
                        .font(.system(size: 12.5, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(LiquidGlassButtonStyle(tintColor: store.accentColor, cornerRadius: 10))
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 12)
    }
}
#endif
