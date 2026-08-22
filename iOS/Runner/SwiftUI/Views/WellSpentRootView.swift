import SwiftUI

public struct WellSpentRootView: View {
    @StateObject private var store = ExpenseStore()
    @State private var selectedTab: TabSelection = .overview
    @State private var previousTab: TabSelection = .overview
    @State private var showQuickAdd: Bool = false

    public init() {}

    public var body: some View {
        #if os(macOS)
        MacDesktopRootView()
            .environmentObject(store)
            .preferredColorScheme(store.colorSchemeForTheme)
        #else
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .quickAdd {
                    PlatformFeedback.impact(.medium)
                    showQuickAdd = true
                } else {
                    PlatformFeedback.selection()
                    selectedTab = newTab
                    previousTab = newTab
                }
            }
        )) {
            OverviewView(showQuickAdd: $showQuickAdd)
                .tabItem {
                    Label(TabSelection.overview.title, systemImage: selectedTab == .overview ? TabSelection.overview.activeIcon : TabSelection.overview.inactiveIcon)
                }
                .tag(TabSelection.overview)

            CategoriesView(showQuickAdd: $showQuickAdd)
                .tabItem {
                    Label(TabSelection.categories.title, systemImage: selectedTab == .categories ? TabSelection.categories.activeIcon : TabSelection.categories.inactiveIcon)
                }
                .tag(TabSelection.categories)

            Color.clear
                .tabItem {
                    Label(TabSelection.quickAdd.title, systemImage: TabSelection.quickAdd.activeIcon)
                }
                .tag(TabSelection.quickAdd)

            InsightsView()
                .tabItem {
                    Label(TabSelection.insights.title, systemImage: selectedTab == .insights ? TabSelection.insights.activeIcon : TabSelection.insights.inactiveIcon)
                }
                .tag(TabSelection.insights)

            SettingsView()
                .tabItem {
                    Label(TabSelection.settings.title, systemImage: selectedTab == .settings ? TabSelection.settings.activeIcon : TabSelection.settings.inactiveIcon)
                }
                .tag(TabSelection.settings)
        }
        .tint(store.accentColor)
        .preferredColorScheme(store.colorSchemeForTheme)
        .environmentObject(store)
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .environmentObject(store)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
        #endif
    }
}
