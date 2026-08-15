import SwiftUI

public struct OverviewView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var searchQuery: String = ""
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Screen Header Title ───────────────────────────────
                    HStack {
                        Text("Overview")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // ── Period Mode Selector ──────────────────────────────
                    Picker("View Mode", selection: $store.currentViewMode) {
                        Text("Daywise").tag("daywise")
                        Text("Monthwise").tag("monthwise")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: store.currentViewMode) { _, _ in
                        UISelectionFeedbackGenerator().selectionChanged()
                    }

                    // ── Liquid Glass Summary Card ─────────────────────────
                    summaryCard
                        .padding(.horizontal)

                    // ── Category Filter Chips ─────────────────────────────
                    categoryFilterRow

                    // ── Inline Search Bar ─────────────────────────────────
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        TextField("Search activity, category...", text: $searchQuery)
                            .font(.system(size: 14.5))
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
                    .padding(.horizontal)

                    // ── Transactions Header ───────────────────────────────
                    HStack {
                        Text("Activity")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Spacer()
                        Text("\(filteredExpenses.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // ── Transaction Feed ──────────────────────────────────
                    if filteredExpenses.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredExpenses) { expense in
                                transactionRow(for: expense)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Bottom padding to clear floating dual-island dock
                    Spacer(minLength: 130)
                }
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(colorScheme == .dark ? Color(red: 0.04, green: 0.05, blue: 0.08) : Color(uiColor: .systemGroupedBackground))
        }
    }

    // ── Summary Card ──────────────────────────────────────────────────────

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
                    .foregroundStyle(isOver ? Color.red : Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((isOver ? Color.red : Color.green).opacity(0.15))
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

            // Apple Native ProgressView
            ProgressView(value: min(1.0, max(0.0, usage)))
                .tint(isOver ? Color.red : Color.green)

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
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85) : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 16, x: 0, y: 6)
        )
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

    // ── Category Filter Chips ─────────────────────────────────────────────

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: store.selectedCategoryFilter == nil) {
                    store.selectedCategoryFilter = nil
                }

                ForEach(ExpenseCategory.allCases) { cat in
                    filterChip(title: cat.displayName, isSelected: store.selectedCategoryFilter == cat) {
                        store.selectedCategoryFilter = cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.green : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.green.opacity(0.18) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.green.opacity(0.35) : Color.clear, lineWidth: 0.8)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ── Transaction Row ───────────────────────────────────────────────────

    private func transactionRow(for expense: Expense) -> some View {
        HStack(spacing: 14) {
            // Category Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(expense.category.color.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.sfSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(expense.category.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(expense.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₹")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.2f", expense.amount))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.7) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.05), lineWidth: 0.6)
                )
        )
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
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No activity recorded")
                .font(.headline)
            Text("Tap the floating ＋ button to record your first expense.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    private var filteredExpenses: [Expense] {
        store.expenses.filter { expense in
            let matchesCategory = store.selectedCategoryFilter == nil || expense.category == store.selectedCategoryFilter
            let matchesQuery = searchQuery.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchQuery) ||
                expense.category.displayName.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesQuery
        }
    }
}
