import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetTransactionItem: Codable, Identifiable {
    public let id: String
    public let title: String
    public let amount: Double
    public let category: String
    public let time: String

    public init(id: String, title: String, amount: Double, category: String, time: String) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.time = time
    }
}

public struct TodayExpenseWidgetData: Codable {
    public let todayTotal: Double
    public let dailyBudget: Double
    public let remainingDaily: Double
    public let monthlyBudget: Double
    public let accentColorName: String
    public let transactionCount: Int
    public let recentTransactions: [WidgetTransactionItem]
    public let lastUpdated: Date

    public init(
        todayTotal: Double,
        dailyBudget: Double,
        remainingDaily: Double,
        monthlyBudget: Double,
        accentColorName: String,
        transactionCount: Int,
        recentTransactions: [WidgetTransactionItem],
        lastUpdated: Date = Date()
    ) {
        self.todayTotal = todayTotal
        self.dailyBudget = dailyBudget
        self.remainingDaily = remainingDaily
        self.monthlyBudget = monthlyBudget
        self.accentColorName = accentColorName
        self.transactionCount = transactionCount
        self.recentTransactions = recentTransactions
        self.lastUpdated = lastUpdated
    }

    public static var placeholder: TodayExpenseWidgetData {
        TodayExpenseWidgetData(
            todayTotal: 380.0,
            dailyBudget: 1600.0,
            remainingDaily: 1220.0,
            monthlyBudget: 50000.0,
            accentColorName: "green",
            transactionCount: 2,
            recentTransactions: [
                WidgetTransactionItem(id: "1", title: "Morning Espresso", amount: 180.0, category: "food", time: "09:15"),
                WidgetTransactionItem(id: "2", title: "Metro Smart Card", amount: 200.0, category: "transport", time: "11:30")
            ]
        )
    }
}

public final class WidgetDataManager {
    public static let shared = WidgetDataManager()
    public static let appGroupSuite = "group.com.example.wellSpent"
    private let storageKey = "today_expense_widget_data"

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: WidgetDataManager.appGroupSuite) ?? UserDefaults.standard
    }

    public func updateWidgetData(expenses: [Expense], monthlyBudget: Double, accentColorName: String) {
        let calendar = Calendar.current
        let todayExpenses = expenses.filter { calendar.isDateInToday($0.date) }
        let todayTotal = todayExpenses.reduce(0.0) { $0 + $1.amount }

        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dailyBudget = monthlyBudget > 0 ? (monthlyBudget / Double(daysInMonth)) : 1500.0
        let remainingDaily = max(0, dailyBudget - todayTotal)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let recentItems: [WidgetTransactionItem] = todayExpenses.prefix(4).map { exp in
            WidgetTransactionItem(
                id: exp.id,
                title: exp.title,
                amount: exp.amount,
                category: exp.category.rawValue,
                time: timeFormatter.string(from: exp.date)
            )
        }

        let widgetData = TodayExpenseWidgetData(
            todayTotal: todayTotal,
            dailyBudget: dailyBudget,
            remainingDaily: remainingDaily,
            monthlyBudget: monthlyBudget,
            accentColorName: accentColorName,
            transactionCount: todayExpenses.count,
            recentTransactions: recentItems,
            lastUpdated: Date()
        )

        if let encoded = try? JSONEncoder().encode(widgetData) {
            userDefaults.set(encoded, forKey: storageKey)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public func getWidgetData() -> TodayExpenseWidgetData {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(TodayExpenseWidgetData.self, from: data) else {
            return TodayExpenseWidgetData.placeholder
        }
        return decoded
    }
}
