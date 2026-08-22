import SwiftUI

// ── Tab Navigation Enum (Single Source of Truth for App Tab Bar) ───────────────

public enum TabSelection: Int, CaseIterable {
    case overview = 0
    case categories = 1
    case quickAdd = 2
    case insights = 3
    case settings = 4

    public static var navTabs: [TabSelection] {
        [.overview, .categories, .insights, .settings]
    }

    public var title: String {
        switch self {
        case .overview: return "Home"
        case .categories: return "Budgets"
        case .quickAdd: return "Add"
        case .insights: return "Trends"
        case .settings: return "Settings"
        }
    }

    public var activeIcon: String {
        switch self {
        case .overview: return "house.fill"
        case .categories: return "chart.pie.fill"
        case .quickAdd: return "plus.circle.fill"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }

    public var inactiveIcon: String {
        switch self {
        case .overview: return "house"
        case .categories: return "chart.pie"
        case .quickAdd: return "plus.circle"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}
