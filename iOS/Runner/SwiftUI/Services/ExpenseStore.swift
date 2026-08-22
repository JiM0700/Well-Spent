import Foundation
import SwiftUI
import Combine

/// Central state store and persistence engine for the Well Spent application
@MainActor
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
        "investment": 15000.0,
        "other": 1000.0
    ]
    @Published public var customCategories: [ExpenseCategory] = []
    
    public var allCategories: [ExpenseCategory] {
        ExpenseCategory.builtInCategories + customCategories
    }
    @Published public var summaryEnabled: Bool = true
    @Published public var summaryPeriod: String = "monthly"
    @Published public var recurringBills: [RecurringBill] = [
        RecurringBill(title: "High-Speed Fiber Internet", amount: 1499.0, category: .utilities, dueDay: 5),
        RecurringBill(title: "Cloud Storage & Backup", amount: 650.0, category: .entertainment, dueDay: 12),
        RecurringBill(title: "Gym Membership", amount: 2500.0, category: .health, dueDay: 18),
        RecurringBill(title: "Apartment Maintenance", amount: 3500.0, category: .housing, dueDay: 25)
    ]
    @Published public var goals: [Goal] = [
        Goal(title: "Emergency Fund", targetAmount: 150000.0, currentAmount: 65000.0, sfSymbol: "shield.fill", colorName: "green"),
        Goal(title: "Japan Vacation", targetAmount: 200000.0, currentAmount: 45000.0, sfSymbol: "airplane", colorName: "blue"),
        Goal(title: "New MacBook Pro", targetAmount: 180000.0, currentAmount: 120000.0, sfSymbol: "laptopcomputer", colorName: "purple")
    ]
    @Published public var netWorth: NetWorth = NetWorth(assets: 450000.0, liabilities: 85000.0)
    @Published public var globalTags: [String] = ["food", "work", "travel", "weekend", "groceries", "coffee", "rent"]
    @Published public var selectedCategoryFilter: ExpenseCategory? = nil
    @Published public var selectedTagFilter: String? = nil
    @Published public var currentViewMode: String = "monthwise" // "daywise" | "monthwise"
    @Published public var appThemeMode: String = "system" // "system" | "light" | "dark"
    @Published public var appAccentColorName: String = "blue"
    @Published public var hapticsEnabled: Bool = true {
        didSet {
            PlatformFeedback.isHapticsEnabled = hapticsEnabled
        }
    }
    @Published public var soundsEnabled: Bool = true {
        didSet {
            PlatformFeedback.isSoundsEnabled = soundsEnabled
        }
    }

    public var accentColor: Color {
        Color.blue
    }

    public var colorSchemeForTheme: ColorScheme? {
        switch appThemeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    public var allUniqueTags: [String] {
        var set = Set(globalTags)
        for e in expenses {
            for t in e.tags {
                set.insert(t.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            }
        }
        return Array(set).filter { !$0.isEmpty }.sorted()
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
        var goals: [Goal]?
        var netWorth: NetWorth?
        var globalTags: [String]?
        var customCategories: [ExpenseCategory]?
        var appThemeMode: String?
        var appAccentColorName: String?
        var hapticsEnabled: Bool?
        var soundsEnabled: Bool?
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
            goals: goals,
            netWorth: netWorth,
            globalTags: globalTags,
            customCategories: customCategories,
            appThemeMode: appThemeMode,
            appAccentColorName: appAccentColorName,
            hapticsEnabled: hapticsEnabled,
            soundsEnabled: soundsEnabled
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            #if os(iOS)
            try encoded.write(to: fileURL, options: [.atomic, .completeFileProtection])
            #else
            try encoded.write(to: fileURL, options: .atomic)
            #endif
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
            if let loadedGoals = decoded.goals {
                self.goals = loadedGoals
            }
            if let loadedNetWorth = decoded.netWorth {
                self.netWorth = loadedNetWorth
            }
            if let loadedTags = decoded.globalTags {
                self.globalTags = loadedTags
            }
            if let loadedCustom = decoded.customCategories {
                self.customCategories = loadedCustom
                // Reconcile custom category definitions on loaded expenses
                for i in 0..<self.expenses.count {
                    if let matched = loadedCustom.first(where: { $0.id == self.expenses[i].category.id }) {
                        self.expenses[i].category = matched
                    }
                }
            }
            self.appThemeMode = decoded.appThemeMode ?? "system"
            self.appAccentColorName = decoded.appAccentColorName ?? "blue"
            self.hapticsEnabled = decoded.hapticsEnabled ?? true
            self.soundsEnabled = decoded.soundsEnabled ?? true
            PlatformFeedback.isHapticsEnabled = self.hapticsEnabled
            PlatformFeedback.isSoundsEnabled = self.soundsEnabled
        } catch {
            print("Error loading data: \(error)")
            let backupURL = fileURL.deletingLastPathComponent().appendingPathComponent("well_spent_store.corrupt.json")
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
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

    public func addRecurringBill(_ bill: RecurringBill) {
        recurringBills.append(bill)
        saveData()
    }

    public func updateRecurringBill(_ bill: RecurringBill) {
        if let idx = recurringBills.firstIndex(where: { $0.id == bill.id }) {
            recurringBills[idx] = bill
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

    public func deleteRecurringBill(id: String) {
        recurringBills.removeAll { $0.id == id }
        saveData()
    }

    // ── Goals CRUD ────────────────────────────────────────────────────────

    public func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveData()
    }

    public func updateGoal(_ goal: Goal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
            saveData()
        }
    }

    public func deleteGoal(id: String) {
        goals.removeAll { $0.id == id }
        saveData()
    }

    public func depositToGoal(id: String, amount: Double) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx].currentAmount = max(0, goals[idx].currentAmount + amount)
            saveData()
        }
    }

    // ── Net Worth & Tags ──────────────────────────────────────────────────

    public func updateNetWorth(assets: Double, liabilities: Double) {
        netWorth = NetWorth(assets: assets, liabilities: liabilities, lastUpdated: Date())
        saveData()
    }

    public func addGlobalTag(_ tag: String) {
        let clean = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !clean.isEmpty && !globalTags.contains(clean) {
            globalTags.append(clean)
            saveData()
        }
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

    public func addCustomCategory(displayName: String, sfSymbol: String, colorHex: String, budget: Double = 0.0) -> ExpenseCategory {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "custom_" + UUID().uuidString.prefix(8).lowercased()
        let newCat = ExpenseCategory(
            id: id,
            displayName: cleanName.isEmpty ? "Custom" : cleanName,
            sfSymbol: sfSymbol.isEmpty ? "tag.fill" : sfSymbol,
            colorHex: colorHex.isEmpty ? "#007AFF" : colorHex,
            isCustom: true
        )
        customCategories.append(newCat)
        if budget > 0 {
            categoryBudgets[newCat.rawValue] = budget
        }
        saveData()
        return newCat
    }

    public func deleteCustomCategory(id: String) {
        customCategories.removeAll { $0.id == id }
        categoryBudgets.removeValue(forKey: id)
        for i in 0..<expenses.count {
            if expenses[i].category.id == id {
                expenses[i].category = .other
            }
        }
        saveData()
    }

    // ── Dynamic Cycle Pacing & Metrics ────────────────────────────────────

    public var cycleStartDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let day = calendar.component(.day, from: now)
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        var startMonth = month
        var startYear = year
        if day < cycleStartDay {
            startMonth -= 1
            if startMonth < 1 {
                startMonth = 12
                startYear -= 1
            }
        }
        var comps = DateComponents(year: startYear, month: startMonth, day: min(cycleStartDay, 28))
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? now
    }

    public var cycleEndDate: Date {
        let calendar = Calendar.current
        let start = cycleStartDate
        let startMonth = calendar.component(.month, from: start)
        let startYear = calendar.component(.year, from: start)
        
        var endMonth = startMonth + 1
        var endYear = startYear
        if endMonth > 12 {
            endMonth = 1
            endYear += 1
        }
        var comps = DateComponents(year: endYear, month: endMonth, day: min(cycleStartDay, 28))
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps) ?? Date()
    }

    public var totalDaysInCycle: Int {
        let diff = Calendar.current.dateComponents([.day], from: cycleStartDate, to: cycleEndDate)
        return max(1, diff.day ?? 30)
    }

    public var daysElapsedInCycle: Int {
        let diff = Calendar.current.dateComponents([.day], from: cycleStartDate, to: Date())
        return max(1, min(totalDaysInCycle, (diff.day ?? 0) + 1))
    }

    public var daysRemainingInCycle: Int {
        max(0, totalDaysInCycle - daysElapsedInCycle)
    }

    public var daysRemainingIncludingToday: Int {
        max(1, totalDaysInCycle - daysElapsedInCycle + 1)
    }

    public var currentPeriodExpenses: [Expense] {
        let start = cycleStartDate
        let end = cycleEndDate
        return expenses.filter { exp in
            exp.isExpense && exp.date >= start && exp.date < end
        }
    }

    public var todayExpenses: [Expense] {
        let calendar = Calendar.current
        return expenses.filter { calendar.isDateInToday($0.date) && $0.isExpense }
    }

    public var todaySpend: Double {
        todayExpenses.reduce(0.0) { $0 + $1.amount }
    }

    public var currentPeriodTotal: Double {
        currentPeriodExpenses.reduce(0.0) { $0 + $1.amount }
    }

    public var remainingBudget: Double {
        max(0.0, monthlyBudget - currentPeriodTotal)
    }

    public var budgetBurnPercentage: Double {
        guard monthlyBudget > 0 else { return 0.0 }
        return min(1.0, currentPeriodTotal / monthlyBudget)
    }

    // Dynamic Daily Allowance based strictly on remaining monthly balance
    public var spentBeforeToday: Double {
        max(0.0, currentPeriodTotal - todaySpend)
    }

    public var remainingMonthBalance: Double {
        max(0.0, monthlyBudget - spentBeforeToday)
    }

    public var dynamicDailyBudget: Double {
        guard remainingMonthBalance > 0 else { return 0.0 }
        return remainingMonthBalance / Double(daysRemainingIncludingToday)
    }

    public var dailyBudget: Double {
        dynamicDailyBudget
    }

    public var todayRemainingBudget: Double {
        max(0.0, dynamicDailyBudget - todaySpend)
    }

    public var todayBudgetBurnPercentage: Double {
        guard dynamicDailyBudget > 0 else { return todaySpend > 0 ? 1.0 : 0.0 }
        return min(1.0, todaySpend / dynamicDailyBudget)
    }

    public func spentForCategory(_ category: ExpenseCategory) -> Double {
        currentPeriodExpenses
            .filter { $0.category == category }
            .reduce(0.0) { $0 + $1.amount }
    }

    public var categoryBreakdown: [ExpenseCategory: Double] {
        var map: [ExpenseCategory: Double] = [:]
        for exp in currentPeriodExpenses {
            map[exp.category, default: 0.0] += exp.amount
        }
        return map
    }

    public var dailySpendAverage: Double {
        currentPeriodTotal / Double(daysElapsedInCycle)
    }

    public var projectedMonthEnd: Double {
        currentPeriodTotal + (dailySpendAverage * Double(daysRemainingInCycle))
    }

    // ── Period Comparison Helpers (Trends & Analytics) ───────────────────

    public var previousCycleStartDate: Date {
        let calendar = Calendar.current
        let currentStart = cycleStartDate
        return calendar.date(byAdding: .month, value: -1, to: currentStart) ?? currentStart.addingTimeInterval(-86400 * 30)
    }

    public var previousCycleEndDate: Date {
        cycleStartDate
    }

    public var previousPeriodExpenses: [Expense] {
        let start = previousCycleStartDate
        let end = previousCycleEndDate
        return expenses.filter { exp in
            exp.isExpense && exp.date >= start && exp.date < end
        }
    }

    public var previousPeriodTotal: Double {
        previousPeriodExpenses.reduce(0.0) { $0 + $1.amount }
    }

    public var previousPeriodPacedSpend: Double {
        // Spend in the previous cycle up to the matching number of elapsed days
        let calendar = Calendar.current
        let start = previousCycleStartDate
        let targetEnd = calendar.date(byAdding: .day, value: daysElapsedInCycle, to: start) ?? cycleStartDate
        return expenses.filter { exp in
            exp.isExpense && exp.date >= start && exp.date < targetEnd
        }.reduce(0.0) { $0 + $1.amount }
    }

    public var last7DaysSpend: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        return expenses.filter { exp in
            exp.isExpense && exp.date >= sevenDaysAgo && exp.date <= Date()
        }.reduce(0.0) { $0 + $1.amount }
    }

    public var previous7DaysSpend: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -13, to: today) ?? today
        return expenses.filter { exp in
            exp.isExpense && exp.date >= fourteenDaysAgo && exp.date < sevenDaysAgo
        }.reduce(0.0) { $0 + $1.amount }
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

    public func exportJsonVault() -> String {
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
            goals: goals,
            netWorth: netWorth,
            globalTags: globalTags,
            appThemeMode: appThemeMode,
            appAccentColorName: appAccentColorName
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let raw = try? encoder.encode(data), let str = String(data: raw, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    public func importJsonVault(content: String) -> Bool {
        guard let raw = content.data(using: .utf8) else { return false }
        do {
            let decoded = try JSONDecoder().decode(PersistedData.self, from: raw)
            self.expenses = decoded.expenses
            self.monthlyBudget = decoded.monthlyBudget
            self.cycleStartDay = decoded.cycleStartDay
            self.baseMonthlyIncome = decoded.baseMonthlyIncome
            self.payDay = decoded.payDay
            self.categoryBudgets = decoded.categoryBudgets
            self.summaryEnabled = decoded.summaryEnabled
            self.summaryPeriod = decoded.summaryPeriod
            self.recurringBills = decoded.recurringBills
            if let loadedGoals = decoded.goals {
                self.goals = loadedGoals
            }
            if let loadedNetWorth = decoded.netWorth {
                self.netWorth = loadedNetWorth
            }
            if let loadedTags = decoded.globalTags {
                self.globalTags = loadedTags
            }
            self.appThemeMode = decoded.appThemeMode ?? "system"
            self.appAccentColorName = decoded.appAccentColorName ?? "blue"
            saveData()
            return true
        } catch {
            print("Failed to import JSON vault: \(error)")
            return false
        }
    }

    public func deleteAllData() {
        expenses.removeAll()
        categoryBudgets.removeAll()
        recurringBills.removeAll()
        goals.removeAll()
        globalTags = ["food", "work", "travel", "weekend"]
        netWorth = NetWorth(assets: 0, liabilities: 0)
        saveData()
    }
}
