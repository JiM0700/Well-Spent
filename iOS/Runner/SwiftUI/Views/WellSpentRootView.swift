import SwiftUI

public struct WellSpentRootView: View {
    @StateObject private var store = ExpenseStore()
    @State private var selectedTab: TabSelection = .overview
    @State private var showQuickAdd: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // ── Primary View Body ─────────────────────────────────────────
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

            // ── Apple Dual-Island Floating Tab Bar ────────────────────────
            DualIslandTabBar(
                selectedTab: $selectedTab,
                onAddTapped: {
                    showQuickAdd = true
                }
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(store.colorSchemeForTheme)
        .environmentObject(store)
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environmentObject(store)
        }
    }
}
