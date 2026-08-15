import Foundation
import SwiftUI
import Combine

/// Central state store and persistence engine for the Well Spent application
public final class ExpenseStore: ObservableObject {
    @Published public var expenses: [Expense] = []
    @Published public var monthlyBudget: Double = 50000.0
    @Published public var cycleStartDay: Int = 1
    @Published public var baseMonthlyIncome: Double = 80000.0
    @Published public var payDay: Int = 1
    @Published public var categoryBudgets: [String: Double] = [
        "food": 12000.0,
        "transport": 6000.0,
        "utilities": 5000.0,
        "entertainment": 4000.0,
        "health": 4000.0,
        "shopping": 8000.0,
        "housing": 10000.0,
        "other": 1000.0
    ]
    @Published public var summaryEnabled: Bool = true
    @Published public var summaryPeriod: String = "monthly"
    @Published public var recurringBills: [RecurringBill] = [
        RecurringBill(title: "High-Speed Fiber Internet", amount: 1499.0, category: .utilities, dueDay: 5),
        RecurringBill(title: "Cloud Storage & Backup", amount: 650.0, category: .entertainment, dueDay: 12),
        RecurringBill(title: "Gym Membership", amount: 2500.0, category: .health, dueDay: 18),
        RecurringBill(title: "Apartment Maintenance", amount: 3500.0, category: .housing, dueDay: 25)
    ]
    @Published public var selectedCategoryFilter: ExpenseCategory? = nil
    @Published public var currentViewMode: String = "daywise" // "daywise" | "monthwise"
    @Published public var appThemeMode: String = "system" // "system" | "light" | "dark"
    @Published public var appAccentColorName: String = "green"

    public var accentColor: Color {
        switch appAccentColorName {
        case "blue": return Color.blue
        case "indigo": return Color.indigo
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "teal": return Color.teal
        case "pink": return Color.pink
        default: return Color.green
        }
    }

    public var colorSchemeForTheme: ColorScheme? {
        switch appThemeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private let fileURL: URL

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("well_spent_store.json")
        loadData()
    }

    // ── Data Persistence ──────────────────────────────────────────────────

    private struct PersistedData: Codable {
        var expenses: [Expense]
        var monthlyBudget: Double
        var cycleStartDay: Int
        var baseMonthlyIncome: Double
        var payDay: Int
        var categoryBudgets: [String: Double]
        var summaryEnabled: Bool
        var summaryPeriod: String
        var recurringBills: [RecurringBill]
        var appThemeMode: String?
        var appAccentColorName: String?
    }

    public func saveData() {
        let data = PersistedData(
            expenses: expenses,
            monthlyBudget: monthlyBudget,
            cycleStartDay: cycleStartDay,
            baseMonthlyIncome: baseMonthlyIncome,
            payDay: payDay,
            categoryBudgets: categoryBudgets,
            summaryEnabled: summaryEnabled,
            summaryPeriod: summaryPeriod,
            recurringBills: recurringBills,
            appThemeMode: appThemeMode,
            appAccentColorName: appAccentColorName
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: .atomic)
            WidgetDataManager.shared.updateWidgetData(
                expenses: expenses,
                monthlyBudget: monthlyBudget,
                accentColorName: appAccentColorName
            )
        } catch {
            print("Error saving data: \(error)")
        }
    }

    public func loadData() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            seedInitialData()
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(PersistedData.self, from: data)
            self.expenses = decoded.expenses
            self.monthlyBudget = decoded.monthlyBudget
            self.cycleStartDay = decoded.cycleStartDay
            self.baseMonthlyIncome = decoded.baseMonthlyIncome
            self.payDay = decoded.payDay
            self.categoryBudgets = decoded.categoryBudgets
            self.summaryEnabled = decoded.summaryEnabled
            self.summaryPeriod = decoded.summaryPeriod
            self.recurringBills = decoded.recurringBills
            self.appThemeMode = decoded.appThemeMode ?? "system"
            self.appAccentColorName = decoded.appAccentColorName ?? "green"
        } catch {
            print("Error loading data: \(error)")
            seedInitialData()
        }
    }

    private func seedInitialData() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now

        self.expenses = [
            Expense(title: "Specialty Espresso & Croissant", amount: 380.0, category: .food, date: now, notes: "Morning cafe"),
            Expense(title: "Organic Grocery Basket", amount: 1450.0, category: .food, date: now, notes: "Fresh produce"),
            Expense(title: "Metro Smart Card Recharge", amount: 500.0, category: .transport, date: yesterday, notes: "Commute"),
            Expense(title: "Quarterly Water & Power Bill", amount: 2400.0, category: .utilities, date: twoDaysAgo, notes: "Home utilities"),
            Expense(title: "Weekend Cinema Tickets", amount: 850.0, category: .entertainment, date: twoDaysAgo, notes: "IMAX")
        ]
        saveData()
    }

    // ── CRUD Operations ───────────────────────────────────────────────────

    public func addExpense(_ expense: Expense) {
        expenses.insert(expense, at: 0)
        saveData()
    }

    public func deleteExpense(id: String) {
        expenses.removeAll { $0.id == id }
        saveData()
    }

    public func updateExpense(_ expense: Expense) {
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx] = expense
            saveData()
        }
    }

    public func toggleBillPaid(id: String) {
        if let idx = recurringBills.firstIndex(where: { $0.id == id }) {
            recurringBills[idx].isPaid.toggle()
            saveData()
        }
    }

    public func toggleRecurringBillPaid(id: String) {
        toggleBillPaid(id: id)
    }

    public func setCategoryBudget(category: ExpenseCategory, amount: Double) {
        categoryBudgets[category.rawValue] = amount
        saveData()
    }

    public func updateCategoryBudget(category: ExpenseCategory, amount: Double) {
        setCategoryBudget(category: category, amount: amount)
    }

    public func getCategoryBudget(category: ExpenseCategory) -> Double {
        categoryBudgets[category.rawValue] ?? 0.0
    }

    // ── Metrics & Calculations ────────────────────────────────────────────

    public var todaySpend: Double {
        let calendar = Calendar.current
        return expenses
            .filter { calendar.isDateInToday($0.date) && $0.isExpense }
            .reduce(0.0) { $0 + $1.amount }
    }

    public var currentPeriodTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses
            .filter { exp in
                guard exp.isExpense else { return false }
                let compExp = calendar.dateComponents([.year, .month], from: exp.date)
                let compNow = calendar.dateComponents([.year, .month], from: now)
                return compExp.year == compNow.year && compExp.month == compNow.month
            }
            .reduce(0.0) { $0 + $1.amount }
    }

    public var remainingBudget: Double {
        max(0.0, monthlyBudget - currentPeriodTotal)
    }

    public var budgetBurnPercentage: Double {
        guard monthlyBudget > 0 else { return 0.0 }
        return min(1.0, currentPeriodTotal / monthlyBudget)
    }

    public func spentForCategory(_ category: ExpenseCategory) -> Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses
            .filter { exp in
                guard exp.category == category && exp.isExpense else { return false }
                let compExp = calendar.dateComponents([.year, .month], from: exp.date)
                let compNow = calendar.dateComponents([.year, .month], from: now)
                return compExp.year == compNow.year && compExp.month == compNow.month
            }
            .reduce(0.0) { $0 + $1.amount }
    }

    public var categoryBreakdown: [ExpenseCategory: Double] {
        var map: [ExpenseCategory: Double] = [:]
        for cat in ExpenseCategory.allCases {
            let total = spentForCategory(cat)
            if total > 0 {
                map[cat] = total
            }
        }
        return map
    }

    public var dailySpendAverage: Double {
        let day = Calendar.current.component(.day, from: Date())
        let elapsed = max(1, day)
        return currentPeriodTotal / Double(elapsed)
    }

    public var projectedMonthEnd: Double {
        let range = Calendar.current.range(of: .day, in: .month, for: Date())
        let totalDays = Double(range?.count ?? 30)
        return dailySpendAverage * totalDays
    }

    // ── Universal CSV Engine Delegation ───────────────────────────────────

    public func exportCsv() -> String {
        return CsvEngine.exportCsv(from: expenses)
    }

    public func importCsv(content: String) -> Int {
        let parsed = CsvEngine.importCsv(content: content)
        guard !parsed.isEmpty else { return 0 }
        expenses.append(contentsOf: parsed)
        saveData()
        return parsed.count
    }

    public func deleteAllData() {
        expenses.removeAll()
        categoryBudgets.removeAll()
        saveData()
    }
}
