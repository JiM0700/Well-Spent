#if os(macOS)
import SwiftUI

public struct MacDesktopRootView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedTab: TabSelection? = .overview
    @State private var showQuickAdd: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // ── Apple HIG Native macOS Sidebar ────────────────────────────
            sidebarList
                .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 290)
                .listStyle(.sidebar)
                .safeAreaInset(edge: .bottom) {
                    sidebarFooterWidget
                }
        } detail: {
            // ── Detail Canvas ─────────────────────────────────────────────
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                Group {
                    switch selectedTab ?? .overview {
                    case .overview:
                        OverviewView(showQuickAdd: $showQuickAdd)
                    case .categories:
                        CategoriesView(showQuickAdd: $showQuickAdd)
                    case .insights:
                        InsightsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                // Primary Action Button (+ New Transaction)
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        PlatformFeedback.impact()
                        showQuickAdd = true
                    }) {
                        Label("New Transaction", systemImage: "plus")
                    }
                    .help("Record a new transaction (⌘N)")
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environmentObject(store)
                .frame(minWidth: 460, minHeight: 520)
        }
    }

    // ── Sidebar List with Native Sections & Badges ────────────────────────

    private var sidebarList: some View {
        List(selection: $selectedTab) {
            // Section 1: Financial Library
            Section("Library") {
                NavigationLink(value: TabSelection.overview) {
                    Label {
                        Text("Home")
                    } icon: {
                        Image(systemName: "house.fill")
                            .foregroundStyle(store.accentColor)
                    }
                }
                .badge(store.expenses.count)
                .keyboardShortcut("1", modifiers: .command)

                NavigationLink(value: TabSelection.categories) {
                    Label {
                        Text("Budgets")
                    } icon: {
                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(Color.orange)
                    }
                }
                .badge(store.allCategories.count)
                .keyboardShortcut("2", modifiers: .command)

                NavigationLink(value: TabSelection.insights) {
                    Label {
                        Text("Trends")
                    } icon: {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(Color.purple)
                    }
                }
                .keyboardShortcut("3", modifiers: .command)
            }

            // Section 2: System & Settings
            Section("System") {
                NavigationLink(value: TabSelection.settings) {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.secondary)
                    }
                }
                .keyboardShortcut("4", modifiers: .command)
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    // ── Sidebar Bottom Inset: Budget Envelope Meter & Quick Add ───────────

    private var sidebarFooterWidget: some View {
        VStack(spacing: 10) {
            Divider()
                .opacity(0.3)

            let budget = store.monthlyBudget
            let spent = store.currentPeriodTotal
            let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
            let isOver = spent > budget && budget > 0
            let remaining = max(0, budget - spent)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Monthly Envelope")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isOver ? "Over Budget" : "\(Int(usage * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : store.accentColor)
                }

                ProgressView(value: usage)
                    .tint(isOver ? Color.red : store.accentColor)

                HStack {
                    Text("₹\(Int(spent)) spent")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₹\(Int(remaining)) left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.appSecondaryGroupedBackground.opacity(0.7))
            )
            .padding(.horizontal, 10)

            // Primary New Transaction Button
            Button(action: {
                PlatformFeedback.impact()
                showQuickAdd = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Transaction")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.accentColor)
            .controlSize(.regular)
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
    }
}
#endif
