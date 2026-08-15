import SwiftUI

public struct OverviewView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var searchQuery: String = ""
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 18) {
                    // ── Header Bar ─────────────────────────────────────────
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // ── Liquid Glass Hero Summary Cards ───────────────────
                    #if os(macOS)
                    desktopHeroGrid
                        .padding(.horizontal, 20)
                    #else
                    summaryCard
                        .padding(.horizontal, 16)
                    #endif

                    // ── Search & Filter Controls ──────────────────────────
                    filterAndSearchSection
                        .padding(.horizontal, 20)

                    // ── Activity Section Header ───────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activity & Transactions")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("\(filteredExpenses.count) transactions recorded")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // ── Transaction Feed ──────────────────────────────────
                    if filteredExpenses.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses) { expense in
                                transactionRow(for: expense)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    #if os(iOS)
                    Spacer(minLength: 120)
                    #else
                    Spacer(minLength: 40)
                    #endif
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .background(colorScheme == .dark ? Color.black : Color.appGroupedBackground)
        }
    }

    // ── Header Bar ────────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Overview")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(store.currentViewMode == "daywise" ? "Today's Financial Pulse" : "Monthly Envelope Cycle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            // Custom Apple 26/27 Liquid Glass Period Capsule
            HStack(spacing: 2) {
                periodButton(title: "Monthwise", mode: "monthwise")
                periodButton(title: "Daywise", mode: "daywise")
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.40 : 0.70),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    )
            )
            .fixedSize()
        }
    }

    private func periodButton(title: String, mode: String) -> some View {
        let isSelected = store.currentViewMode == mode
        return Button(action: {
            if store.currentViewMode != mode {
                PlatformFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    store.currentViewMode = mode
                }
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(store.accentColor)
                                .shadow(color: store.accentColor.opacity(0.45), radius: 6, x: 0, y: 2)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ── Desktop 3-Card Hero Grid ──────────────────────────────────────────

    #if os(macOS)
    private var desktopHeroGrid: some View {
        let budget = store.monthlyBudget
        let spent = store.currentPeriodTotal
        let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
        let isOver = spent > budget && budget > 0
        let remaining = max(0, budget - spent)

        return HStack(spacing: 14) {
            // Card 1: Monthly Envelope
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MONTHLY ENVELOPE")
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
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                }

                // Glowing Liquid Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOver ? [Color.orange, Color.red] : [store.accentColor, store.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * CGFloat(usage)), height: 7)
                            .shadow(color: (isOver ? Color.red : store.accentColor).opacity(0.4), radius: 4, x: 0, y: 1)
                    }
                }
                .frame(height: 7)

                HStack {
                    Text("₹\(Int(remaining)) left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isOver ? Color.red : Color.primary)
                    Spacer()
                    Text("Budget: ₹\(Int(budget))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)

            // Card 2: Daily Pulse & Run Rate
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("DAILY RUN RATE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("₹")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(Int(store.dailySpendAverage))")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("/day")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .opacity(0.3)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Month Est.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text("₹\(Int(store.projectedMonthEnd))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(store.projectedMonthEnd > budget ? Color.red : Color.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Cycle Status")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(store.projectedMonthEnd > budget ? "Warning" : "Optimal")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(store.projectedMonthEnd > budget ? Color.red : Color.green)
                    }
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)

            // Card 3: Top Category & Breakdown
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TOP CATEGORY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(store.accentColor)
                }

                let topCategory = ExpenseCategory.allCases.max(by: { (store.categoryBreakdown[$0] ?? 0) < (store.categoryBreakdown[$1] ?? 0) }) ?? .food
                let topAmt = store.categoryBreakdown[topCategory] ?? 0

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
                        Text("₹\(Int(topAmt)) (\(Int(spent > 0 ? (topAmt / spent * 100) : 0))%)")
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
        let budget = store.monthlyBudget
        let spent = store.currentPeriodTotal
        let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
        let isOver = spent > budget && budget > 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(store.currentViewMode == "daywise" ? "Today's Pulse" : "Monthly Envelope")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(isOver ? "Over Budget" : "\(Int(usage * 100))% used")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isOver ? Color.red : store.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((isOver ? Color.red : store.accentColor).opacity(0.15))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("₹")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                    Text(String(format: "%.2f", spent))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                HStack(spacing: 3) {
                    Text("of")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("₹\(Int(budget))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("total budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: min(1.0, max(0.0, usage)))
                .tint(isOver ? Color.red : store.accentColor)

            Divider()
                .opacity(0.5)

            HStack {
                metricColumn(title: "Remaining", value: "₹\(Int(store.remainingBudget))", color: .primary)
                Spacer()
                metricColumn(title: "Daily Burn", value: "₹\(Int(store.dailySpendAverage))/day", color: .secondary)
                Spacer()
                metricColumn(title: "Month-End Est.", value: "₹\(Int(store.projectedMonthEnd))", color: isOver ? .red : .primary)
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 20)
    }

    private func metricColumn(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // ── Filter & Search Section ───────────────────────────────────────────

    private var filterAndSearchSection: some View {
        VStack(spacing: 12) {
            // Search Bar with Liquid Glass styling
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                TextField("Search activities, merchants, categories...", text: $searchQuery)
                    .font(.system(size: 13.5))

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .liquidGlassCard(cornerRadius: 12, interactiveHover: false)

            // Category Filter Chips Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All Activity", isSelected: store.selectedCategoryFilter == nil) {
                        store.selectedCategoryFilter = nil
                    }

                    ForEach(ExpenseCategory.allCases) { cat in
                        filterChip(title: cat.displayName, icon: cat.sfSymbol, color: cat.color, isSelected: store.selectedCategoryFilter == cat) {
                            store.selectedCategoryFilter = cat
                        }
                    }
                }
            }
        }
    }

    private func filterChip(title: String, icon: String? = nil, color: Color? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            PlatformFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                action()
            }
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color ?? store.accentColor)
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? (color ?? store.accentColor) : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill((color ?? store.accentColor).opacity(0.18))
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                (color ?? store.accentColor).opacity(0.6),
                                                (color ?? store.accentColor).opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                    } else {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ── Transaction Row with Liquid Glass ─────────────────────────────────

    private func transactionRow(for expense: Expense) -> some View {
        HStack(spacing: 14) {
            // Glowing Avatar Icon
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(expense.category.color.opacity(0.3), lineWidth: 0.8)
                    )

                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(expense.category.displayName)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(expense.date, style: .date)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)

                    if !expense.notes.isEmpty {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(expense.notes)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Amount Display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₹")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f", expense.amount))
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassCard(cornerRadius: 14)
        .contextMenu {
            Button(role: .destructive, action: {
                withAnimation {
                    store.deleteExpense(id: expense.id)
                }
            }) {
                Label("Delete Entry", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Activity Recorded",
            systemImage: "tray",
            description: Text("Use the ＋ Add Expense action to record your first transaction.")
        )
        .padding(.vertical, 40)
    }

    private var filteredExpenses: [Expense] {
        store.expenses.filter { expense in
            let matchesCategory = store.selectedCategoryFilter == nil || expense.category == store.selectedCategoryFilter
            let matchesQuery = searchQuery.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchQuery) ||
                expense.category.displayName.localizedCaseInsensitiveContains(searchQuery) ||
                expense.notes.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesQuery
        }
    }
}
