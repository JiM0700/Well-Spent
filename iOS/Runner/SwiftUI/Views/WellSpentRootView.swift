import SwiftUI

public struct WellSpentRootView: View {
    @StateObject private var store = ExpenseStore()
    @State private var selectedTab: TabSelection = .overview
    @State private var showQuickAdd: Bool = false

    public init() {}

    public var body: some View {
        #if os(macOS)
        MacDesktopRootView()
            .environmentObject(store)
            .preferredColorScheme(store.colorSchemeForTheme)
        #else
        TabView(selection: $selectedTab) {
            OverviewView(showQuickAdd: $showQuickAdd)
                .tabItem {
                    Label("Home", systemImage: selectedTab == .overview ? "house.fill" : "house")
                }
                .tag(TabSelection.overview)

            CategoriesView(showQuickAdd: $showQuickAdd)
                .tabItem {
                    Label("Budgets", systemImage: selectedTab == .categories ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .tag(TabSelection.categories)

            InsightsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar.xaxis")
                }
                .tag(TabSelection.insights)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(TabSelection.settings)
        }
        .tint(store.accentColor)
        .preferredColorScheme(store.colorSchemeForTheme)
        .environmentObject(store)
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environmentObject(store)
        }
        #endif
    }
}
