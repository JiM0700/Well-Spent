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

    public func updateWidgetData(expenses: [Expense], monthlyBudget: Double, accentColorName: String, cycleStartDay: Int = 1) {
        let calendar = Calendar.current
        let now = Date()
        let day = calendar.component(.day, from: now)
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        var startMonth = month
        var startYear = year
        if day < cycleStartDay {
            startMonth -= 1
            if startMonth < 1 { startMonth = 12; startYear -= 1 }
        }
        var comps = DateComponents(year: startYear, month: startMonth, day: min(cycleStartDay, 28))
        comps.hour = 0; comps.minute = 0; comps.second = 0
        let cycleStart = calendar.date(from: comps) ?? now

        var endMonth = startMonth + 1
        var endYear = startYear
        if endMonth > 12 { endMonth = 1; endYear += 1 }
        var endComps = DateComponents(year: endYear, month: endMonth, day: min(cycleStartDay, 28))
        endComps.hour = 0; endComps.minute = 0; endComps.second = 0
        let cycleEnd = calendar.date(from: endComps) ?? now

        let totalDays = max(1, calendar.dateComponents([.day], from: cycleStart, to: cycleEnd).day ?? 30)
        let daysElapsed = max(1, min(totalDays, (calendar.dateComponents([.day], from: cycleStart, to: now).day ?? 0) + 1))
        let daysRemainingIncludingToday = max(1, totalDays - daysElapsed + 1)

        let cycleExpenses = expenses.filter { $0.isExpense && $0.date >= cycleStart && $0.date < cycleEnd }
        let monthTotal = cycleExpenses.reduce(0.0) { $0 + $1.amount }

        let todayExpenses = expenses.filter { calendar.isDateInToday($0.date) && $0.isExpense }
        let todayTotal = todayExpenses.reduce(0.0) { $0 + $1.amount }

        let previousSpend = max(0.0, monthTotal - todayTotal)
        let remainingMonthBalance = max(0.0, monthlyBudget - previousSpend)
        let dynamicDailyBudget = remainingMonthBalance > 0 ? (remainingMonthBalance / Double(daysRemainingIncludingToday)) : 0.0
        let remainingDaily = max(0.0, dynamicDailyBudget - todayTotal)

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
            dailyBudget: dynamicDailyBudget,
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
