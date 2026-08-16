import SwiftUI

public struct CategoriesView: View {
    @EnvironmentObject var store: ExpenseStore
    @State private var selectedCategoryForEdit: ExpenseCategory? = nil
    @State private var newBudgetString: String = ""
    @State private var showEditDialog: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var showQuickAdd: Bool

    public init(showQuickAdd: Binding<Bool>? = nil) {
        self._showQuickAdd = showQuickAdd ?? .constant(false)
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // ── Clean Page Header (No empty space above page name) ─
                    HStack(alignment: .center) {
                        Text("Budgets")
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

                    // ── Allocation Summary Bar ────────────────────────────
                    allocationSummaryCard
                        .padding(.horizontal, 20)

                    // ── Category Envelope Grid ────────────────────────────
                    #if os(macOS)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(ExpenseCategory.allCases) { category in
                            envelopeCard(for: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    #else
                    LazyVStack(spacing: 12) {
                        ForEach(ExpenseCategory.allCases) { category in
                            envelopeCard(for: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    #endif
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .background(Color.appGroupedBackground)
            .alert("Edit Category Budget Target", isPresented: $showEditDialog) {
                TextField("Target Amount", text: $newBudgetString)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Button("Save Target") {
                    if let cat = selectedCategoryForEdit, let amt = Double(newBudgetString) {
                        PlatformFeedback.success()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            store.updateCategoryBudget(category: cat, amount: amt)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(selectedCategoryForEdit?.displayName ?? "")
            }
        }
    }

    // ── Allocation Summary Card ───────────────────────────────────────────

    private var allocationSummaryCard: some View {
        let totalAllocated = ExpenseCategory.allCases.reduce(0.0) { $0 + store.getCategoryBudget(category: $1) }
        let budget = store.monthlyBudget
        let percentAllocated = budget > 0 ? (totalAllocated / budget) : 0.0

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Total Allocated Targets")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("₹\(Int(totalAllocated))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text("of ₹\(Int(budget)) monthly cap")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(percentAllocated * 100))% Target Allocated")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(percentAllocated > 1.0 ? Color.red : store.accentColor)

                ProgressView(value: min(1.0, percentAllocated))
                    .frame(width: 110)
                    .tint(percentAllocated > 1.0 ? Color.red : store.accentColor)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }

    // ── Envelope Card ─────────────────────────────────────────────────────

    private func envelopeCard(for category: ExpenseCategory) -> some View {
        let budget = store.getCategoryBudget(category: category)
        let spent = store.categoryBreakdown[category] ?? 0.0
        let usage = budget > 0 ? min(1.0, spent / budget) : 0.0
        let isOver = spent > budget && budget > 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.sfSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.headline.weight(.bold))
                    Text("Budget: ₹\(Int(budget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: {
                    PlatformFeedback.selection()
                    selectedCategoryForEdit = category
                    newBudgetString = String(format: "%.0f", budget)
                    showEditDialog = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            ProgressView(value: usage)
                .tint(isOver ? Color.red : category.color)

            HStack {
                Text("Spent: ₹\(Int(spent))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isOver ? Color.red : Color.primary)

                Spacer()

                if isOver {
                    Text("Over by ₹\(Int(spent - budget))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.red)
                } else {
                    Text("₹\(Int(max(0, budget - spent))) left")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }
}
