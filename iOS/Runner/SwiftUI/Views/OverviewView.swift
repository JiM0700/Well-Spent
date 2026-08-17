import SwiftUI

public struct OverviewView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var searchQuery: String = ""
    @Environment(\.colorScheme) var colorScheme
    @Binding var showQuickAdd: Bool

    public init(showQuickAdd: Binding<Bool>? = nil) {
        self._showQuickAdd = showQuickAdd ?? .constant(false)
    }

    private var isDaywise: Bool {
        store.currentViewMode == "daywise"
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // ── Clean Page Header (No empty space above page name) ─
                    HStack(alignment: .center) {
                        Text("Home")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Spacer()

                        Button(action: {
                            PlatformFeedback.impact()
                            showQuickAdd = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.appSecondaryGroupedBackground)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("New Transaction")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // ── Period Picker (Segmented Control) ─────────────────
                    Picker("Period", selection: $store.currentViewMode) {
                        Text("Monthwise").tag("monthwise")
                        Text("Daywise").tag("daywise")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // ── Hero Summary Cards ────────────────────────────────
                    #if os(macOS)
                    desktopHeroGrid
                        .padding(.horizontal, 20)
                    #else
                    summaryCard
                        .padding(.horizontal, 20)
                    #endif

                    // ── Search & Filter Controls ──────────────────────────
                    filterAndSearchSection
                        .padding(.horizontal, 20)

                    // ── Activity Section Header ───────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isDaywise ? "Today's Activity" : "Monthly Transactions")
                                .font(.headline)
                            Text("\(filteredExpenses.count) \(isDaywise ? "entries today" : "entries this cycle")")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 2)

                    // ── Transaction Feed with Slide-to-Delete ─────────────
                    if filteredExpenses.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses) { expense in
                                SwipeableTransactionRow(
                                    expense: expense,
                                    formattedDate: formattedDate,
                                    onDelete: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            store.deleteExpense(id: expense.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .background(Color.appGroupedBackground)
        }
    }

    // ── Desktop 3-Card Hero Grid ──────────────────────────────────────────

    #if os(macOS)
    private var desktopHeroGrid: some View {
        let budget = isDaywise ? store.dailyBudget : store.monthlyBudget
        let spent = isDaywise ? store.todaySpend : store.currentPeriodTotal
        let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
        let isOver = spent > budget && budget > 0
        let remaining = max(0, budget - spent)

        return HStack(spacing: 14) {
            // Card 1: Active Pulse / Envelope
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isDaywise ? "TODAY'S PULSE" : "MONTHLY ENVELOPE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isOver ? "OVER BUDGET" : "\(Int(usage * 100))% USED")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : store.accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background((isOver ? Color.red : store.accentColor).opacity(0.15))
                        .clipShape(Capsule())
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", spent))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }

                ProgressView(value: usage)
                    .tint(isOver ? Color.red : store.accentColor)

                HStack {
                    Text("Limit: ₹\(Int(budget))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₹\(Int(remaining)) left")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : store.accentColor)
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)

            // Card 2: Projected Month-End Run Rate
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("PROJECTION & RUN RATE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11))
                        .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red : store.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Burn Rate")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("₹\(Int(store.dailySpendAverage))/day")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }

                Divider()
                    .opacity(0.3)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Month-End Est.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("₹\(Int(store.projectedMonthEnd))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red : Color.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Pace Status")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(store.projectedMonthEnd > store.monthlyBudget ? "Warning" : "On Track")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red : Color.green)
                    }
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)

            // Card 3: Top Category & Breakdown
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Top Category")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(store.accentColor)
                }

                let topCategory = ExpenseCategory.allCases.max(by: { (store.categoryBreakdown[$0] ?? 0) < (store.categoryBreakdown[$1] ?? 0) }) ?? .food
                let topAmt = store.categoryBreakdown[topCategory] ?? 0
                let totalMonth = store.currentPeriodTotal

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(topCategory.color.opacity(0.2))
                            .frame(width: 38, height: 38)
                        Image(systemName: topCategory.sfSymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(topCategory.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(topCategory.displayName)
                            .font(.system(size: 14, weight: .bold))
                        Text("₹\(Int(topAmt)) (\(Int(totalMonth > 0 ? (topAmt / totalMonth * 100) : 0))%)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .opacity(0.3)

                HStack {
                    Text("Active Categories: \(store.categoryBreakdown.filter { $0.value > 0 }.count)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Cycle Day \(Calendar.current.component(.day, from: Date()))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)
        }
    }
    #endif

    // ── Mobile Summary Card ───────────────────────────────────────────────

    private var summaryCard: some View {
        let budget = isDaywise ? store.dailyBudget : store.monthlyBudget
        let spent = isDaywise ? store.todaySpend : store.currentPeriodTotal
        let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
        let isOver = spent > budget && budget > 0
        let remaining = isDaywise ? store.todayRemainingBudget : store.remainingBudget

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isDaywise ? "Today's Pulse" : "Monthly Envelope")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(isOver ? "Over Budget" : "\(Int(usage * 100))% used")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isOver ? Color.red : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isOver ? Color.red.opacity(0.12) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("₹")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", spent))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                Text("of ₹\(Int(budget)) \(isDaywise ? "daily allowance" : "total monthly budget")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: usage)
                .tint(isOver ? Color.red : store.accentColor)

            Divider()
                .opacity(0.4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isDaywise ? "Remaining Today" : "Remaining Month")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("₹\(Int(remaining))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("Daily Burn")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("₹\(Int(store.dailySpendAverage))/day")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Month-End Est.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("₹\(Int(store.projectedMonthEnd))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(store.projectedMonthEnd > store.monthlyBudget ? Color.red : Color.primary)
                }
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 20)
    }

    // ── Search & Filters Section ──────────────────────────────────────────

    private var filterAndSearchSection: some View {
        VStack(spacing: 10) {
            // Search Input Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Search activities, merchants, categories...", text: $searchQuery)
                    .font(.system(size: 14))

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.appSecondaryGroupedBackground)
            )

            // Category Filter Chips Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryFilterChip(title: "All Activity", icon: nil, isSelected: store.selectedCategoryFilter == nil) {
                        PlatformFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            store.selectedCategoryFilter = nil
                        }
                    }

                    ForEach(ExpenseCategory.allCases) { cat in
                        categoryFilterChip(title: cat.displayName, icon: cat.sfSymbol, isSelected: store.selectedCategoryFilter == cat) {
                            PlatformFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                if store.selectedCategoryFilter == cat {
                                    store.selectedCategoryFilter = nil
                                } else {
                                    store.selectedCategoryFilter = cat
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func categoryFilterChip(title: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? (colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.85))
                            : Color.appSecondaryGroupedBackground
                    )
            )
            .foregroundStyle(
                isSelected
                    ? (colorScheme == .dark ? Color.white : Color.white)
                    : Color.primary
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ── Transaction Row ───────────────────────────────────────────────────

    private func transactionRow(for expense: Expense) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appSecondaryGroupedBackground)
                    .frame(width: 42, height: 42)

                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(expense.category.displayName)
                    Text("•")
                    Text(formattedDate(expense.date))
                    if !expense.notes.isEmpty {
                        Text("•")
                        Text(expense.notes)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text("₹\(String(format: "%.2f", expense.amount))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSecondaryGroupedBackground)
        )
    }

    // ── Empty State ───────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.top, 24)

            Text(isDaywise ? "No Activity Today" : "No Activity This Month")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("No transactions recorded for the current \(isDaywise ? "day" : "monthly cycle").")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let baseList: [Expense]
        if isDaywise {
            baseList = store.expenses.filter { calendar.isDateInToday($0.date) }
        } else {
            baseList = store.currentPeriodExpenses
        }

        return baseList.filter { exp in
            let matchesQuery = searchQuery.isEmpty ||
                exp.title.localizedCaseInsensitiveContains(searchQuery) ||
                exp.category.displayName.localizedCaseInsensitiveContains(searchQuery) ||
                exp.notes.localizedCaseInsensitiveContains(searchQuery)

            let matchesCat = store.selectedCategoryFilter == nil || exp.category == store.selectedCategoryFilter

            return matchesQuery && matchesCat
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
