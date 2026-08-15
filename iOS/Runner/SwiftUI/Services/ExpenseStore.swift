import Foundation
import SwiftUI
import Combine

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
            recurringBills: recurringBills
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: .atomic)
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

    public func updateCategoryBudget(category: ExpenseCategory, amount: Double) {
        categoryBudgets[category.rawValue] = amount
        saveData()
    }

    public func getCategoryBudget(category: ExpenseCategory) -> Double {
        return categoryBudgets[category.rawValue] ?? 0.0
    }

    public func toggleRecurringBillPaid(id: String) {
        if let idx = recurringBills.firstIndex(where: { $0.id == id }) {
            recurringBills[idx].isPaid.toggle()
            saveData()
        }
    }

    // ── Metrics & Calculations ────────────────────────────────────────────

    public var currentPeriodExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        return expenses.filter { exp in
            guard exp.isExpense else { return false }
            return calendar.isDate(exp.date, equalTo: now, toGranularity: .month)
        }
    }

    public var currentPeriodTotal: Double {
        currentPeriodExpenses.reduce(0.0) { $0 + $1.amount }
    }

    public var todayTotal: Double {
        let calendar = Calendar.current
        return expenses.filter { exp in
            exp.isExpense && calendar.isDateInToday(exp.date)
        }.reduce(0.0) { $0 + $1.amount }
    }

    public var remainingBudget: Double {
        max(0, monthlyBudget - currentPeriodTotal)
    }

    public var categoryBreakdown: [ExpenseCategory: Double] {
        var map: [ExpenseCategory: Double] = [:]
        for exp in currentPeriodExpenses {
            map[exp.category, default: 0.0] += exp.amount
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

    // ── CSV Export & Import ────────────────────────────────────────────────

    public func exportCsv() -> String {
        var csv = "ID,Title,Amount,Category,Date,Notes,IsExpense\n"
        let formatter = ISO8601DateFormatter()
        for exp in expenses {
            let safeTitle = exp.title.replacingOccurrences(of: "\"", with: "\"\"")
            let safeNotes = exp.notes.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(exp.id)\",\"\(safeTitle)\",\(exp.amount),\"\(exp.category.rawValue)\",\"\(formatter.string(from: exp.date))\",\"\(safeNotes)\",\(exp.isExpense)\n"
        }
        return csv
    }

    public func importCsv(content: String) -> Int {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { return 0 }
        let formatter = ISO8601DateFormatter()
        var imported = 0

        for line in lines.dropFirst() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let parts = line.components(separatedBy: ",")
            if parts.count >= 4 {
                let title = parts[1].replacingOccurrences(of: "\"", with: "")
                let amount = Double(parts[2].trimmingCharacters(in: .whitespaces)) ?? 0.0
                let catRaw = parts[3].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                let cat = ExpenseCategory(rawValue: catRaw) ?? .other
                let dateStr = parts.count > 4 ? parts[4].replacingOccurrences(of: "\"", with: "") : ""
                let date = formatter.date(from: dateStr) ?? Date()
                let notes = parts.count > 5 ? parts[5].replacingOccurrences(of: "\"", with: "") : ""

                let expense = Expense(title: title, amount: amount, category: cat, date: date, notes: notes)
                expenses.append(expense)
                imported += 1
            }
        }
        if imported > 0 {
            saveData()
        }
        return imported
    }
}
